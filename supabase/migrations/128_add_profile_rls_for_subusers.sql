-- =============================================
-- Migration 128: Add RLS policies for profiles
-- table to support sub-user creation and management
-- =============================================

-- Enable RLS on profiles if not already enabled
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Drop any existing policies to avoid conflicts
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can view sub-users of same care home" ON public.profiles;
DROP POLICY IF EXISTS "Users can create sub-users under themselves" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Overseers can update their sub-users" ON public.profiles;
DROP POLICY IF EXISTS "Overseers can soft-delete their sub-users" ON public.profiles;

-- 1. Users can view their own profile
CREATE POLICY "Users can view own profile"
  ON public.profiles
  FOR SELECT
  USING (
    id = auth.uid()
  );

-- 2. Users can view sub-users of the same care home (for the sub-users list)
-- A user can see profiles where:
--   - They are the overseer (they created them), OR
--   - They share the same client_organisation_id
CREATE POLICY "Users can view sub-users of same care home"
  ON public.profiles
  FOR SELECT
  USING (
    client_organisation_id = (
      SELECT client_organisation_id FROM public.profiles WHERE id = auth.uid()
    ) AND role = 'carer'
  );

-- 3. Users can create sub-users under themselves (they become the overseer)
-- The new profile must reference the creator as overseer_id
CREATE POLICY "Users can create sub-users under themselves"
  ON public.profiles
  FOR INSERT
  WITH CHECK (
    overseer_id = auth.uid()
  );

-- 4. Users can update their own profile
CREATE POLICY "Users can update own profile"
  ON public.profiles
  FOR UPDATE
  USING (id = auth.uid());

-- 5. Overseers can update their sub-users (e.g. role changes)
CREATE POLICY "Overseers can update their sub-users"
  ON public.profiles
  FOR UPDATE
  USING (overseer_id = auth.uid());

-- 6. Overseers can soft-delete their sub-users (set is_active = false)
CREATE POLICY "Overseers can soft-delete their sub-users"
  ON public.profiles
  FOR UPDATE
  USING (overseer_id = auth.uid())
  WITH CHECK (overseer_id = auth.uid());