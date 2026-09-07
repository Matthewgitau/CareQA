-- ============================================================
-- MIGRATION 149: Fix client_organisations RLS for billing
--
-- Problem 1: The client_organisations RLS policies (migration 029)
-- reference public.get_user_organisation_id() and
-- public.get_user_role() which are never defined anywhere.
-- Any SELECT on client_organisations therefore errors out and
-- the admin invoice page silently shows no billable clients.
--
-- Problem 2: Migration 129's signup trigger stores client orgs
-- under a dummy parent organisation
-- ('11111111-1111-1111-1111-111111111111'), so even with the
-- helper functions, the "organisation_id = my org" check would
-- filter them out.
--
-- Fix: Define the missing helper functions, then add a SELECT
-- policy that lets admin/manager/super_admin roles (the billing
-- users) read every active client organisation, regardless of
-- the dummy organisation_id.
-- ============================================================

-- 1. Helper functions (idempotent) used by existing RLS policies.
CREATE OR REPLACE FUNCTION public.get_user_organisation_id()
RETURNS UUID
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public
AS $$
  SELECT organisation_id FROM public.profiles WHERE id = auth.uid();
$$;

CREATE OR REPLACE FUNCTION public.get_user_role()
RETURNS TEXT
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public
AS $$
  SELECT role FROM public.profiles WHERE id = auth.uid();
$$;

GRANT EXECUTE ON FUNCTION public.get_user_organisation_id() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_role() TO authenticated;

-- 2. Admin/manager billing visibility on client_organisations.
--    Staff (carers) are not given this; only users who manage
--    the agency's billing can see every active client org.
DROP POLICY IF EXISTS "Admins can view all client organisations for billing" ON public.client_organisations;
CREATE POLICY "Admins can view all client organisations for billing"
  ON public.client_organisations FOR SELECT TO authenticated
  USING (
    is_active = true
    AND public.get_user_role() IN ('admin', 'super_admin', 'manager')
  );

NOTIFY pgrst, 'reload schema';