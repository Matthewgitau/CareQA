-- Add compliance fields to appraisals table
ALTER TABLE appraisals
ADD COLUMN IF NOT EXISTS employee_signature TEXT,
ADD COLUMN IF NOT EXISTS employee_signature_date DATE,
ADD COLUMN IF NOT EXISTS reviewer_signature TEXT,
ADD COLUMN IF NOT EXISTS reviewer_signature_date DATE,
ADD COLUMN IF NOT EXISTS witness_name TEXT,
ADD COLUMN IF NOT EXISTS witness_signature TEXT,
ADD COLUMN IF NOT EXISTS authorised_by TEXT,
ADD COLUMN IF NOT EXISTS authorised_date DATE,
ADD COLUMN IF NOT EXISTS completed_date DATE;