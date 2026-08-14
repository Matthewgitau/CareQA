-- Fix shifts status check constraint to include all valid statuses

-- Drop the existing constraint
ALTER TABLE shifts DROP CONSTRAINT IF EXISTS shifts_status_check;

-- Add new constraint with all valid statuses
ALTER TABLE shifts ADD CONSTRAINT shifts_status_check 
  CHECK (status = ANY (ARRAY[
    'scheduled'::text,
    'pending'::text,
    'assigned'::text,
    'confirmed'::text,
    'in_progress'::text,
    'completed'::text,
    'cancelled'::text,
    'declined'::text
  ]));