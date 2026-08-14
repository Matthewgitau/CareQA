-- Create organisations for existing users without one
-- This fixes the foreign key error when users have NULL organisation_id

-- First, ensure organisations table has all needed columns
ALTER TABLE organisations ADD COLUMN IF NOT EXISTS subscription_tier TEXT DEFAULT 'trial';
ALTER TABLE organisations ADD COLUMN IF NOT EXISTS settings JSONB DEFAULT '{}';

-- Create an organisation for every user that doesn't have one
DO $$
DECLARE
  user_record RECORD;
  org_id UUID;
  org_count INTEGER;
BEGIN
  -- Count how many users need organisations
  SELECT COUNT(*) INTO org_count FROM profiles WHERE organisation_id IS NULL;
  RAISE NOTICE 'Found % users without organisations', org_count;
  
  FOR user_record IN SELECT id, email FROM profiles WHERE organisation_id IS NULL
  LOOP
    -- Create a unique organisation for this user
    INSERT INTO organisations (id, name, subscription_tier)
    VALUES (
      gen_random_uuid(),
      COALESCE(user_record.email, 'Organisation_' || gen_random_uuid()),
      'trial'
    )
    RETURNING id INTO org_id;
    
    -- Update the user's profile with the new organisation ID
    UPDATE profiles SET organisation_id = org_id WHERE id = user_record.id;
    
    RAISE NOTICE 'Created organisation for user: %', user_record.email;
  END LOOP;
END $$;

-- Verify all profiles now have organisation_id
SELECT COUNT(*) as total_profiles, 
       COUNT(organisation_id) as profiles_with_org
FROM profiles;

-- Show any profiles still missing organisation_id (should be 0)
SELECT id, email, organisation_id 
FROM profiles 
WHERE organisation_id IS NULL;