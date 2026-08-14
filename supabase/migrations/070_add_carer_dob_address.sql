-- Add Date of Birth and Address columns to carers table
ALTER TABLE carers ADD COLUMN IF NOT EXISTS date_of_birth DATE;
ALTER TABLE carers ADD COLUMN IF NOT EXISTS address TEXT;