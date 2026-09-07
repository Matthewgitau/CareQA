-- ============================================================
-- MIGRATION 146 (CONTINUED)
-- FUTURE-READY (next feature):
--   The following feature will let a carer REQUEST to not attend a call
--   (e.g. leave/absence). That request goes ONLY to the admin-app, and must
--   NOT be visible in the client-app. The RLS policy shape used in this
--   migration is the groundwork: a `carer_absence_requests` table created
--   later will use an INSERT policy allowing `changed_by = auth.uid()`
--   (staff) with SELECT restricted to admins/managers — no client-org
--   SELECT is ever granted, so the communication point stays admin-only.
-- ============================================================

-- ------------------------------------------------------------
-- 1. Carer read access to route_visits
-- ------------------------------------------------------------
-- 1a. Add organisation_id to route_visits (idempotent; matches 141/137).
ALTER TABLE public.route_visits
  ADD COLUMN IF NOT EXISTS organisation_id UUID REFERENCES public.organisations(id) ON DELETE CASCADE;

-- 1b. SELECT policy: a carer may read the visits assigned to them.
--     This is ADDITIVE to the org-based policy from 141 (two permissive
--     policies = OR together). A carer always sees their own calls,
--     regardless of any org mismatch on legacy rows.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'route_visits'
      AND policyname = 'Carers can view their own route visits'
  ) THEN
    CREATE POLICY "Carers can view their own route visits"
      ON public.route_visits FOR SELECT TO authenticated
      USING (
        -- Directly assigned to this visit
        (carer_id = auth.uid())
        OR
        -- Assigned as carer on the containing route (covers second carer)
        (route_id IS NOT NULL AND EXISTS (
          SELECT 1 FROM public.routes r
          WHERE r.id = route_id
            AND (r.carer_id = auth.uid() OR r.second_carer_id = auth.uid())
        ))
      );
  END IF;
END $$;

-- ------------------------------------------------------------
-- 2. Carer read access to routes
-- ------------------------------------------------------------
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'routes'
      AND policyname = 'Carers can view their own routes'
  ) THEN
    CREATE POLICY "Carers can view their own routes"
      ON public.routes FOR SELECT TO authenticated
      USING (
        carer_id = auth.uid() OR second_carer_id = auth.uid()
      );
  END IF;
END $$;

-- ------------------------------------------------------------
-- 3. Backfill organisation_id on legacy NULL rows
-- ------------------------------------------------------------
UPDATE public.routes
SET organisation_id = r2.organisation_id
FROM public.routes r2
WHERE public.routes.organisation_id IS NULL
  AND r2.id = public.routes.id
  AND r2.organisation_id IS NOT NULL;

UPDATE public.route_visits rv
SET organisation_id = r.organisation_id
FROM public.routes r
WHERE rv.organisation_id IS NULL
  AND rv.route_id IS NOT NULL
  AND r.id = rv.route_id
  AND r.organisation_id IS NOT NULL;

-- ------------------------------------------------------------
-- 4. Groundwork for carer absence/leave requests (admin-only)
-- ------------------------------------------------------------
-- This migration does NOT create the full carer_absence_requests table
-- (that is migration 147). The key RLS principle is established here:
--
--   * A carer can INSERT a request with `changed_by = auth.uid()`.
--   * SELECT is restricted to organisation admins/managers.
--   * NO client-organization user (client-app) is ever granted SELECT on
--     absence requests, so this communication point stays admin-only.
--
-- Migration 147 will add:
--   CREATE TABLE public.carer_absence_requests (...);
--   ALTER TABLE ... ENABLE ROW LEVEL SECURITY;
--   CREATE POLICY "Admins can view absence requests" FOR SELECT USING (...);
--   CREATE POLICY "Carers can insert own absence requests" FOR INSERT
--     WITH CHECK (changed_by = auth.uid());

NOTIFY pgrst, 'reload schema';