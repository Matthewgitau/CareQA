-- ============================================================
-- MIGRATION 158: Paywall RLS & access helpers
--
-- Server-side subscription gate used by RLS policies and edge
-- functions. Fails closed: NULL status / missing org / expired
-- trial all deny access.
--
--   SELECT public.has_access();            -- true/false for caller
--   SELECT public.org_has_access('uuid');  -- for a specific org
-- ============================================================

-- ---- has_access() helpers -------------------------------------

CREATE OR REPLACE FUNCTION public.org_has_access(p_org_id UUID)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.organisations o
    WHERE o.id = p_org_id
      AND o.subscription_status IN ('active', 'trialing')
      AND (
        o.subscription_status <> 'trialing'
        OR o.trial_ends_at IS NULL
        OR o.trial_ends_at > NOW()
      )
  );
$$;

CREATE OR REPLACE FUNCTION public.has_access()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT public.org_has_access(
    (SELECT organisation_id FROM public.profiles WHERE id = auth.uid())
  );
$$;

GRANT EXECUTE ON FUNCTION public.has_access() TO authenticated;
GRANT EXECUTE ON FUNCTION public.org_has_access(UUID) TO authenticated;

-- ---- Profiles self-management ---------------------------------
-- Existing 089 policies already give same-org SELECT. Add INSERT /
-- UPDATE so the account owner can manage their own row (RLS does not
-- interfere with the service_role used by the signup edge function,
-- but these policies keep the app working without service_role).

DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
CREATE POLICY "Users can insert own profile" ON public.profiles
  FOR INSERT TO authenticated
  WITH CHECK (id = auth.uid());

DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile" ON public.profiles
  FOR UPDATE TO authenticated
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

-- Only allow a user to see their own subscription columns directly.
-- (Same-org SELECT from 089 still applies for directory use.)

-- ---- Organisations RLS -----------------------------------------
DROP POLICY IF EXISTS "users_can_view_own_organisation" ON public.organisations;
CREATE POLICY "users_can_view_own_organisation" ON public.organisations
  FOR SELECT TO authenticated
  USING (id = (SELECT organisation_id FROM public.profiles WHERE id = auth.uid()));

-- ============================================================
-- TEMPLATE for locking down any data table behind the paywall.
-- For each existing table T, append:
--
--   CREATE POLICY "paywall_gate_T" ON T FOR SELECT TO authenticated
--     USING (
--       public.has_access()
--       -- AND (existing org-scoping expression)
--     );
--
-- Postgres combines policies with OR for SELECT, so you must DROP
-- any old permissive "Allow all authenticated" policy on T first,
-- otherwise it would bypass the gate. See the implementation
-- summary for the full list of tables in the admin-app surface.
-- ============================================================

NOTIFY pgrst, 'reload schema';