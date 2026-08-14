-- Staff Competency Records table
-- Stores competency assessments for staff members across all competency types

CREATE TABLE staff_competency_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  staff_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  staff_name TEXT,
  competency_type TEXT NOT NULL CHECK (competency_type IN (
    'medication',
    'manual_handling',
    'catheter_care',
    'spot_check',
    'pressure_prevention',
    'infection_control',
    'fire_safety',
    'first_aid',
    'moving_handling',
    'safeguarding',
    'dignity_respect',
    'communication'
  )),
  completed_date DATE NOT NULL,
  expiry_date DATE,
  status TEXT NOT NULL DEFAULT 'valid' CHECK (status IN ('valid', 'expiring', 'expired')),
  outcome TEXT NOT NULL DEFAULT 'pass' CHECK (outcome IN ('pass', 'fail', 'requires_training')),
  assessor_id UUID REFERENCES profiles(id),
  assessor_name TEXT,
  answers JSONB DEFAULT '{}',
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE staff_competency_records ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view competency records"
  ON staff_competency_records FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE id = auth.uid() 
      AND role IN ('admin', 'carer', 'manager')
    )
  );

CREATE POLICY "Users can insert competency records"
  ON staff_competency_records FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE id = auth.uid() 
      AND role IN ('admin', 'manager')
    )
  );

CREATE POLICY "Users can update competency records"
  ON staff_competency_records FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE id = auth.uid() 
      AND role IN ('admin', 'manager')
    )
  );

CREATE POLICY "Users can delete competency records"
  ON staff_competency_records FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE id = auth.uid() 
      AND role = 'admin'
    )
  );

-- Indexes for performance
CREATE INDEX idx_staff_competency_records_staff_id ON staff_competency_records(staff_id);
CREATE INDEX idx_staff_competency_records_competency_type ON staff_competency_records(competency_type);
CREATE INDEX idx_staff_competency_records_status ON staff_competency_records(status);
CREATE INDEX idx_staff_competency_records_expiry_date ON staff_competency_records(expiry_date);
CREATE INDEX idx_staff_competency_records_completed_date ON staff_competency_records(completed_date);

-- Updated at trigger
CREATE OR REPLACE FUNCTION update_staff_competency_records_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS staff_competency_records_updated_at ON staff_competency_records;
CREATE TRIGGER staff_competency_records_updated_at
  BEFORE UPDATE ON staff_competency_records
  FOR EACH ROW
  EXECUTE FUNCTION update_staff_competency_records_updated_at();

-- Function to update expired competencies
CREATE OR REPLACE FUNCTION update_expired_competencies(current_date DATE DEFAULT CURRENT_DATE)
RETURNS VOID AS $$
BEGIN
  UPDATE staff_competency_records
  SET status = 'expired'
  WHERE expiry_date IS NOT NULL
    AND expiry_date < current_date
    AND status != 'expired';
END;
$$ LANGUAGE plpgsql;

-- Function to update expiring competencies (within 30 days)
CREATE OR REPLACE FUNCTION update_expiring_competencies(
  current_date DATE DEFAULT CURRENT_DATE,
  threshold_date DATE DEFAULT CURRENT_DATE + INTERVAL '30 days'
)
RETURNS VOID AS $$
BEGIN
  UPDATE staff_competency_records
  SET status = 'expiring'
  WHERE expiry_date IS NOT NULL
    AND expiry_date >= current_date
    AND expiry_date <= threshold_date
    AND status = 'valid';
END;
$$ LANGUAGE plpgsql;

-- Grant permissions
GRANT ALL ON staff_competency_records TO authenticated;