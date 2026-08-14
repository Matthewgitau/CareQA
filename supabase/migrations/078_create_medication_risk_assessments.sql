-- Create medication_risk_assessments table
CREATE TABLE IF NOT EXISTS medication_risk_assessments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  service_user_id UUID REFERENCES service_users(id) ON DELETE CASCADE,
  service_user_name TEXT NOT NULL,
  assessor_name TEXT NOT NULL,
  date_of_birth DATE NOT NULL,
  assessment_date DATE NOT NULL,
  
  -- Scoring categories
  medication_count_score INT,
  high_risk_meds_score INT,
  sedation_score INT,
  adherence_score INT,
  side_effects_score INT,
  polypharmacy_score INT,
  
  -- Additional fields
  medications_list TEXT,
  notes TEXT,
  total_score INT,
  risk_level TEXT,
  
  -- Verification
  verified_by TEXT,
  signature_data TEXT,
  verification_date DATE,
  
  -- Status & tracking
  status TEXT DEFAULT 'draft',
  created_at TIMESTAMPTZ DEFAULT now(),
  created_by UUID,
  updated_at TIMESTAMPTZ DEFAULT now(),
  organisation_id UUID
);

-- Add RLS policies
ALTER TABLE medication_risk_assessments ENABLE ROW LEVEL SECURITY;

CREATE POLICY IF NOT EXISTS "Users can view their org's medication assessments"
  ON medication_risk_assessments FOR SELECT
  USING (auth.uid() IS NOT NULL);

CREATE POLICY IF NOT EXISTS "Users can insert medication assessments"
  ON medication_risk_assessments FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY IF NOT EXISTS "Users can update their org's medication assessments"
  ON medication_risk_assessments FOR UPDATE
  USING (auth.uid() IS NOT NULL);