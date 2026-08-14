-- Add mobility test, grip strength, and risk trigger columns to falls_risk_assessments
ALTER TABLE falls_risk_assessments 
ADD COLUMN IF NOT EXISTS mobility_test_completed BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS mobility_test_date DATE,
ADD COLUMN IF NOT EXISTS mobility_changed BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS grip_strength_kg NUMERIC(5,2),
ADD COLUMN IF NOT EXISTS grip_strength_risk TEXT,
ADD COLUMN IF NOT EXISTS mobility_risk_triggered BOOLEAN DEFAULT FALSE;