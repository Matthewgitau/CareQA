-- ============================================================
-- 159_fix_carer_double_booking_trigger.sql
--
-- The check_carer_double_booking() trigger introduced in migration
-- 123 had a bug: it compared a UUID column (carer_id) to an empty
-- string.  Postgres raises
--   22P02: invalid input syntax for type uuid: ""
-- whenever that comparison runs, which means EVERY UPDATE of a row
-- in the public.shifts table blows up — including cascade UPDATEs
-- caused by DELETE on organisations (which sets shifts.organisation_id
-- to NULL).  This blocks legitimate cleanups and any other write
-- that touches shifts.
--
-- The fix is the obvious one: drop the dead `!= ''` clause.  A
-- uuid column is either a uuid or NULL, never ''.
-- ============================================================

CREATE OR REPLACE FUNCTION check_carer_double_booking()
RETURNS TRIGGER AS $$
DECLARE
  conflicting_shift RECORD;
BEGIN
  -- Only check if carer_id is being set and it's not null.
  -- (Was: AND NEW.carer_id != '' — invalid for uuid columns.)
  IF NEW.carer_id IS NOT NULL THEN
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

-- The trigger definition itself is unchanged.
DROP TRIGGER IF EXISTS check_carer_double_booking_trigger ON shifts;
CREATE TRIGGER check_carer_double_booking_trigger
  BEFORE INSERT OR UPDATE ON shifts
  FOR EACH ROW
  EXECUTE FUNCTION check_carer_double_booking();
