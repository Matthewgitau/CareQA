-- Fix profiles table
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS organisation_id UUID;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS name TEXT;

-- Fix carers table
ALTER TABLE carers ADD COLUMN IF NOT EXISTS organisation_id UUID;

-- Drop existing policies on profiles
DROP POLICY IF EXISTS "Users can view profiles in same organisation" ON profiles;
DROP POLICY IF EXISTS "Admins can view all profiles" ON profiles;
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;

-- Create policy for same-organisation access on profiles
CREATE POLICY "Users can view profiles in same organisation" ON profiles
  FOR SELECT USING (
    organisation_id = (SELECT organisation_id FROM profiles WHERE id = auth.uid())
  );

-- Admin policy (for users with admin role)
CREATE POLICY "Admins can view all profiles" ON profiles
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Enable RLS on profiles if not already
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Drop existing policies on carers
DROP POLICY IF EXISTS "Users can view carers in same organisation" ON carers;
DROP POLICY IF EXISTS "Allow all authenticated" ON carers;

-- Create policy for same-organisation access on carers
CREATE POLICY "Users can view carers in same organisation" ON carers
  FOR SELECT USING (
    organisation_id = (SELECT organisation_id FROM profiles WHERE id = auth.uid())
  );

-- Enable RLS on carers if not already
ALTER TABLE carers ENABLE ROW LEVEL SECURITY;