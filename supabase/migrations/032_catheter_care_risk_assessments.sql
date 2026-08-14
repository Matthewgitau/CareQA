-- Create catheter_care_risk_assessments table
create table if not exists catheter_care_risk_assessments (
  id uuid default gen_random_uuid() primary key,
  service_user_id uuid not null references service_users(id) on delete cascade,
  assessor_id uuid references profiles(id),
  assessment_date timestamp with time zone default now(),
  
  -- Catheter Information
  catheter_type text not null check (catheter_type in ('indwelling', 'suprapubic', 'intermittent')),
  insertion_date date,
  next_change_date date,
  catheter_size text, -- e.g., "14Fr", "16Fr", "18Fr"
  balloon_volume text, -- e.g., "10ml", "30ml"
  
  -- Urine Monitoring
  urine_output_morning integer, -- ml per shift
  urine_output_afternoon integer,
  urine_output_night integer,
  urine_appearance text check (urine_appearance in ('clear', 'cloudy', 'blood-stained', 'other')),
  urine_appearance_notes text,
  
  -- Infection Monitoring
  fever_present boolean default false,
  pain_present boolean default false,
  urine_odour_present boolean default false,
  infection_notes text,
  
  -- Skin Condition
  skin_condition text check (skin_condition in ('intact', 'redness', 'irritation', 'breakdown', 'other')),
  skin_condition_notes text,
  
  -- Drainage System
  bag_position_correct boolean default true,
  bag_secure boolean default true,
  tubing_secure boolean default true,
  drainage_notes text,
  
  -- Patient Comfort
  pain_level integer check (pain_level >= 0 and pain_level <= 10), -- 0-10 scale
  comfort_level integer check (comfort_level >= 1 and comfort_level <= 5), -- 1-5 scale
  patient_complaints text,
  
  -- Risk Assessment
  infection_risk boolean default false,
  blockage_risk boolean default false,
  dislodgement_risk boolean default false,
  skin_breakdown_risk boolean default false,
  overall_risk_level text check (overall_risk_level in ('low', 'medium', 'high')),
  
  -- Actions and Monitoring
  actions_required boolean default false,
  actions_details text,
  monitoring_frequency text, -- e.g., "4 hourly", "8 hourly", "12 hourly"
  next_review_date date,
  
  -- Status and Signatures
  status text default 'draft' check (status in ('draft', 'completed', 'reviewed')),
  signature text,
  reviewed_by uuid references profiles(id),
  reviewed_at timestamp with time zone,
  
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- Create indexes for performance
create index if not exists idx_catheter_care_service_user on catheter_care_risk_assessments(service_user_id);
create index if not exists idx_catheter_care_assessor on catheter_care_risk_assessments(assessor_id);
create index if not exists idx_catheter_care_date on catheter_care_risk_assessments(assessment_date);
create index if not exists idx_catheter_care_next_change on catheter_care_risk_assessments(next_change_date);
create index if not exists idx_catheter_care_infection_risk on catheter_care_risk_assessments(infection_risk);

-- Create function to update updated_at timestamp
create or replace function update_catheter_care_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

-- Create trigger to automatically update updated_at
drop trigger if exists update_catheter_care_updated_at on catheter_care_risk_assessments;
create trigger update_catheter_care_updated_at
  before update on catheter_care_risk_assessments
  for each row execute function update_catheter_care_updated_at();

-- Create function to submit catheter care assessment
create or replace function submit_catheter_care_assessment(
  assessment_id uuid,
  signature_data text
)
returns boolean
language plpgsql
security definer
as $$
begin
  -- Validate that the assessment exists and is not already completed
  if not exists (select 1 from catheter_care_risk_assessments where id = assessment_id) then
    raise exception 'Assessment not found';
  end if;
  
  -- Update the assessment to completed status with signature
  update catheter_care_risk_assessments 
  set status = 'completed',
      signature = signature_data,
      updated_at = now()
  where id = assessment_id;
  
  return true;
end;
$$;

-- Create function to get catheter care assessment summary
create or replace function get_catheter_care_assessment_summary(
  service_user_id_param uuid
)
returns jsonb
language plpgsql
security definer
as $$
declare
  summary jsonb;
begin
  select jsonb_build_object(
    'total_assessments', count(*),
    'completed_assessments', count(*) filter (where status = 'completed'),
    'infection_risk_count', count(*) filter (where infection_risk = true),
    'high_risk_count', count(*) filter (where overall_risk_level = 'high'),
    'due_for_change_count', count(*) filter (where next_change_date <= current_date + interval '7 days'),
    'latest_assessment', (
      select jsonb_build_object(
        'id', id,
        'assessment_date', assessment_date,
        'catheter_type', catheter_type,
        'next_change_date', next_change_date,
        'infection_risk', infection_risk,
        'overall_risk_level', overall_risk_level,
        'status', status
      ) from catheter_care_risk_assessments 
      where service_user_id = service_user_id_param 
      order by assessment_date desc 
      limit 1
    ),
    'upcoming_changes', (
      select jsonb_agg(
        jsonb_build_object(
          'id', id,
          'catheter_type', catheter_type,
          'next_change_date', next_change_date,
          'days_until_change', next_change_date - current_date
        )
      ) from catheter_care_risk_assessments 
      where service_user_id = service_user_id_param 
        and next_change_date between current_date and current_date + interval '7 days'
        and status = 'completed'
    )
  ) into summary
  from catheter_care_risk_assessments 
  where service_user_id = service_user_id_param;
  
  return coalesce(summary, '{}');
end;
$$;

-- Create function to validate catheter care assessment completeness
create or replace function validate_catheter_care_assessment_completeness(
  assessment_id uuid
)
returns jsonb
language plpgsql
security definer
as $$
declare
  assessment_record catheter_care_risk_assessments;
  validation_result jsonb;
  missing_fields text[] := '{}';
  warnings text[] := '{}';
begin
  -- Get the assessment record
  select * into assessment_record 
  from catheter_care_risk_assessments 
  where id = assessment_id;
  
  if not found then
    raise exception 'Assessment not found';
  end if;
  
  -- Check required fields
  if assessment_record.catheter_type is null then
    missing_fields := array_append(missing_fields, 'catheter_type');
  end if;
  
  if assessment_record.insertion_date is null then
    missing_fields := array_append(missing_fields, 'insertion_date');
  end if;
  
  if assessment_record.next_change_date is null then
    missing_fields := array_append(missing_fields, 'next_change_date');
  end if;
  
  if assessment_record.catheter_size is null then
    missing_fields := array_append(missing_fields, 'catheter_size');
  end if;
  
  if assessment_record.balloon_volume is null then
    missing_fields := array_append(missing_fields, 'balloon_volume');
  end if;
  
  -- Check for infection signs
  if assessment_record.fever_present or assessment_record.pain_present or assessment_record.urine_odour_present then
    warnings := array_append(warnings, 'Infection signs detected - monitor closely');
  end if;
  
  -- Check for high risk indicators
  if assessment_record.overall_risk_level = 'high' then
    warnings := array_append(warnings, 'High risk assessment - increased monitoring required');
  end if;
  
  -- Check if next change date is approaching
  if assessment_record.next_change_date <= current_date + interval '3 days' then
    warnings := array_append(warnings, 'Catheter change due within 3 days');
  elsif assessment_record.next_change_date <= current_date + interval '7 days' then
    warnings := array_append(warnings, 'Catheter change due within 7 days');
  end if;
  
  -- Build validation result
  validation_result := jsonb_build_object(
    'is_complete', array_length(missing_fields, 1) = 0,
    'missing_fields', missing_fields,
    'warnings', warnings,
    'has_infection_risk', assessment_record.infection_risk,
    'overall_risk_level', assessment_record.overall_risk_level
  );
  
  return validation_result;
end;
$$;

-- Create function to get upcoming catheter changes
create or replace function get_upcoming_catheter_changes(
  days_ahead integer default 7
)
returns table (
  service_user_name text,
  service_user_id uuid,
  catheter_type text,
  next_change_date date,
  days_until_change integer,
  assessment_id uuid
)
language sql
security definer
as $$
  select 
    su.full_name,
    su.id,
    c.catheter_type,
    c.next_change_date,
    c.next_change_date - current_date,
    c.id
  from catheter_care_risk_assessments c
  join service_users su on c.service_user_id = su.id
  where c.next_change_date between current_date and current_date + (days_ahead || ' days')::interval
    and c.status = 'completed'
  order by c.next_change_date asc;
$$;

-- Create function to flag high-risk catheter assessments
create or replace function flag_high_risk_catheter_assessments()
returns table (
  service_user_name text,
  service_user_id uuid,
  assessment_id uuid,
  risk_factors text[]
)
language sql
security definer
as $$
  select 
    su.full_name,
    su.id,
    c.id,
    array[
      case when c.infection_risk then 'Infection Risk' end,
      case when c.blockage_risk then 'Blockage Risk' end,
      case when c.dislodgement_risk then 'Dislodgement Risk' end,
      case when c.skin_breakdown_risk then 'Skin Breakdown Risk' end
    ] filter (where true)
  from catheter_care_risk_assessments c
  join service_users su on c.service_user_id = su.id
  where c.overall_risk_level = 'high'
    and c.status = 'completed'
  order by c.assessment_date desc;
$$;

-- RLS Policies
alter table catheter_care_risk_assessments enable row level security;

-- Allow authenticated users to view their own assessments and those they can access
create policy "Users can view catheter care assessments" on catheter_care_risk_assessments
  for select using (
    auth.uid() in (
      select carehome_users.user_id 
      from carehome_users 
      where carehome_users.carehome_id = (
        select su.carehome_id 
        from service_users su 
        where su.id = catheter_care_risk_assessments.service_user_id
      )
    )
  );

-- Allow authenticated users to insert assessments
create policy "Users can insert catheter care assessments" on catheter_care_risk_assessments
  for insert with check (
    auth.uid() in (
      select carehome_users.user_id 
      from carehome_users 
      where carehome_users.carehome_id = (
        select su.carehome_id 
        from service_users su 
        where su.id = catheter_care_risk_assessments.service_user_id
      )
    )
  );

-- Allow users to update their own assessments
create policy "Users can update catheter care assessments" on catheter_care_risk_assessments
  for update using (
    auth.uid() = assessor_id or
    auth.uid() in (
      select carehome_users.user_id 
      from carehome_users 
      where carehome_users.carehome_id = (
        select su.carehome_id 
        from service_users su 
        where su.id = catheter_care_risk_assessments.service_user_id
      )
    )
  );

-- Allow users to delete their own assessments
create policy "Users can delete catheter care assessments" on catheter_care_risk_assessments
  for delete using (
    auth.uid() = assessor_id or
    auth.uid() in (
      select carehome_users.user_id 
      from carehome_users 
      where carehome_users.carehome_id = (
        select su.carehome_id 
        from service_users su 
        where su.id = catheter_care_risk_assessments.service_user_id
      )
    )
  );