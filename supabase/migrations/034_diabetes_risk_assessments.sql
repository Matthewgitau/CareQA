-- Create diabetes_risk_assessments table
create table if not exists diabetes_risk_assessments (
  id uuid default gen_random_uuid() primary key,
  service_user_id uuid not null references service_users(id) on delete cascade,
  assessor_id uuid references users(id),
  
  -- Diabetes Information
  diabetes_type text not null check (diabetes_type in ('type1', 'type2', 'gestational', 'other')),
  diabetes_type_other text, -- If 'other' is selected
  diagnosis_date date,
  last_hba1c_value numeric(4,1), -- HbA1c percentage (e.g., 7.5)
  last_hba1c_date date,
  hba1c_target numeric(4,1), -- Target HbA1c value
  
  -- Blood Glucose Monitoring
  bg_monitoring_frequency text not null check (bg_monitoring_frequency in ('multiple_daily', 'once_daily', 'few_times_week', 'occasionally', 'none')),
  bg_monitoring_method text check (bg_monitoring_method in ('finger_prick', 'cgm', 'both')),
  cgm_device_name text,
  cgm_target_range_low numeric(4,1),
  cgm_target_range_high numeric(4,1),
  
  -- Medication Information
  insulin_regime text check (insulin_regime in ('basal_bolus', 'premixed', 'basal_only', 'pump', 'none')),
  insulin_type text, -- Type of insulin used
  insulin_dose_details text, -- Detailed dose information
  oral_medications text[], -- Array of oral medications
  other_medications text[], -- Other diabetes-related medications
  
  -- Hypoglycaemia Assessment
  hypoglycaemia_frequency text not null check (hypoglycaemia_frequency in ('none', 'monthly', 'weekly', 'daily', 'multiple_daily')),
  hypoglycaemia_symptoms_recognized boolean default true,
  hypoglycaemia_severe_episodes integer default 0, -- Number of severe episodes in last 6 months
  hypoglycaemia_unawareness boolean default false,
  
  -- Hyperglycaemia Assessment
  hyperglycaemia_episodes text check (hyperglycaemia_episodes in ('none', 'occasional', 'frequent', 'always')),
  hyperglycaemia_ketoacidosis boolean default false, -- DKA episodes
  hyperglycaemia_hyperosmolar boolean default false, -- HHS episodes
  
  -- Foot Care Assessment
  foot_care_assessment_date date,
  foot_care_assessment_result text check (foot_care_assessment_result in ('normal', 'reduced_sensation', 'ulceration', 'amputation', 'other')),
  foot_care_assessment_details text,
  foot_care_reminder_date date, -- Next foot assessment due
  footwear_assessment boolean default false,
  nail_care_assessment boolean default false,
  
  -- Eye Care Assessment
  eye_screening_date date,
  eye_screening_result text check (eye_screening_result in ('normal', 'background_retinopathy', 'preproliferative', 'proliferative', 'maculopathy', 'other')),
  eye_screening_details text,
  
  -- Lifestyle Assessment
  dietary_management text check (dietary_management in ('diet_controlled', 'carb_counting', 'meal_planning', 'dietitian_input', 'other')),
  dietary_management_details text,
  exercise_level text check (exercise_level in ('sedentary', 'light', 'moderate', 'active', 'very_active')),
  exercise_frequency text, -- How often they exercise
  smoking_status text check (smoking_status in ('non_smoker', 'current_smoker', 'ex_smoker')),
  alcohol_consumption text check (alcohol_consumption in ('none', 'occasional', 'moderate', 'heavy')),
  
  -- Hospital and Complications
  hospital_admissions_last_year integer default 0,
  hospital_admission_reasons text[], -- Reasons for hospitalization
  diabetes_complications text[], -- Array of complications (neuropathy, retinopathy, etc.)
  other_health_conditions text[], -- Other relevant health conditions
  
  -- Sick Day Rules
  sick_day_rules_knowledge boolean default false,
  sick_day_rules_documented boolean default false,
  sick_day_rules_details text,
  ketone_testing_knowledge boolean default false,
  when_to_seek_medical_help text,
  
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
create index if not exists idx_diabetes_assessments_service_user on diabetes_risk_assessments(service_user_id);
create index if not exists idx_diabetes_assessments_assessor on diabetes_risk_assessments(assessor_id);
create index if not exists idx_diabetes_assessments_date on diabetes_risk_assessments(created_at);
create index if not exists idx_diabetes_assessments_type on diabetes_risk_assessments(diabetes_type);
create index if not exists idx_diabetes_assessments_hba1c on diabetes_risk_assessments(last_hba1c_value);

-- Create function to update updated_at timestamp
create or replace function update_diabetes_assessment_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

-- Create trigger to automatically update updated_at
drop trigger if exists update_diabetes_assessment_updated_at on diabetes_risk_assessments;
create trigger update_diabetes_assessment_updated_at
  before update on diabetes_risk_assessments
  for each row execute function update_diabetes_assessment_updated_at();

-- Create function to calculate overall risk level
create or replace function calculate_diabetes_risk_level(
  p_diabetes_type text,
  p_last_hba1c_value numeric,
  p_hypoglycaemia_frequency text,
  p_foot_care_result text,
  p_eye_screening_result text,
  p_hospital_admissions integer
) returns text as $$
declare
  risk_score integer := 0;
begin
  -- Base risk from diabetes type
  case p_diabetes_type
    when 'type1' then risk_score := risk_score + 3;
    when 'type2' then risk_score := risk_score + 2;
    when 'gestational' then risk_score := risk_score + 1;
    when 'other' then risk_score := risk_score + 2;
  end case;
  
  -- HbA1c risk factors
  if p_last_hba1c_value > 58 then -- High HbA1c (>58 mmol/mol)
    risk_score := risk_score + 3;
  elsif p_last_hba1c_value > 53 then -- Moderate HbA1c (53-58 mmol/mol)
    risk_score := risk_score + 2;
  elsif p_last_hba1c_value > 48 then -- Slightly elevated (48-53 mmol/mol)
    risk_score := risk_score + 1;
  end if;
  
  -- Hypoglycaemia risk
  case p_hypoglycaemia_frequency
    when 'daily' then risk_score := risk_score + 3;
    when 'weekly' then risk_score := risk_score + 2;
    when 'monthly' then risk_score := risk_score + 1;
    when 'multiple_daily' then risk_score := risk_score + 4;
  end case;
  
  -- Foot care risk
  if p_foot_care_result in ('reduced_sensation', 'ulceration', 'amputation') then
    risk_score := risk_score + 3;
  end if;
  
  -- Eye screening risk
  if p_eye_screening_result in ('preproliferative', 'proliferative', 'maculopathy') then
    risk_score := risk_score + 2;
  end if;
  
  -- Hospital admission risk
  if p_hospital_admissions > 2 then
    risk_score := risk_score + 2;
  elsif p_hospital_admissions > 0 then
    risk_score := risk_score + 1;
  end if;
  
  -- Determine risk level
  if risk_score <= 4 then
    return 'low';
  elsif risk_score <= 8 then
    return 'medium';
  else
    return 'high';
  end if;
end;
$$ language plpgsql;

-- Create function to flag high-risk diabetes assessments
create or replace function flag_high_risk_diabetes_assessments()
returns table (
  assessment_id uuid,
  service_user_id uuid,
  service_user_name text,
  diabetes_type text,
  last_hba1c_value numeric,
  last_hba1c_date date,
  hypoglycaemia_frequency text,
  foot_care_result text,
  eye_screening_result text,
  hospital_admissions integer,
  overall_risk_level text
) as $$
begin
  return query
  select 
    da.id,
    da.service_user_id,
    su.full_name,
    da.diabetes_type,
    da.last_hba1c_value,
    da.last_hba1c_date,
    da.hypoglycaemia_frequency,
    da.foot_care_assessment_result,
    da.eye_screening_result,
    da.hospital_admissions_last_year,
    da.overall_risk_level
  from diabetes_risk_assessments da
  join service_users su on da.service_user_id = su.id
  where da.overall_risk_level = 'high'
     or da.last_hba1c_value > 58 -- Auto-flag HbA1c >58
     or da.hypoglycaemia_frequency in ('daily', 'multiple_daily')
     or da.foot_care_assessment_result in ('reduced_sensation', 'ulceration', 'amputation')
     or da.eye_screening_result in ('preproliferative', 'proliferative', 'maculopathy')
     or da.hospital_admissions_last_year > 2
  order by da.overall_risk_level desc, da.last_hba1c_value desc;
end;
$$ language plpgsql;

-- Create function to get diabetes assessment summary
create or replace function get_diabetes_assessment_summary(p_service_user_id uuid)
returns jsonb as $$
declare
  latest_assessment diabetes_risk_assessments;
  summary jsonb;
begin
  select * into latest_assessment
  from diabetes_risk_assessments
  where service_user_id = p_service_user_id
  order by created_at desc
  limit 1;
  
  if latest_assessment is null then
    return jsonb_build_object(
      'has_assessment', false,
      'message', 'No diabetes risk assessment found'
    );
  end if;
  
  summary := jsonb_build_object(
    'has_assessment', true,
    'diabetes_type', latest_assessment.diabetes_type,
    'diabetes_type_other', latest_assessment.diabetes_type_other,
    'last_hba1c_value', latest_assessment.last_hba1c_value,
    'last_hba1c_date', latest_assessment.last_hba1c_date,
    'hba1c_target', latest_assessment.hba1c_target,
    'bg_monitoring_frequency', latest_assessment.bg_monitoring_frequency,
    'insulin_regime', latest_assessment.insulin_regime,
    'hypoglycaemia_frequency', latest_assessment.hypoglycaemia_frequency,
    'foot_care_assessment_result', latest_assessment.foot_care_assessment_result,
    'foot_care_reminder_date', latest_assessment.foot_care_reminder_date,
    'eye_screening_date', latest_assessment.eye_screening_date,
    'eye_screening_result', latest_assessment.eye_screening_result,
    'overall_risk_level', latest_assessment.overall_risk_level,
    'hospital_admissions_last_year', latest_assessment.hospital_admissions_last_year,
    'next_review_date', latest_assessment.next_review_date,
    'assessment_date', latest_assessment.created_at
  );
  
  return summary;
end;
$$ language plpgsql;

-- Create function to validate diabetes assessment completeness
create or replace function validate_diabetes_assessment_completeness(p_assessment_id uuid)
returns jsonb as $$
declare
  assessment diabetes_risk_assessments;
  is_complete boolean := true;
  missing_fields text[] := array[]::text[];
  validation_result jsonb;
begin
  select * into assessment from diabetes_risk_assessments where id = p_assessment_id;
  
  if assessment is null then
    return jsonb_build_object(
      'valid', false,
      'message', 'Assessment not found'
    );
  end if;
  
  -- Check required fields
  if assessment.diabetes_type is null or assessment.diabetes_type = '' then
    is_complete := false;
    missing_fields := array_append(missing_fields, 'diabetes_type');
  end if;
  
  if assessment.bg_monitoring_frequency is null or assessment.bg_monitoring_frequency = '' then
    is_complete := false;
    missing_fields := array_append(missing_fields, 'bg_monitoring_frequency');
  end if;
  
  if assessment.hypoglycaemia_frequency is null or assessment.hypoglycaemia_frequency = '' then
    is_complete := false;
    missing_fields := array_append(missing_fields, 'hypoglycaemia_frequency');
  end if;
  
  if assessment.overall_risk_level is null or assessment.overall_risk_level = '' then
    is_complete := false;
    missing_fields := array_append(missing_fields, 'overall_risk_level');
  end if;
  
  if assessment.next_review_date is null then
    is_complete := false;
    missing_fields := array_append(missing_fields, 'next_review_date');
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

-- Create function to calculate insulin dose (for Type 1 diabetes)
create or replace function calculate_insulin_dose(
  p_total_daily_dose numeric,
  p_carb_ratio numeric,
  p_correction_factor numeric,
  p_current_bg numeric,
  p_target_bg numeric,
  p_carbs_to_eat numeric
) returns jsonb as $$
declare
  basal_dose numeric;
  bolus_dose numeric;
  carb_bolus numeric;
  correction_bolus numeric;
  total_bolus numeric;
begin
  -- Calculate basal dose (50% of TDD)
  basal_dose := p_total_daily_dose * 0.5;
  
  -- Calculate carb bolus
  if p_carb_ratio > 0 then
    carb_bolus := p_carbs_to_eat / p_carb_ratio;
  else
    carb_bolus := 0;
  end if;
  
  -- Calculate correction bolus
  if p_correction_factor > 0 and p_current_bg > p_target_bg then
    correction_bolus := (p_current_bg - p_target_bg) / p_correction_factor;
  else
    correction_bolus := 0;
  end if;
  
  -- Total bolus
  total_bolus := carb_bolus + correction_bolus;
  
  return jsonb_build_object(
    'basal_dose', round(basal_dose, 1),
    'carb_bolus', round(carb_bolus, 1),
    'correction_bolus', round(correction_bolus, 1),
    'total_bolus', round(total_bolus, 1),
    'total_daily_dose', round(p_total_daily_dose, 1)
  );
end;
$$ language plpgsql;

-- Create function to submit diabetes assessment
create or replace function submit_diabetes_assessment(
  p_assessment_id uuid,
  p_signature_data text
) returns void as $$
begin
  update diabetes_risk_assessments
  set 
    status = 'completed',
    signature = p_signature_data,
    updated_at = now()
  where id = p_assessment_id;
end;
$$ language plpgsql;

-- Create RLS policies
alter table diabetes_risk_assessments enable row level security;

-- Allow authenticated users to view their own assessments and those they can access
create policy "Users can view diabetes assessments" on diabetes_risk_assessments
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
create policy "Users can insert diabetes assessments" on diabetes_risk_assessments
  for insert with check (auth.role() = 'authenticated');

-- Allow users to update their own assessments
create policy "Users can update diabetes assessments" on diabetes_risk_assessments
  for update using (
    auth.role() = 'authenticated' and (
      assessor_id = auth.uid() or
      auth.has_role('admin')
    )
  );

-- Allow users to delete their own assessments
create policy "Users can delete diabetes assessments" on diabetes_risk_assessments
  for delete using (
    auth.role() = 'authenticated' and (
      assessor_id = auth.uid() or
      auth.has_role('admin')
    )
  );