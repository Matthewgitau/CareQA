-- Add missing columns to service_users
ALTER TABLE service_users 
ADD COLUMN IF NOT EXISTS email TEXT,
ADD COLUMN IF NOT EXISTS phone TEXT,
ADD COLUMN IF NOT EXISTS job_role TEXT,
ADD COLUMN IF NOT EXISTS employee_number TEXT,
ADD COLUMN IF NOT EXISTS is_carer BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS employment_type TEXT,
ADD COLUMN IF NOT EXISTS dbs_number TEXT,
ADD COLUMN IF NOT EXISTS dbs_expiry_date DATE;

-- Add RLS policy for service_users (allow all authenticated)
DROP POLICY IF EXISTS "Authenticated users can view service_users" ON service_users;
CREATE POLICY "Authenticated users can view service_users" ON service_users
  FOR SELECT USING (auth.role() = 'authenticated');