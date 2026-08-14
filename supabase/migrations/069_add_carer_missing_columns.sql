-- Add missing columns to carers table
ALTER TABLE carers ADD COLUMN IF NOT EXISTS account_number TEXT;
ALTER TABLE carers ADD COLUMN IF NOT EXISTS sort_code TEXT;
ALTER TABLE carers ADD COLUMN IF NOT EXISTS employee_number TEXT;
ALTER TABLE carers ADD COLUMN IF NOT EXISTS photo_url TEXT;

-- Compliance document fields
ALTER TABLE carers ADD COLUMN IF NOT EXISTS dbs_number TEXT;
ALTER TABLE carers ADD COLUMN IF NOT EXISTS dbs_expiry DATE;
ALTER TABLE carers ADD COLUMN IF NOT EXISTS proof_of_id_url TEXT;
ALTER TABLE carers ADD COLUMN IF NOT EXISTS proof_of_id_expiry DATE;
ALTER TABLE carers ADD COLUMN IF NOT EXISTS proof_of_residence_url TEXT;
ALTER TABLE carers ADD COLUMN IF NOT EXISTS proof_of_residence_expiry DATE;
ALTER TABLE carers ADD COLUMN IF NOT EXISTS infection_control_url TEXT;
ALTER TABLE carers ADD COLUMN IF NOT EXISTS infection_control_expiry DATE;
ALTER TABLE carers ADD COLUMN IF NOT EXISTS manual_handling_url TEXT;
ALTER TABLE carers ADD COLUMN IF NOT EXISTS manual_handling_expiry DATE;
ALTER TABLE carers ADD COLUMN IF NOT EXISTS safeguarding_url TEXT;
ALTER TABLE carers ADD COLUMN IF NOT EXISTS safeguarding_expiry DATE;
ALTER TABLE carers ADD COLUMN IF NOT EXISTS fitness_to_work_expiry DATE;

-- Add index on employee_number for faster lookups
CREATE INDEX IF NOT EXISTS idx_carers_employee_number ON carers(employee_number);