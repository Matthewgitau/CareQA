-- Create policy_library table
CREATE TABLE policy_library (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  -- Policy Details
  policy_title TEXT NOT NULL,
  policy_reference TEXT UNIQUE NOT NULL,
  version TEXT NOT NULL DEFAULT '1.0',
  department TEXT,
  
  -- Classification
  category TEXT CHECK (category IN (
    'clinical',
    'governance',
    'health_safety',
    'human_resources',
    'finance',
    'data_protection',
    'safeguarding',
    'medication',
    'staff',
    'service_user',
    'quality',
    'operations',
    'other'
  )),
  sub_category TEXT,
  
  -- Policy Content
  summary TEXT,
  policy_body TEXT NOT NULL,
  scope TEXT,
  purpose TEXT,
  definitions JSONB,
  responsibilities JSONB,
  
  -- Compliance & Regulatory
  regulatory_basis TEXT[],
  standards TEXT[],
  
  -- Workflow
  status TEXT DEFAULT 'draft' CHECK (status IN (
    'draft',
    'review_pending',
    'approved',
    'published',
    'archived'
  )),
  approval_date DATE,
  approved_by UUID REFERENCES profiles(id),
  publish_date DATE,
  published_by UUID REFERENCES profiles(id),
  
  -- Dates
  effective_date DATE,
  review_date DATE,
  next_review_date DATE,
  archived_date DATE,
  
  -- Ownership
  owner_id UUID REFERENCES profiles(id),
  owner_name TEXT,
  author_id UUID REFERENCES profiles(id),
  author_name TEXT,
  
  -- Documents
  file_url TEXT,
  file_name TEXT,
  file_size INTEGER,
  file_type TEXT,
  
  -- Training
  training_required BOOLEAN DEFAULT FALSE,
  training_course_id UUID REFERENCES training_courses(id),
  training_notes TEXT,
  
  -- Metadata
  tags TEXT[],
  keywords TEXT[],
  
  -- Review History
  review_history JSONB DEFAULT '[]',
  
  -- Read Tracking
  read_by JSONB DEFAULT '[]',
  acknowledged_by JSONB DEFAULT '[]',
  
  -- Compliance
  is_mandatory BOOLEAN DEFAULT TRUE,
  non_compliance_risk TEXT,
  enforcement_notes TEXT,
  
  -- Notes
  notes TEXT,
  internal_notes TEXT,
  
  -- Audit
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_by UUID REFERENCES profiles(id),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  organisation_id UUID REFERENCES organisations(id),
  
  -- Soft Delete
  deleted_at TIMESTAMP WITH TIME ZONE
);

-- Enable RLS
ALTER TABLE policy_library ENABLE ROW LEVEL SECURITY;

-- RLS Policy
CREATE POLICY tenant_isolation_policy_library ON policy_library
  FOR ALL USING (organisation_id = (SELECT organisation_id FROM profiles WHERE id = auth.uid()));

-- Indexes
CREATE INDEX idx_policy_reference ON policy_library(policy_reference);
CREATE INDEX idx_policy_category ON policy_library(category);
CREATE INDEX idx_policy_status ON policy_library(status);
CREATE INDEX idx_policy_review_date ON policy_library(next_review_date);
CREATE INDEX idx_policy_owner ON policy_library(owner_id);

-- Generate policy reference function
CREATE OR REPLACE FUNCTION generate_policy_reference()
RETURNS TRIGGER AS $$
DECLARE
  prefix TEXT;
  seq TEXT;
BEGIN
  prefix := CASE NEW.category
    WHEN 'clinical' THEN 'CLIN'
    WHEN 'governance' THEN 'GOV'
    WHEN 'health_safety' THEN 'HS'
    WHEN 'human_resources' THEN 'HR'
    WHEN 'finance' THEN 'FIN'
    WHEN 'data_protection' THEN 'DP'
    WHEN 'safeguarding' THEN 'SAF'
    WHEN 'medication' THEN 'MED'
    WHEN 'staff' THEN 'STF'
    WHEN 'service_user' THEN 'SU'
    WHEN 'quality' THEN 'QUAL'
    ELSE 'POL'
  END;
  
  SELECT LPAD((COUNT(*) + 1)::TEXT, 3, '0') INTO seq
  FROM policy_library 
  WHERE organisation_id = NEW.organisation_id 
  AND category = NEW.category;
  
  IF seq IS NULL THEN seq := '001'; END IF;
  
  NEW.policy_reference := prefix || '-' || seq;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for policy reference
CREATE TRIGGER set_policy_reference
  BEFORE INSERT ON policy_library
  FOR EACH ROW
  EXECUTE FUNCTION generate_policy_reference();

-- Function to check review dates
CREATE OR REPLACE FUNCTION check_policy_review()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.next_review_date IS NOT NULL AND NEW.next_review_date < CURRENT_DATE THEN
    NEW.status := 'review_pending';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for review check
CREATE TRIGGER policy_review_check
  BEFORE INSERT OR UPDATE ON policy_library
  FOR EACH ROW
  EXECUTE FUNCTION check_policy_review();