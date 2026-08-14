-- Add timesheet workflow fields to visits table
-- For tracking: voided shifts, disputes, late details, and signed-off status

-- Add voided flag for no-show shifts
ALTER TABLE visits ADD COLUMN IF NOT EXISTS voided BOOLEAN DEFAULT FALSE;
ALTER TABLE visits ADD COLUMN IF NOT EXISTS voided_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE visits ADD COLUMN IF NOT EXISTS voided_reason TEXT;

-- Add dispute tracking
ALTER TABLE visits ADD COLUMN IF NOT EXISTS disputed BOOLEAN DEFAULT FALSE;
ALTER TABLE visits ADD COLUMN IF NOT EXISTS dispute_reason TEXT;
ALTER TABLE visits ADD COLUMN IF NOT EXISTS disputed_at TIMESTAMP WITH TIME ZONE;

-- Add late minutes detail (rounding to nearest minute)
ALTER TABLE visits ADD COLUMN IF NOT EXISTS late_minutes INTEGER DEFAULT 0;

-- Add sign-off completion status
ALTER TABLE visits ADD COLUMN IF NOT EXISTS sign_off_status TEXT DEFAULT 'pending'
  CHECK (sign_off_status IN ('pending', 'signed', 'voided', 'disputed'));

-- Add arrival status
ALTER TABLE visits ADD COLUMN IF NOT EXISTS arrival_status TEXT DEFAULT 'not_arrived'
  CHECK (arrival_status IN ('not_arrived', 'on_time', 'late'));

-- Index for grouping timesheets by status
CREATE INDEX IF NOT EXISTS idx_visits_sign_off_status ON visits(sign_off_status);