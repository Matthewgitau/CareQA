-- Waterlow Pressure Ulcer Risk Assessment System
-- Based on comprehensive waterlow assessment requirements

-- Waterlow assessment questions (26 questions from waterloo.html)
CREATE TABLE IF NOT EXISTS waterlow_questions (
  id SERIAL PRIMARY KEY,
  question_text TEXT NOT NULL,
  category TEXT,
  display_order INTEGER NOT NULL,
  options JSONB NOT NULL, -- Stores option text and score values
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert the 26 questions from waterloo.html (only if not already inserted)
INSERT INTO waterlow_questions (question_text, display_order, category, options) 
SELECT * FROM (VALUES
-- Category: Build and Skin Type
('Build', 1, 'Build and Skin Type', '{"Very thin": 2, "Thin": 1, "Normal": 0, "Obese": 1}'::jsonb),
('Skin type', 2, 'Build and Skin Type', '{"Very dry/flaky": 1, "Moist": 0, "Oedematous": 1}'::jsonb),

-- Category: Age/Sex
('Age/Sex', 3, 'Age/Sex', '{"14-49 Female": 0, "14-49 Male": 0, "50-64 Female": 1, "50-64 Male": 1, "65-74 Female": 2, "65-74 Male": 1, "75-80 Female": 3, "75-80 Male": 2, "80+ Female": 4, "80+ Male": 3}'::jsonb),

-- Category: Continence
('Continence', 4, 'Continence', '{"Urinary and faecal continence": 0, "Urinary incontinence": 3, "Faecal incontinence": 3, "Urinary and faecal incontinence": 4}'::jsonb),

-- Category: Mobility
('Mobility', 5, 'Mobility', '{"Walks independently": 0, "Walks + aid": 1, "Chair/bed bound": 2, "Stoop": 2}'::jsonb),

-- Category: Appetite
('Appetite', 6, 'Appetite', '{"Eats most of most meals": 0, "Eats most of some meals": 1, "Eats some of most meals": 2, "Eats some of some meals": 3}'::jsonb),

-- Category: Special Risks
('Neurological deficit (MS, Parkinsons, etc.)', 7, 'Special Risks', '{"Yes": 1, "No": 0}'::jsonb),
('Under 45 with high risk disease (cancer, liver, renal, cardiac)', 8, 'Special Risks', '{"Yes": 2, "No": 0}'::jsonb),
('Prescription drugs (corticosteroids, H2-receptor antagonists, tranquilizers, sedatives)', 9, 'Special Risks', '{"Yes": 1, "No": 0}'::jsonb),
('Previous pressure sore', 10, 'Special Risks', '{"Yes": 3, "No": 0}'::jsonb),
('Tissue viability liaison nurse involved', 11, 'Special Risks', '{"Yes": -1, "No": 0}'::jsonb),

-- Category: Medication
('Prescription drugs (corticosteroids, H2-receptor antagonists, tranquilizers, sedatives)', 12, 'Medication', '{"Yes": 1, "No": 0}'::jsonb),

-- Category: Neurological
('Neurological deficit (MS, Parkinsons, etc.)', 13, 'Neurological', '{"Yes": 1, "No": 0}'::jsonb),

-- Category: Previous Pressure Sores
('Previous pressure sore', 14, 'Previous Pressure Sores', '{"Yes": 3, "No": 0}'::jsonb),

-- Category: Tissue Viability
('Tissue viability liaison nurse involved', 15, 'Tissue Viability', '{"Yes": -1, "No": 0}'::jsonb),

-- Category: High Risk Diseases
('Under 45 with high risk disease (cancer, liver, renal, cardiac)', 16, 'High Risk Diseases', '{"Yes": 2, "No": 0}'::jsonb),

-- Category: Additional Risk Factors
('Malnutrition', 17, 'Additional Risk Factors', '{"Severe": 2, "Moderate": 1, "None": 0}'::jsonb),
('Dehydration', 18, 'Additional Risk Factors', '{"Severe": 2, "Moderate": 1, "None": 0}'::jsonb),
('Smoking', 19, 'Additional Risk Factors', '{"Yes": 1, "No": 0}'::jsonb),
('Diabetes', 20, 'Additional Risk Factors', '{"Yes": 1, "No": 0}'::jsonb),
('Peripheral vascular disease', 21, 'Additional Risk Factors', '{"Yes": 1, "No": 0}'::jsonb),
('Spinal cord injury', 22, 'Additional Risk Factors', '{"Yes": 2, "No": 0}'::jsonb),
('Multiple trauma', 23, 'Additional Risk Factors', '{"Yes": 1, "No": 0}'::jsonb),
('Post-operative (major surgery)', 24, 'Additional Risk Factors', '{"Yes": 1, "No": 0}'::jsonb),
('Prolonged exposure to moisture', 25, 'Additional Risk Factors', '{"Yes": 1, "No": 0}'::jsonb),
('Fever', 26, 'Additional Risk Factors', '{"Yes": 1, "No": 0}'::jsonb)
) AS temp_values (question_text, display_order, category, options)
WHERE NOT EXISTS (
  SELECT 1 FROM waterlow_questions 
  WHERE question_text = temp_values.question_text
);

-- Waterlow assessments
CREATE TABLE IF NOT EXISTS waterlow_assessments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  service_user_id UUID REFERENCES service_users(id) ON DELETE CASCADE,
  assessor_id UUID REFERENCES profiles(id),
  assessment_date DATE NOT NULL,
  responses JSONB NOT NULL, -- Stores all question responses
  action_plan JSONB, -- Stores action plan items
  signature TEXT,
  status TEXT DEFAULT 'completed',
  total_score INTEGER,
  risk_level TEXT,
  pdf_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS Policies
ALTER TABLE waterlow_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE waterlow_assessments ENABLE ROW LEVEL SECURITY;

-- Policies for waterlow questions (read-only for most users)
DROP POLICY IF EXISTS "Allow read access to waterlow questions" ON waterlow_questions;
CREATE POLICY "Allow read access to waterlow questions" ON waterlow_questions
FOR SELECT USING (true);

DROP POLICY IF EXISTS "Allow insert for admin users" ON waterlow_questions;
CREATE POLICY "Allow insert for admin users" ON waterlow_questions
FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);

DROP POLICY IF EXISTS "Allow update for admin users" ON waterlow_questions;
CREATE POLICY "Allow update for admin users" ON waterlow_questions
FOR UPDATE USING (
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);

-- Policies for waterlow assessments
DROP POLICY IF EXISTS "Allow read access to waterlow assessments" ON waterlow_assessments;
CREATE POLICY "Allow read access to waterlow assessments" ON waterlow_assessments
FOR SELECT USING (true);

DROP POLICY IF EXISTS "Allow insert for care staff" ON waterlow_assessments;
CREATE POLICY "Allow insert for care staff" ON waterlow_assessments
FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin', 'manager', 'carer'))
);

DROP POLICY IF EXISTS "Allow update for care staff" ON waterlow_assessments;
CREATE POLICY "Allow update for care staff" ON waterlow_assessments
FOR UPDATE USING (
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin', 'manager', 'carer'))
);

-- Indexes for performance (only create if they don't exist)
CREATE INDEX IF NOT EXISTS idx_waterlow_assessments_service_user_id ON waterlow_assessments(service_user_id);
CREATE INDEX IF NOT EXISTS idx_waterlow_assessments_assessor_id ON waterlow_assessments(assessor_id);
CREATE INDEX IF NOT EXISTS idx_waterlow_assessments_date ON waterlow_assessments(assessment_date);
CREATE INDEX IF NOT EXISTS idx_waterlow_assessments_risk_level ON waterlow_assessments(risk_level);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_waterlow_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers for updated_at (only create if they don't exist)
DROP TRIGGER IF EXISTS update_waterlow_questions_timestamp ON waterlow_questions;
CREATE TRIGGER update_waterlow_questions_timestamp
  BEFORE UPDATE ON waterlow_questions
  FOR EACH ROW EXECUTE FUNCTION update_waterlow_timestamp();

DROP TRIGGER IF EXISTS update_waterlow_assessments_timestamp ON waterlow_assessments;
CREATE TRIGGER update_waterlow_assessments_timestamp
  BEFORE UPDATE ON waterlow_assessments
  FOR EACH ROW EXECUTE FUNCTION update_waterlow_timestamp();

-- Function to generate PDF URL (placeholder for actual PDF generation)
CREATE OR REPLACE FUNCTION generate_waterlow_pdf_url(assessment_id UUID)
RETURNS TEXT AS $$
DECLARE
  pdf_url TEXT;
BEGIN
  -- In a real implementation, this would generate a PDF and return the URL
  -- For now, we'll return a placeholder URL
  pdf_url := 'https://careqa-documents.s3.amazonaws.com/waterlow/' || assessment_id::text || '.pdf';
  
  UPDATE waterlow_assessments 
  SET pdf_url = pdf_url 
  WHERE id = assessment_id;
  
  RETURN pdf_url;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get waterlow summary
CREATE OR REPLACE FUNCTION get_waterlow_summary(service_user_id_param UUID)
RETURNS TABLE (
  total_questions INTEGER,
  total_score INTEGER,
  risk_level TEXT,
  last_assessment_date DATE,
  action_items_count INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COUNT(DISTINCT wq.id)::INTEGER as total_questions,
    COALESCE(MAX(wa.total_score), 0)::INTEGER as total_score,
    COALESCE(MAX(wa.risk_level), 'Low') as risk_level,
    MAX(wa.assessment_date) as last_assessment_date,
    COALESCE(MAX(jsonb_array_length(wa.action_plan)), 0)::INTEGER as action_items_count
  FROM waterlow_questions wq
  LEFT JOIN waterlow_assessments wa ON wa.service_user_id = service_user_id_param
  WHERE wq.is_active = true
  GROUP BY wa.service_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;