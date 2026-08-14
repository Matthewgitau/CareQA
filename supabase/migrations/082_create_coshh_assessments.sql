-- Create coshh_risk_assessments table if not exists
CREATE TABLE IF NOT EXISTS coshh_risk_assessments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  service_user_id UUID,
  assessor_id UUID,
  assessment_date DATE DEFAULT CURRENT_DATE,
  
  -- Substance information
  substance_name TEXT NOT NULL DEFAULT '',
  type_of_harm TEXT NOT NULL DEFAULT '',
  description TEXT NOT NULL DEFAULT '',
  how_causes_harm TEXT NOT NULL DEFAULT 'inhalation',
  who_exposed TEXT[] NOT NULL DEFAULT '{}',
  frequency_of_use TEXT NOT NULL DEFAULT 'daily',
  purpose_activity TEXT NOT NULL DEFAULT '',
  
  -- Risk decisions
  can_be_eliminated BOOLEAN DEFAULT false,
  elimination_reason TEXT,
  
  -- Control measures
  control_measures JSONB DEFAULT '{"engineering":[],"PPE":[],"procedures":[]}',
  emergency_procedures JSONB DEFAULT '{"spill":[],"exposure":[]}',
  
  -- Staff awareness
  staff_aware BOOLEAN DEFAULT false,
  training_required BOOLEAN DEFAULT false,
  training_details TEXT,
  
  -- Final assessment
  risk_acceptable BOOLEAN,
  risk_level TEXT,
  reconsider_controls TEXT,
  
  -- CQC compliance fields
  assessor_signature TEXT,
  review_date DATE,
  reassessment_frequency TEXT,
  
  -- Metadata
  status TEXT DEFAULT 'draft',
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  organisation_id UUID
);

-- Enable RLS
ALTER TABLE coshh_risk_assessments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow all for authenticated users" ON coshh_risk_assessments;
CREATE POLICY "Allow all for authenticated users" ON coshh_risk_assessments
  FOR ALL USING (auth.role() = 'authenticated');