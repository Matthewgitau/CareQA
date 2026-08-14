-- Pre-Admission Assessment Form
-- Based on comprehensive Word DOC requirements

-- Pre-admission assessments table
CREATE TABLE IF NOT EXISTS pre_admissions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  -- Personal Details
  family_name TEXT NOT NULL,
  first_name TEXT NOT NULL,
  preferred_name TEXT,
  title TEXT,
  date_of_birth DATE NOT NULL,
  address_street TEXT,
  address_town TEXT,
  address_postcode TEXT,
  current_address_street TEXT,
  current_address_town TEXT,
  current_address_postcode TEXT,
  telephone TEXT,
  ethnicity TEXT,
  
  -- Main Carer
  main_carer_name TEXT,
  main_carer_street TEXT,
  main_carer_town TEXT,
  main_carer_postcode TEXT,
  main_carer_telephone TEXT,
  
  -- Next of Kin
  next_of_kin_name TEXT,
  next_of_kin_street TEXT,
  next_of_kin_town TEXT,
  next_of_kin_postcode TEXT,
  next_of_kin_telephone TEXT,
  
  -- GP Details
  gp_name TEXT,
  gp_surgery TEXT,
  gp_street TEXT,
  gp_town TEXT,
  gp_postcode TEXT,
  gp_telephone TEXT,
  
  -- Communication
  first_language TEXT,
  communication_needs TEXT,
  capacity_doubts BOOLEAN,
  requires_imca BOOLEAN,
  
  -- Assessment People (JSON for dynamic list)
  assessment_people JSONB DEFAULT '[]',
  
  -- Background
  background_reason TEXT,
  service_user_views TEXT,
  carer_views TEXT,
  life_history TEXT,
  
  -- Medical
  medical_conditions TEXT,
  antibiotic_last_3_months BOOLEAN,
  antibiotic_details TEXT,
  vaccination_influenza BOOLEAN,
  vaccination_pneumonia BOOLEAN,
  vaccination_shingles BOOLEAN,
  vaccination_covid BOOLEAN,
  invasive_devices TEXT,
  wounds TEXT,
  
  -- Physical Health
  physical_health TEXT,
  
  -- ADL Assessments (JSON for flexible structure)
  adl_assessments JSONB DEFAULT '[]',
  
  -- Financial
  funding_source TEXT CHECK (funding_source IN ('adult_care_services', 'self_payer')),
  
  -- Metadata
  service_user_id UUID, -- After admission
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID,
  status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'completed', 'admitted')),
  submitted_at TIMESTAMP WITH TIME ZONE,
  submitted_by UUID
);

-- ADL categories reference table
CREATE TABLE IF NOT EXISTS adl_categories (
  id SERIAL PRIMARY KEY,
  category_name TEXT NOT NULL UNIQUE,
  display_order INTEGER NOT NULL,
  description TEXT
);

-- Insert ADL categories
INSERT INTO adl_categories (category_name, display_order, description) VALUES
('Relationships', 1, 'Ability to form and maintain relationships'),
('Communication', 2, 'Verbal and non-verbal communication abilities'),
('Mental Health', 3, 'Psychological and emotional wellbeing'),
('Mobility', 4, 'Ability to move and change positions'),
('Personal Hygiene', 5, 'Personal cleanliness and grooming'),
('Dressing', 6, 'Ability to select and put on clothing'),
('Eating and Drinking', 7, 'Ability to feed self and maintain hydration'),
('Toileting', 8, 'Bladder and bowel continence management'),
('Medication Management', 9, 'Ability to manage own medications'),
('Household Tasks', 10, 'Basic housekeeping and maintenance'),
('Shopping', 11, 'Ability to purchase necessary items'),
('Cooking', 12, 'Food preparation and cooking skills'),
('Money Management', 13, 'Financial management and budgeting'),
('Transportation', 14, 'Ability to travel and use transport'),
('Safety Awareness', 15, 'Understanding of personal safety'),
('Sleep Patterns', 16, 'Sleep quality and patterns'),
('Nutrition', 17, 'Dietary needs and eating habits'),
('Exercise', 18, 'Physical activity and exercise routines'),
('Social Activities', 19, 'Participation in social events'),
('Hobbies and Interests', 20, 'Leisure activities and interests'),
('Spiritual/Religious Needs', 21, 'Spiritual or religious requirements')
ON CONFLICT (category_name) DO NOTHING;

-- RLS Policies
ALTER TABLE pre_admissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE adl_categories ENABLE ROW LEVEL SECURITY;

-- Policies for pre-admissions (simplified - will be updated later when tables exist)
DROP POLICY IF EXISTS "Allow read access to pre-admissions" ON pre_admissions;
CREATE POLICY "Allow read access to pre-admissions" ON pre_admissions
FOR SELECT USING (true);

DROP POLICY IF EXISTS "Allow insert for authenticated users" ON pre_admissions;
CREATE POLICY "Allow insert for authenticated users" ON pre_admissions
FOR INSERT WITH CHECK (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Allow update for authenticated users" ON pre_admissions;
CREATE POLICY "Allow update for authenticated users" ON pre_admissions
FOR UPDATE USING (auth.role() = 'authenticated');

-- Policies for ADL categories (read-only for most users)
DROP POLICY IF EXISTS "Allow read access to ADL categories" ON adl_categories;
CREATE POLICY "Allow read access to ADL categories" ON adl_categories
FOR SELECT USING (true);

DROP POLICY IF EXISTS "Allow insert for authenticated users" ON adl_categories;
CREATE POLICY "Allow insert for authenticated users" ON adl_categories
FOR INSERT WITH CHECK (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Allow update for authenticated users" ON adl_categories;
CREATE POLICY "Allow update for authenticated users" ON adl_categories
FOR UPDATE USING (auth.role() = 'authenticated');

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_pre_admissions_service_user_id ON pre_admissions(service_user_id);
CREATE INDEX IF NOT EXISTS idx_pre_admissions_created_by ON pre_admissions(created_by);
CREATE INDEX IF NOT EXISTS idx_pre_admissions_status ON pre_admissions(status);
CREATE INDEX IF NOT EXISTS idx_pre_admissions_date_of_birth ON pre_admissions(date_of_birth);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_pre_admission_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for updated_at
DROP TRIGGER IF EXISTS update_pre_admissions_timestamp ON pre_admissions;
CREATE TRIGGER update_pre_admissions_timestamp
  BEFORE UPDATE ON pre_admissions
  FOR EACH ROW EXECUTE FUNCTION update_pre_admission_timestamp();

-- Function to get pre-admission summary
CREATE OR REPLACE FUNCTION get_pre_admission_summary(pre_admission_id UUID)
RETURNS TABLE (
  total_adl_categories INTEGER,
  completed_adl_categories INTEGER,
  has_medical_conditions BOOLEAN,
  has_vaccination_info BOOLEAN,
  status TEXT,
  created_date DATE,
  submitted_date DATE
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    (SELECT COUNT(*) FROM adl_categories)::INTEGER as total_adl_categories,
    (SELECT COUNT(*) FROM jsonb_array_elements(pa.adl_assessments) WHERE value IS NOT NULL)::INTEGER as completed_adl_categories,
    (pa.medical_conditions IS NOT NULL AND pa.medical_conditions != '')::BOOLEAN as has_medical_conditions,
    (
      pa.vaccination_influenza IS NOT NULL OR
      pa.vaccination_pneumonia IS NOT NULL OR
      pa.vaccination_shingles IS NOT NULL OR
      pa.vaccination_covid IS NOT NULL
    )::BOOLEAN as has_vaccination_info,
    pa.status,
    pa.created_at::DATE as created_date,
    pa.submitted_at::DATE as submitted_date
  FROM pre_admissions pa
  WHERE pa.id = pre_admission_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to validate pre-admission completeness
CREATE OR REPLACE FUNCTION validate_pre_admission_completeness(pre_admission_id UUID)
RETURNS TABLE (
  is_complete BOOLEAN,
  missing_sections TEXT[],
  warnings TEXT[]
) AS $$
DECLARE
  missing_sections_array TEXT[] := '{}';
  warnings_array TEXT[] := '{}';
  pa_record pre_admissions%ROWTYPE;
BEGIN
  SELECT * INTO pa_record FROM pre_admissions WHERE id = pre_admission_id;
  
  -- Check required personal details
  IF pa_record.family_name IS NULL OR pa_record.first_name IS NULL OR pa_record.date_of_birth IS NULL THEN
    missing_sections_array := array_append(missing_sections_array, 'Personal Details');
  END IF;
  
  -- Check required medical information
  IF pa_record.medical_conditions IS NULL THEN
    missing_sections_array := array_append(missing_sections_array, 'Medical Information');
  END IF;
  
  -- Check if ADL assessments are complete
  IF pa_record.adl_assessments IS NULL OR jsonb_array_length(pa_record.adl_assessments) = 0 THEN
    missing_sections_array := array_append(missing_sections_array, 'ADL Assessments');
  END IF;
  
  -- Check for warnings
  IF pa_record.capacity_doubts = true AND pa_record.requires_imca IS NULL THEN
    warnings_array := array_append(warnings_array, 'IMCA requirement not specified when capacity doubts exist');
  END IF;
  
  IF pa_record.antibiotic_last_3_months = true AND pa_record.antibiotic_details IS NULL THEN
    warnings_array := array_append(warnings_array, 'Antibiotic details required when antibiotics used in last 3 months');
  END IF;
  
  RETURN QUERY SELECT 
    (array_length(missing_sections_array, 1) IS NULL)::BOOLEAN as is_complete,
    missing_sections_array as missing_sections,
    warnings_array as warnings;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to submit pre-admission
CREATE OR REPLACE FUNCTION submit_pre_admission(pre_admission_id UUID, submitted_by_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  validation_result RECORD;
BEGIN
  -- Validate completeness
  SELECT * INTO validation_result FROM validate_pre_admission_completeness(pre_admission_id);
  
  IF NOT validation_result.is_complete THEN
    RAISE EXCEPTION 'Cannot submit incomplete pre-admission. Missing sections: %', validation_result.missing_sections;
  END IF;
  
  -- Update status and submission info
  UPDATE pre_admissions 
  SET 
    status = 'completed',
    submitted_at = NOW(),
    submitted_by = submitted_by_id
  WHERE id = pre_admission_id;
  
  RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;