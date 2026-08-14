-- =============================================
-- Migration 129: Fix sub-user creation trigger +
-- correct profile RLS SELECT policies
-- =============================================

-- ─────────────────────────────────────────────
-- 1. FIX RLS SELECT POLICIES
--    (previous policy wrongly restricted to role='carer';
--     sub-users are role='client' and need overseer-based SELECT)
-- ─────────────────────────────────────────────
DROP POLICY IF EXISTS "Users can view sub-users of same care home" ON public.profiles;
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can create sub-users under themselves" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Overseers can update their sub-users" ON public.profiles;
DROP POLICY IF EXISTS "Overseers can soft-delete their sub-users" ON public.profiles;
DROP POLICY IF EXISTS "Users can view their sub-users" ON public.profiles;
DROP POLICY IF EXISTS "Users can view profiles in same care home" ON public.profiles;

-- 1a. Users can view their own profile
CREATE POLICY "Users can view own profile"
  ON public.profiles
  FOR SELECT
  USING (id = auth.uid());

-- 1b. Users can view profiles they created (sub-users)
CREATE POLICY "Users can view their sub-users"
  ON public.profiles
  FOR SELECT
  USING (overseer_id = auth.uid());

-- 1c. Users can view other profiles in the same care home
CREATE POLICY "Users can view profiles in same care home"
  ON public.profiles
  FOR SELECT
  USING (
    client_organisation_id = (
      SELECT p.client_organisation_id FROM public.profiles p WHERE p.id = auth.uid()
    )
    AND is_active = true
  );

-- 1d. Users can create sub-users under themselves
CREATE POLICY "Users can create sub-users under themselves"
  ON public.profiles
  FOR INSERT
  WITH CHECK (overseer_id = auth.uid());

-- 1e. Users can update their own profile
CREATE POLICY "Users can update own profile"
  ON public.profiles
  FOR UPDATE
  USING (id = auth.uid());

-- 1f. Overseers can update their sub-users
CREATE POLICY "Overseers can update their sub-users"
  ON public.profiles
  FOR UPDATE
  USING (overseer_id = auth.uid());

-- 1g. Overseers can soft-delete their sub-users
CREATE POLICY "Overseers can soft-delete their sub-users"
  ON public.profiles
  FOR UPDATE
  USING (overseer_id = auth.uid());

-- ─────────────────────────────────────────────
-- 2. FIX SUB-USER CREATION IN THE SIGNUP TRIGGER
--    When a client creates a sub-user, the app passes
--    `is_sub_user: 'true'` + `overseer_id` +
--    `client_organisation_id` + `organisation_id` in
--    the auth signup metadata. This modified function
--    reuses the parent's organisation instead of
--    creating a brand-new client organisation.
-- ─────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.handle_new_client_signup()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  new_org_id UUID;
  meta JSONB;
  v_role TEXT;
  v_org_name TEXT;
  v_org_type TEXT;
  v_org_address TEXT;
  v_org_phone TEXT;
  v_full_name TEXT;
  v_parent_org_id UUID;
  v_client_org_id UUID;
  v_overseer_id UUID;
BEGIN
  meta := NEW.raw_user_meta_data;
  v_role := COALESCE(meta->>'role', 'client');

  -- Only process if role is 'client'
  IF v_role = 'client' THEN

    -- ── SUB-USER CREATION (parent is creating a sub-user) ──
    IF meta->>'is_sub_user' = 'true' THEN
      v_parent_org_id := NULLIF(meta->>'organisation_id', '')::UUID;
      v_client_org_id := NULLIF(meta->>'client_organisation_id', '')::UUID;
      v_overseer_id   := NULLIF(meta->>'overseer_id', '')::UUID;
      v_full_name     := COALESCE(meta->>'full_name', NEW.email);

      IF v_client_org_id IS NULL OR v_overseer_id IS NULL THEN
        RAISE EXCEPTION 'Sub-user signup requires client_organisation_id and overseer_id';
      END IF;

      -- Reuse the parent's care home org; do NOT create a new organisation.
      -- Set overseer_id so the parent can manage this sub-user.
      INSERT INTO public.profiles (
        id,
        email,
        full_name,
        name,
        role,
        client_organisation_id,
        organisation_id,
        overseer_id,
        is_active
      )
      VALUES (
        NEW.id,
        NEW.email,
        v_full_name,
        v_full_name,
        'client',
        v_client_org_id,
        v_parent_org_id,
        v_overseer_id,
        true
      )
      ON CONFLICT (id) DO UPDATE SET
        role = 'client',
        client_organisation_id = EXCLUDED.client_organisation_id,
        organisation_id = EXCLUDED.organisation_id,
        overseer_id = EXCLUDED.overseer_id,
        full_name = COALESCE(EXCLUDED.full_name, profiles.full_name),
        name = COALESCE(EXCLUDED.name, profiles.name),
        is_active = true;

    -- ── NORMAL CLIENT SIGNUP (self-registration) ──
    ELSE
      v_parent_org_id := '11111111-1111-1111-1111-111111111111';
      v_org_name := COALESCE(meta->>'org_name', 'New Client Organisation');
      v_org_type := COALESCE(meta->>'org_type', 'Care Home');
      v_org_address := COALESCE(meta->>'org_address', '');
      v_org_phone := COALESCE(meta->>'org_phone', '');
      v_full_name := COALESCE(meta->>'full_name', NEW.email);

      -- 1. Create the client organisation
      INSERT INTO public.client_organisations (
        name,
        organisation_id,
        organisation_types,
        address,
        phone,
        email,
        is_active
      )
      VALUES (
        v_org_name,
        v_parent_org_id,
        jsonb_build_array(v_org_type),
        v_org_address,
        v_org_phone,
        NEW.email,
        true
      )
      RETURNING id INTO new_org_id;

      -- 2. Create the profile
      INSERT INTO public.profiles (
        id,
        email,
        full_name,
        name,
        role,
        client_organisation_id,
        organisation_id,
        is_active
      )
      VALUES (
        NEW.id,
        NEW.email,
        v_full_name,
        v_full_name,
        'client',
        new_org_id,
        v_parent_org_id,
        true
      )
      ON CONFLICT (id) DO UPDATE SET
        role = 'client',
        client_organisation_id = EXCLUDED.client_organisation_id,
        organisation_id = EXCLUDED.organisation_id,
        full_name = COALESCE(EXCLUDED.full_name, profiles.full_name),
        name = COALESCE(EXCLUDED.name, profiles.name),
        is_active = true;
    END IF;
  END IF;

  RETURN NEW;
END;
$function$;