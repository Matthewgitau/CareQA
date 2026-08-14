-- MAR Audit Form
-- Based on comprehensive Mar audit.html requirements

-- MAR Audit questions (hardcoded from HTML)
CREATE TABLE IF NOT EXISTS mar_audit_questions (
  id SERIAL PRIMARY KEY,
  question_text TEXT NOT NULL,
  category TEXT, -- 'Legibility', 'Signatures', 'Dosages', 'Codes', 'Warfarin', etc.
  display_order INTEGER NOT NULL,
  is_active BOOLEAN DEFAULT TRUE,
  requires_deadline BOOLEAN DEFAULT FALSE,
  requires_comment BOOLEAN DEFAULT TRUE
);

-- Insert all questions from Mar audit.html (only if not already inserted)
INSERT INTO mar_audit_questions (question_text, display_order, category, requires_deadline) 
SELECT * FROM (VALUES
('Is the MAR legible?', 1, 'Legibility', false),
('Are entries cross-referenced to the service users notes?', 2, 'Documentation', false),
('Are all Service User details completed on the front of each MAR?', 3, 'Details', false),
('Are all doses and times clearly stated?', 4, 'Dosages', false),
('Are medications given at the correct time?', 5, 'Administration', false),
('Are the correct codes being used on the MARs?', 6, 'Codes', false),
('Does the MAR audit cover appropriate recording, missed/omitted dosages and the use of ''when required'' medicines?', 7, 'Coverage', false),
('Is the person who gives the medicine signing the MAR?', 8, 'Signatures', false),
('Do MAR directions match pharmacy labels?', 9, 'Accuracy', false),
('Are all boxes on the MAR signed for regular medicines?', 10, 'Completion', false),
('Are MARs stored in the agreed place to maintain confidentiality?', 11, 'Storage', false),
('Is the INR result sheet included?', 12, 'Warfarin', false),
('Is it clear that medication has been given to the service user from the MAR?', 13, 'Clarity', false),
('Do Warfarin doses match INR results?', 14, 'Warfarin', true),
('Is the current Warfarin dose correctly marked?', 15, 'Warfarin', false),
('Is there a central list of signatures/initials for staff involved in the medication administration?', 16, 'Signatures', false),
('Are the directions for the administration of a medicine clear on the MAR?', 17, 'Directions', false),
('Do the levels of administration support required in the care plans tally with the MARs?', 18, 'Care Plans', false),
('Do directions on the MAR match the pharmacy label for that medicine?', 19, 'Accuracy', false),
('Are all doses and times clearly stated on the MAR?', 20, 'Dosages', false),
('Is it clear from the directions on the MAR the number of medicines that will be given?', 21, 'Clarity', false),
('If the directions are, for example; ''1 or 2 tablets'', is it clear on the MAR if 1 tablet or 2 tablets have been given?', 22, 'PRN', false),
('Is it clear when the medicines have not been given/have been refused, etc?', 23, 'Omissions', false),
('Are medicines given at the correct time?', 24, 'Administration', false),
('Are the correct codes being used on the MARs?', 25, 'Codes', false),
('Is the International Normalised Ratio (INR) result sheet and yellow book stored with the MAR?', 26, 'Warfarin', false),
('Are all the details in the general information section of the yellow book?', 27, 'Warfarin', false),
('Do all the doses on the MAR match the doses specified in the yellow book, or the INR results sheet, for the audit period?', 28, 'Warfarin', true),
('Is the current dose marked clearly in milligrams on the MAR (not the number of tablets)?', 29, 'Warfarin', false),
('Warfarin tablets should not be broken in half. Has it been necessary to break any tablets in half in order to administer the prescribed dose?', 30, 'Warfarin', true),
('Is the date of the next INR blood test noted on the MAR and/or in a diary?', 31, 'Warfarin', true)
) AS temp_values (question_text, display_order, category, requires_deadline)
WHERE NOT EXISTS (
  SELECT 1 FROM mar_audit_questions 
  WHERE question_text = temp_values.question_text
);

-- MAR Audits
CREATE TABLE IF NOT EXISTS mar_audits (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  service_user_id UUID REFERENCES service_users(id) ON DELETE CASCADE,
  service_user_name TEXT NOT NULL,
  assessor_name TEXT NOT NULL,
  audit_date DATE NOT NULL,
  
  -- Status
  status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'completed', 'archived')),
  
  -- Metadata
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES profiles(id),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- MAR Audit Answers
CREATE TABLE IF NOT EXISTS mar_audit_answers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  audit_id UUID REFERENCES mar_audits(id) ON DELETE CASCADE,
  question_id INTEGER REFERENCES mar_audit_questions(id),
  answer TEXT CHECK (answer IN ('yes', 'no', 'na')),
  comment TEXT,
  deadline_date DATE,
  notification_sent BOOLEAN DEFAULT FALSE,
  
  UNIQUE(audit_id, question_id)
);

-- Enable RLS
ALTER TABLE mar_audits ENABLE ROW LEVEL SECURITY;
ALTER TABLE mar_audit_answers ENABLE ROW LEVEL SECURITY;

-- RLS Policies (already created in initial schema)

-- Indexes (only create if they don't exist)
CREATE INDEX IF NOT EXISTS idx_mar_audits_service_user ON mar_audits(service_user_id);
CREATE INDEX IF NOT EXISTS idx_mar_audits_date ON mar_audits(audit_date);
CREATE INDEX IF NOT EXISTS idx_mar_audits_status ON mar_audits(status);
CREATE INDEX IF NOT EXISTS idx_mar_answers_audit ON mar_audit_answers(audit_id);
CREATE INDEX IF NOT EXISTS idx_mar_answers_deadline ON mar_audit_answers(deadline_date) WHERE deadline_date IS NOT NULL;

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_mar_audit_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for updated_at (only create if it doesn't exist)
DROP TRIGGER IF EXISTS update_mar_audits_timestamp ON mar_audits;
CREATE TRIGGER update_mar_audits_timestamp
  BEFORE UPDATE ON mar_audits
  FOR EACH ROW EXECUTE FUNCTION update_mar_audit_timestamp();

-- Function to get MAR audit summary
CREATE OR REPLACE FUNCTION get_mar_audit_summary(audit_id UUID)
RETURNS TABLE (
  total_questions INTEGER,
  answered_questions INTEGER,
  yes_answers INTEGER,
  no_answers INTEGER,
  na_answers INTEGER,
  pending_deadlines INTEGER,
  audit_date DATE,
  assessor_name TEXT,
  service_user_name TEXT,
  status TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    (SELECT COUNT(*) FROM mar_audit_questions WHERE is_active = true)::INTEGER as total_questions,
    (SELECT COUNT(*) FROM mar_audit_answers WHERE audit_id = mar_audits.id AND answer IS NOT NULL)::INTEGER as answered_questions,
    (SELECT COUNT(*) FROM mar_audit_answers WHERE audit_id = mar_audits.id AND answer = 'yes')::INTEGER as yes_answers,
    (SELECT COUNT(*) FROM mar_audit_answers WHERE audit_id = mar_audits.id AND answer = 'no')::INTEGER as no_answers,
    (SELECT COUNT(*) FROM mar_audit_answers WHERE audit_id = mar_audits.id AND answer = 'na')::INTEGER as na_answers,
    (SELECT COUNT(*) FROM mar_audit_answers WHERE audit_id = mar_audits.id AND deadline_date IS NOT NULL AND deadline_date > CURRENT_DATE)::INTEGER as pending_deadlines,
    mar_audits.audit_date,
    mar_audits.assessor_name,
    mar_audits.service_user_name,
    mar_audits.status
  FROM mar_audits
  WHERE mar_audits.id = audit_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to validate MAR audit completeness
CREATE OR REPLACE FUNCTION validate_mar_audit_completeness(audit_id UUID)
RETURNS TABLE (
  is_complete BOOLEAN,
  missing_answers INTEGER,
  warnings TEXT[]
) AS $$
DECLARE
  missing_answers_count INTEGER := 0;
  warnings_array TEXT[] := '{}';
  ma_record mar_audits%ROWTYPE;
BEGIN
  SELECT * INTO ma_record FROM mar_audits WHERE id = audit_id;
  
  -- Count missing answers
  SELECT COUNT(*) INTO missing_answers_count 
  FROM mar_audit_questions 
  WHERE is_active = true 
  AND id NOT IN (
    SELECT question_id FROM mar_audit_answers WHERE audit_id = audit_id
  );
  
  -- Check if assessor name is provided
  IF ma_record.assessor_name IS NULL OR ma_record.assessor_name = '' THEN
    warnings_array := array_append(warnings_array, 'Assessor name is required');
  END IF;
  
  -- Check for upcoming deadlines
  IF EXISTS (
    SELECT 1 FROM mar_audit_answers 
    WHERE audit_id = audit_id 
    AND deadline_date IS NOT NULL 
    AND deadline_date <= CURRENT_DATE + INTERVAL '7 days'
  ) THEN
    warnings_array := array_append(warnings_array, 'Some questions have approaching deadlines');
  END IF;
  
  RETURN QUERY SELECT 
    (missing_answers_count = 0)::BOOLEAN as is_complete,
    missing_answers_count::INTEGER as missing_answers,
    warnings_array as warnings;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to submit MAR audit
CREATE OR REPLACE FUNCTION submit_mar_audit(audit_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  validation_result RECORD;
BEGIN
  -- Validate completeness
  SELECT * INTO validation_result FROM validate_mar_audit_completeness(audit_id);
  
  IF NOT validation_result.is_complete THEN
    RAISE EXCEPTION 'Cannot submit incomplete audit. Missing answers: %', validation_result.missing_answers;
  END IF;
  
  -- Update status
  UPDATE mar_audits 
  SET 
    status = 'completed',
    updated_at = NOW()
  WHERE id = audit_id;
  
  RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get audit with answers
CREATE OR REPLACE FUNCTION get_mar_audit_with_answers(audit_id UUID)
RETURNS TABLE (
  audit_data JSONB,
  answers_data JSONB
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    to_jsonb(ma) as audit_data,
    (
      SELECT jsonb_agg(
        jsonb_build_object(
          'question_id', maa.question_id,
          'answer', maa.answer,
          'comment', maa.comment,
          'deadline_date', maa.deadline_date,
          'notification_sent', maa.notification_sent,
          'question_text', maq.question_text,
          'category', maq.category,
          'requires_deadline', maq.requires_deadline
        )
      )
      FROM mar_audit_answers maa
      JOIN mar_audit_questions maq ON maa.question_id = maq.id
      WHERE maa.audit_id = audit_id
    ) as answers_data
  FROM mar_audits ma
  WHERE ma.id = audit_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to search MAR audits
CREATE OR REPLACE FUNCTION search_mar_audits(
  search_service_user_name TEXT DEFAULT '',
  search_assessor_name TEXT DEFAULT '',
  date_from DATE DEFAULT NULL,
  date_to DATE DEFAULT NULL,
  search_status TEXT DEFAULT ''
)
RETURNS TABLE (
  audit_id UUID,
  service_user_name TEXT,
  audit_date DATE,
  assessor_name TEXT,
  status TEXT,
  created_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    ma.id,
    ma.service_user_name,
    ma.audit_date,
    ma.assessor_name,
    ma.status,
    ma.created_at
  FROM mar_audits ma
  WHERE (search_service_user_name = '' OR ma.service_user_name ILIKE ('%' || search_service_user_name || '%'))
    AND (search_assessor_name = '' OR ma.assessor_name ILIKE ('%' || search_assessor_name || '%'))
    AND (search_status = '' OR ma.status = search_status)
    AND (date_from IS NULL OR ma.audit_date >= date_from)
    AND (date_to IS NULL OR ma.audit_date <= date_to)
  ORDER BY ma.audit_date DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check approaching deadlines and send notifications
CREATE OR REPLACE FUNCTION check_mar_deadlines()
RETURNS TRIGGER AS $$
BEGIN
  -- Check if deadline is approaching (within 7 days) and notification not sent
  IF NEW.deadline_date IS NOT NULL AND 
     NEW.deadline_date <= CURRENT_DATE + INTERVAL '7 days' AND
     NEW.notification_sent = false THEN
    
    -- Insert notification (assuming notifications table exists)
    INSERT INTO notifications (
      user_id,
      type,
      title,
      body,
      data,
      created_at
    ) VALUES (
      (SELECT created_by FROM mar_audits WHERE id = NEW.audit_id),
      'mar_deadline',
      'MAR Audit Action Required',
      format('Action needed by %s for question: %s', NEW.deadline_date, 
             (SELECT question_text FROM mar_audit_questions WHERE id = NEW.question_id)),
      jsonb_build_object(
        'audit_id', NEW.audit_id, 
        'question_id', NEW.question_id, 
        'deadline', NEW.deadline_date,
        'question_text', (SELECT question_text FROM mar_audit_questions WHERE id = NEW.question_id)
      ),
      NOW()
    ) ON CONFLICT DO NOTHING;
    
    NEW.notification_sent := true;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for deadline notifications (only create if it doesn't exist)
DROP TRIGGER IF EXISTS mar_deadline_trigger ON mar_audit_answers;
CREATE TRIGGER mar_deadline_trigger
  AFTER INSERT OR UPDATE ON mar_audit_answers
  FOR EACH ROW
  EXECUTE FUNCTION check_mar_deadlines();

-- Function to get questions by category
CREATE OR REPLACE FUNCTION get_mar_audit_questions_by_category()
RETURNS TABLE (
  category TEXT,
  questions JSONB
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    maq.category,
    jsonb_agg(
      jsonb_build_object(
        'id', maq.id,
        'question_text', maq.question_text,
        'display_order', maq.display_order,
        'requires_deadline', maq.requires_deadline,
        'requires_comment', maq.requires_comment
      ) ORDER BY maq.display_order
    ) as questions
  FROM mar_audit_questions maq
  WHERE maq.is_active = true
  GROUP BY maq.category
  ORDER BY maq.category;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;