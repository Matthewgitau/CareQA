-- =============================================
-- Migration 133: Carer Invite & Management System
--
-- Adds:
--   1. staff_types table (carer, driver, warehouse, factory, admin)
--   2. staff_type + invite_status columns on carers
--   3. RLS policies on carers (admins manage, carers view own)
--   4. RPC function to create a carer + auth user + profile atomically
-- =============================================

-- ─────────────────────────────────────────────
-- 1. STAFF TYPES TABLE
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.staff_types (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,  -- 'carer', 'driver', 'warehouse', 'factory', 'admin'
  description TEXT,
  required_training JSONB,
  default_role TEXT  -- 'carer', 'driver', etc.
);

-- Seed default staff types
INSERT INTO public.staff_types (name, description, default_role) VALUES
  ('carer', 'Care worker providing personal care', 'carer'),
  ('driver', 'Transport / driving staff', 'driver'),
  ('warehouse', 'Warehouse / logistics staff', 'warehouse'),
  ('factory', 'Factory / production staff', 'factory'),
  ('admin', 'Administrative staff', 'admin')
ON CONFLICT (name) DO NOTHING;

-- ─────────────────────────────────────────────
-- 2. ADD COLUMNS TO CARERS
-- ─────────────────────────────────────────────
ALTER TABLE public.carers
  ADD COLUMN IF NOT EXISTS staff_type TEXT DEFAULT 'carer',
  ADD COLUMN IF NOT EXISTS invite_status TEXT DEFAULT 'invited',  -- invited | active | inactive
  ADD COLUMN IF NOT EXISTS invited_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS invited_by UUID;

-- ─────────────────────────────────────────────
-- 3. RLS POLICIES ON CARERS
-- ─────────────────────────────────────────────
ALTER TABLE public.carers ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins can manage all carers" ON public.carers;
DROP POLICY IF EXISTS "Carers can view own record" ON public.carers;

-- Admins can do everything
CREATE POLICY "Admins can manage all carers"
  ON public.carers
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
        AND profiles.role = 'admin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
        AND profiles.role = 'admin'
    )
  );

-- Carers can view their own record (id matches their auth.uid())
CREATE POLICY "Carers can view own record"
  ON public.carers
  FOR SELECT
  USING (id = auth.uid());

-- ─────────────────────────────────────────────
-- 4. RPC: CREATE CARER + AUTH USER + PROFILE
--    (SECURITY DEFINER so the anon key can create
--     auth users + profiles atomically)
-- ─────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.create_carer_with_auth(
  p_name TEXT,
  p_email TEXT,
  p_phone TEXT,
  p_job_role TEXT,
  p_staff_type TEXT,
  p_organisation_id UUID,
  p_invited_by UUID,
  p_temporary_password TEXT
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $function$
DECLARE
  v_carer_id UUID := gen_random_uuid();
  v_user_id UUID;
BEGIN
  -- Validate inputs
  IF p_name IS NULL OR p_email IS NULL OR p_temporary_password IS NULL THEN
    RAISE EXCEPTION 'name, email and password are required';
  END IF;
  IF length(p_temporary_password) < 6 THEN
    RAISE EXCEPTION 'Password must be at least 6 characters';
  END IF;

  -- 1. Create the auth user (GoTrue)
  INSERT INTO auth.users (
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    raw_app_meta_data,
    raw_user_meta_data,
    created_at,
    updated_at,
    confirmation_token,
    email_change,
    email_change_token_new,
    recovery_token
  )
  VALUES (
    '00000000-0000-0000-0000-000000000000',
    v_carer_id,
    'authenticated',
    'authenticated',
    p_email,
    crypt(p_temporary_password, gen_salt('bf')),
    now(),
    jsonb_build_object('provider', 'email', 'providers', jsonb_build_array('email')),
    jsonb_build_object('role', p_staff_type, 'full_name', p_name),
    now(),
    now(),
    '',
    '',
    '',
    ''
  )
  RETURNING id INTO v_user_id;

  -- 2. Create the profile (linked to carer.id)
  INSERT INTO public.profiles (
    id,
    email,
    full_name,
    name,
    role,
    organisation_id,
    overseer_id,
    is_active
  )
  VALUES (
    v_carer_id,
    p_email,
    p_name,
    p_name,
    p_staff_type,
    p_organisation_id,
    p_invited_by,
    true
  );

  -- 3. Create the carer record
  INSERT INTO public.carers (
    id,
    name,
    email,
    phone,
    job_role,
    staff_type,
    organisation_id,
    invite_status,
    invited_at,
    invited_by,
    is_active
  )
  VALUES (
    v_carer_id,
    p_name,
    p_email,
    p_phone,
    p_job_role,
    p_staff_type,
    p_organisation_id,
    'invited',
    now(),
    p_invited_by,
    true
  );

  RETURN v_carer_id;
END;
$function$;

-- Grant execute to authenticated users
REVOKE ALL ON FUNCTION public.create_carer_with_auth(TEXT, TEXT, TEXT, TEXT, TEXT, UUID, UUID, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.create_carer_with_auth(TEXT, TEXT, TEXT, TEXT, TEXT, UUID, UUID, TEXT) TO authenticated;