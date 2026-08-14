-- Create epilepsy_risk_assessments table
create table if not exists epilepsy_risk_assessments (
  id uuid default gen_random_uuid() primary key,
  service_user_id uuid not null references service_users(id) on delete cascade,
  assessor_id uuid references users(id),
  
  -- Seizure Information
  seizure_type text not null check (seizure_type in ('tonic-clonic', 'absence', 'focal', 'atonic', 'myoclonic', 'unknown')),
  seizure_frequency text not null check (seizure_frequency in ('daily', 'weekly', 'monthly', 'rarely', 'none')),
  seizure_frequency_details text,
  seizure_triggers text[], -- Array of triggers
  last_seizure_date date,
  
  -- Medication Information
  medication_name text,
  medication_dose text,
  medication_times text[], -- Array of times (e.g., ['morning', 'evening'])
  medication_compliance boolean default true,
  
  -- Seizure Characteristics
  typical_duration interval, -- Duration of typical seizures
  warning_signs text, -- Aura description
  recovery_time interval, -- Time to full recovery
  post_seizure_behaviour text,
  
  -- Risk Assessment
  injury_risk_factors text[], -- Array of injury risks
  safeguarding_concerns boolean default false,
  unwitnessed_seizure_locations text[], -- Where seizures might occur unobserved
  
  -- Emergency Protocol
  emergency_protocol text, -- When to call ambulance
  rescue_medication_name text,
  rescue_medication_dose text,
  rescue_medication_administered boolean default false,
  rescue_medication_response text,
  
  -- Assessment Metadata
  overall_risk_level text check (overall_risk_level in ('low', 'medium', 'high')),
  risk_factors_identified text[],
  monitoring_requirements text,
  next_review_date date,
  
  -- Status and Signatures
  status text default 'draft' check (status in ('draft', 'completed', 'reviewed')),
  signature text,
  reviewed_by uuid references users(id),
  reviewed_at timestamp with time zone,
  
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- Create indexes for performance
create index if not exists idx_epilepsy_assessments_service_user on epilepsy_risk_assessments(service_user_id);
create index if not exists idx_epilepsy_assessments_assessor on epilepsy_risk_assessments(assessor_id);
create index if not exists idx_epilepsy_assessments_date on epilepsy_risk_assessments(created_at);
create index if not exists idx_epilepsy_assessments_risk_level on epilepsy_risk_assessments(overall_risk_level);

-- Create function to update updated_at timestamp
create or replace function update_epilepsy_assessment_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

-- Create trigger to automatically update updated_at
drop trigger if exists update_epilepsy_assessment_updated_at on epilepsy_risk_assessments;
create trigger update_epilepsy_assessment_updated_at
  before update on epilepsy_risk_assessments
  for each row execute function update_epilepsy_assessment_updated_at();

-- Create function to calculate overall risk level
create or replace function calculate_epilepsy_risk_level(
  p_seizure_frequency text,
  p_seizure_triggers text[],
  p_medication_compliance boolean,
  p_injury_risk_factors text[],
  p_safeguarding_concerns boolean
) returns text as $$
declare
  risk_score integer := 0;
begin
  -- Base risk from frequency
  case p_seizure_frequency
    when 'daily' then risk_score := risk_score + 4;
    when 'weekly' then risk_score := risk_score + 3;
    when 'monthly' then risk_score := risk_score + 2;
    when 'rarely' then risk_score := risk_score + 1;
    when 'none' then risk_score := risk_score + 0;
  end case;
  
  -- Additional risk factors
  if not p_medication_compliance then
    risk_score := risk_score + 2;
  end if;
  
  if p_safeguarding_concerns then
    risk_score := risk_score + 3;
  end if;
  
  if array_length(p_injury_risk_factors, 1) > 0 then
    risk_score := risk_score + array_length(p_injury_risk_factors, 1);
  end if;
  
  -- Determine risk level
  if risk_score <= 3 then
    return 'low';
  elsif risk_score <= 6 then
    return 'medium';
  else
    return 'high';
  end if;
end;
$$ language plpgsql;

-- Create function to flag high-risk epilepsy assessments
create or replace function flag_high_risk_epilepsy_assessments()
returns table (
  assessment_id uuid,
  service_user_id uuid,
  service_user_name text,
  seizure_frequency text,
  overall_risk_level text,
  last_seizure_date date,
  medication_compliance boolean,
  safeguarding_concerns boolean
) as $$
begin
  return query
  select 
    ea.id,
    ea.service_user_id,
    su.full_name,
    ea.seizure_frequency,
    ea.overall_risk_level,
    ea.last_seizure_date,
    ea.medication_compliance,
    ea.safeguarding_concerns
  from epilepsy_risk_assessments ea
  join service_users su on ea.service_user_id = su.id
  where ea.overall_risk_level = 'high'
     or ea.seizure_frequency in ('daily', 'weekly')
     or not ea.medication_compliance
     or ea.safeguarding_concerns = true
  order by ea.overall_risk_level desc, ea.last_seizure_date desc;
end;
$$ language plpgsql;

-- Create function to get epilepsy assessment summary
create or replace function get_epilepsy_assessment_summary(p_service_user_id uuid)
returns jsonb as $$
declare
  latest_assessment epilepsy_risk_assessments;
  summary jsonb;
begin
  select * into latest_assessment
  from epilepsy_risk_assessments
  where service_user_id = p_service_user_id
  order by created_at desc
  limit 1;
  
  if latest_assessment is null then
    return jsonb_build_object(
      'has_assessment', false,
      'message', 'No epilepsy risk assessment found'
    );
  end if;
  
  summary := jsonb_build_object(
    'has_assessment', true,
    'seizure_type', latest_assessment.seizure_type,
    'seizure_frequency', latest_assessment.seizure_frequency,
    'last_seizure_date', latest_assessment.last_seizure_date,
    'medication_name', latest_assessment.medication_name,
    'medication_compliance', latest_assessment.medication_compliance,
    'overall_risk_level', latest_assessment.overall_risk_level,
    'safeguarding_concerns', latest_assessment.safeguarding_concerns,
    'injury_risk_factors', latest_assessment.injury_risk_factors,
    'emergency_protocol', latest_assessment.emergency_protocol,
    'next_review_date', latest_assessment.next_review_date,
    'assessment_date', latest_assessment.created_at
  );
  
  return summary;
end;
$$ language plpgsql;

-- Create function to validate epilepsy assessment completeness
create or replace function validate_epilepsy_assessment_completeness(p_assessment_id uuid)
returns jsonb as $$
declare
  assessment epilepsy_risk_assessments;
  is_complete boolean := true;
  missing_fields text[] := array[]::text[];
  validation_result jsonb;
begin
  select * into assessment from epilepsy_risk_assessments where id = p_assessment_id;
  
  if assessment is null then
    return jsonb_build_object(
      'valid', false,
      'message', 'Assessment not found'
    );
  end if;
  
  -- Check required fields
  if assessment.seizure_type is null or assessment.seizure_type = '' then
    is_complete := false;
    missing_fields := array_append(missing_fields, 'seizure_type');
  end if;
  
  if assessment.seizure_frequency is null or assessment.seizure_frequency = '' then
    is_complete := false;
    missing_fields := array_append(missing_fields, 'seizure_frequency');
  end if;
  
  if assessment.medication_compliance is null then
    is_complete := false;
    missing_fields := array_append(missing_fields, 'medication_compliance');
  end if;
  
  if assessment.overall_risk_level is null or assessment.overall_risk_level = '' then
    is_complete := false;
    missing_fields := array_append(missing_fields, 'overall_risk_level');
  end if;
  
  if assessment.emergency_protocol is null or assessment.emergency_protocol = '' then
    is_complete := false;
    missing_fields := array_append(missing_fields, 'emergency_protocol');
  end if;
  
  validation_result := jsonb_build_object(
    'valid', is_complete,
    'missing_fields', missing_fields,
    'message', case 
      when is_complete then 'Assessment is complete'
      else 'Assessment is incomplete. Missing fields: ' || array_to_string(missing_fields, ', ')
    end
  );
  
  return validation_result;
end;
$$ language plpgsql;

-- Create function to submit epilepsy assessment
create or replace function submit_epilepsy_assessment(
  p_assessment_id uuid,
  p_signature_data text
) returns void as $$
begin
  update epilepsy_risk_assessments
  set 
    status = 'completed',
    signature = p_signature_data,
    updated_at = now()
  where id = p_assessment_id;
end;
$$ language plpgsql;

-- Create RLS policies
alter table epilepsy_risk_assessments enable row level security;

-- Allow authenticated users to view their own assessments and those they can access
create policy "Users can view epilepsy assessments" on epilepsy_risk_assessments
  for select using (
    auth.role() = 'authenticated' and (
      assessor_id = auth.uid() or
      service_user_id in (
        select id from service_users where carehome_id in (
          select carehome_id from carer_carehomes where carer_id = auth.uid()
        )
      )
    )
  );

-- Allow authenticated users to insert assessments
create policy "Users can insert epilepsy assessments" on epilepsy_risk_assessments
  for insert with check (auth.role() = 'authenticated');

-- Allow users to update their own assessments
create policy "Users can update epilepsy assessments" on epilepsy_risk_assessments
  for update using (
    auth.role() = 'authenticated' and (
      assessor_id = auth.uid() or
      auth.has_role('admin')
    )
  );

-- Allow users to delete their own assessments
create policy "Users can delete epilepsy assessments" on epilepsy_risk_assessments
  for delete using (
    auth.role() = 'authenticated' and (
      assessor_id = auth.uid() or
      auth.has_role('admin')
    )
  );