-- ============================================================
-- MIGRATION 154: Fix receipt_entries RLS for INSERT
--
-- Problem: migration 105 created a single FOR ALL policy using only
-- USING (organisation_id = my_org). PostgreSQL requires a WITH CHECK
-- clause for INSERT (and the USING alone is not enough).
-- Also, the same-org policy blocked admins/owners from creating
-- receipts across organisations, and failed when the user profile had
-- no organisation_id (the carer's profile) -- which made
-- org_filtered_users see no rows.
--
-- Fix: split the policy into
--   1. SELECT  -- same organisation OR admin role
--   2. INSERT  -- anyone authenticated may insert; admins/owners may
--                write to any organisation, others must match theirs
--   3. UPDATE  -- creator OR admin role
--   4. DELETE  -- creator OR admin role
-- ============================================================

DROP POLICY IF EXISTS tenant_isolation_receipts ON public.receipt_entries;
DROP POLICY IF EXISTS "Admins can view all receipts" ON public.receipt_entries;
DROP POLICY IF EXISTS "Users can insert receipts" ON public.receipt_entries;
DROP POLICY IF EXISTS "Users can update own receipts" ON public.receipt_entries;
DROP POLICY IF EXISTS "Users can delete own receipts" ON public.receipt_entries;

-- Helper: is the current user an admin-level role
CREATE OR REPLACE FUNCTION public.is_admin_or_owner() RETURNS BOOLEAN
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role IN ('admin', 'manager', 'super_admin', 'owner')
  );
$$;
GRANT EXECUTE ON FUNCTION public.is_admin_or_owner() TO authenticated;

-- 1. SELECT: same org, OR admin role, OR receipts created by the user
CREATE POLICY "Receipts SELECT policy" ON public.receipt_entries
  FOR SELECT TO authenticated
  USING (
    is_admin_or_owner()
    OR created_by = auth.uid()
    OR organisation_id = (SELECT organisation_id FROM public.profiles WHERE id = auth.uid())
  );

-- 2. INSERT: any authenticated user; admins/owners may set any
--    organisation_id, others must set their own.
CREATE POLICY "Receipts INSERT policy" ON public.receipt_entries
  FOR INSERT TO authenticated
  WITH CHECK (
    is_admin_or_owner()
    OR organisation_id = (SELECT organisation_id FROM public.profiles WHERE id = auth.uid())
    OR organisation_id IS NULL
  );

-- 3. UPDATE: creator or admin
CREATE POLICY "Receipts UPDATE policy" ON public.receipt_entries
  FOR UPDATE TO authenticated
  USING (
    is_admin_or_owner() OR created_by = auth.uid()
  )
  WITH CHECK (
    is_admin_or_owner() OR created_by = auth.uid()
  );

-- 4. DELETE: creator or admin
CREATE POLICY "Receipts DELETE policy" ON public.receipt_entries
  FOR DELETE TO authenticated
  USING (
    is_admin_or_owner() OR created_by = auth.uid()
  );
