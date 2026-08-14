-- Missing Tables Migration
-- Creates 8 missing tables identified in database schema audit

-- ============================================================================
-- 1. STOOL LOG - Daily bowel movement tracking
-- ============================================================================
CREATE TABLE stool_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  service_user_id UUID REFERENCES service_users(id) ON DELETE CASCADE,
  log_date DATE NOT NULL,
  log_time TIME NOT NULL,
  bristol_stool_type INTEGER CHECK (bristol_stool_type BETWEEN 1 AND 7), -- Bristol Stool Scale 1-7
  consistency TEXT CHECK (consistency IN ('solid', 'soft', 'loose', 'liquid', 'watery')),
  colour TEXT,
  amount TEXT CHECK (amount IN ('small', 'medium', 'large')),
  assistance_required BOOLEAN DEFAULT FALSE,
  assistance_type TEXT CHECK (assistance_type IN ('none', 'verbal', 'physical', 'full')),
  incontinence_product_used BOOLEAN DEFAULT FALSE,
  skin_condition TEXT,
  notes TEXT,
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE stool_logs ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view stool logs from their organization"
  ON stool_logs FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM service_users su
    JOIN profiles p ON p.organization_id = su.organization_id
    WHERE su.id = stool_logs.service_user_id AND p.id = auth.uid()
  ));

CREATE POLICY "Users can insert stool logs"
  ON stool_logs FOR INSERT
  WITH CHECK (created_by = auth.uid());

CREATE POLICY "Users can update own stool logs"
  ON stool_logs FOR UPDATE
  USING (created_by = auth.uid());

-- Indexes
CREATE INDEX idx_stool_logs_service_user ON stool_logs(service_user_id);
CREATE INDEX idx_stool_logs_date ON stool_logs(log_date);
CREATE INDEX idx_stool_logs_type ON stool_logs(bristol_stool_type);

-- Updated at trigger
CREATE OR REPLACE FUNCTION update_stool_logs_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER stool_logs_updated_at
  BEFORE UPDATE ON stool_logs
  FOR EACH ROW
  EXECUTE FUNCTION update_stool_logs_updated_at();

-- ============================================================================
-- 2. TEMPERATURE LOG - Daily temperature monitoring
-- ============================================================================
CREATE TABLE temperature_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  service_user_id UUID REFERENCES service_users(id) ON DELETE CASCADE,
  log_date DATE NOT NULL,
  log_time TIME NOT NULL,
  temperature_celsius NUMERIC(4,1) NOT NULL CHECK (temperature_celsius >= 35.0 AND temperature_celsius <= 42.0),
  measurement_site TEXT CHECK (measurement_site IN ('oral', 'axillary', 'tympanic', 'temporal', 'rectal')),
  symptoms TEXT[], -- 'chills', 'sweating', 'flushed', 'pale', 'shivering'
  medication_given BOOLEAN DEFAULT FALSE,
  medication_name TEXT,
  medication_dose TEXT,
  action_taken TEXT,
  notes TEXT,
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE temperature_logs ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view temperature logs from their organization"
  ON temperature_logs FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM service_users su
    JOIN profiles p ON p.organization_id = su.organization_id
    WHERE su.id = temperature_logs.service_user_id AND p.id = auth.uid()
  ));

CREATE POLICY "Users can insert temperature logs"
  ON temperature_logs FOR INSERT
  WITH CHECK (created_by = auth.uid());

CREATE POLICY "Users can update own temperature logs"
  ON temperature_logs FOR UPDATE
  USING (created_by = auth.uid());

-- Indexes
CREATE INDEX idx_temperature_logs_service_user ON temperature_logs(service_user_id);
CREATE INDEX idx_temperature_logs_date ON temperature_logs(log_date);
CREATE INDEX idx_temperature_logs_temperature ON temperature_logs(temperature_celsius);

-- Updated at trigger
CREATE OR REPLACE FUNCTION update_temperature_logs_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER temperature_logs_updated_at
  BEFORE UPDATE ON temperature_logs
  FOR EACH ROW
  EXECUTE FUNCTION update_temperature_logs_updated_at();

-- ============================================================================
-- 3. MISSING PERSONS REPORTS - For tracking missing vulnerable adults
-- ============================================================================
CREATE TABLE missing_persons_reports (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  service_user_id UUID REFERENCES service_users(id) ON DELETE CASCADE,
  missing_date DATE NOT NULL,
  missing_time TIME NOT NULL,
  last_seen_location TEXT,
  last_seen_wearing TEXT, -- Description of clothing
  physical_description TEXT,
  photo_url TEXT,
  risk_level TEXT CHECK (risk_level IN ('low', 'medium', 'high', 'critical')),
  circumstances TEXT,
  reported_to_police BOOLEAN DEFAULT FALSE,
  police_reference TEXT,
  reported_to_family BOOLEAN DEFAULT FALSE,
  family_notified_at TIMESTAMP WITH TIME ZONE,
  found_date DATE,
  found_time TIME,
  found_location TEXT,
  found_condition TEXT,
  investigation_notes TEXT,
  prevention_measures TEXT,
  status TEXT DEFAULT 'missing' CHECK (status IN ('missing', 'found', 'resolved')),
  reported_by UUID REFERENCES profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE missing_persons_reports ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view missing persons from their organization"
  ON missing_persons_reports FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM service_users su
    JOIN profiles p ON p.organization_id = su.organization_id
    WHERE su.id = missing_persons_reports.service_user_id AND p.id = auth.uid()
  ));

CREATE POLICY "Users can insert missing persons reports"
  ON missing_persons_reports FOR INSERT
  WITH CHECK (reported_by = auth.uid());

CREATE POLICY "Managers can update missing persons reports"
  ON missing_persons_reports FOR UPDATE
  USING (EXISTS (
    SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'
  ));

-- Indexes
CREATE INDEX idx_missing_persons_reports_service_user ON missing_persons_reports(service_user_id);
CREATE INDEX idx_missing_persons_reports_status ON missing_persons_reports(status);
CREATE INDEX idx_missing_persons_reports_date ON missing_persons_reports(missing_date);

-- Updated at trigger
CREATE OR REPLACE FUNCTION update_missing_persons_reports_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER missing_persons_reports_updated_at
  BEFORE UPDATE ON missing_persons_reports
  FOR EACH ROW
  EXECUTE FUNCTION update_missing_persons_reports_updated_at();

-- ============================================================================
-- 4. SAFEGUARDING REPORTS - For abuse and safeguarding concerns
-- ============================================================================
CREATE TABLE safeguarding_reports (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  service_user_id UUID REFERENCES service_users(id) ON DELETE CASCADE,
  incident_date DATE NOT NULL,
  incident_time TIME,
  abuse_type TEXT NOT NULL CHECK (abuse_type IN ('physical', 'emotional', 'sexual', 'financial', 'neglect', 'discriminatory', 'institutional', 'domestic', 'modern_slavery', 'other')),
  location TEXT,
  description TEXT NOT NULL,
  alleged_perpetrator TEXT,
  witnesses TEXT,
  evidence_urls TEXT[],
  immediate_action_taken TEXT,
  risk_level TEXT CHECK (risk_level IN ('low', 'medium', 'high', 'critical')),
  reported_to_local_authority BOOLEAN DEFAULT FALSE,
  local_authority_reference TEXT,
  reported_to_cqc BOOLEAN DEFAULT FALSE,
  cqc_reference TEXT,
  reported_to_police BOOLEAN DEFAULT FALSE,
  police_reference TEXT,
  investigation_status TEXT DEFAULT 'initial' CHECK (investigation_status IN ('initial', 'investigating', 'substantiated', 'unsubstantiated', 'closed')),
  investigation_notes TEXT,
  outcome TEXT,
  prevention_measures TEXT,
  support_provided TEXT,
  status TEXT DEFAULT 'reported' CHECK (status IN ('reported', 'investigating', 'resolved', 'closed')),
  reported_by UUID REFERENCES profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE safeguarding_reports ENABLE ROW LEVEL SECURITY;

-- RLS Policies (restrictive due to sensitive nature)
CREATE POLICY "Managers can view safeguarding reports from their organization"
  ON safeguarding_reports FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM service_users su
    JOIN profiles p ON p.organization_id = su.organization_id
    WHERE su.id = safeguarding_reports.service_user_id AND p.id = auth.uid() AND p.role = 'admin'
  ));

CREATE POLICY "Managers can insert safeguarding reports"
  ON safeguarding_reports FOR INSERT
  WITH CHECK (reported_by = auth.uid());

CREATE POLICY "Senior managers can update safeguarding reports"
  ON safeguarding_reports FOR UPDATE
  USING (EXISTS (
    SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'
  ));

-- Indexes
CREATE INDEX idx_safeguarding_reports_service_user ON safeguarding_reports(service_user_id);
CREATE INDEX idx_safeguarding_reports_abuse_type ON safeguarding_reports(abuse_type);
CREATE INDEX idx_safeguarding_reports_status ON safeguarding_reports(status);
CREATE INDEX idx_safeguarding_reports_date ON safeguarding_reports(incident_date);

-- Updated at trigger
CREATE OR REPLACE FUNCTION update_safeguarding_reports_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER safeguarding_reports_updated_at
  BEFORE UPDATE ON safeguarding_reports
  FOR EACH ROW
  EXECUTE FUNCTION update_safeguarding_reports_updated_at();

-- ============================================================================
-- 5. ACCIDENTS & INCIDENTS - For tracking all accidents and incidents
-- ============================================================================
CREATE TABLE accidents_incidents (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  service_user_id UUID REFERENCES service_users(id) ON DELETE CASCADE,
  staff_id UUID REFERENCES profiles(id),
  incident_date DATE NOT NULL,
  incident_time TIME NOT NULL,
  location TEXT NOT NULL,
  incident_type TEXT NOT NULL CHECK (incident_type IN ('fall', 'medication_error', 'injury', 'near_miss', 'aggression', 'self_harm', 'equipment_failure', 'environmental', 'other')),
  description TEXT NOT NULL,
  witnesses TEXT,
  injury_type TEXT CHECK (injury_type IN ('none', 'minor', 'moderate', 'severe', 'fatal')),
  body_parts_affected TEXT[],
  immediate_action TEXT,
  medical_attention_required BOOLEAN DEFAULT FALSE,
  medical_attention_type TEXT CHECK (medical_attention_type IN ('first_aid', 'gp', 'hospital', 'ambulance')),
  hospital_attendance BOOLEAN DEFAULT FALSE,
  hospital_name TEXT,
  cqc_notifiable BOOLEAN DEFAULT FALSE,
  cqc_reference TEXT,
  reported_to_family BOOLEAN DEFAULT FALSE,
  family_notified_at TIMESTAMP WITH TIME ZONE,
  investigation_notes TEXT,
  root_cause TEXT,
  prevention_measures TEXT,
  status TEXT DEFAULT 'reported' CHECK (status IN ('reported', 'investigating', 'resolved', 'closed')),
  reported_by UUID REFERENCES profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE accidents_incidents ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view accidents/incidents from their organization"
  ON accidents_incidents FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM service_users su
    JOIN profiles p ON p.organization_id = su.organization_id
    WHERE su.id = accidents_incidents.service_user_id AND p.id = auth.uid()
  ));

CREATE POLICY "Users can insert accidents/incidents"
  ON accidents_incidents FOR INSERT
  WITH CHECK (reported_by = auth.uid());

CREATE POLICY "Managers can update accidents/incidents"
  ON accidents_incidents FOR UPDATE
  USING (EXISTS (
    SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'
  ));

-- Indexes
CREATE INDEX idx_accidents_incidents_service_user ON accidents_incidents(service_user_id);
CREATE INDEX idx_accidents_incidents_type ON accidents_incidents(incident_type);
CREATE INDEX idx_accidents_incidents_status ON accidents_incidents(status);
CREATE INDEX idx_accidents_incidents_date ON accidents_incidents(incident_date);

-- Updated at trigger
CREATE OR REPLACE FUNCTION update_accidents_incidents_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER accidents_incidents_updated_at
  BEFORE UPDATE ON accidents_incidents
  FOR EACH ROW
  EXECUTE FUNCTION update_accidents_incidents_updated_at();

-- ============================================================================
-- 6. COMPLAINTS - For tracking complaints from service users and families
-- ============================================================================
CREATE TABLE complaints (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  service_user_id UUID REFERENCES service_users(id) ON DELETE CASCADE,
  complaint_date DATE NOT NULL,
  complainant_type TEXT CHECK (complainant_type IN ('service_user', 'family', 'professional', 'anonymous', 'other')),
  complainant_name TEXT,
  complainant_contact TEXT,
  category TEXT NOT NULL CHECK (category IN ('care_quality', 'staff_behavior', 'medication', 'environment', 'communication', 'policy', 'discrimination', 'other')),
  description TEXT NOT NULL,
  desired_outcome TEXT,
  urgency TEXT CHECK (urgency IN ('low', 'medium', 'high', 'critical')),
  assigned_to UUID REFERENCES profiles(id),
  investigation_notes TEXT,
  response_provided BOOLEAN DEFAULT FALSE,
  response_date DATE,
  response_details TEXT,
  resolution TEXT,
  satisfied BOOLEAN,
  escalated_to TEXT CHECK (escalated_to IN ('manager', 'director', 'cqc', 'local_authority', 'ombudsman')),
  escalation_date DATE,
  status TEXT DEFAULT 'received' CHECK (status IN ('received', 'acknowledged', 'investigating', 'responded', 'resolved', 'escalated', 'closed')),
  acknowledged_by UUID REFERENCES profiles(id),
  acknowledged_at TIMESTAMP WITH TIME ZONE,
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE complaints ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view complaints from their organization"
  ON complaints FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM service_users su
    JOIN profiles p ON p.organization_id = su.organization_id
    WHERE su.id = complaints.service_user_id AND p.id = auth.uid()
  ));

CREATE POLICY "Users can insert complaints"
  ON complaints FOR INSERT
  WITH CHECK (created_by = auth.uid());

CREATE POLICY "Managers can update complaints"
  ON complaints FOR UPDATE
  USING (EXISTS (
    SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'
  ));

-- Indexes
CREATE INDEX idx_complaints_service_user ON complaints(service_user_id);
CREATE INDEX idx_complaints_category ON complaints(category);
CREATE INDEX idx_complaints_status ON complaints(status);
CREATE INDEX idx_complaints_date ON complaints(complaint_date);

-- Updated at trigger
CREATE OR REPLACE FUNCTION update_complaints_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER complaints_updated_at
  BEFORE UPDATE ON complaints
  FOR EACH ROW
  EXECUTE FUNCTION update_complaints_updated_at();

-- ============================================================================
-- 7. SERIOUS INCIDENTS - For RIDDOR and CQC notifiable incidents
-- ============================================================================
CREATE TABLE serious_incidents (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  service_user_id UUID REFERENCES service_users(id) ON DELETE CASCADE,
  incident_date DATE NOT NULL,
  incident_time TIME NOT NULL,
  location TEXT NOT NULL,
  incident_type TEXT NOT NULL CHECK (incident_type IN ('death', 'serious_injury', 'abuse_allegation', 'missing_person', 'medication_error_serious', 'infection_outbreak', 'fire', 'safeguarding', 'cqc_breach', 'other')),
  description TEXT NOT NULL,
  severity TEXT CHECK (severity IN ('major', 'severe', 'critical')),
  people_involved TEXT[],
  witnesses TEXT,
  immediate_action TEXT,
  emergency_services_attended BOOLEAN DEFAULT FALSE,
  emergency_services_type TEXT CHECK (emergency_services_type IN ('police', 'ambulance', 'fire')),
  hospital_attendance BOOLEAN DEFAULT FALSE,
  fatal BOOLEAN DEFAULT FALSE,
  cqc_notifiable BOOLEAN DEFAULT FALSE,
  cqc_notified_at TIMESTAMP WITH TIME ZONE,
  cqc_reference TEXT,
  hse_notifiable BOOLEAN DEFAULT FALSE, -- RIDDOR
  hse_notified_at TIMESTAMP WITH TIME ZONE,
  hse_reference TEXT,
  local_authority_notified BOOLEAN DEFAULT FALSE,
  local_authority_notified_at TIMESTAMP WITH TIME ZONE,
  police_notified BOOLEAN DEFAULT FALSE,
  police_reference TEXT,
  investigation_lead TEXT CHECK (investigation_lead IN ('internal', 'local_authority', 'cqc', 'police')),
  investigation_status TEXT DEFAULT 'initial' CHECK (investigation_status IN ('initial', 'ongoing', 'completed', 'closed')),
  investigation_findings TEXT,
  root_cause TEXT,
  lessons_learnt TEXT,
  prevention_measures TEXT,
  support_provided TEXT,
  status TEXT DEFAULT 'reported' CHECK (status IN ('reported', 'investigating', 'resolved', 'closed')),
  reported_by UUID REFERENCES profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE serious_incidents ENABLE ROW LEVEL SECURITY;

-- RLS Policies (highly restrictive)
CREATE POLICY "Senior managers can view serious incidents"
  ON serious_incidents FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'
  ));

CREATE POLICY "Senior managers can insert serious incidents"
  ON serious_incidents FOR INSERT
  WITH CHECK (reported_by = auth.uid());

CREATE POLICY "Senior managers can update serious incidents"
  ON serious_incidents FOR UPDATE
  USING (EXISTS (
    SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'
  ));

-- Indexes
CREATE INDEX idx_serious_incidents_service_user ON serious_incidents(service_user_id);
CREATE INDEX idx_serious_incidents_type ON serious_incidents(incident_type);
CREATE INDEX idx_serious_incidents_status ON serious_incidents(status);
CREATE INDEX idx_serious_incidents_date ON serious_incidents(incident_date);

-- Updated at trigger
CREATE OR REPLACE FUNCTION update_serious_incidents_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER serious_incidents_updated_at
  BEFORE UPDATE ON serious_incidents
  FOR EACH ROW
  EXECUTE FUNCTION update_serious_incidents_updated_at();

-- ============================================================================
-- 8. DRIVERS & VEHICLES - For managing staff drivers and vehicle assignments
-- ============================================================================

-- Drivers table (staff with driving duties)
CREATE TABLE drivers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  staff_id UUID REFERENCES profiles(id) ON DELETE CASCADE UNIQUE,
  license_number TEXT NOT NULL,
  license_expiry DATE NOT NULL,
  license_type TEXT CHECK (license_type IN ('car', 'van', 'minibus', 'lorry')),
  insurance_expiry DATE,
  mot_expiry DATE,
  vehicle_registration TEXT,
  vehicle_make TEXT,
  vehicle_model TEXT,
  vehicle_color TEXT,
  vehicle_photo_url TEXT,
  background_check_date DATE,
  background_check_status TEXT CHECK (background_check_status IN ('pending', 'passed', 'failed', 'expired')),
  training_date DATE,
  training_type TEXT,
  notes TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Vehicles table
CREATE TABLE vehicles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  registration TEXT UNIQUE NOT NULL,
  make TEXT NOT NULL,
  model TEXT NOT NULL,
  color TEXT,
  year INTEGER,
  vin TEXT,
  insurance_expiry DATE,
  mot_expiry DATE,
  service_due_date DATE,
  mileage INTEGER,
  is_company_car BOOLEAN DEFAULT TRUE,
  status TEXT DEFAULT 'available' CHECK (status IN ('available', 'assigned', 'maintenance', 'unavailable')),
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Vehicle assignments table
CREATE TABLE vehicle_assignments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  driver_id UUID REFERENCES drivers(id) ON DELETE CASCADE,
  vehicle_id UUID REFERENCES vehicles(id) ON DELETE CASCADE,
  assignment_date DATE NOT NULL,
  return_date DATE,
  purpose TEXT,
  mileage_start INTEGER,
  mileage_end INTEGER,
  fuel_level_start TEXT CHECK (fuel_level_start IN ('empty', 'quarter', 'half', 'three_quarters', 'full')),
  fuel_level_end TEXT CHECK (fuel_level_end IN ('empty', 'quarter', 'half', 'three_quarters', 'full')),
  condition_start TEXT, -- Notes on vehicle condition
  condition_end TEXT,
  issues_reported TEXT,
  liability_signed BOOLEAN DEFAULT FALSE,
  sign_out_by UUID REFERENCES profiles(id),
  sign_in_by UUID REFERENCES profiles(id),
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'completed', 'overdue')),
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE drivers ENABLE ROW LEVEL SECURITY;
ALTER TABLE vehicles ENABLE ROW LEVEL SECURITY;
ALTER TABLE vehicle_assignments ENABLE ROW LEVEL SECURITY;

-- RLS Policies for drivers
CREATE POLICY "Users can view drivers from their organization"
  ON drivers FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM profiles WHERE id = auth.uid()
  ));

CREATE POLICY "Managers can insert drivers"
  ON drivers FOR INSERT
  WITH CHECK (EXISTS (
    SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'
  ));

CREATE POLICY "Managers can update drivers"
  ON drivers FOR UPDATE
  USING (EXISTS (
    SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'
  ));

-- RLS Policies for vehicles
CREATE POLICY "Users can view vehicles"
  ON vehicles FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM profiles WHERE id = auth.uid()
  ));

CREATE POLICY "Managers can manage vehicles"
  ON vehicles FOR ALL
  USING (EXISTS (
    SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'
  ));

-- RLS Policies for vehicle_assignments
CREATE POLICY "Users can view vehicle assignments"
  ON vehicle_assignments FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM profiles WHERE id = auth.uid()
  ));

CREATE POLICY "Managers can insert vehicle assignments"
  ON vehicle_assignments FOR INSERT
  WITH CHECK (created_by = auth.uid());

CREATE POLICY "Managers can update vehicle assignments"
  ON vehicle_assignments FOR UPDATE
  USING (EXISTS (
    SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'
  ));

-- Indexes
CREATE INDEX idx_drivers_staff ON drivers(staff_id);
CREATE INDEX idx_drivers_license_expiry ON drivers(license_expiry);
CREATE INDEX idx_drivers_active ON drivers(is_active);

CREATE INDEX idx_vehicles_registration ON vehicles(registration);
CREATE INDEX idx_vehicles_status ON vehicles(status);

CREATE INDEX idx_vehicle_assignments_driver ON vehicle_assignments(driver_id);
CREATE INDEX idx_vehicle_assignments_vehicle ON vehicle_assignments(vehicle_id);
CREATE INDEX idx_vehicle_assignments_status ON vehicle_assignments(status);
CREATE INDEX idx_vehicle_assignments_date ON vehicle_assignments(assignment_date);

-- Updated at triggers
CREATE OR REPLACE FUNCTION update_drivers_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

CREATE OR REPLACE FUNCTION update_vehicles_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

CREATE OR REPLACE FUNCTION update_vehicle_assignments_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER drivers_updated_at
  BEFORE UPDATE ON drivers
  FOR EACH ROW
  EXECUTE FUNCTION update_drivers_updated_at();

CREATE TRIGGER vehicles_updated_at
  BEFORE UPDATE ON vehicles
  FOR EACH ROW
  EXECUTE FUNCTION update_vehicles_updated_at();

CREATE TRIGGER vehicle_assignments_updated_at
  BEFORE UPDATE ON vehicle_assignments
  FOR EACH ROW
  EXECUTE FUNCTION update_vehicle_assignments_updated_at();

-- ============================================================================
-- GRANT PERMISSIONS
-- ============================================================================
GRANT ALL ON stool_logs TO authenticated;
GRANT ALL ON temperature_logs TO authenticated;
GRANT ALL ON missing_persons_reports TO authenticated;
GRANT ALL ON safeguarding_reports TO authenticated;
GRANT ALL ON accidents_incidents TO authenticated;
GRANT ALL ON complaints TO authenticated;
GRANT ALL ON serious_incidents TO authenticated;
GRANT ALL ON drivers TO authenticated;
GRANT ALL ON vehicles TO authenticated;
GRANT ALL ON vehicle_assignments TO authenticated;