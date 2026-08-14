-- Create spot_checks table
CREATE TABLE IF NOT EXISTS spot_checks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  spot_check_number TEXT UNIQUE,
  service_user_id UUID NOT NULL,
  service_user_name TEXT NOT NULL,
  service_user_dob DATE,
  carer_id UUID NOT NULL,
  carer_name TEXT NOT NULL,
  carer_role TEXT,
  carer_employment_type TEXT,
  spot_check_date DATE NOT NULL DEFAULT CURRENT_DATE,
  spot_check_time TIME NOT NULL,
  spot_check_duration_minutes INTEGER,
  spot_check_type TEXT NOT NULL,
  spot_check_reason TEXT,
  conducted_by_id UUID NOT NULL,
  conducted_by_name TEXT NOT NULL,
  conducted_by_role TEXT,
  witness_present BOOLEAN DEFAULT false,
  witness_name TEXT,
  witness_role TEXT,
  prep_handover_reviewed INTEGER, prep_medication_checked INTEGER, prep_equipment_ready INTEGER,
  arrival_punctuality INTEGER, arrival_presentation INTEGER, arrival_communication INTEGER,
  ic_hand_hygiene INTEGER, ic_ppe_worn INTEGER, ic_ppe_changed INTEGER,
  ic_equipment_cleanliness INTEGER, ic_environment_hygiene INTEGER, ic_waste_disposal INTEGER,
  interaction_greeting INTEGER, interaction_consent INTEGER, interaction_dignity INTEGER,
  interaction_privacy INTEGER, interaction_communication INTEGER, interaction_hearing_listening INTEGER,
  interaction_choice_promoted INTEGER, interaction_capacity_considered INTEGER, interaction_emotional_support INTEGER,
  care_follows_care_plan INTEGER, care_personal_care_quality INTEGER, care_mobility_assistance INTEGER,
  care_medication_administration INTEGER, care_nutrition_hydration INTEGER, care_documentation INTEGER, care_handover_communication INTEGER,
  safety_risk_assessment INTEGER, safety_environment_check INTEGER, safety_moving_handling INTEGER,
  safety_emergency_knowledge INTEGER, safety_medication_security INTEGER, safety_challenging_behaviour INTEGER,
  comm_daily_note_quality INTEGER, comm_incident_reporting INTEGER, comm_family_communication INTEGER,
  comm_other_professionals INTEGER, comm_escalation_awareness INTEGER,
  prof_code_of_conduct INTEGER, prof_medication_knowledge INTEGER, prof_safeguarding_knowledge INTEGER,
  prof_data_protection INTEGER, prof_team_working INTEGER, prof_feedback_receptiveness INTEGER,
  flag_medication_error BOOLEAN DEFAULT false, flag_infection_breach BOOLEAN DEFAULT false,
  flag_dignity_breach BOOLEAN DEFAULT false, flag_safeguarding_concern BOOLEAN DEFAULT false,
  flag_unauthorized_absence BOOLEAN DEFAULT false, flag_untrained_task BOOLEAN DEFAULT false,
  flag_falsified_records BOOLEAN DEFAULT false, flag_refused_care BOOLEAN DEFAULT false,
  flag_aggressive_behaviour BOOLEAN DEFAULT false,
  total_score INTEGER, max_possible_score INTEGER DEFAULT 240,
  overall_percentage DECIMAL, competency_rating TEXT,
  strengths TEXT, areas_for_improvement TEXT, immediate_concerns TEXT, additional_observations TEXT,
  requires_action BOOLEAN DEFAULT false, action_required TEXT,
  action_assigned_to UUID, action_deadline DATE,
  action_completed BOOLEAN DEFAULT false, action_completed_date DATE, action_notes TEXT,
  follow_up_required BOOLEAN DEFAULT false, follow_up_date DATE,
  follow_up_type TEXT, follow_up_completed BOOLEAN DEFAULT false,
  auditor_signature TEXT NOT NULL,
  carer_acknowledged BOOLEAN DEFAULT false, carer_acknowledged_at TIMESTAMPTZ, carer_comments TEXT,
  manager_reviewed BOOLEAN DEFAULT false, manager_reviewed_by UUID,
  manager_reviewed_at TIMESTAMPTZ, manager_notes TEXT,
  status TEXT DEFAULT 'draft',
  created_at TIMESTAMPTZ DEFAULT NOW(), created_by UUID,
  updated_at TIMESTAMPTZ DEFAULT NOW(), organisation_id UUID
);

ALTER TABLE spot_checks ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow all authenticated" ON spot_checks;
CREATE POLICY "Allow all authenticated" ON spot_checks FOR ALL USING (auth.role() = 'authenticated');

CREATE OR REPLACE FUNCTION generate_spot_check_number()
RETURNS TEXT AS $$
DECLARE year TEXT; month TEXT; seq INTEGER; seq_text TEXT;
BEGIN
  year := TO_CHAR(CURRENT_DATE, 'YYYY');
  month := TO_CHAR(CURRENT_DATE, 'MM');
  SELECT COALESCE(MAX(CAST(SUBSTRING(spot_check_number FROM '....$') AS INTEGER)), 0) + 1
  INTO seq FROM spot_checks
  WHERE spot_check_number LIKE 'SPOT-' || year || '-' || month || '-%';
  seq_text := LPAD(seq::TEXT, 4, '0');
  RETURN 'SPOT-' || year || '-' || month || '-' || seq_text;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION trigger_set_spot_check_number()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.spot_check_number IS NULL THEN
    NEW.spot_check_number := generate_spot_check_number();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS set_spot_check_number ON spot_checks;
CREATE TRIGGER set_spot_check_number BEFORE INSERT ON spot_checks FOR EACH ROW EXECUTE FUNCTION trigger_set_spot_check_number();