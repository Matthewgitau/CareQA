-- Training Courses table
CREATE TABLE IF NOT EXISTS training_courses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  description TEXT,
  is_mandatory BOOLEAN DEFAULT TRUE,
  default_renewal_interval_months INTEGER DEFAULT 12,
  category TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  organisation_id UUID REFERENCES organisations(id),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Allow NULL organisation_id for global courses
ALTER TABLE training_courses ALTER COLUMN organisation_id DROP NOT NULL;

-- Carer Training Records table
CREATE TABLE IF NOT EXISTS carer_training_records (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  carer_id UUID REFERENCES carers(id) ON DELETE CASCADE,
  training_course_id UUID REFERENCES training_courses(id) ON DELETE CASCADE,
  completed_date DATE NOT NULL,
  expiry_date DATE,
  certificate_url TEXT,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'expired', 'revoked')),
  notes TEXT,
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  organisation_id UUID REFERENCES organisations(id)
);

-- Carer Training History (audit log)
CREATE TABLE IF NOT EXISTS carer_training_history (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  training_record_id UUID REFERENCES carer_training_records(id) ON DELETE CASCADE,
  action TEXT NOT NULL,
  previous_data JSONB,
  new_data JSONB,
  changed_by UUID REFERENCES profiles(id),
  changed_at TIMESTAMP DEFAULT NOW(),
  organisation_id UUID REFERENCES organisations(id)
);

-- Enable RLS
ALTER TABLE training_courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE carer_training_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE carer_training_history ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- Training courses: allow access if organisation_id matches OR is NULL (global courses)
CREATE POLICY tenant_isolation_training_courses ON training_courses
  FOR ALL USING (organisation_id IS NULL OR organisation_id = get_organisation_id());

CREATE POLICY tenant_isolation_carer_training_records ON carer_training_records
  FOR ALL USING (organisation_id = get_organisation_id());

CREATE POLICY tenant_isolation_carer_training_history ON carer_training_history
  FOR ALL USING (organisation_id = get_organisation_id());

-- Indexes
CREATE INDEX idx_training_courses_org ON training_courses(organisation_id);
CREATE INDEX idx_carer_training_records_carer ON carer_training_records(carer_id);
CREATE INDEX idx_carer_training_records_course ON carer_training_records(training_course_id);
CREATE INDEX idx_carer_training_history_record ON carer_training_history(training_record_id);