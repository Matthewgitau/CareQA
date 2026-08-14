-- Falls Risk Assessment Form
-- Based on comprehensive falls.html requirements

-- Falls Risk Assessments
CREATE TABLE IF NOT EXISTS falls_risk_assessments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  service_user_id UUID,
  service_user_name TEXT NOT NULL,
  assessor_name TEXT NOT NULL,
  date_of_birth DATE NOT NULL,
  assessment_date DATE NOT NULL,
  
  -- Scoring Categories
  age_score INTEGER CHECK (age_score BETWEEN 0 AND 3),
  fall_history_score INTEGER CHECK (fall_history_score BETWEEN 0 AND 5),
  elimination_score INTEGER CHECK (elimination_score BETWEEN 0 AND 4),
  medication_score INTEGER CHECK (medication_score BETWEEN 0 AND 7),
  equipment_score INTEGER CHECK (equipment_score BETWEEN 0 AND 3),
  mobility_score INTEGER CHECK (mobility_score BETWEEN 0 AND 7),
  cognition_score INTEGER CHECK (cognition_score BETWEEN 0 AND 4),
  
  -- Calculated total
  total_score INTEGER,
  
  -- Risk level (calculated)
  risk_level TEXT,
  
  -- Verification
  verified_by TEXT,
  signature_data TEXT,
  verification_date DATE,
  
  -- Status
  status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'completed', 'archived')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Action Plan Items (dynamic rows)
CREATE TABLE IF NOT EXISTS falls_action_plans (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  falls_assessment_id UUID REFERENCES falls_risk_assessments(id) ON DELETE CASCADE,
  action TEXT NOT NULL,
  outcome TEXT,
  completed BOOLEAN DEFAULT FALSE,
  completed_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE falls_risk_assessments ENABLE ROW LEVEL SECURITY;
ALTER TABLE falls_action_plans ENABLE ROW LEVEL SECURITY;

-- RLS Policies
DROP POLICY IF EXISTS "Users can view their organization's falls assessments" ON falls_risk_assessments;
CREATE POLICY "Users can view their organization's falls assessments" ON falls_risk_assessments
FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can insert falls assessments" ON falls_risk_assessments;
CREATE POLICY "Users can insert falls assessments" ON falls_risk_assessments
FOR INSERT WITH CHECK (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Users can update their own falls assessments" ON falls_risk_assessments;
CREATE POLICY "Users can update their own falls assessments" ON falls_risk_assessments
FOR UPDATE USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Users can view their organization's falls action plans" ON falls_action_plans;
CREATE POLICY "Users can view their organization's falls action plans" ON falls_action_plans
FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can insert falls action plans" ON falls_action_plans;
CREATE POLICY "Users can insert falls action plans" ON falls_action_plans
FOR INSERT WITH CHECK (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Users can update their own falls action plans" ON falls_action_plans;
CREATE POLICY "Users can update their own falls action plans" ON falls_action_plans
FOR UPDATE USING (auth.role() = 'authenticated');

-- Indexes
CREATE INDEX IF NOT EXISTS idx_falls_assessments_service_user ON falls_risk_assessments(service_user_id);
CREATE INDEX IF NOT EXISTS idx_falls_assessments_date ON falls_risk_assessments(assessment_date);
CREATE INDEX IF NOT EXISTS idx_falls_assessments_status ON falls_risk_assessments(status);
CREATE INDEX IF NOT EXISTS idx_falls_action_plans_assessment ON falls_action_plans(falls_assessment_id);

-- Function to update updated_at timestamp and calculate scores
CREATE OR REPLACE FUNCTION update_falls_assessment_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  -- Calculate total score
  NEW.total_score := COALESCE(NEW.age_score, 0) + 
                     COALESCE(NEW.fall_history_score, 0) + 
                     COALESCE(NEW.elimination_score, 0) + 
                     COALESCE(NEW.medication_score, 0) + 
                     COALESCE(NEW.equipment_score, 0) + 
                     COALESCE(NEW.mobility_score, 0) + 
                     COALESCE(NEW.cognition_score, 0);
  
  -- Calculate risk level
  NEW.risk_level := CASE 
    WHEN NEW.total_score BETWEEN 6 AND 8 THEN 'Low'
    WHEN NEW.total_score BETWEEN 9 AND 12 THEN 'Moderate'
    WHEN NEW.total_score >= 13 THEN 'High'
    ELSE 'Not Calculated'
  END;
  
  -- Update timestamp
  NEW.updated_at = NOW();
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for updated_at and score calculation
DROP TRIGGER IF EXISTS update_falls_assessments_timestamp ON falls_risk_assessments;
CREATE TRIGGER update_falls_assessments_timestamp
  BEFORE UPDATE ON falls_risk_assessments
  FOR EACH ROW EXECUTE FUNCTION update_falls_assessment_timestamp();

-- Function to calculate age from date of birth
CREATE OR REPLACE FUNCTION calculate_age_from_dob(dob DATE)
RETURNS INTEGER AS $$
BEGIN
  RETURN EXTRACT(YEAR FROM AGE(NOW(), dob))::INTEGER;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Function to get falls risk assessment summary
CREATE OR REPLACE FUNCTION get_falls_risk_summary(assessment_id UUID)
RETURNS TABLE (
  total_score INTEGER,
  risk_level TEXT,
  risk_color TEXT,
  assessment_date DATE,
  assessor_name TEXT,
  service_user_name TEXT,
  status TEXT,
  age_score INTEGER,
  fall_history_score INTEGER,
  elimination_score INTEGER,
  medication_score INTEGER,
  equipment_score INTEGER,
  mobility_score INTEGER,
  cognition_score INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    fra.total_score,
    fra.risk_level,
    CASE 
      WHEN fra.risk_level = 'Low' THEN '#4caf50' -- Green
      WHEN fra.risk_level = 'Moderate' THEN '#ff9800' -- Orange
      WHEN fra.risk_level = 'High' THEN '#f44336' -- Red
      ELSE '#9e9e9e' -- Grey
    END as risk_color,
    fra.assessment_date,
    fra.assessor_name,
    fra.service_user_name,
    fra.status,
    fra.age_score,
    fra.fall_history_score,
    fra.elimination_score,
    fra.medication_score,
    fra.equipment_score,
    fra.mobility_score,
    fra.cognition_score
  FROM falls_risk_assessments fra
  WHERE fra.id = assessment_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to validate falls risk assessment completeness
CREATE OR REPLACE FUNCTION validate_falls_risk_completeness(assessment_id UUID)
RETURNS TABLE (
  is_complete BOOLEAN,
  missing_scores TEXT[],
  warnings TEXT[]
) AS $$
DECLARE
  missing_scores_array TEXT[] := '{}';
  warnings_array TEXT[] := '{}';
  fra_record falls_risk_assessments%ROWTYPE;
BEGIN
  SELECT * INTO fra_record FROM falls_risk_assessments WHERE id = assessment_id;
  
  -- Check if all required scores are provided
  IF fra_record.age_score IS NULL THEN
    missing_scores_array := array_append(missing_scores_array, 'Age Score');
  END IF;
  
  IF fra_record.fall_history_score IS NULL THEN
    missing_scores_array := array_append(missing_scores_array, 'Fall History Score');
  END IF;
  
  IF fra_record.elimination_score IS NULL THEN
    missing_scores_array := array_append(missing_scores_array, 'Elimination Score');
  END IF;
  
  IF fra_record.medication_score IS NULL THEN
    missing_scores_array := array_append(missing_scores_array, 'Medication Score');
  END IF;
  
  IF fra_record.equipment_score IS NULL THEN
    missing_scores_array := array_append(missing_scores_array, 'Equipment Score');
  END IF;
  
  IF fra_record.mobility_score IS NULL THEN
    missing_scores_array := array_append(missing_scores_array, 'Mobility Score');
  END IF;
  
  IF fra_record.cognition_score IS NULL THEN
    missing_scores_array := array_append(missing_scores_array, 'Cognition Score');
  END IF;
  
  -- Check if assessor name is provided
  IF fra_record.assessor_name IS NULL OR fra_record.assessor_name = '' THEN
    warnings_array := array_append(warnings_array, 'Assessor name is required');
  END IF;
  
  -- Check if verification is provided for completed assessments
  IF fra_record.status = 'completed' AND (fra_record.verified_by IS NULL OR fra_record.signature_data IS NULL) THEN
    warnings_array := array_append(warnings_array, 'Verification required for completed assessments');
  END IF;
  
  RETURN QUERY SELECT 
    (array_length(missing_scores_array, 1) IS NULL)::BOOLEAN as is_complete,
    missing_scores_array as missing_scores,
    warnings_array as warnings;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to submit falls risk assessment
CREATE OR REPLACE FUNCTION submit_falls_risk_assessment(assessment_id UUID, verified_by_name TEXT, signature_data TEXT)
RETURNS BOOLEAN AS $$
DECLARE
  validation_result RECORD;
BEGIN
  -- Validate completeness
  SELECT * INTO validation_result FROM validate_falls_risk_completeness(assessment_id);
  
  IF NOT validation_result.is_complete THEN
    RAISE EXCEPTION 'Cannot submit incomplete assessment. Missing scores: %', validation_result.missing_scores;
  END IF;
  
  -- Update status and verification
  UPDATE falls_risk_assessments 
  SET 
    status = 'completed',
    verified_by = verified_by_name,
    signature_data = signature_data,
    verification_date = NOW()::DATE,
    updated_at = NOW()
  WHERE id = assessment_id;
  
  RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get assessment with action plans
CREATE OR REPLACE FUNCTION get_falls_assessment_with_action_plans(assessment_id UUID)
RETURNS TABLE (
  assessment_data JSONB,
  action_plans_data JSONB
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    to_jsonb(fra) as assessment_data,
    (
      SELECT jsonb_agg(
        jsonb_build_object(
          'id', fap.id,
          'action', fap.action,
          'outcome', fap.outcome,
          'completed', fap.completed,
          'completed_at', fap.completed_at,
          'created_at', fap.created_at
        )
      )
      FROM falls_action_plans fap
      WHERE fap.falls_assessment_id = assessment_id
    ) as action_plans_data
  FROM falls_risk_assessments fra
  WHERE fra.id = assessment_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to calculate age-based score
CREATE OR REPLACE FUNCTION calculate_age_score(dob DATE)
RETURNS INTEGER AS $$
DECLARE
  age_years INTEGER;
BEGIN
  age_years := EXTRACT(YEAR FROM AGE(NOW(), dob))::INTEGER;
  
  CASE 
    WHEN age_years BETWEEN 60 AND 69 THEN RETURN 1;
    WHEN age_years BETWEEN 70 AND 79 THEN RETURN 2;
    WHEN age_years >= 80 THEN RETURN 3;
    ELSE RETURN 0;
  END CASE;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Function to get falls risk history
CREATE OR REPLACE FUNCTION get_falls_risk_history(service_user_id UUID)
RETURNS TABLE (
  assessment_id UUID,
  assessment_date DATE,
  assessor_name TEXT,
  total_score INTEGER,
  risk_level TEXT,
  status TEXT,
  created_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    fra.id,
    fra.assessment_date,
    fra.assessor_name,
    fra.total_score,
    fra.risk_level,
    fra.status,
    fra.created_at
  FROM falls_risk_assessments fra
  WHERE fra.service_user_id = service_user_id
  ORDER BY fra.assessment_date DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;