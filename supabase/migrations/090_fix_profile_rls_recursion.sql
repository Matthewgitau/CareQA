-- Fix infinite recursion in profiles RLS policy
-- The problem: Subquery on profiles table triggers the same RLS policy, creating infinite recursion.
-- Solution: Use a SECURITY DEFINER function that bypasses RLS to read the current user's organisation.

-- Create a helper function that bypasses RLS to get the current user's organisation_id
CREATE OR REPLACE FUNCTION public.get_current_user_organisation()
RETURNS UUID
SECURITY DEFINER
SET search_path = public
LANGUAGE sql
STABLE
AS $$
  SELECT organisation_id FROM public.profiles WHERE id = auth.uid();
$$;

-- Drop the problematic policies
DROP POLICY IF EXISTS "Users can view profiles in same organisation" ON profiles;
DROP POLICY IF EXISTS "Admins can view all profiles" ON profiles;
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;

-- Recreate using the SECURITY DEFINER function (no recursion)
CREATE POLICY "Users can view profiles in same organisation" ON profiles
  FOR SELECT USING (
    organisation_id = public.get_current_user_organisation()
  );

-- Admin bypass (uses SECURITY DEFINER so no recursion)
CREATE POLICY "Admins can view all profiles" ON profiles
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.get_current_user_organisation() TO authenticated;

-- Also fix the carers policy (same issue might exist if it queries profiles)
DROP POLICY IF EXISTS "Users can view carers in same organisation" ON carers;
DROP POLICY IF EXISTS "Allow all authenticated" ON carers;

CREATE POLICY "Users can view carers in same organisation" ON carers
  FOR SELECT USING (
    organisation_id = public.get_current_user_organisation()
  );

-- Also fix service_users policy
DROP POLICY IF EXISTS "Authenticated users can view service_users" ON service_users;
DROP POLICY IF EXISTS "Allow all authenticated" ON service_users;

CREATE POLICY "Authenticated users can view service_users" ON service_users
  FOR SELECT USING (
    organisation_id = public.get_current_user_organisation() OR organisation_id IS NULL
  );