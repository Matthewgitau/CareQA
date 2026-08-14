-- Prevent double booking of carers on the same day
-- This creates a function and trigger to check for time overlaps

-- Create a function to check for carer double bookings
CREATE OR REPLACE FUNCTION check_carer_double_booking()
RETURNS TRIGGER AS $$
DECLARE
  conflicting_shift RECORD;
BEGIN
  -- Only check if carer_id is being set and it's not null
  IF NEW.carer_id IS NOT NULL AND NEW.carer_id != '' THEN
    -- Check for overlapping shifts on the same day
    SELECT * INTO conflicting_shift FROM shifts
    WHERE carer_id = NEW.carer_id
      AND scheduled_date = NEW.scheduled_date
      AND id != NEW.id
      AND status NOT IN ('cancelled', 'declined')
      AND (
        -- New shift starts during existing shift
        (NEW.start_time >= start_time AND NEW.start_time < end_time)
        OR
        -- New shift ends during existing shift
        (NEW.end_time > start_time AND NEW.end_time <= end_time)
        OR
        -- New shift completely covers existing shift
        (NEW.start_time <= start_time AND NEW.end_time >= end_time)
      )
    LIMIT 1;

    IF FOUND THEN
      RAISE EXCEPTION 'carer_double_booking: Carer % is already booked on % from % to % (shift %: %)',
        NEW.carer_id,
        NEW.scheduled_date,
        conflicting_shift.start_time,
        conflicting_shift.end_time,
        conflicting_shift.id,
        conflicting_shift.location;
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to check for double bookings
DROP TRIGGER IF EXISTS check_carer_double_booking_trigger ON shifts;
CREATE TRIGGER check_carer_double_booking_trigger
  BEFORE INSERT OR UPDATE ON shifts
  FOR EACH ROW
  EXECUTE FUNCTION check_carer_double_booking();