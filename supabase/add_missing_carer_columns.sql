-- Add missing columns to carers table for driver linking
ALTER TABLE carers ADD COLUMN IF NOT EXISTS job_role TEXT;
ALTER TABLE carers ADD COLUMN IF NOT EXISTS employee_number TEXT;
ALTER TABLE carers ADD COLUMN IF NOT EXISTS phone TEXT;

-- Verify columns were added
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'carers' 
  AND column_name IN ('job_role', 'employee_number', 'phone');