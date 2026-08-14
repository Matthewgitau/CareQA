-- Create disciplinary_cases table
CREATE TABLE IF NOT EXISTS disciplinary_cases (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  staff_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  staff_name TEXT NOT NULL,
  employee_number TEXT,
  department TEXT,
  job_title TEXT,

  -- Carer/Service User Involvement
  carer_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  carer_name TEXT,
  service_user_involved BOOLEAN DEFAULT FALSE,
  service_user_id UUID REFERENCES service_users(id) ON DELETE SET NULL,
  service_user_name TEXT,

  -- Case Details
  case_reference TEXT UNIQUE,
  incident_date DATE NOT NULL,
  report_date DATE NOT NULL,
  reported_by UUID REFERENCES profiles(id),
  reported_by_name TEXT,

  -- Incident Information
  incident_type TEXT CHECK (incident_type IN (
    'gross_misconduct',
    'misconduct',
    'poor_performance',
    'attendance',
    'health_and_safety',
    'bullying_harassment',
    'theft_fraud',
    'data_breach',
    'confidentiality_breach',
    'conduct_outside_work',
    'other'
  )),
  severity TEXT CHECK (severity IN ('low', 'medium', 'high', 'critical')),
  description TEXT NOT NULL,

  -- Investigation
  investigation_notes TEXT,
  investigation_completed BOOLEAN DEFAULT FALSE,
  investigation_completed_date DATE,
  investigation_officer TEXT,
  investigation_findings TEXT,

  -- Witnesses
  witnesses JSONB DEFAULT '[]',

  -- Hearing/Meeting
  hearing_date DATE,
  hearing_notes TEXT,
  hearing_outcome TEXT,

  -- Decision
  decision TEXT,
  decision_date DATE,
  decision_made_by UUID REFERENCES profiles(id),
  decision_made_by_name TEXT,

  -- Actions
  action_taken TEXT,
  action_start_date DATE,
  action_end_date DATE,
  action_notes TEXT,

  -- Appeal
  appeal_raised BOOLEAN DEFAULT FALSE,
  appeal_date DATE,
  appeal_outcome TEXT,
  appeal_notes TEXT,

  -- Outcomes
  outcome_type TEXT CHECK (outcome_type IN (
    'dismissed',
    'final_written_warning',
    'written_warning',
    'verbal_warning',
    'suspension',
    'demotion',
    'training_required',
    'monitoring_required',
    'no_action'
  )),
  outcome_details TEXT,

  -- Status
  status TEXT DEFAULT 'open' CHECK (status IN (
    'open',
    'investigating',
    'hearing_scheduled',
    'decision_pending',
    'closed',
    'appealed'
  )),

  -- Compliance & Notes
  notes TEXT,
  signature_url TEXT,
  is_confidential BOOLEAN DEFAULT TRUE,
  compliance_risk BOOLEAN DEFAULT FALSE,

  -- HR Use Only
  hr_review_required BOOLEAN DEFAULT FALSE,
  hr_review_date DATE,
  hr_notes TEXT,

  -- Metadata
  organisation_id UUID REFERENCES organisations(id),
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE disciplinary_cases ENABLE ROW LEVEL SECURITY;

-- RLS Policies
DROP POLICY IF EXISTS "tenant_isolation_disciplinary" ON disciplinary_cases;
CREATE POLICY "tenant_isolation_disciplinary" ON disciplinary_cases
  FOR ALL USING (organisation_id = (SELECT organisation_id FROM profiles WHERE id = auth.uid()));

-- Indexes
CREATE INDEX idx_disciplinary_staff_id ON disciplinary_cases(staff_id);
CREATE INDEX idx_disciplinary_status ON disciplinary_cases(status);
CREATE INDEX idx_disciplinary_incident_date ON disciplinary_cases(incident_date);
CREATE INDEX idx_disciplinary_case_reference ON disciplinary_cases(case_reference);

-- Generate case reference function
CREATE OR REPLACE FUNCTION generate_case_reference()
RETURNS TRIGGER AS $$
BEGIN
  NEW.case_reference := 'DISC-' || TO_CHAR(NEW.created_at, 'YYYYMMDD') || '-' || LPAD(CAST(EXTRACT(EPOCH FROM NEW.created_at) AS TEXT), 6, '0');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-generate case reference
CREATE TRIGGER set_case_reference
  BEFORE INSERT ON disciplinary_cases
  FOR EACH ROW
  EXECUTE FUNCTION generate_case_reference();