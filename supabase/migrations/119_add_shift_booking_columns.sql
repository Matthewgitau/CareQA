-- Add missing columns to shifts table needed by the booking flow
-- These columns are used by client-app createShift() and broadcast methods

ALTER TABLE shifts ADD COLUMN IF NOT EXISTS client_organisation_id UUID REFERENCES organisations(id) ON DELETE CASCADE;
ALTER TABLE shifts ADD COLUMN IF NOT EXISTS location TEXT;
ALTER TABLE shifts ADD COLUMN IF NOT EXISTS staff_required INTEGER DEFAULT 1;
ALTER TABLE shifts ADD COLUMN IF NOT EXISTS staff_type TEXT DEFAULT 'carer';
ALTER TABLE shifts ADD COLUMN IF NOT EXISTS notes TEXT;
ALTER TABLE shifts ADD COLUMN IF NOT EXISTS shift_type TEXT DEFAULT 'care';
ALTER TABLE shifts ADD COLUMN IF NOT EXISTS recurring BOOLEAN DEFAULT FALSE;
ALTER TABLE shifts ADD COLUMN IF NOT EXISTS recurring_pattern JSONB;
ALTER TABLE shifts ADD COLUMN IF NOT EXISTS created_by UUID;
ALTER TABLE shifts ADD COLUMN IF NOT EXISTS rate DECIMAL(10,2);
ALTER TABLE shifts ADD COLUMN IF NOT EXISTS broadcast_agency_ids JSONB DEFAULT '[]'::jsonb;

-- Add index for faster shift queries by client organisation
CREATE INDEX IF NOT EXISTS idx_shifts_client_organisation_id ON shifts(client_organisation_id);
CREATE INDEX IF NOT EXISTS idx_shifts_scheduled_date ON shifts(scheduled_date);

-- Add check constraint for status values if not already present
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'shifts_status_check'
  ) THEN
    ALTER TABLE shifts ADD CONSTRAINT shifts_status_check
      CHECK (status IN ('scheduled', 'in_progress', 'completed', 'cancelled', 'confirmed'));
  END IF;
END $$;