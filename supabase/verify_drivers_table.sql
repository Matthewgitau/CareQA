-- STEP 1: Check if drivers table exists
SELECT EXISTS (
  SELECT FROM information_schema.tables 
  WHERE table_schema = 'public' 
  AND table_name = 'drivers'
) AS drivers_table_exists;

-- STEP 2: If exists, show its structure
SELECT 
  column_name, 
  data_type, 
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'drivers'
ORDER BY ordinal_position;

-- STEP 3: Check if table has any data
SELECT COUNT(*) AS driver_count FROM drivers;

-- STEP 4: Show sample data if exists
SELECT 
  id, 
  staff_name, 
  employee_id, 
  job_role, 
  license_number, 
  license_expiry, 
  is_exclusive_driver, 
  is_active, 
  created_at
FROM drivers
ORDER BY created_at DESC
LIMIT 5;

-- STEP 5: If table doesn't exist, uncomment and run this to create it:
-- CREATE TABLE drivers (
--   id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
--   carer_id UUID REFERENCES carers(id) ON DELETE SET NULL,
--   is_exclusive_driver BOOLEAN DEFAULT FALSE,
--   staff_name TEXT NOT NULL,
--   employee_id TEXT,
--   job_role TEXT,
--   contact_phone TEXT,
--   date_of_birth DATE,
--   license_number TEXT,
--   license_expiry DATE,
--   license_categories TEXT,
--   license_issue_date DATE,
--   license_checked BOOLEAN DEFAULT FALSE,
--   has_endorsements BOOLEAN DEFAULT FALSE,
--   endorsement_details TEXT,
--   license_copy_url TEXT,
--   is_active BOOLEAN DEFAULT TRUE,
--   created_at TIMESTAMP DEFAULT NOW()
-- );

-- STEP 6: If table exists but has no data, uncomment to add a test driver:
-- INSERT INTO drivers (staff_name, employee_id, job_role, contact_phone, is_active, created_at) 
-- VALUES ('Test Driver', 'EMP001', 'Senior Carer', '07123 456789', true, NOW());