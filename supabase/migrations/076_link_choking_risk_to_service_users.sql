-- Add service_user_id column to choking_risk_assessments
ALTER TABLE choking_risk_assessments 
ADD COLUMN IF NOT EXISTS service_user_id UUID REFERENCES service_users(id) ON DELETE CASCADE;

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_choking_risk_service_user 
ON choking_risk_assessments(service_user_id);