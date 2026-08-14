-- Create action_plans table
CREATE TABLE action_plans (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  -- Reference Details
  reference_number TEXT UNIQUE NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  
  -- Source (where did this action come from?)
  source_type TEXT CHECK (source_type IN (
    'risk_assessment',
    'audit',
    'complaint',
    'incident',
    'safeguarding',
    'regulatory',
    'staff_supervision',
    'service_user_feedback',
    'quality_review',
    'other'
  )),
  source_id UUID,
  source_reference TEXT,
  
  -- Priority & Risk
  priority TEXT CHECK (priority IN ('critical', 'high', 'medium', 'low')),
  risk_level TEXT CHECK (risk_level IN ('critical', 'high', 'medium', 'low')),
  
  -- Categorisation
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
    'other'
  )),
  
  -- Compliance & Regulatory
  regulatory_reference TEXT,
  compliance_requirement TEXT,
  
  -- Action Details
  action_required TEXT NOT NULL,
  action_type TEXT CHECK (action_type IN (
    'corrective',
    'preventive',
    'improvement',
    'training',
    'review',
    'policy_update',
    'other'
  )),
  
  -- Assignment
  assigned_to UUID REFERENCES profiles(id),
  assigned_to_name TEXT,
  assigned_by UUID REFERENCES profiles(id),
  assigned_date DATE NOT NULL,
  
  -- Deadlines
  target_completion_date DATE NOT NULL,
  actual_completion_date DATE,
  
  -- Progress
  status TEXT DEFAULT 'open' CHECK (status IN (
    'open',
    'in_progress',
    'under_review',
    'completed',
    'verified',
    'closed',
    'overdue'
  )),
  progress_percentage INTEGER DEFAULT 0 CHECK (progress_percentage BETWEEN 0 AND 100),
  
  -- Verification & Sign-off
  verification_required BOOLEAN DEFAULT FALSE,
  verified_by UUID REFERENCES profiles(id),
  verified_date DATE,
  verification_notes TEXT,
  
  -- Evidence & Attachments
  evidence_urls TEXT[],
  notes TEXT,
  update_log JSONB DEFAULT '[]',
  
  -- Related
  related_action_plan_ids UUID[],
  depends_on UUID[],
  
  -- Review
  review_date DATE,
  next_review_date DATE,
  
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
ALTER TABLE action_plans ENABLE ROW LEVEL SECURITY;

-- RLS Policy
CREATE POLICY tenant_isolation_action_plans ON action_plans
  FOR ALL USING (organisation_id = (SELECT organisation_id FROM profiles WHERE id = auth.uid()));

-- Indexes
CREATE INDEX idx_action_plans_reference ON action_plans(reference_number);
CREATE INDEX idx_action_plans_assigned_to ON action_plans(assigned_to);
CREATE INDEX idx_action_plans_status ON action_plans(status);
CREATE INDEX idx_action_plans_priority ON action_plans(priority);
CREATE INDEX idx_action_plans_deadline ON action_plans(target_completion_date);
CREATE INDEX idx_action_plans_source ON action_plans(source_type, source_id);

-- Generate reference number function
CREATE OR REPLACE FUNCTION generate_action_reference()
RETURNS TRIGGER AS $$
DECLARE
  year TEXT;
  seq TEXT;
BEGIN
  year := TO_CHAR(NEW.created_at, 'YYYY');
  
  SELECT LPAD((COUNT(*) + 1)::TEXT, 4, '0') INTO seq
  FROM action_plans 
  WHERE organisation_id = NEW.organisation_id 
  AND EXTRACT(YEAR FROM created_at) = EXTRACT(YEAR FROM NEW.created_at);
  
  IF seq IS NULL THEN seq := '0001'; END IF;
  
  NEW.reference_number := 'AP-' || year || '-' || seq;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for reference number
CREATE TRIGGER set_action_reference
  BEFORE INSERT ON action_plans
  FOR EACH ROW
  EXECUTE FUNCTION generate_action_reference();

-- Function to check overdue actions
CREATE OR REPLACE FUNCTION check_overdue_actions()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status NOT IN ('completed', 'verified', 'closed') 
     AND NEW.target_completion_date < CURRENT_DATE THEN
    NEW.status := 'overdue';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for overdue check
CREATE TRIGGER check_action_overdue
  BEFORE INSERT OR UPDATE ON action_plans
  FOR EACH ROW
  EXECUTE FUNCTION check_overdue_actions();