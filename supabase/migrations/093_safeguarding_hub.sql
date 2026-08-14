-- 093: Safeguarding Hub
-- Consolidates all incident, concern, and whistleblowing reports

-- ============================================
-- SAFEGUARDING HUB TABLES
-- ============================================

-- 1. Accident Logs
CREATE TABLE IF NOT EXISTS accident_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  service_user_id UUID REFERENCES service_users(id),
  service_user_name TEXT,
  accident_date DATE NOT NULL,
  accident_time TIME,
  location TEXT,
  accident_type TEXT,
  description TEXT NOT NULL,
  injury_severity TEXT,
  first_aid_given BOOLEAN DEFAULT false,
  first_aid_details TEXT,
  medical_attention_sought BOOLEAN DEFAULT false,
  medical_provider TEXT,
  hospital_reference TEXT,
  reported_to_family BOOLEAN DEFAULT false,
  family_notified_at TIMESTAMPTZ,
  reported_to_cqc BOOLEAN DEFAULT false,
  cqc_reference TEXT,
  root_cause_analysis TEXT,
  preventive_actions TEXT,
  status TEXT DEFAULT 'investigating',
  resolved_at TIMESTAMPTZ,
  resolved_by UUID,
  created_by UUID,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  organisation_id UUID
);

-- 2. Complaints Log
CREATE TABLE IF NOT EXISTS complaints_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  service_user_id UUID REFERENCES service_users(id),
  service_user_name TEXT,
  complainant_name TEXT,
  complainant_type TEXT,
  complaint_date DATE NOT NULL,
  complaint_category TEXT,
  description TEXT NOT NULL,
  investigation_summary TEXT,
  outcome TEXT,
  actions_taken TEXT,
  complainant_satisfied BOOLEAN,
  response_date DATE,
  cqc_notified BOOLEAN DEFAULT false,
  status TEXT DEFAULT 'investigating',
  resolved_at TIMESTAMPTZ,
  resolved_by UUID,
  created_by UUID,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  organisation_id UUID
);

-- 3. Medication Incidents / Errors
CREATE TABLE IF NOT EXISTS medication_incidents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  service_user_id UUID REFERENCES service_users(id),
  service_user_name TEXT,
  incident_date DATE NOT NULL,
  incident_time TIME,
  medication_name TEXT NOT NULL,
  prescribed_dosage TEXT,
  actual_dosage TEXT,
  incident_type TEXT,
  severity TEXT,
  description TEXT NOT NULL,
  immediate_action TEXT,
  root_cause TEXT,
  preventive_measures TEXT,
  reported_to_gp BOOLEAN DEFAULT false,
  reported_to_family BOOLEAN DEFAULT false,
  mar_chart_updated BOOLEAN DEFAULT false,
  status TEXT DEFAULT 'investigating',
  resolved_at TIMESTAMPTZ,
  resolved_by UUID,
  created_by UUID,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  organisation_id UUID
);

-- 4. Missing Persons Report
CREATE TABLE IF NOT EXISTS missing_persons (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  service_user_id UUID REFERENCES service_users(id),
  service_user_name TEXT,
  missing_date DATE NOT NULL,
  missing_time TIME NOT NULL,
  last_seen_location TEXT,
  circumstances TEXT,
  risk_assessment TEXT,
  police_informed BOOLEAN DEFAULT false,
  police_reference TEXT,
  police_contact_name TEXT,
  family_informed BOOLEAN DEFAULT false,
  family_notified_at TIMESTAMPTZ,
  cqc_informed BOOLEAN DEFAULT false,
  safeguarding_lead_informed BOOLEAN DEFAULT false,
  internal_search_conducted BOOLEAN DEFAULT false,
  search_details TEXT,
  found_at TIMESTAMPTZ,
  found_location TEXT,
  condition_on_return TEXT,
  debrief_conducted BOOLEAN DEFAULT false,
  debrief_notes TEXT,
  preventive_actions TEXT,
  status TEXT DEFAULT 'active',
  resolved_at TIMESTAMPTZ,
  resolved_by UUID,
  created_by UUID,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  organisation_id UUID
);

-- 5. Serious Incidents (RIDDOR / CQC Notifiable)
CREATE TABLE IF NOT EXISTS serious_incidents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  service_user_id UUID REFERENCES service_users(id),
  service_user_name TEXT,
  incident_date DATE NOT NULL,
  incident_time TIME,
  incident_type TEXT,
  description TEXT NOT NULL,
  notification_required BOOLEAN DEFAULT true,
  cqc_notified_at TIMESTAMPTZ,
  cqc_reference TEXT,
  cqc_notification_method TEXT,
  local_authority_notified BOOLEAN DEFAULT false,
  local_authority_reference TEXT,
  police_involved BOOLEAN DEFAULT false,
  police_reference TEXT,
  coroner_involved BOOLEAN DEFAULT false,
  coroner_reference TEXT,
  investigation_lead TEXT,
  investigation_summary TEXT,
  root_cause_analysis TEXT,
  action_plan TEXT,
  lessons_learned TEXT,
  status TEXT DEFAULT 'investigating',
  cqc_acknowledged BOOLEAN DEFAULT false,
  cqc_acknowledged_at TIMESTAMPTZ,
  resolved_at TIMESTAMPTZ,
  resolved_by UUID,
  created_by UUID,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  organisation_id UUID
);

-- 6. Whistleblower Reports (Anonymous)
CREATE TABLE IF NOT EXISTS whistleblower_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  report_reference TEXT UNIQUE,
  reported_by_email TEXT,
  report_date DATE NOT NULL DEFAULT CURRENT_DATE,
  category TEXT NOT NULL,
  description TEXT NOT NULL,
  service_user_id UUID,
  service_user_name TEXT,
  carer_id UUID,
  carer_name TEXT,
  date_time_occurred TIMESTAMPTZ,
  location TEXT,
  witnesses TEXT,
  evidence_provided BOOLEAN DEFAULT false,
  evidence_details TEXT,
  anonymous BOOLEAN DEFAULT true,
  status TEXT DEFAULT 'pending',
  priority TEXT DEFAULT 'medium',
  assigned_to UUID,
  assigned_at TIMESTAMPTZ,
  review_notes TEXT,
  investigation_outcome TEXT,
  actions_taken TEXT,
  resolved_at TIMESTAMPTZ,
  resolved_by UUID,
  feedback_to_reporter TEXT,
  archived BOOLEAN DEFAULT false,
  archived_at TIMESTAMPTZ,
  archived_by UUID,
  archive_reason TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  organisation_id UUID
);

-- 7. Missing Items (Theft/Loss)
CREATE TABLE IF NOT EXISTS missing_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  service_user_id UUID REFERENCES service_users(id),
  service_user_name TEXT,
  item_name TEXT NOT NULL,
  item_description TEXT,
  item_value DECIMAL(10,2),
  missing_date DATE NOT NULL,
  last_seen_location TEXT,
  circumstances TEXT,
  police_informed BOOLEAN DEFAULT false,
  police_reference TEXT,
  family_informed BOOLEAN DEFAULT false,
  insurance_claim_filed BOOLEAN DEFAULT false,
  insurance_reference TEXT,
  internal_investigation TEXT,
  outcome TEXT,
  status TEXT DEFAULT 'investigating',
  created_by UUID,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  organisation_id UUID
);

-- ============================================
-- INDEXES
-- ============================================
CREATE INDEX IF NOT EXISTS idx_accident_logs_date ON accident_logs(accident_date);
CREATE INDEX IF NOT EXISTS idx_accident_logs_status ON accident_logs(status);
CREATE INDEX IF NOT EXISTS idx_complaints_logs_date ON complaints_logs(complaint_date);
CREATE INDEX IF NOT EXISTS idx_complaints_logs_status ON complaints_logs(status);
CREATE INDEX IF NOT EXISTS idx_medication_incidents_date ON medication_incidents(incident_date);
CREATE INDEX IF NOT EXISTS idx_medication_incidents_status ON medication_incidents(status);
CREATE INDEX IF NOT EXISTS idx_missing_persons_date ON missing_persons(missing_date);
CREATE INDEX IF NOT EXISTS idx_missing_persons_status ON missing_persons(status);
CREATE INDEX IF NOT EXISTS idx_serious_incidents_date ON serious_incidents(incident_date);
CREATE INDEX IF NOT EXISTS idx_serious_incidents_status ON serious_incidents(status);
CREATE INDEX IF NOT EXISTS idx_whistleblower_reports_status ON whistleblower_reports(status);
CREATE INDEX IF NOT EXISTS idx_whistleblower_reports_priority ON whistleblower_reports(priority);
CREATE INDEX IF NOT EXISTS idx_whistleblower_reports_reference ON whistleblower_reports(report_reference);
CREATE INDEX IF NOT EXISTS idx_missing_items_date ON missing_items(missing_date);

-- ============================================
-- RLS POLICIES
-- ============================================
ALTER TABLE accident_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE complaints_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE medication_incidents ENABLE ROW LEVEL SECURITY;
ALTER TABLE missing_persons ENABLE ROW LEVEL SECURITY;
ALTER TABLE serious_incidents ENABLE ROW LEVEL SECURITY;
ALTER TABLE whistleblower_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE missing_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow all authenticated" ON accident_logs FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Allow all authenticated" ON complaints_logs FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Allow all authenticated" ON medication_incidents FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Allow all authenticated" ON missing_persons FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Allow all authenticated" ON serious_incidents FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Allow all authenticated" ON whistleblower_reports FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Allow all authenticated" ON missing_items FOR ALL USING (auth.role() = 'authenticated');

-- ============================================
-- AUTO-GENERATE WHISTLEBLOWER REFERENCE
-- ============================================
CREATE OR REPLACE FUNCTION generate_whistleblower_reference()
RETURNS TRIGGER AS $$
DECLARE
  year TEXT;
  month TEXT;
  seq INTEGER;
  seq_text TEXT;
BEGIN
  year := TO_CHAR(NEW.report_date, 'YYYY');
  month := TO_CHAR(NEW.report_date, 'MM');

  SELECT COALESCE(MAX(CAST(SUBSTRING(report_reference FROM 'WB-\d{4}-\d{2}-(\d{4})$') AS INTEGER)), 0) + 1
  INTO seq
  FROM whistleblower_reports
  WHERE report_reference LIKE 'WB-' || year || '-' || month || '-%';

  seq_text := LPAD(seq::TEXT, 4, '0');
  NEW.report_reference := 'WB-' || year || '-' || month || '-' || seq_text;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS set_whistleblower_reference ON whistleblower_reports;
CREATE TRIGGER set_whistleblower_reference
  BEFORE INSERT ON whistleblower_reports
  FOR EACH ROW
  WHEN (NEW.report_reference IS NULL)
  EXECUTE FUNCTION generate_whistleblower_reference();

-- ============================================
-- UPDATED_AT TRIGGERS
-- ============================================
CREATE OR REPLACE FUNCTION update_safeguarding_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_accident_logs_updated BEFORE UPDATE ON accident_logs FOR EACH ROW EXECUTE FUNCTION update_safeguarding_updated_at();
CREATE TRIGGER trg_complaints_logs_updated BEFORE UPDATE ON complaints_logs FOR EACH ROW EXECUTE FUNCTION update_safeguarding_updated_at();
CREATE TRIGGER trg_medication_incidents_updated BEFORE UPDATE ON medication_incidents FOR EACH ROW EXECUTE FUNCTION update_safeguarding_updated_at();
CREATE TRIGGER trg_missing_persons_updated BEFORE UPDATE ON missing_persons FOR EACH ROW EXECUTE FUNCTION update_safeguarding_updated_at();
CREATE TRIGGER trg_serious_incidents_updated BEFORE UPDATE ON serious_incidents FOR EACH ROW EXECUTE FUNCTION update_safeguarding_updated_at();
CREATE TRIGGER trg_missing_items_updated BEFORE UPDATE ON missing_items FOR EACH ROW EXECUTE FUNCTION update_safeguarding_updated_at();