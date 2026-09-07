-- ============================================================
-- MIGRATION 152: HEAL RLS RECURSION from migration 151
--
-- WHAT HAPPENED: migration 151 re-created RLS policies on
-- profiles / carers / payroll_history using inline subqueries
-- like "EXISTS (SELECT 1 FROM public.profiles ...)" INSIDE
-- policies on those same tables. PostgreSQL applies RLS to
-- policy subqueries, so a self-referencing subquery re-enters
-- the policy until it hits "infinite recursion detected in
-- policy for relation" -> every query returns HTTP 500 ->
-- the dashboard spins forever.
--
-- FIX: every role / organisation look-up goes through the
-- SECURITY DEFINER functions public.get_user_role() and
-- public.get_current_user_organisation(), which read profiles
-- WITHOUT RLS. No policy below references profiles/carers
-- from inside a policy on the same table.
--
-- This file is fully idempotent: safe to run even if 151 only
-- partially applied (or was re-run).
-- ============================================================

-- ============================================
-- 1. Helper functions (SECURITY DEFINER = bypass RLS)
-- ============================================
CREATE OR REPLACE FUNCTION public.get_current_user_organisation()
RETURNS UUID
SECURITY DEFINER
SET search_path = public
LANGUAGE sql
STABLE
AS $$
  SELECT organisation_id FROM public.profiles WHERE id = auth.uid();
$$;

CREATE OR REPLACE FUNCTION public.get_user_role()
RETURNS TEXT
SECURITY DEFINER
SET search_path = public
LANGUAGE sql
STABLE
AS $$
  SELECT role FROM public.profiles WHERE id = auth.uid();
$$;

GRANT EXECUTE ON FUNCTION public.get_current_user_organisation() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_role() TO authenticated;

-- ============================================
-- 2. payroll_history schema (idempotent re-run of 151)
-- ============================================
-- Drop restrictive FK so staff_id may be NULL for carer-only workers.
ALTER TABLE public.payroll_history DROP CONSTRAINT IF EXISTS payroll_history_staff_id_fkey;

-- Add carer_id FK (the identity shifts / route_visits actually use).
ALTER TABLE public.payroll_history ADD COLUMN IF NOT EXISTS carer_id UUID REFERENCES public.carers(id) ON DELETE SET NULL;

-- Backfill carer_id from rows whose staff_id matches an actual carer.
UPDATE public.payroll_history ph
SET carer_id = ph.staff_id
WHERE ph.carer_id IS NULL
  AND EXISTS (SELECT 1 FROM public.carers c WHERE c.id = ph.staff_id);

-- Index for carer look-ups.
CREATE INDEX IF NOT EXISTS idx_payroll_history_carer ON public.payroll_history(carer_id);

-- Re-add staff_id -> profiles FK as nullable (SET NULL), only if missing.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'payroll_history_staff_id_fkey'
      AND conrelid = 'public.payroll_history'::regclass
  ) THEN
    ALTER TABLE public.payroll_history
      ADD CONSTRAINT payroll_history_staff_id_fkey
      FOREIGN KEY (staff_id) REFERENCES public.profiles(id) ON DELETE SET NULL;
  END IF;
END $$;
-- ============================================
-- 3. payroll_history RLS (function-based, no recursion)
-- ============================================
DROP POLICY IF EXISTS "tenant_isolation_payroll_history" ON public.payroll_history;
CREATE POLICY "tenant_isolation_payroll_history"
  ON public.payroll_history FOR ALL TO authenticated
  USING (organisation_id = public.get_current_user_organisation())
  WITH CHECK (organisation_id = public.get_current_user_organisation());

DROP POLICY IF EXISTS "Admins can view all payroll history" ON public.payroll_history;
CREATE POLICY "Admins can view all payroll history"
  ON public.payroll_history FOR SELECT TO authenticated
  USING (
    public.get_user_role() IN ('admin', 'manager', 'super_admin')
    OR organisation_id = public.get_current_user_organisation()
    OR organisation_id IS NULL
  );

DROP POLICY IF EXISTS "Carers can view their own payroll" ON public.payroll_history;
CREATE POLICY "Carers can view their own payroll"
  ON public.payroll_history FOR SELECT TO authenticated
  USING (staff_id = auth.uid() OR carer_id = auth.uid());

DROP POLICY IF EXISTS "Admins can insert payroll" ON public.payroll_history;
CREATE POLICY "Admins can insert payroll"
  ON public.payroll_history FOR INSERT TO authenticated
  WITH CHECK (public.get_user_role() IN ('admin', 'manager', 'super_admin'));

DROP POLICY IF EXISTS "Admins can update payroll" ON public.payroll_history;
CREATE POLICY "Admins can update payroll"
  ON public.payroll_history FOR UPDATE TO authenticated
  USING (public.get_user_role() IN ('admin', 'manager', 'super_admin'))
  WITH CHECK (public.get_user_role() IN ('admin', 'manager', 'super_admin'));

-- ============================================
-- 4. profiles RLS (function-based, no self-reference)
-- ============================================
DROP POLICY IF EXISTS "Users can view profiles in same organisation" ON public.profiles;
CREATE POLICY "Users can view profiles in same organisation"
  ON public.profiles FOR SELECT TO authenticated
  USING (organisation_id = public.get_current_user_organisation());

DROP POLICY IF EXISTS "Admins can view all profiles" ON public.profiles;
CREATE POLICY "Admins can view all profiles"
  ON public.profiles FOR SELECT TO authenticated
  USING (
    public.get_user_role() IN ('admin', 'manager', 'super_admin')
    OR organisation_id = public.get_current_user_organisation()
    OR id = auth.uid()
  );

DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
CREATE POLICY "Users can view own profile"
  ON public.profiles FOR SELECT TO authenticated
  USING (id = auth.uid());

-- ============================================
-- 5. carers RLS (function-based, no recursion)
-- ============================================
DROP POLICY IF EXISTS "Users can view carers in same organisation" ON public.carers;
CREATE POLICY "Users can view carers in same organisation"
  ON public.carers FOR SELECT TO authenticated
  USING (organisation_id = public.get_current_user_organisation());

DROP POLICY IF EXISTS "Admins can view all carers" ON public.carers;
CREATE POLICY "Admins can view all carers"
  ON public.carers FOR SELECT TO authenticated
  USING (
    public.get_user_role() IN ('admin', 'manager', 'super_admin')
    OR organisation_id = public.get_current_user_organisation()
    OR organisation_id IS NULL
  );

NOTIFY pgrst, 'reload schema';