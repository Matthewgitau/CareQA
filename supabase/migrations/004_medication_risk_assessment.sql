-- Medication Risk Assessment System
-- Based on medication.html requirements

-- Risk assessment questions (hardcoded from HTML)
CREATE TABLE IF NOT EXISTS risk_assessment_questions (
  id SERIAL PRIMARY KEY,
  question_text TEXT NOT NULL,
  category TEXT,
  display_order INTEGER NOT NULL,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert the 16 questions from medication.html (only if not already exists)
INSERT INTO risk_assessment_questions (question_text, display_order, category) 
SELECT 'Is the service user able to obtain supplies of medicines as needed?', 1, 'Access'
WHERE NOT EXISTS (SELECT 1 FROM risk_assessment_questions WHERE question_text = 'Is the service user able to obtain supplies of medicines as needed?');

INSERT INTO risk_assessment_questions (question_text, display_order, category) 
SELECT 'Does the service user know where all the medicines are stored at home?', 2, 'Storage'
WHERE NOT EXISTS (SELECT 1 FROM risk_assessment_questions WHERE question_text = 'Does the service user know where all the medicines are stored at home?');

INSERT INTO risk_assessment_questions (question_text, display_order, category) 
SELECT 'Is there any excess medicine in the home which may give rise to confusion or mistakes in administration?', 3, 'Storage'
WHERE NOT EXISTS (SELECT 1 FROM risk_assessment_questions WHERE question_text = 'Is there any excess medicine in the home which may give rise to confusion or mistakes in administration?');

INSERT INTO risk_assessment_questions (question_text, display_order, category) 
SELECT 'Can the service user read the label on the medicines?', 4, 'Reading'
WHERE NOT EXISTS (SELECT 1 FROM risk_assessment_questions WHERE question_text = 'Can the service user read the label on the medicines?');

INSERT INTO risk_assessment_questions (question_text, display_order, category) 
SELECT 'Can the service user access the medication container unaided?', 5, 'Access'
WHERE NOT EXISTS (SELECT 1 FROM risk_assessment_questions WHERE question_text = 'Can the service user access the medication container unaided?');

INSERT INTO risk_assessment_questions (question_text, display_order, category) 
SELECT 'Can the service user get the tablet/capsule out of the bottle/container or pack?', 6, 'Access'
WHERE NOT EXISTS (SELECT 1 FROM risk_assessment_questions WHERE question_text = 'Can the service user get the tablet/capsule out of the bottle/container or pack?');

INSERT INTO risk_assessment_questions (question_text, display_order, category) 
SELECT 'Can the service user pick the tablet up and put it into his/her mouth once they are out of the container?', 7, 'Administration'
WHERE NOT EXISTS (SELECT 1 FROM risk_assessment_questions WHERE question_text = 'Can the service user pick the tablet up and put it into his/her mouth once they are out of the container?');

INSERT INTO risk_assessment_questions (question_text, display_order, category) 
SELECT 'Does the service user have any problems swallowing their tablets/capsules?', 8, 'Administration'
WHERE NOT EXISTS (SELECT 1 FROM risk_assessment_questions WHERE question_text = 'Does the service user have any problems swallowing their tablets/capsules?');

INSERT INTO risk_assessment_questions (question_text, display_order, category) 
SELECT 'Can the service user pick up a bottle and pour out the dose of liquid medicine?', 9, 'Administration'
WHERE NOT EXISTS (SELECT 1 FROM risk_assessment_questions WHERE question_text = 'Can the service user pick up a bottle and pour out the dose of liquid medicine?');

INSERT INTO risk_assessment_questions (question_text, display_order, category) 
SELECT 'Can the service user use an inhaler correctly?', 10, 'Administration'
WHERE NOT EXISTS (SELECT 1 FROM risk_assessment_questions WHERE question_text = 'Can the service user use an inhaler correctly?');

INSERT INTO risk_assessment_questions (question_text, display_order, category) 
SELECT 'Can the service user use eye drops correctly?', 11, 'Administration'
WHERE NOT EXISTS (SELECT 1 FROM risk_assessment_questions WHERE question_text = 'Can the service user use eye drops correctly?');

INSERT INTO risk_assessment_questions (question_text, display_order, category) 
SELECT 'Does the service user remember to take their medicine?', 12, 'Adherence'
WHERE NOT EXISTS (SELECT 1 FROM risk_assessment_questions WHERE question_text = 'Does the service user remember to take their medicine?');

INSERT INTO risk_assessment_questions (question_text, display_order, category) 
SELECT 'Does the service user always take the right quantity of medicine at the right time?', 13, 'Adherence'
WHERE NOT EXISTS (SELECT 1 FROM risk_assessment_questions WHERE question_text = 'Does the service user always take the right quantity of medicine at the right time?');

INSERT INTO risk_assessment_questions (question_text, display_order, category) 
SELECT 'Does the service user always want to take their medication?', 14, 'Adherence'
WHERE NOT EXISTS (SELECT 1 FROM risk_assessment_questions WHERE question_text = 'Does the service user always want to take their medication?');

INSERT INTO risk_assessment_questions (question_text, display_order, category) 
SELECT 'Is the service user a diabetic?', 15, 'Medical Condition'
WHERE NOT EXISTS (SELECT 1 FROM risk_assessment_questions WHERE question_text = 'Is the service user a diabetic?');

INSERT INTO risk_assessment_questions (question_text, display_order, category) 
SELECT 'Does the service user have any allergies to medication?', 16, 'Medical Condition'
WHERE NOT EXISTS (SELECT 1 FROM risk_assessment_questions WHERE question_text = 'Does the service user have any allergies to medication?');

-- Risk assessment submissions
CREATE TABLE IF NOT EXISTS risk_assessments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  service_user_id UUID,
  assessment_date DATE NOT NULL,
  completed_by UUID,
  statement_confirmed BOOLEAN DEFAULT FALSE,
  submitted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  pdf_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Individual answers
CREATE TABLE IF NOT EXISTS risk_assessment_answers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  assessment_id UUID REFERENCES risk_assessments(id) ON DELETE CASCADE,
  question_id INTEGER REFERENCES risk_assessment_questions(id),
  risk_identified BOOLEAN DEFAULT FALSE,
  if_risk_identified BOOLEAN DEFAULT FALSE,
  action_required BOOLEAN DEFAULT FALSE,
  action_text TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS Policies
ALTER TABLE risk_assessment_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE risk_assessments ENABLE ROW LEVEL SECURITY;
ALTER TABLE risk_assessment_answers ENABLE ROW LEVEL SECURITY;

-- Policies for risk assessment questions (read-only for most users)
DROP POLICY IF EXISTS "Allow read access to risk assessment questions" ON risk_assessment_questions;
CREATE POLICY "Allow read access to risk assessment questions" ON risk_assessment_questions
FOR SELECT USING (true);

-- Policies for risk assessments (simplified - will be updated later when tables exist)
DROP POLICY IF EXISTS "Allow read access to risk assessments" ON risk_assessments;
CREATE POLICY "Allow read access to risk assessments" ON risk_assessments
FOR SELECT USING (true);

DROP POLICY IF EXISTS "Allow insert for authenticated users" ON risk_assessments;
CREATE POLICY "Allow insert for authenticated users" ON risk_assessments
FOR INSERT WITH CHECK (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Allow update for authenticated users" ON risk_assessments;
CREATE POLICY "Allow update for authenticated users" ON risk_assessments
FOR UPDATE USING (auth.role() = 'authenticated');

-- Policies for risk assessment answers (simplified - will be updated later when tables exist)
DROP POLICY IF EXISTS "Allow read access to risk assessment answers" ON risk_assessment_answers;
CREATE POLICY "Allow read access to risk assessment answers" ON risk_assessment_answers
FOR SELECT USING (true);

DROP POLICY IF EXISTS "Allow insert for authenticated users" ON risk_assessment_answers;
CREATE POLICY "Allow insert for authenticated users" ON risk_assessment_answers
FOR INSERT WITH CHECK (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Allow update for authenticated users" ON risk_assessment_answers;
CREATE POLICY "Allow update for authenticated users" ON risk_assessment_answers
FOR UPDATE USING (auth.role() = 'authenticated');

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_risk_assessments_service_user_id ON risk_assessments(service_user_id);
CREATE INDEX IF NOT EXISTS idx_risk_assessments_completed_by ON risk_assessments(completed_by);
CREATE INDEX IF NOT EXISTS idx_risk_assessments_date ON risk_assessments(assessment_date);
CREATE INDEX IF NOT EXISTS idx_risk_assessment_answers_assessment_id ON risk_assessment_answers(assessment_id);
CREATE INDEX IF NOT EXISTS idx_risk_assessment_answers_question_id ON risk_assessment_answers(question_id);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_risk_assessment_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers for updated_at
DROP TRIGGER IF EXISTS update_risk_assessment_questions_timestamp ON risk_assessment_questions;
CREATE TRIGGER update_risk_assessment_questions_timestamp
  BEFORE UPDATE ON risk_assessment_questions
  FOR EACH ROW EXECUTE FUNCTION update_risk_assessment_timestamp();

DROP TRIGGER IF EXISTS update_risk_assessments_timestamp ON risk_assessments;
CREATE TRIGGER update_risk_assessments_timestamp
  BEFORE UPDATE ON risk_assessments
  FOR EACH ROW EXECUTE FUNCTION update_risk_assessment_timestamp();

DROP TRIGGER IF EXISTS update_risk_assessment_answers_timestamp ON risk_assessment_answers;
CREATE TRIGGER update_risk_assessment_answers_timestamp
  BEFORE UPDATE ON risk_assessment_answers
  FOR EACH ROW EXECUTE FUNCTION update_risk_assessment_timestamp();

-- Function to generate PDF URL (placeholder for actual PDF generation)
CREATE OR REPLACE FUNCTION generate_risk_assessment_pdf_url(assessment_id UUID)
RETURNS TEXT AS $$
DECLARE
  pdf_url TEXT;
BEGIN
  -- In a real implementation, this would generate a PDF and return the URL
  -- For now, we'll return a placeholder URL
  pdf_url := 'https://careqa-documents.s3.amazonaws.com/risk_assessments/' || assessment_id::text || '.pdf';
  
  UPDATE risk_assessments 
  SET pdf_url = pdf_url 
  WHERE id = assessment_id;
  
  RETURN pdf_url;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get risk assessment summary
CREATE OR REPLACE FUNCTION get_risk_assessment_summary(service_user_id_param UUID)
RETURNS TABLE (
  total_questions INTEGER,
  risks_identified INTEGER,
  actions_required INTEGER,
  last_assessment_date DATE,
  statement_confirmed BOOLEAN
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COUNT(DISTINCT raq.id)::INTEGER as total_questions,
    COUNT(DISTINCT CASE WHEN raa.risk_identified THEN raa.question_id END)::INTEGER as risks_identified,
    COUNT(DISTINCT CASE WHEN raa.action_required THEN raa.question_id END)::INTEGER as actions_required,
    MAX(ra.assessment_date) as last_assessment_date,
    MAX(ra.statement_confirmed)::BOOLEAN as statement_confirmed
  FROM risk_assessment_questions raq
  LEFT JOIN risk_assessment_answers raa ON raq.id = raa.question_id
  LEFT JOIN risk_assessments ra ON raa.assessment_id = ra.id
  WHERE ra.service_user_id = service_user_id_param
  GROUP BY ra.service_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;