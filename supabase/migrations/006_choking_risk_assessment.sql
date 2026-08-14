-- Choking Risk Assessment Form
-- Based on comprehensive choking.html requirements

-- Choking risk factors table (32 factors from HTML)
CREATE TABLE IF NOT EXISTS choking_risk_factors (
  id SERIAL PRIMARY KEY,
  factor_text TEXT NOT NULL,
  category TEXT, -- 'Physical', 'Neurological', 'Cognitive', 'Behavioral', 'Dental', 'Eating', 'Medication'
  display_order INTEGER NOT NULL,
  is_active BOOLEAN DEFAULT TRUE
);

-- Insert the 32 factors from choking.html
INSERT INTO choking_risk_factors (factor_text, display_order, category) VALUES
('Weak cough and/or inability to clear throat', 1, 'Physical'),
('History of chest infections', 2, 'Physical'),
('Breathing difficulties/COPD', 3, 'Physical'),
('Known to aspirate', 4, 'Physical'),
('History of choking/requiring intervention', 5, 'Physical'),
('Gurly or wet voice after swallowing', 6, 'Physical'),
('Epilepsy', 7, 'Neurological'),
('Cerebral palsy', 8, 'Neurological'),
('Dementia/confusion', 9, 'Cognitive'),
('Mental health history', 10, 'Cognitive'),
('Known neurological conditions e.g., CVA, Parkinson''s, Huntington''s', 11, 'Neurological'),
('Learning disabilities', 12, 'Cognitive'),
('Postural problems/increased rigidity/severe flexion/cannot sit upright aided or unaided', 13, 'Physical'),
('Poor head control', 14, 'Physical'),
('Tongue thrust', 15, 'Physical'),
('Difficulties chewing or prolonged chewing time', 16, 'Eating'),
('Slurred speech and/or facial weakness', 17, 'Physical'),
('Any known injury/trauma to neck or throat', 18, 'Physical'),
('Eats rapidly', 19, 'Behavioral'),
('Drinks rapidly', 20, 'Behavioral'),
('Continues to eat whilst coughing', 21, 'Behavioral'),
('Continues to drink whilst coughing', 22, 'Behavioral'),
('Cramming food in mouth', 23, 'Behavioral'),
('Pocketing food or drink in mouth', 24, 'Behavioral'),
('Swallowing without chewing', 25, 'Behavioral'),
('Would take food from others/cupboards/fruit bowls if not supervised', 26, 'Behavioral'),
('Drinks independently and safely', 27, 'Eating'),
('Eats independently and safely', 28, 'Eating'),
('Poor fitting/missing dentures/poor dentition/dental pain', 29, 'Dental'),
('Fatigue at meal times', 30, 'Physical'),
('Needs food cutting up or prepared prior to eating', 31, 'Eating'),
('Is on a modified consistency diet', 32, 'Eating'),
('Requires thickened fluids', 33, 'Eating'),
('Requires specialist feeding aids to reduce the risk of choking', 34, 'Eating'),
('Will accept/put any item into mouth including non-food items', 35, 'Behavioral'),
('Taking medication that can affect swallowing', 36, 'Medication');

-- Choking Risk Assessments
CREATE TABLE IF NOT EXISTS choking_risk_assessments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  service_user_id UUID,
  service_user_name TEXT NOT NULL,
  date_of_birth DATE NOT NULL,
  assessor_name TEXT NOT NULL,
  assessment_date DATE NOT NULL,
  assessment_time TIME NOT NULL,
  
  -- Status
  status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'completed', 'archived')),
  
  -- Signature
  sfarr_signature TEXT, -- Base64 or reference to signature storage
  
  -- Metadata
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Individual risk factor scores
CREATE TABLE IF NOT EXISTS choking_risk_scores (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  assessment_id UUID REFERENCES choking_risk_assessments(id) ON DELETE CASCADE,
  risk_factor_id INTEGER REFERENCES choking_risk_factors(id),
  score INTEGER NOT NULL CHECK (score >= 0),
  notes TEXT,
  
  UNIQUE(assessment_id, risk_factor_id)
);

-- Calculate total score view for easy querying
CREATE OR REPLACE VIEW choking_risk_totals AS
SELECT 
  cra.id as assessment_id,
  cra.service_user_id,
  cra.service_user_name,
  cra.assessment_date,
  cra.assessment_time,
  cra.assessor_name,
  cra.date_of_birth,
  cra.status,
  cra.sfarr_signature,
  SUM(crs.score) as total_score,
  CASE 
    WHEN SUM(crs.score) <= 24 THEN 'Low'
    WHEN SUM(crs.score) <= 49 THEN 'Medium'
    ELSE 'High'
  END as risk_level,
  cra.created_at,
  cra.created_by
FROM choking_risk_assessments cra
JOIN choking_risk_scores crs ON cra.id = crs.assessment_id
GROUP BY cra.id, cra.service_user_id, cra.service_user_name, cra.assessment_date, 
         cra.assessment_time, cra.assessor_name, cra.date_of_birth, cra.status,
         cra.sfarr_signature, cra.created_at, cra.created_by;

-- Enable RLS
ALTER TABLE choking_risk_assessments ENABLE ROW LEVEL SECURITY;
ALTER TABLE choking_risk_scores ENABLE ROW LEVEL SECURITY;

-- RLS Policies (simplified - will be updated later when tables exist)
DROP POLICY IF EXISTS "Allow read access to choking assessments" ON choking_risk_assessments;
CREATE POLICY "Allow read access to choking assessments" ON choking_risk_assessments
FOR SELECT USING (true);

DROP POLICY IF EXISTS "Allow insert for authenticated users" ON choking_risk_assessments;
CREATE POLICY "Allow insert for authenticated users" ON choking_risk_assessments
FOR INSERT WITH CHECK (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Allow update for authenticated users" ON choking_risk_assessments;
CREATE POLICY "Allow update for authenticated users" ON choking_risk_assessments
FOR UPDATE USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Allow read access to choking scores" ON choking_risk_scores;
CREATE POLICY "Allow read access to choking scores" ON choking_risk_scores
FOR SELECT USING (true);

DROP POLICY IF EXISTS "Allow insert for authenticated users" ON choking_risk_scores;
CREATE POLICY "Allow insert for authenticated users" ON choking_risk_scores
FOR INSERT WITH CHECK (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Allow update for authenticated users" ON choking_risk_scores;
CREATE POLICY "Allow update for authenticated users" ON choking_risk_scores
FOR UPDATE USING (auth.role() = 'authenticated');

-- Indexes
CREATE INDEX IF NOT EXISTS idx_choking_assessments_service_user ON choking_risk_assessments(service_user_id);
CREATE INDEX IF NOT EXISTS idx_choking_assessments_date ON choking_risk_assessments(assessment_date);
CREATE INDEX IF NOT EXISTS idx_choking_assessments_status ON choking_risk_assessments(status);
CREATE INDEX IF NOT EXISTS idx_choking_scores_assessment ON choking_risk_scores(assessment_id);
CREATE INDEX IF NOT EXISTS idx_choking_scores_risk_factor ON choking_risk_scores(risk_factor_id);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_choking_assessment_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for updated_at
DROP TRIGGER IF EXISTS update_choking_assessments_timestamp ON choking_risk_assessments;
CREATE TRIGGER update_choking_assessments_timestamp
  BEFORE UPDATE ON choking_risk_assessments
  FOR EACH ROW EXECUTE FUNCTION update_choking_assessment_timestamp();

-- Function to get choking risk assessment summary
CREATE OR REPLACE FUNCTION get_choking_risk_summary(assessment_id UUID)
RETURNS TABLE (
  total_score INTEGER,
  risk_level TEXT,
  risk_color TEXT,
  assessment_date DATE,
  assessor_name TEXT,
  service_user_name TEXT,
  status TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    crt.total_score,
    crt.risk_level,
    CASE 
      WHEN crt.risk_level = 'Low' THEN '#4caf50' -- Green
      WHEN crt.risk_level = 'Medium' THEN '#ff9800' -- Orange
      ELSE '#f44336' -- Red
    END as risk_color,
    crt.assessment_date,
    crt.assessor_name,
    crt.service_user_name,
    crt.status
  FROM choking_risk_totals crt
  WHERE crt.assessment_id = assessment_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to validate choking risk assessment completeness
CREATE OR REPLACE FUNCTION validate_choking_risk_completeness(assessment_id UUID)
RETURNS TABLE (
  is_complete BOOLEAN,
  missing_scores INTEGER,
  total_possible_scores INTEGER,
  warnings TEXT[]
) AS $$
DECLARE
  missing_scores_count INTEGER := 0;
  warnings_array TEXT[] := '{}';
  total_factors INTEGER := 0;
BEGIN
  -- Count total factors
  SELECT COUNT(*) INTO total_factors FROM choking_risk_factors WHERE is_active = true;
  
  -- Count scores provided
  SELECT COUNT(*) INTO missing_scores_count 
  FROM choking_risk_scores 
  WHERE assessment_id = assessment_id;
  
  -- Check if all factors have scores
  IF missing_scores_count < total_factors THEN
    warnings_array := array_append(warnings_array, 'Not all risk factors have been scored');
  END IF;
  
  -- Check if assessor name is provided
  IF NOT EXISTS (
    SELECT 1 FROM choking_risk_assessments 
    WHERE id = assessment_id AND assessor_name IS NOT NULL AND assessor_name != ''
  ) THEN
    warnings_array := array_append(warnings_array, 'Assessor name is required');
  END IF;
  
  -- Check if signature is provided for completed assessments
  IF EXISTS (
    SELECT 1 FROM choking_risk_assessments 
    WHERE id = assessment_id AND status = 'completed' AND sfarr_signature IS NULL
  ) THEN
    warnings_array := array_append(warnings_array, 'Signature required for completed assessments');
  END IF;
  
  RETURN QUERY SELECT 
    (missing_scores_count >= total_factors)::BOOLEAN as is_complete,
    (total_factors - missing_scores_count)::INTEGER as missing_scores,
    total_factors::INTEGER as total_possible_scores,
    warnings_array as warnings;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to submit choking risk assessment
CREATE OR REPLACE FUNCTION submit_choking_risk_assessment(assessment_id UUID, signature_data TEXT)
RETURNS BOOLEAN AS $$
DECLARE
  validation_result RECORD;
BEGIN
  -- Validate completeness
  SELECT * INTO validation_result FROM validate_choking_risk_completeness(assessment_id);
  
  IF NOT validation_result.is_complete THEN
    RAISE EXCEPTION 'Cannot submit incomplete assessment. Missing scores: %', validation_result.missing_scores;
  END IF;
  
  -- Update status and signature
  UPDATE choking_risk_assessments 
  SET 
    status = 'completed',
    sfarr_signature = signature_data,
    updated_at = NOW()
  WHERE id = assessment_id;
  
  RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get assessment with all scores
CREATE OR REPLACE FUNCTION get_choking_assessment_with_scores(assessment_id UUID)
RETURNS TABLE (
  assessment_data JSONB,
  scores_data JSONB
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    to_jsonb(cra) as assessment_data,
    (
      SELECT jsonb_agg(
        jsonb_build_object(
          'risk_factor_id', crs.risk_factor_id,
          'score', crs.score,
          'notes', crs.notes,
          'factor_text', crf.factor_text,
          'category', crf.category
        )
      )
      FROM choking_risk_scores crs
      JOIN choking_risk_factors crf ON crs.risk_factor_id = crf.id
      WHERE crs.assessment_id = assessment_id
    ) as scores_data
  FROM choking_risk_assessments cra
  WHERE cra.id = assessment_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;