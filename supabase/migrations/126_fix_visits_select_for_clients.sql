-- Fix SELECT policy on visits to allow client users to view visits in their care home
-- The current policy only allows carers, admins, or org null users

-- Drop existing SELECT policy
DROP POLICY IF EXISTS "Carers can view own visits" ON visits;

-- Create a broader SELECT policy
CREATE POLICY "Users can view visits"
  ON visits
  FOR SELECT
  TO authenticated
  USING (
    (
      -- Carer viewing their own visits
      carer_id = auth.uid()
    )
    OR
    (
      -- Admin can view all
      EXISTS (
        SELECT 1 FROM profiles
        WHERE profiles.id = auth.uid()
          AND profiles.role = 'admin'::text
      )
    )
    OR
    (
      -- Client user viewing visits for their care home
      client_organisation_id = (
        SELECT profiles.client_organisation_id FROM profiles
        WHERE profiles.id = auth.uid()
      )
      AND client_organisation_id IS NOT NULL
    )
    OR
    (
      -- Fallback: visits with no org association
      organisation_id IS NULL
    )
  );