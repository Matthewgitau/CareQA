-- Create drivers table
CREATE TABLE IF NOT EXISTS drivers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  carer_id UUID REFERENCES carers(id) ON DELETE SET NULL,
  is_exclusive_driver BOOLEAN DEFAULT FALSE,
  staff_name TEXT NOT NULL,
  employee_id TEXT,
  job_role TEXT,
  contact_phone TEXT,
  date_of_birth DATE,
  license_number TEXT,
  license_expiry DATE,
  license_categories TEXT,
  license_issue_date DATE,
  license_checked BOOLEAN DEFAULT FALSE,
  has_endorsements BOOLEAN DEFAULT FALSE,
  endorsement_details TEXT,
  license_copy_url TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  organisation_id UUID REFERENCES organisations(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE drivers ENABLE ROW LEVEL SECURITY;

-- Create RLS policy
DROP POLICY IF EXISTS "Users can view their organisation's drivers" ON drivers;
CREATE POLICY "Users can view their organisation's drivers"
  ON drivers FOR SELECT
  USING (organisation_id = (SELECT organisation_id FROM profiles WHERE id = auth.uid()));

-- Allow insert for authenticated users
DROP POLICY IF EXISTS "Users can insert drivers" ON drivers;
CREATE POLICY "Users can insert drivers"
  ON drivers FOR INSERT
  WITH CHECK (organisation_id = (SELECT organisation_id FROM profiles WHERE id = auth.uid()));

-- Add indexes
CREATE INDEX IF NOT EXISTS idx_drivers_organisation ON drivers(organisation_id);
CREATE INDEX IF NOT EXISTS idx_drivers_carer ON drivers(carer_id);

-- Verify table exists
SELECT COUNT(*) FROM drivers;