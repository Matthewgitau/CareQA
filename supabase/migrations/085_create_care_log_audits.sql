-- Create care_log_audits table
CREATE TABLE IF NOT EXISTS care_log_audits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  daily_note_id UUID NOT NULL REFERENCES daily_notes(id) ON DELETE CASCADE,
  service_user_id UUID NOT NULL,
  service_user_name TEXT NOT NULL,
  audit_date DATE NOT NULL DEFAULT CURRENT_DATE,
  auditor_name TEXT NOT NULL,
  auditor_id UUID,
  
  -- Section 1: Completeness (0-2 score each)
  completeness_basic_info INTEGER, -- 0-2 (service user, date, time, carer)
  completeness_visit_type INTEGER, -- 0-2 (visit type selected)
  completeness_care_acceptance INTEGER, -- 0-2 (acceptance recorded, reason if refused)
  completeness_emotional_state INTEGER, -- 0-2 (emotional state recorded)
  completeness_pad_check INTEGER, -- 0-2 (pad check if applicable)
  completeness_food_fluid INTEGER, -- 0-2 (food/fluid recorded if offered)
  completeness_medication INTEGER, -- 0-2 (medication observed if applicable)
  completeness_observations INTEGER, -- 0-2 (skin, mobility, communication)
  completeness_incidents INTEGER, -- 0-2 (incidents recorded if occurred)
  completeness_signature INTEGER, -- 0-2 (signature present)
  
  -- Section 2: Accuracy (0-2 score each)
  accuracy_emotional_state_match BOOLEAN, -- Does emotional state match notes?
  accuracy_food_fluid_amounts BOOLEAN, -- Are amounts realistic?
  accuracy_medication_details BOOLEAN, -- Do med details match MAR?
  accuracy_skin_condition BOOLEAN, -- Is skin condition documented correctly?
  accuracy_incident_details BOOLEAN, -- Are incident details complete?
  
  -- Section 3: Compliance (0-2 score each)
  compliance_care_act_2014 BOOLEAN, -- Person-centred care principles followed?
  compliance_mca_2005 BOOLEAN, -- Capacity considerations noted if relevant?
  compliance_dols BOOLEAN, -- DoLS considerations if applicable?
  compliance_confidentiality BOOLEAN, -- No breach of confidentiality?
  compliance_timeliness BOOLEAN, -- Note completed within 24 hours?
  
  -- Section 4: Quality (0-2 score each)
  quality_professional_language BOOLEAN, -- Professional, not informal
  quality_objective_observations BOOLEAN, -- Facts, not opinions
  quality_legibility_readability BOOLEAN, -- Clear and readable
  quality_actionable_information BOOLEAN, -- Contains actionable info for next carer
  quality_continuity_of_care BOOLEAN, -- References previous notes appropriately
  
  -- Section 5: Clinical Safety (Critical — any issue flags this)
  clinical_safety_medication_errors BOOLEAN DEFAULT false, -- Any medication discrepancies?
  clinical_safety_safeguarding BOOLEAN DEFAULT false, -- Missing safeguarding concerns?
  clinical_safety_health_deterioration BOOLEAN DEFAULT false, -- Missed health changes?
  clinical_safety_falls_risk BOOLEAN DEFAULT false, -- Falls risk not documented?
  clinical_safety_nutrition_hydration BOOLEAN DEFAULT false, -- Nutrition/hydration concerns missed?
  
  -- Overall scores
  total_completeness_score INTEGER,
  max_completeness_possible INTEGER DEFAULT 20,
  total_accuracy_score INTEGER,
  max_accuracy_possible INTEGER DEFAULT 10,
  total_compliance_score INTEGER,
  max_compliance_possible INTEGER DEFAULT 10,
  total_quality_score INTEGER,
  max_quality_possible INTEGER DEFAULT 10,
  overall_score INTEGER,
  overall_percentage DECIMAL,
  risk_level TEXT, -- 'low', 'medium', 'high', 'critical'
  
  -- Clinical safety flag
  clinical_safety_alert BOOLEAN DEFAULT false,
  clinical_safety_notes TEXT,
  
  -- Audit outcome
  requires_action BOOLEAN DEFAULT false,
  action_required TEXT,
  action_assigned_to UUID,
  action_deadline DATE,
  action_completed BOOLEAN DEFAULT false,
  action_completed_date DATE,
  action_notes TEXT,
  
  -- Sign-off
  auditor_signature TEXT,
  manager_reviewed BOOLEAN DEFAULT false,
  manager_reviewed_by UUID,
  manager_reviewed_at TIMESTAMPTZ,
  manager_notes TEXT,
  
  -- Metadata
  status TEXT DEFAULT 'draft', -- 'draft', 'completed', 'reviewed', 'action_required'
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  organisation_id UUID
);

-- Enable RLS
ALTER TABLE care_log_audits ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow all authenticated" ON care_log_audits;
CREATE POLICY "Allow all authenticated" ON care_log_audits
  FOR ALL USING (auth.role() = 'authenticated');