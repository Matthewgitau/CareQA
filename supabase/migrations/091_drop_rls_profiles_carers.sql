-- TEMPORARY: Disable RLS on profiles, carers, and service_users
-- Reason: No organisations table exists yet to support proper org-based RLS
-- Will be re-enabled after organisations table is created with proper FK relationships

-- Drop the SECURITY DEFINER helper function (no longer needed)
DROP FUNCTION IF EXISTS public.get_current_user_organisation();

-- Drop all policies on profiles
DROP POLICY IF EXISTS "Users can view profiles in same organisation" ON profiles;
DROP POLICY IF EXISTS "Admins can view all profiles" ON profiles;
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;

-- Drop all policies on carers
DROP POLICY IF EXISTS "Users can view carers in same organisation" ON carers;
DROP POLICY IF EXISTS "Allow all authenticated" ON carers;

-- Drop all policies on service_users
DROP POLICY IF EXISTS "Authenticated users can view service_users" ON service_users;
DROP POLICY IF EXISTS "Allow all authenticated" ON service_users;

-- Disable RLS on profiles, carers, and service_users
ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE carers DISABLE ROW LEVEL SECURITY;
ALTER TABLE service_users DISABLE ROW LEVEL SECURITY;

-- Grant table-level SELECT permission to authenticated users (since RLS is off, this is the actual permission)
GRANT SELECT ON profiles TO authenticated;
GRANT SELECT ON carers TO authenticated;
GRANT SELECT ON service_users TO authenticated;