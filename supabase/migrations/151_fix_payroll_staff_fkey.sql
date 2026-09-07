-- ============================================================
-- MIGRATION 151: Fix payroll_history staff FK for carer-only workers
--
-- Problem: payroll_history.staff_id has a hard FK to profiles(id).
-- Some workers (e.g. legacy carers, and staff entered only in the
-- carers table) have a carers.id that is NOT present in profiles.
-- Generating a payslip for them failed with error 23503
-- ("Key is not present in table profiles").
--
-- Fix: relax the FK so staff_id can be NULL, and add a nullable
-- carer_id column that references carers(id) -- the identity that
-- shifts.carer_id / route_visits.carer_id actually use.
-- ============================================================

-- 0. Ensure the RLS helper function exists (originally from migration 090).
CREATE OR REPLACE FUNCTION public.get_current_user_organisation()
RETURNS UUID
SECURITY DEFINER
SET search_path = public
LANGUAGE sql
STABLE
AS $$
  SELECT organisation_id FROM public.profiles WHERE id = auth.uid();
$$;
GRANT EXECUTE ON FUNCTION public.get_current_user_organisation() TO authenticated;

-- 1. Drop the restrictive FK so staff_id can be NULL or unlinked.
ALTER TABLE public.payroll_history DROP CONSTRAINT IF EXISTS payroll_history_staff_id_fkey;

-- 2. Add carer_id FK -- the identity used by shifts / route_visits.
ALTER TABLE public.payroll_history ADD COLUMN IF NOT EXISTS carer_id UUID REFERENCES public.carers(id) ON DELETE SET NULL;

-- 3. Backfill carer_id from existing rows where staff_id matches a carer.
UPDATE public.payroll_history ph
SET carer_id = ph.staff_id
WHERE ph.carer_id IS NULL
  AND EXISTS (SELECT 1 FROM public.carers c WHERE c.id = ph.staff_id);

-- 4. Index for the new column.
CREATE INDEX IF NOT EXISTS idx_payroll_history_carer ON public.payroll_history(carer_id);

-- 5. Re-add staff_id -> profiles FK but with SET NULL, so staff_id may be
--    NULL for carer-only workers while still validated when present.
ALTER TABLE public.payroll_history
  ADD CONSTRAINT payroll_history_staff_id_fkey
  FOREIGN KEY (staff_id) REFERENCES public.profiles(id) ON DELETE SET NULL;

-- 6. RLS: extend carer self-access to also match carer_id (legacy identity),
--    and allow admins/managers to insert + update payroll rows.
--    IMPORTANT: never reference profiles/carers inside their own policies
--    (infinite RLS recursion -> HTTP 500). Use the SECURITY DEFINER helper
--    functions public.get_user_role() / get_current_user_organisation()
--    which read profiles WITHOUT applying RLS.
DROP POLICY IF EXISTS "Carers can view their own payroll" ON public.payroll_history;
CREATE POLICY "Carers can view their own payroll"
  ON public.payroll_history FOR SELECT TO authenticated
  USING (staff_id = auth.uid() OR carer_id = auth.uid());

DROP POLICY IF EXISTS "Admins can insert payroll" ON public.payroll_history;
CREATE POLICY "Admins can insert payroll"
  ON public.payroll_history FOR INSERT TO authenticated
  WITH CHECK (
    public.get_user_role() IN ('admin', 'manager', 'super_admin')
  );

DROP POLICY IF EXISTS "Admins can update payroll" ON public.payroll_history;
CREATE POLICY "Admins can update payroll"
  ON public.payroll_history FOR UPDATE TO authenticated
  USING (public.get_user_role() IN ('admin', 'manager', 'super_admin'))
  WITH CHECK (public.get_user_role() IN ('admin', 'manager', 'super_admin'));

-- 7. RLS visibility fixes so the payroll page can list ALL staff.
--    The profiles/carers policies from migration 089/090 only expose
--    same-organisation rows (plus role='admin' for profiles). Staff with
--    NULL organisation_id were invisible to admins, which is why the
--    payroll list showed almost nobody.
DROP POLICY IF EXISTS "Admins can view all profiles" ON public.profiles;
CREATE POLICY "Admins can view all profiles"
  ON public.profiles FOR SELECT TO authenticated
  USING (
    public.get_user_role() IN ('admin', 'manager', 'super_admin')
    OR organisation_id = public.get_current_user_organisation()
    OR id = auth.uid()
  );

DROP POLICY IF EXISTS "Admins can view all payroll history" ON public.payroll_history;
CREATE POLICY "Admins can view all payroll history"
  ON public.payroll_history FOR SELECT TO authenticated
  USING (
    public.get_user_role() IN ('admin', 'manager', 'super_admin')
    OR organisation_id = public.get_current_user_organisation()
    OR organisation_id IS NULL
  );

-- Admin bypass for carers table: without this, carers with NULL or a
-- different organisation_id are completely hidden from the payroll page.
DROP POLICY IF EXISTS "Admins can view all carers" ON public.carers;
CREATE POLICY "Admins can view all carers"
  ON public.carers FOR SELECT TO authenticated
  USING (
    public.get_user_role() IN ('admin', 'manager', 'super_admin')
    OR organisation_id = public.get_current_user_organisation()
    OR organisation_id IS NULL
  );

NOTIFY pgrst, 'reload schema';