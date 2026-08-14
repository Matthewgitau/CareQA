-- Create care_plan_audits table
CREATE TABLE IF NOT EXISTS care_plan_audits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  care_plan_id UUID,
  service_user_id UUID NOT NULL,
  service_user_name TEXT NOT NULL,
  audit_date DATE NOT NULL DEFAULT CURRENT_DATE,
  auditor_name TEXT NOT NULL,
  auditor_id UUID,
  
  -- ============================================
  -- SECTION 1: Person-Centred Care (Max 12)
  -- Score each 0-2 (0=Not met, 1=Partially met, 2=Fully met)
  -- ============================================
  
  pc_what_matters_to_me INTEGER,
  pc_personal_history INTEGER,
  pc_communication_needs INTEGER,
  pc_cultural_spiritual INTEGER,
  pc_social_connections INTEGER,
  pc_goals_aspirations INTEGER,
  
  -- ============================================
  -- SECTION 2: Risk Assessment Integration (Max 18)
  -- ============================================
  
  risk_falls INTEGER,
  risk_medication INTEGER,
  risk_nutrition INTEGER,
  risk_pressure_sores INTEGER,
  risk_continence INTEGER,
  risk_mental_capacity INTEGER,
  risk_challenging_behaviour INTEGER,
  risk_self_harm INTEGER,
  risk_epilepsy INTEGER,
  risk_diabetes INTEGER,
  
  -- ============================================
  -- SECTION 3: Care Delivery Instructions (Max 14)
  -- ============================================
  
  delivery_daily_living INTEGER,
  delivery_personal_care INTEGER,
  delivery_mobility INTEGER,
  delivery_medication_support INTEGER,
  delivery_mealtimes INTEGER,
  delivery_social_activities INTEGER,
  delivery_night_time INTEGER,
  
  -- ============================================
  -- SECTION 4: Legal & Ethical Compliance (Max 12)
  -- ============================================
  
  legal_mca_2005 INTEGER,
  legal_consent INTEGER,
  legal_dols INTEGER,
  legal_advance_decisions INTEGER,
  legal_epr INTEGER,
  legal_data_protection INTEGER,
  
  -- ============================================
  -- SECTION 5: Review & Monitoring (Max 12)
  -- ============================================
  
  review_frequency INTEGER,
  review_last_date INTEGER,
  review_next_date INTEGER,
  review_effectiveness INTEGER,
  review_changes_documented INTEGER,
  review_incident_integration INTEGER,
  
  -- ============================================
  -- SECTION 6: Multi-Disciplinary Working (Max 20)
  -- ============================================
  
  md_gp_details INTEGER,
  md_district_nurse INTEGER,
  md_specialist_nurse INTEGER,
  md_pharmacist INTEGER,
  md_occupational_therapist INTEGER,
  md_physiotherapist INTEGER,
  md_speech_therapy INTEGER,
  md_dietitian INTEGER,
  md_mental_health INTEGER,
  md_family_carers INTEGER,
  
  -- ============================================
  -- SECTION 7: End of Life Care (Max 10, optional)
  -- ============================================
  
  eol_preferences INTEGER,
  eol_care_plan INTEGER,
  eol_preferred_place INTEGER,
  eol_advanced_care_plan INTEGER,
  eol_dnacpr INTEGER,
  
  -- ============================================
  -- SECTION 8: Format & Accessibility (Max 10)
  -- ============================================
  
  format_accessible INTEGER,
  format_language INTEGER,
  format_legible INTEGER,
  format_sectioned INTEGER,
  format_version_control INTEGER,
  
  -- ============================================
  -- SECTION 9: Critical Compliance Flags
  -- ============================================
  
  critical_no_care_plan BOOLEAN DEFAULT false,
  critical_not_reviewed_annually BOOLEAN DEFAULT false,
  critical_missing_mca BOOLEAN DEFAULT false,
  critical_missing_consent BOOLEAN DEFAULT false,
  critical_risk_not_managed BOOLEAN DEFAULT false,
  critical_medication_error BOOLEAN DEFAULT false,
  critical_safeguarding_missing BOOLEAN DEFAULT false,
  critical_contradictory_instructions BOOLEAN DEFAULT false,
  critical_outdated_information BOOLEAN DEFAULT false,
  
  -- ============================================
  -- Calculated Scores
  -- ============================================
  
  pc_total_score INTEGER,
  pc_max_possible INTEGER DEFAULT 12,
  risk_total_score INTEGER,
  risk_max_possible INTEGER DEFAULT 18,
  delivery_total_score INTEGER,
  delivery_max_possible INTEGER DEFAULT 14,
  legal_total_score INTEGER,
  legal_max_possible INTEGER DEFAULT 12,
  review_total_score INTEGER,
  review_max_possible INTEGER DEFAULT 12,
  md_total_score INTEGER,
  md_max_possible INTEGER DEFAULT 20,
  eol_total_score INTEGER,
  eol_max_possible INTEGER DEFAULT 10,
  eol_applicable BOOLEAN DEFAULT false,
  format_total_score INTEGER,
  format_max_possible INTEGER DEFAULT 10,
  
  total_score INTEGER,
  max_possible_score INTEGER,
  overall_percentage DECIMAL,
  risk_level TEXT,
  
  critical_flags_present BOOLEAN DEFAULT false,
  critical_flags_count INTEGER DEFAULT 0,
  critical_flags_details TEXT,
  
  -- ============================================
  -- Audit Outcome
  -- ============================================
  
  requires_action BOOLEAN DEFAULT false,
  action_required TEXT,
  action_assigned_to UUID,
  action_deadline DATE,
  action_completed BOOLEAN DEFAULT false,
  action_completed_date DATE,
  action_notes TEXT,
  recommendations TEXT,
  
  -- ============================================
  -- Sign-off
  -- ============================================
  
  auditor_signature TEXT,
  clinical_lead_reviewed BOOLEAN DEFAULT false,
  clinical_lead_reviewed_by UUID,
  clinical_lead_reviewed_at TIMESTAMPTZ,
  clinical_lead_notes TEXT,
  registered_manager_reviewed BOOLEAN DEFAULT false,
  registered_manager_reviewed_by UUID,
  registered_manager_reviewed_at TIMESTAMPTZ,
  registered_manager_notes TEXT,
  
  -- ============================================
  -- Metadata
  -- ============================================
  
  status TEXT DEFAULT 'draft',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  organisation_id UUID
);

ALTER TABLE care_plan_audits ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow all authenticated" ON care_plan_audits;
CREATE POLICY "Allow all authenticated" ON care_plan_audits
  FOR ALL USING (auth.role() = 'authenticated');