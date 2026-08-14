-- Extend Choking Risk Assessment with comprehensive questions
-- This migration adds an extended_questions JSONB column to store additional assessment data

-- Add extended_questions column if it doesn't exist
ALTER TABLE choking_risk_assessments 
ADD COLUMN IF NOT EXISTS extended_questions JSONB DEFAULT '{}'::jsonb;

-- Add additional fields for comprehensive assessment
ALTER TABLE choking_risk_assessments 
ADD COLUMN IF NOT EXISTS total_score INTEGER DEFAULT 0;

ALTER TABLE choking_risk_assessments 
ADD COLUMN IF NOT EXISTS risk_category TEXT DEFAULT 'physical' CHECK (risk_category IN ('physical', 'neurological', 'cognitive', 'behavioral', 'dental', 'eating', 'medication', 'mixed'));

ALTER TABLE choking_risk_assessments 
ADD COLUMN IF NOT EXISTS review_date DATE;

ALTER TABLE choking_risk_assessments 
ADD COLUMN IF NOT EXISTS slt_review_required BOOLEAN DEFAULT FALSE;

ALTER TABLE choking_risk_assessments 
ADD COLUMN IF NOT EXISTS diet_modification_required BOOLEAN DEFAULT FALSE;

ALTER TABLE choking_risk_assessments 
ADD COLUMN IF NOT EXISTS fluid_modification_required BOOLEAN DEFAULT FALSE;

ALTER TABLE choking_risk_assessments 
ADD COLUMN IF NOT EXISTS feeding_aid_required BOOLEAN DEFAULT FALSE;

ALTER TABLE choking_risk_assessments 
ADD COLUMN IF NOT EXISTS supervision_level TEXT DEFAULT 'independent' 
  CHECK (supervision_level IN ('independent', 'minimal', 'moderate', 'maximal', 'total'));

-- Create extended choking risk questions table
CREATE TABLE IF NOT EXISTS choking_extended_questions (
  id SERIAL PRIMARY KEY,
  category TEXT NOT NULL CHECK (category IN (
    'background_identification',
    'medical_condition',
    'mechanical_oral',
    'swallowing_symptoms',
    'mouth_positioning',
    'cognitive_capacity',
    'eating_behaviors',
    'control_measures',
    'medications',
    'risk_scoring'
  )),
  question_text TEXT NOT NULL,
  display_order INTEGER NOT NULL,
  is_active BOOLEAN DEFAULT TRUE
);

-- Insert extended questions for Background and Identification (5 questions)
INSERT INTO choking_extended_questions (category, question_text, display_order) VALUES
('background_identification', 'Does the individual have a known diagnosis that may affect swallowing?', 1),
('background_identification', 'Has the individual had a recent swallowing assessment by a Speech and Language Therapist?', 2),
('background_identification', 'Is there a current care plan in place for eating and drinking?', 3),
('background_identification', 'Are family members or advocates involved in meal times?', 4),
('background_identification', 'Has the individual experienced recent weight loss or changes in appetite?', 5);

-- Medical and Condition-Related Risks (13 questions)
INSERT INTO choking_extended_questions (category, question_text, display_order) VALUES
('medical_condition', 'Does the individual have a history of stroke or TIA?', 6),
('medical_condition', 'Is the individual diagnosed with Parkinson''s disease?', 7),
('medical_condition', 'Does the individual have Motor Neurone Disease (MND)?', 8),
('medical_condition', 'Is the individual diagnosed with Multiple Sclerosis?', 9),
('medical_condition', 'Does the individual have Myasthenia Gravis?', 10),
('medical_condition', 'Is the individual diagnosed with Huntington''s disease?', 11),
('medical_condition', 'Does the individual have cerebral palsy?', 12),
('medical_condition', 'Is the individual receiving palliative or end-of-life care?', 13),
('medical_condition', 'Does the individual have a history of head and neck cancer?', 14),
('medical_condition', 'Has the individual had recent head or neck surgery?', 15),
('medical_condition', 'Does the individual have gastro-oesophageal reflux disease (GORD)?', 16),
('medical_condition', 'Is the individual diagnosed with respiratory conditions (COPD, asthma)?', 17),
('medical_condition', 'Does the individual have a tracheostomy?', 18);

-- Mechanical Breakdown and Oral Health (7 questions)
INSERT INTO choking_extended_questions (category, question_text, display_order) VALUES
('mechanical_oral', 'Does the individual have natural teeth?', 19),
('mechanical_oral', 'Does the individual wear dentures?', 20),
('mechanical_oral', 'Are dentures well-fitting and in good condition?', 21),
('mechanical_oral', 'Does the individual have adequate saliva production?', 22),
('mechanical_oral', 'Is the individual able to close lips effectively?', 23),
('mechanical_oral', 'Does the individual have adequate tongue movement?', 24),
('mechanical_oral', 'Is the individual able to manage oral secretions?', 25);

-- Swallowing Symptoms and Aspiration Signs (7 questions)
INSERT INTO choking_extended_questions (category, question_text, display_order) VALUES
('swallowing_symptoms', 'Does the individual cough during or immediately after swallowing?', 26),
('swallowing_symptoms', 'Does the individual have a wet or gurgly voice quality after swallowing?', 27),
('swallowing_symptoms', 'Does the individual have difficulty managing saliva?', 28),
('swallowing_symptoms', 'Does the individual experience food sticking in the throat?', 29),
('swallowing_symptoms', 'Does the individual have recurrent chest infections?', 30),
('swallowing_symptoms', 'Does the individual take longer than 30 minutes to complete meals?', 31),
('swallowing_symptoms', 'Does the individual demonstrate multiple swallows per mouthful?', 32);

-- Awareness of Mouth Positioning (3 questions)
INSERT INTO choking_extended_questions (category, question_text, display_order) VALUES
('mouth_positioning', 'Is the individual able to maintain an upright posture during meals?', 33),
('mouth_positioning', 'Can the individual maintain head control and midline position?', 34),
('mouth_positioning', 'Is the individual aware of food placement in the mouth?', 35);

-- Cognitive Capacity and Risk Awareness (5 questions)
INSERT INTO choking_extended_questions (category, question_text, display_order) VALUES
('cognitive_capacity', 'Does the individual understand instructions related to eating and drinking?', 36),
('cognitive_capacity', 'Is the individual able to recognize when they are full?', 37),
('cognitive_capacity', 'Does the individual have insight into their swallowing difficulties?', 38),
('cognitive_capacity', 'Is the individual able to communicate food preferences and difficulties?', 39),
('cognitive_capacity', 'Does the individual require prompting to eat and drink?', 40);

-- Eating Behaviours and Functional Capacity (7 questions)
INSERT INTO choking_extended_questions (category, question_text, display_order) VALUES
('eating_behaviors', 'Is the individual able to use cutlery independently?', 41),
('eating_behaviors', 'Does the individual require assistance with meal set-up?', 42),
('eating_behaviors', 'Is the individual able to bring food to mouth independently?', 43),
('eating_behaviors', 'Does the individual demonstrate appropriate pacing during meals?', 44),
('eating_behaviors', 'Is the individual able to chew food effectively?', 45),
('eating_behaviors', 'Does the individual accept all food textures?', 46),
('eating_behaviors', 'Does the individual accept all fluid consistencies?', 47);

-- Control Measures and Support (6 questions)
INSERT INTO choking_extended_questions (category, question_text, display_order) VALUES
('control_measures', 'Is the individual supervised during meals?', 48),
('control_measures', 'Does the individual require verbal prompts during eating?', 49),
('control_measures', 'Does the individual require physical assistance during eating?', 50),
('control_measures', 'Are adaptive utensils or equipment in use?', 51),
('control_measures', 'Is the individual positioned appropriately (upright, supported)?', 52),
('control_measures', 'Are staff trained in choking first aid and prevention?', 53);

-- Medications and Other Factors (2 questions)
INSERT INTO choking_extended_questions (category, question_text, display_order) VALUES
('medications', 'Is the individual taking medications that may affect swallowing?', 54),
('medications', 'Does the individual require assistance with medication administration?', 55);

-- Risk Scoring and Review (5 questions)
INSERT INTO choking_extended_questions (category, question_text, display_order) VALUES
('risk_scoring', 'Has a formal swallowing screening tool been completed?', 56),
('risk_scoring', 'Is a referral to Speech and Language Therapy indicated?', 57),
('risk_scoring', 'Is a dietitian referral required?', 58),
('risk_scoring', 'When is the next review date for this assessment?', 59),
('risk_scoring', 'Has this assessment been discussed with the individual and/or family?', 60);

-- Update the view to include extended data
CREATE OR REPLACE VIEW choking_risk_totals_extended AS
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
  cra.total_score,
  cra.risk_category,
  cra.review_date,
  cra.slt_review_required,
  cra.diet_modification_required,
  cra.fluid_modification_required,
  cra.feeding_aid_required,
  cra.supervision_level,
  cra.extended_questions,
  COALESCE(SUM(crs.score), 0) as risk_factor_score,
  CASE 
    WHEN COALESCE(SUM(crs.score), 0) <= 24 THEN 'Low'
    WHEN COALESCE(SUM(crs.score), 0) <= 49 THEN 'Medium'
    ELSE 'High'
  END as risk_level,
  cra.created_at,
  cra.created_by
FROM choking_risk_assessments cra
LEFT JOIN choking_risk_scores crs ON cra.id = crs.assessment_id
GROUP BY cra.id, cra.service_user_id, cra.service_user_name, cra.assessment_date, 
         cra.assessment_time, cra.assessor_name, cra.date_of_birth, cra.status,
         cra.sfarr_signature, cra.total_score, cra.risk_category, cra.review_date,
         cra.slt_review_required, cra.diet_modification_required, cra.fluid_modification_required,
         cra.feeding_aid_required, cra.supervision_level, cra.extended_questions, cra.created_at, cra.created_by;

-- Create function to calculate comprehensive risk score
CREATE OR REPLACE FUNCTION calculate_comprehensive_choking_risk(assessment_id UUID)
RETURNS TABLE (
  total_score INTEGER,
  risk_level TEXT,
  recommendations TEXT[]
) AS $$
DECLARE
  basic_score INTEGER := 0;
  extended_score INTEGER := 0;
  recommendations_array TEXT[] := '{}';
  ext_questions JSONB;
BEGIN
  -- Get basic risk factor score
  SELECT COALESCE(SUM(score), 0) INTO basic_score
  FROM choking_risk_scores
  WHERE assessment_id = assessment_id;
  
  -- Get extended questions data
  SELECT extended_questions INTO ext_questions
  FROM choking_risk_assessments
  WHERE id = assessment_id;
  
  -- Calculate extended score based on answers (simplified scoring)
  -- Each 'yes' answer to risk questions adds points
  IF ext_questions IS NOT NULL THEN
    -- Add points for high-risk medical conditions
    IF (ext_questions->>'medical_condition_score')::INTEGER IS NOT NULL THEN
      extended_score := extended_score + (ext_questions->>'medical_condition_score')::INTEGER;
    END IF;
    
    -- Add points for swallowing symptoms
    IF (ext_questions->>'swallowing_symptoms_score')::INTEGER IS NOT NULL THEN
      extended_score := extended_score + (ext_questions->>'swallowing_symptoms_score')::INTEGER;
    END IF;
  END IF;
  
  total_score := basic_score + extended_score;
  
  -- Determine risk level
  IF total_score <= 24 THEN
    risk_level := 'Low';
  ELSIF total_score <= 49 THEN
    risk_level := 'Medium';
  ELSE
    risk_level := 'High';
  END IF;
  
  -- Generate recommendations based on findings
  IF extended_score > 0 THEN
    recommendations_array := array_append(recommendations_array, 'Consider Speech and Language Therapy referral');
  END IF;
  
  IF (ext_questions->>'diet_modification_required')::BOOLEAN = true THEN
    recommendations_array := array_append(recommendations_array, 'Diet modification required - consult dietitian');
  END IF;
  
  IF (ext_questions->>'fluid_modification_required')::BOOLEAN = true THEN
    recommendations_array := array_append(recommendations_array, 'Fluid modification required - consider thickened fluids');
  END IF;
  
  IF (ext_questions->>'slt_review_required')::BOOLEAN = true THEN
    recommendations_array := array_append(recommendations_array, 'Urgent SLT review required');
  END IF;
  
  RETURN QUERY SELECT total_score, risk_level, recommendations_array;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update indexes for better performance
CREATE INDEX IF NOT EXISTS idx_choking_assessments_risk_category ON choking_risk_assessments(risk_category);
CREATE INDEX IF NOT EXISTS idx_choking_assessments_slt_review ON choking_risk_assessments(slt_review_required) WHERE slt_review_required = true;
CREATE INDEX IF NOT EXISTS idx_choking_assessments_review_date ON choking_risk_assessments(review_date) WHERE review_date IS NOT NULL;

-- Grant permissions
GRANT ALL ON choking_extended_questions TO authenticated;