-- Add timesheet-specific fields to visits table
-- Each visit = 1 timesheet per carer per shift

ALTER TABLE visits ADD COLUMN IF NOT EXISTS break_taken INTEGER DEFAULT 0; -- minutes
ALTER TABLE visits ADD COLUMN IF NOT EXISTS total_hours_paid NUMERIC(5,2); -- paid hours
ALTER TABLE visits ADD COLUMN IF NOT EXISTS punctuality TEXT DEFAULT 'on_time' CHECK (punctuality IN ('on_time', 'late', 'early'));
ALTER TABLE visits ADD COLUMN IF NOT EXISTS staff_rating INTEGER CHECK (staff_rating >= 1 AND staff_rating <= 5);
ALTER TABLE visits ADD COLUMN IF NOT EXISTS signed BOOLEAN DEFAULT FALSE;
ALTER TABLE visits ADD COLUMN IF NOT EXISTS signed_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE visits ADD COLUMN IF NOT EXISTS signed_by UUID;

-- Add index for faster timesheet queries
CREATE INDEX IF NOT EXISTS idx_visits_shift_carer ON visits(shift_id, carer_id);