-- Create lessons_learnt table
CREATE TABLE lessons_learnt (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  -- Reference Details
  reference_number TEXT UNIQUE NOT NULL,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  
  -- Incident/Source
  source_type TEXT CHECK (source_type IN (
    'incident',
    'accident',
    'complaint',
    'safeguarding',
    'audit_finding',
    'inspection',
    'near_miss',
    'medication_error',
    'service_user_feedback',
    'staff_feedback',
    'external_review',
    'other'
  )),
  source_id UUID,
  source_reference TEXT,
  incident_date DATE,
  
  -- Classification
  severity TEXT CHECK (severity IN ('critical', 'high', 'medium', 'low')),
  category TEXT CHECK (category IN (
    'clinical_care',
    'medication',
    'safeguarding',
    'staff_training',
    'documentation',
    'equipment',
    'environment',
    'communication',
    'governance',
    'finance',
    'health_safety',
    'other'
  )),
  
  -- Root Cause Analysis
  root_cause TEXT,
  contributing_factors TEXT[],
  root_cause_category TEXT CHECK (root_cause_category IN (
    'training_gap',
    'process_failure',
    'communication_breakdown',
    'resource_shortage',
    'environmental',
    'equipment_failure',
    'staffing',
    'systemic',
    'other'
  )),
  
  -- Learning & Action
  key_learning TEXT NOT NULL,
  recommendations TEXT,
  changes_made TEXT,
  evidence_urls TEXT[],
  
  -- Action Plan Link
  action_plan_id UUID REFERENCES action_plans(id),
  action_plan_reference TEXT,
  
  -- Implementation
  implemented BOOLEAN DEFAULT FALSE,
  implementation_date DATE,
  implemented_by UUID REFERENCES profiles(id),
  implementation_notes TEXT,
  
  -- Review & Verification
  reviewed_by UUID REFERENCES profiles(id),
  reviewed_date DATE,
  review_notes TEXT,
  effectiveness_rating INTEGER CHECK (effectiveness_rating BETWEEN 1 AND 5),
  
  -- Sharing
  shared_with_team BOOLEAN DEFAULT FALSE,
  shared_date DATE,
  shared_method TEXT CHECK (shared_method IN ('meeting', 'email', 'newsletter', 'training', 'other')),
  shared_notes TEXT,
  
  -- Classification
  is_confidential BOOLEAN DEFAULT FALSE,
  is_training_required BOOLEAN DEFAULT FALSE,
  training_course_id UUID REFERENCES training_courses(id),
  
  -- Status
  status TEXT DEFAULT 'draft' CHECK (status IN (
    'draft',
    'review_pending',
    'approved',
    'implemented',
    'shared',
    'closed'
  )),
  
  -- Metadata
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_by UUID REFERENCES profiles(id),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  organisation_id UUID REFERENCES organisations(id),
  
  -- Soft Delete
  deleted_at TIMESTAMP WITH TIME ZONE
);

-- Enable RLS
ALTER TABLE lessons_learnt ENABLE ROW LEVEL SECURITY;

-- RLS Policy
CREATE POLICY tenant_isolation_lessons_learnt ON lessons_learnt
  FOR ALL USING (organisation_id = (SELECT organisation_id FROM profiles WHERE id = auth.uid()));

-- Indexes
CREATE INDEX idx_lessons_reference ON lessons_learnt(reference_number);
CREATE INDEX idx_lessons_source ON lessons_learnt(source_type, source_id);
CREATE INDEX idx_lessons_status ON lessons_learnt(status);
CREATE INDEX idx_lessons_category ON lessons_learnt(category);
CREATE INDEX idx_lessons_implemented ON lessons_learnt(implemented);

-- Generate reference number function
CREATE OR REPLACE FUNCTION generate_lesson_reference()
RETURNS TRIGGER AS $$
DECLARE
  year TEXT;
  seq TEXT;
BEGIN
  year := TO_CHAR(NEW.created_at, 'YYYY');
  
  SELECT LPAD((COUNT(*) + 1)::TEXT, 4, '0') INTO seq
  FROM lessons_learnt 
  WHERE organisation_id = NEW.organisation_id 
  AND EXTRACT(YEAR FROM created_at) = EXTRACT(YEAR FROM NEW.created_at);
  
  IF seq IS NULL THEN seq := '0001'; END IF;
  
  NEW.reference_number := 'LL-' || year || '-' || seq;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for reference number
CREATE TRIGGER set_lesson_reference
  BEFORE INSERT ON lessons_learnt
  FOR EACH ROW
  EXECUTE FUNCTION generate_lesson_reference();