-- Add 'client' role to profiles table
-- This allows care home clients to log into the client-app

-- Drop the existing CHECK constraint
ALTER TABLE profiles DROP CONSTRAINT IF EXISTS profiles_role_check;

-- Add new CHECK constraint with 'client' role included
ALTER TABLE profiles ADD CONSTRAINT profiles_role_check 
  CHECK (role IN ('admin', 'carer', 'client'));

-- Add comment to document the roles
COMMENT ON COLUMN profiles.role IS 'User role: admin (organisation admin), carer (care staff), client (care home client)';