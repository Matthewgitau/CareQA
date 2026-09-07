-- ============================================================
-- MIGRATION 155: Unified notification system
--
-- Purpose: wire every event source (safeguarding, risk, MAR, shifts,
-- routes, payroll, invoices, care logs, new staff/service users) to
-- the existing `notifications` table so the admin-app notification
-- hub can display them.
--
-- Design:
--   - NO new tables.
--   - NO destructive ALTER on existing tables.
--   - Defines/replaces two PL/pgSQL functions only:
--       * public.notify_admins(...)
--           Used by the pre-existing 003 triggers (risk_assessments,
--           safeguarding_incidents, policies). Migration 003 referenced
--           this function but never created it, so those triggers have
--           been dead. CREATE OR REPLACE here revives them.
--       * public.check_missed_mar_doses(...)
--           Sweep function that the Dart poller calls. It does NOT
--           insert notifications itself - it returns a table of missed
--           doses. The Dart layer dedupes and writes the notification
--           rows (so this stays inside the existing notifications
--           table and respects its RLS / schema).
--
-- Re-runnability: this migration was originally applied to production
-- with an earlier return shape for check_missed_mar_doses. PostgreSQL
-- refuses to CREATE OR REPLACE a function whose OUT signature has
-- changed, so we explicitly DROP the old overload first (no-op if it
-- doesn't exist). notify_admins() is signature-compatible so it uses
-- CREATE OR REPLACE.
-- ============================================================

-- Drop any prior overloads of check_missed_mar_doses so the new
-- definition below is always applied. We drop both common arities to
-- be safe in case multiple versions exist in production.
DROP FUNCTION IF EXISTS public.check_missed_mar_doses(DATE, DATE);
DROP FUNCTION IF EXISTS public.check_missed_mar_doses();
DROP FUNCTION IF EXISTS public.check_missed_mar_doses(DATE);

-- ============================================================
-- 1. notify_admins(...)
--    Revives migration 003's dead triggers.
-- ============================================================
CREATE OR REPLACE FUNCTION public.notify_admins(
  p_category     TEXT,
  p_priority     TEXT,
  p_title        TEXT,
  p_message      TEXT,
  p_action_url   TEXT DEFAULT NULL,
  p_related_id   UUID DEFAULT NULL,
  p_metadata     JSONB DEFAULT NULL
) RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_admin RECORD;
BEGIN
  FOR v_admin IN
    SELECT id
    FROM public.profiles
    WHERE role IN ('admin', 'super_admin', 'manager')
  LOOP
    INSERT INTO public.notifications (
      user_id,
      category,
      priority,
      title,
      message,
      action_url,
      related_id,
      metadata,
      read_at
    ) VALUES (
      v_admin.id,
      LOWER(p_category),
      LOWER(p_priority),
      p_title,
      p_message,
      p_action_url,
      p_related_id,
      p_metadata,
      NULL
    )
    ON CONFLICT DO NOTHING;
  END LOOP;
END;
$$;

GRANT EXECUTE ON FUNCTION public.notify_admins(TEXT, TEXT, TEXT, TEXT, TEXT, UUID, JSONB) TO authenticated;
GRANT EXECUTE ON FUNCTION public.notify_admins(TEXT, TEXT, TEXT, TEXT, TEXT, UUID, JSONB) TO service_role;

-- ============================================================
-- 2. check_missed_mar_doses(...)
--    Returns one row per expected-but-undocumented administration.
--    Caller (Dart) is responsible for writing notification rows.
-- ============================================================
CREATE OR REPLACE FUNCTION public.check_missed_mar_doses(
  p_from_date DATE DEFAULT (CURRENT_DATE - INTERVAL '7 days')::DATE,
  p_to_date   DATE DEFAULT CURRENT_DATE
) RETURNS TABLE (
  medication_id       UUID,
  service_user_id     UUID,
  service_user_name   TEXT,
  administration_date DATE,
  scheduled_time      TIME,
  medication_name     TEXT,
  dosage              TEXT,
  frequency           TEXT,
  expected_count      INT,
  logged_count        INT,
  is_prn              BOOLEAN,
  service_user_away   BOOLEAN
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_now TIMESTAMPTZ := NOW();
BEGIN
  RETURN QUERY
  WITH date_series AS (
    SELECT d::DATE AS admin_date
    FROM generate_series(p_from_date, p_to_date, INTERVAL '1 day') d
  ),
  med_schedule AS (
    SELECT
      mm.id                AS medication_id,
      mm.service_user_id   AS service_user_id,
      mm.service_user_name AS service_user_name,
      mm.medication_name   AS medication_name,
      mm.dosage            AS dosage,
      mm.frequency         AS frequency,
      mm.frequency_times   AS frequency_times,
      mm.days_of_week      AS days_of_week,
      mm.is_prn            AS is_prn,
      mm.start_date        AS start_date,
      mm.end_date          AS end_date,
      mm.stopped_date      AS stopped_date,
      mm.is_active         AS is_active
    FROM public.mar_medications mm
    WHERE mm.is_active = TRUE
      AND mm.deleted_at IS NULL
      AND COALESCE(mm.is_prn, FALSE) = FALSE   -- PRN is "as needed", skip
      AND mm.stopped_date IS NULL              -- only currently prescribed courses
  ),
  expanded AS (
    -- one row per (medication, date, scheduled-time)
    SELECT
      ms.medication_id, ms.service_user_id, ms.service_user_name,
      ms.medication_name, ms.dosage, ms.frequency, ms.is_prn,
      ds.admin_date AS administration_date,
      slot.slot_time::TIME AS scheduled_time
    FROM med_schedule ms
    CROSS JOIN date_series ds
    CROSS JOIN LATERAL unnest(COALESCE(ms.frequency_times, ARRAY['08:00']::TEXT[]))
      AS slot(slot_time)
    WHERE ds.admin_date >= ms.start_date
      AND (ms.end_date IS NULL OR ds.admin_date <= ms.end_date)
      AND (
        ms.days_of_week IS NULL
        OR EXTRACT(DOW FROM ds.admin_date)::INT = ANY(ms.days_of_week)
      )
  ),
  away_days AS (
    -- days the service user was officially away (respite/hospital/holiday)
    SELECT s.service_user_id,
           gs::DATE AS away_day
    FROM public.service_user_statuses s
    CROSS JOIN LATERAL generate_series(
      GREATEST((s.started_at AT TIME ZONE 'UTC')::DATE, p_from_date),
      LEAST(COALESCE((s.ended_at AT TIME ZONE 'UTC')::DATE, p_to_date), p_to_date),
      INTERVAL '1 day'
    ) gs
    WHERE s.status_type IN ('respite', 'hospital', 'holiday')
      AND (
        s.ended_at IS NULL
        OR (s.ended_at AT TIME ZONE 'UTC')::DATE >= p_from_date
      )
  ),
  expected AS (
    SELECT e.*, 1::INT AS expected_count
    FROM expanded e
    WHERE NOT EXISTS (
      SELECT 1 FROM away_days a
      WHERE a.service_user_id = e.service_user_id
        AND a.away_day = e.administration_date
    )
  ),
  logged AS (
    SELECT
      mal.medication_id,
      mal.service_user_id,
      (mal.administered_at AT TIME ZONE 'UTC')::DATE AS administration_date,
      (mal.administered_at AT TIME ZONE 'UTC')::TIME AS administered_time
    FROM public.mar_administration_logs mal
    WHERE mal.administered_at IS NOT NULL
      AND LOWER(COALESCE(mal.status, '')) = 'administered'
      AND (mal.administered_at AT TIME ZONE 'UTC')::DATE BETWEEN p_from_date AND p_to_date
  ),
  matched AS (
    SELECT
      ex.medication_id, ex.service_user_id, ex.service_user_name,
      ex.medication_name, ex.dosage, ex.frequency, ex.is_prn,
      ex.administration_date, ex.scheduled_time, ex.expected_count,
      COALESCE(COUNT(l.administered_time) FILTER (
        WHERE ABS(EXTRACT(EPOCH FROM (l.administered_time - ex.scheduled_time))) <= 7200
      ), 0)::INT AS logged_count
    FROM expected ex
    LEFT JOIN logged l
      ON l.medication_id = ex.medication_id
     AND l.service_user_id = ex.service_user_id
     AND l.administration_date = ex.administration_date
    GROUP BY ex.medication_id, ex.service_user_id, ex.service_user_name,
             ex.medication_name, ex.dosage, ex.frequency, ex.is_prn,
             ex.administration_date, ex.scheduled_time, ex.expected_count
  )
  SELECT
    m.medication_id, m.service_user_id, m.service_user_name,
    m.administration_date, m.scheduled_time,
    m.medication_name, m.dosage, m.frequency,
    m.expected_count, m.logged_count,
    m.is_prn,
    FALSE::BOOLEAN AS service_user_away
  FROM matched m
  WHERE m.logged_count < m.expected_count
    AND ((m.administration_date + m.scheduled_time) AT TIME ZONE 'UTC')
        < (v_now - INTERVAL '2 hours')   -- only flag slots at least 2h in the past
  ORDER BY m.administration_date DESC, m.scheduled_time, m.medication_name;
END;
$$;

GRANT EXECUTE ON FUNCTION public.check_missed_mar_doses(DATE, DATE) TO authenticated;
GRANT EXECUTE ON FUNCTION public.check_missed_mar_doses(DATE, DATE) TO service_role;

-- ============================================================
-- 3. Make sure the existing notifications table has the columns
--    the Dart layer writes. These are idempotent ALTER ADD COLUMN
--    IF NOT EXISTS statements - no-op if columns already exist.
-- ============================================================
ALTER TABLE public.notifications
  ADD COLUMN IF NOT EXISTS category   TEXT,
  ADD COLUMN IF NOT EXISTS priority   TEXT,
  ADD COLUMN IF NOT EXISTS title      TEXT,
  ADD COLUMN IF NOT EXISTS message    TEXT,
  ADD COLUMN IF NOT EXISTS action_url TEXT,
  ADD COLUMN IF NOT EXISTS related_id UUID,
  ADD COLUMN IF NOT EXISTS metadata   JSONB,
  ADD COLUMN IF NOT EXISTS read_at    TIMESTAMPTZ;

-- ============================================================
-- 4. RLS on notifications: allow SELECT for authenticated users
--    and UPDATE so they can mark-as-read.
-- ============================================================
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'notifications'
      AND policyname = 'Authenticated users can view notifications'
  ) THEN
    EXECUTE $POL$
      CREATE POLICY "Authenticated users can view notifications"
        ON public.notifications
        FOR SELECT TO authenticated
        USING (TRUE);
    $POL$;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'notifications'
      AND policyname = 'Users can mark notifications read'
  ) THEN
    EXECUTE $POL$
      CREATE POLICY "Users can mark notifications read"
        ON public.notifications
        FOR UPDATE TO authenticated
        USING (TRUE)
        WITH CHECK (TRUE);
    $POL$;
  END IF;
END
$$;

-- ============================================================
-- 5. Grants on the notifications table itself.
-- ============================================================
GRANT SELECT, UPDATE ON public.notifications TO authenticated;

-- ============================================================
-- 6. Revive 003's dead triggers.
--    The triggers reference public.notify_admins(...) which
--    did not exist until now. With notify_admins() defined in
--    section 1, they will start firing on INSERT into:
--      - risk_assessments
--      - safeguarding_incidents
--      - policies
-- ============================================================
DO $$
DECLARE
  trig RECORD;
  v_relname TEXT;
BEGIN
  FOR trig IN
    SELECT t.tgname, c.relname
    FROM pg_trigger t
    JOIN pg_class c ON c.oid = t.tgrelid
    JOIN pg_proc p ON p.oid = t.tgfoid
    WHERE c.relname IN ('risk_assessments', 'safeguarding_incidents', 'policies')
      AND NOT t.tgisinternal
      AND p.proname = 'notify_admins'
  LOOP
    v_relname := trig.relname;
    EXECUTE format('ALTER TABLE public.%I ENABLE TRIGGER %I', v_relname, trig.tgname);
  END LOOP;
END
$$;

-- ============================================================
-- Done. After running this migration:
--   * 003's pre-existing triggers on risk_assessments,
--     safeguarding_incidents, policies will start firing
--     correctly.
--   * The Dart poller can call public.check_missed_mar_doses()
--     to find missed MAR administrations.
--   * The notifications table will accept INSERTs from the
--     notify_admins(...) function and from the poller, and
--     authenticated users can SELECT/UPDATE it for the hub UI.
-- ============================================================
