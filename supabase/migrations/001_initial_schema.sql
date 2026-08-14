-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Profiles table (extends Supabase Auth)
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id),
  email TEXT NOT NULL,
  full_name TEXT,
  role TEXT NOT NULL CHECK (role IN ('admin', 'carer')),
  phone TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Carers table (extends profiles)
CREATE TABLE carers (
  id UUID PRIMARY KEY REFERENCES profiles(id),
  employee_number TEXT UNIQUE,
  dbs_number TEXT,
  dbs_expiry_date DATE,
  dbs_certificate_url TEXT,
  id_document_url TEXT,
  id_expiry_date DATE,
  right_to_work_expiry DATE,
  training_records JSONB,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Service Users
CREATE TABLE service_users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  address TEXT,
  notes TEXT,
  emergency_contact_name TEXT,
  emergency_contact_phone TEXT,
  emergency_contact_relation TEXT,
  care_plan JSONB DEFAULT '{
    "medications": [],
    "allergies": [],
    "mobility": "",
    "dietary": [],
    "personal_care": []
  }',
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Shifts
CREATE TABLE shifts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  service_user_id UUID REFERENCES service_users(id) ON DELETE CASCADE,
  carer_id UUID REFERENCES carers(id) ON DELETE SET NULL,
  scheduled_date DATE NOT NULL,
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  status TEXT DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'in_progress', 'completed', 'cancelled')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Visits
CREATE TABLE visits (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  shift_id UUID REFERENCES shifts(id) ON DELETE CASCADE,
  carer_id UUID REFERENCES carers(id) ON DELETE SET NULL,
  check_in_time TIMESTAMP WITH TIME ZONE,
  check_out_time TIMESTAMP WITH TIME ZONE,
  duration_minutes INTEGER,
  notes TEXT,
  flagged BOOLEAN DEFAULT FALSE,
  flag_reason TEXT,
  compliance_percentage NUMERIC(5,2),
  structured_notes JSONB DEFAULT '{
    "mood_score": null,
    "medication_given": false,
    "family_present": false,
    "incident_occurred": false,
    "incident_type": null
  }',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Documents (for compliance)
CREATE TABLE documents (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  carer_id UUID REFERENCES carers(id) ON DELETE CASCADE,
  document_type TEXT NOT NULL CHECK (document_type IN ('dbs', 'id', 'training', 'right_to_work')),
  file_url TEXT NOT NULL,
  expiry_date DATE NOT NULL,
  verified BOOLEAN DEFAULT FALSE,
  verified_by UUID REFERENCES profiles(id),
  verified_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Notifications
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  type TEXT NOT NULL,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  data JSONB,
  read BOOLEAN DEFAULT FALSE,
  read_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Settings (configurable rules)
CREATE TABLE settings (
  id INTEGER PRIMARY KEY DEFAULT 1,
  dbs_warning_days INTEGER DEFAULT 30,
  min_visit_percentage INTEGER DEFAULT 85,
  require_documents_before_shift BOOLEAN DEFAULT TRUE,
  auto_flag_short_visits BOOLEAN DEFAULT TRUE,
  notification_before_expiry_days INTEGER DEFAULT 30,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_by UUID REFERENCES profiles(id),
  CONSTRAINT single_row CHECK (id = 1)
);

-- Enable Row Level Security
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE carers ENABLE ROW LEVEL SECURITY;
ALTER TABLE service_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE shifts ENABLE ROW LEVEL SECURITY;
ALTER TABLE visits ENABLE ROW LEVEL SECURITY;
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Create RLS Policies
CREATE POLICY "Users can view own profile"
  ON profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id);

CREATE POLICY "Admins can view all carers"
  ON carers FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM profiles 
    WHERE id = auth.uid() AND role = 'admin'
  ));

CREATE POLICY "Carers can view own profile"
  ON carers FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Admins can manage all carers"
  ON carers FOR ALL
  USING (EXISTS (
    SELECT 1 FROM profiles 
    WHERE id = auth.uid() AND role = 'admin'
  ));

CREATE POLICY "Admins can view all service users"
  ON service_users FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM profiles 
    WHERE id = auth.uid() AND role = 'admin'
  ));

CREATE POLICY "Admins can manage service users"
  ON service_users FOR ALL
  USING (EXISTS (
    SELECT 1 FROM profiles 
    WHERE id = auth.uid() AND role = 'admin'
  ));

CREATE POLICY "Carers can view assigned shifts"
  ON shifts FOR SELECT
  USING (carer_id = auth.uid() OR auth.uid() IN (
    SELECT id FROM profiles WHERE role = 'admin'
  ));

CREATE POLICY "Admins can manage all shifts"
  ON shifts FOR ALL
  USING (EXISTS (
    SELECT 1 FROM profiles 
    WHERE id = auth.uid() AND role = 'admin'
  ));

CREATE POLICY "Carers can view own visits"
  ON visits FOR SELECT
  USING (carer_id = auth.uid() OR auth.uid() IN (
    SELECT id FROM profiles WHERE role = 'admin'
  ));

CREATE POLICY "Carers can create visits for own shifts"
  ON visits FOR INSERT
  WITH CHECK (carer_id = auth.uid() OR auth.uid() IN (
    SELECT id FROM profiles WHERE role = 'admin'
  ));

CREATE POLICY "Carers can update own visits"
  ON visits FOR UPDATE
  USING (carer_id = auth.uid() OR auth.uid() IN (
    SELECT id FROM profiles WHERE role = 'admin'
  ));

CREATE POLICY "Carers can view own documents"
  ON documents FOR SELECT
  USING (carer_id = auth.uid() OR auth.uid() IN (
    SELECT id FROM profiles WHERE role = 'admin'
  ));

CREATE POLICY "Carers can manage own documents"
  ON documents FOR ALL
  USING (carer_id = auth.uid() OR auth.uid() IN (
    SELECT id FROM profiles WHERE role = 'admin'
  ));

CREATE POLICY "Users can view own notifications"
  ON notifications FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Users can update own notifications"
  ON notifications FOR UPDATE
  USING (user_id = auth.uid());

CREATE POLICY "Admins can manage all notifications"
  ON notifications FOR ALL
  USING (EXISTS (
    SELECT 1 FROM profiles 
    WHERE id = auth.uid() AND role = 'admin'
  ));

-- Create indexes for performance
CREATE INDEX idx_shifts_carer_date ON shifts(carer_id, scheduled_date);
CREATE INDEX idx_visits_carer ON visits(carer_id);
CREATE INDEX idx_documents_expiry ON documents(expiry_date) WHERE verified = false;
CREATE INDEX idx_notifications_user_read ON notifications(user_id, read);
CREATE INDEX idx_visits_shift_id ON visits(shift_id);
CREATE INDEX idx_carers_active ON carers(is_active);
CREATE INDEX idx_service_users_active ON service_users(is_active);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_carers_updated_at BEFORE UPDATE ON carers FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_service_users_updated_at BEFORE UPDATE ON service_users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_shifts_updated_at BEFORE UPDATE ON shifts FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_visits_updated_at BEFORE UPDATE ON visits FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_documents_updated_at BEFORE UPDATE ON documents FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_settings_updated_at BEFORE UPDATE ON settings FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger function to compute compliance_percentage
CREATE OR REPLACE FUNCTION compute_visit_compliance()
RETURNS TRIGGER AS $$
DECLARE
  shift_start TIME;
  shift_end   TIME;
  shift_duration_minutes NUMERIC;
BEGIN
  IF NEW.check_in_time IS NULL
     OR NEW.check_out_time IS NULL
     OR NEW.shift_id IS NULL THEN
    NEW.compliance_percentage := NULL;
    RETURN NEW;
  END IF;

  SELECT start_time, end_time
    INTO shift_start, shift_end
    FROM shifts
   WHERE id = NEW.shift_id;

  IF shift_start IS NULL OR shift_end IS NULL THEN
    NEW.compliance_percentage := NULL;
    RETURN NEW;
  END IF;

  shift_duration_minutes :=
    EXTRACT(EPOCH FROM (shift_end - shift_start)) / 60.0;

  IF shift_duration_minutes <= 0 THEN
    NEW.compliance_percentage := NULL;
    RETURN NEW;
  END IF;

  IF NEW.duration_minutes IS NULL AND
     NEW.check_in_time IS NOT NULL AND
     NEW.check_out_time IS NOT NULL THEN
    NEW.duration_minutes :=
      EXTRACT(EPOCH FROM (NEW.check_out_time - NEW.check_in_time)) / 60.0;
  END IF;

  IF NEW.duration_minutes IS NULL THEN
    NEW.compliance_percentage := NULL;
  ELSE
    NEW.compliance_percentage :=
      ROUND((NEW.duration_minutes * 100.0) / shift_duration_minutes, 2);
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS visits_compute_compliance ON visits;
CREATE TRIGGER visits_compute_compliance
  BEFORE INSERT OR UPDATE ON visits
  FOR EACH ROW
  EXECUTE FUNCTION compute_visit_compliance();

-- Insert default settings
INSERT INTO settings (id) VALUES (1);
