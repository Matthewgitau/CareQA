-- Medications prescribed to service user
CREATE TABLE IF NOT EXISTS mar_medications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  service_user_id UUID REFERENCES service_users(id) ON DELETE CASCADE,
  medication_name TEXT NOT NULL,
  dosage TEXT NOT NULL,
  route TEXT NOT NULL,
  frequency TEXT NOT NULL,
  times TEXT[] NOT NULL, -- e.g., ['08:00', '13:00', '18:00', '22:00']
  prescribed_by TEXT,
  start_date DATE NOT NULL,
  end_date DATE,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Record when medication was actually given
CREATE TABLE IF NOT EXISTS mar_administrations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  medication_id UUID REFERENCES mar_medications(id) ON DELETE CASCADE,
  scheduled_time TIME NOT NULL,
  administered_date DATE NOT NULL,
  administered_time TIME,
  administered_by UUID REFERENCES profiles(id),
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'given', 'missed', 'refused', 'withheld')),
  refusal_reason TEXT,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE mar_medications ENABLE ROW LEVEL SECURITY;
ALTER TABLE mar_administrations ENABLE ROW LEVEL SECURITY;

-- Policies for mar_medications
CREATE POLICY "Authenticated users can view medications" ON mar_medications
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Authenticated users can insert medications" ON mar_medications
  FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "Authenticated users can update medications" ON mar_medications
  FOR UPDATE TO authenticated USING (true);

CREATE POLICY "Authenticated users can delete medications" ON mar_medications
  FOR DELETE TO authenticated USING (true);

-- Policies for mar_administrations
CREATE POLICY "Authenticated users can view administrations" ON mar_administrations
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Authenticated users can insert administrations" ON mar_administrations
  FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "Authenticated users can update administrations" ON mar_administrations
  FOR UPDATE TO authenticated USING (true);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_mar_medications_service_user ON mar_medications(service_user_id);
CREATE INDEX IF NOT EXISTS idx_mar_medications_active ON mar_medications(is_active);
CREATE INDEX IF NOT EXISTS idx_mar_administrations_medication ON mar_administrations(medication_id);
CREATE INDEX IF NOT EXISTS idx_mar_administrations_date ON mar_administrations(administered_date);
CREATE INDEX IF NOT EXISTS idx_mar_administrations_status ON mar_administrations(status);