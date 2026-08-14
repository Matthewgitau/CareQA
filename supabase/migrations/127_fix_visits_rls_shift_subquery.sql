-- Rebuild RLS policies on visits to validate against the SHIFT record
-- This is more robust: we don't rely on the client_organisation_id being passed in the insert
-- Instead, we check that the SHIFT referenced belongs to the user's care home

-- Drop existing policies
DROP POLICY IF EXISTS "Users can create visits" ON visits;
DROP POLICY IF EXISTS "Users can update visits" ON visits;
DROP POLICY IF EXISTS "Users can view visits" ON visits;

-- INSERT policy
-- Allows:
--  1. Carers inserting their own visits
--  2. Admins inserting any visit
--  3. Client users inserting visits for shifts that belong to their care home
CREATE POLICY "Users can create visits"
  ON visits
  FOR INSERT
  TO authenticated
  WITH CHECK (
    (carer_id = auth.uid())
    OR
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
        AND profiles.role = 'admin'::text
    )
    OR
    EXISTS (
      SELECT 1 FROM shifts s
      WHERE s.id = visits.shift_id
        AND s.client_organisation_id = (
          SELECT profiles.client_organisation_id FROM profiles
          WHERE profiles.id = auth.uid()
        )
        AND s.client_organisation_id IS NOT NULL
    )
  );

-- UPDATE policy
-- Allows:
--  1. Carers updating their own visits
--  2. Admins updating any visit
--  3. Client users updating visits for shifts that belong to their care home
CREATE POLICY "Users can update visits"
  ON visits
  FOR UPDATE
  TO authenticated
  USING (
    (carer_id = auth.uid())
    OR
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
        AND profiles.role = 'admin'::text
    )
    OR
    EXISTS (
      SELECT 1 FROM shifts s
      WHERE s.id = visits.shift_id
        AND s.client_organisation_id = (
          SELECT profiles.client_organisation_id FROM profiles
          WHERE profiles.id = auth.uid()
        )
        AND s.client_organisation_id IS NOT NULL
    )
  )
  WITH CHECK (
    (carer_id = auth.uid())
    OR
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
        AND profiles.role = 'admin'::text
    )
    OR
    EXISTS (
      SELECT 1 FROM shifts s
      WHERE s.id = visits.shift_id
        AND s.client_organisation_id = (
          SELECT profiles.client_organisation_id FROM profiles
          WHERE profiles.id = auth.uid()
        )
        AND s.client_organisation_id IS NOT NULL
    )
  );

-- SELECT policy
-- Allows:
--  1. Carers viewing their own visits
--  2. Admins viewing all
--  3. Client users viewing visits for shifts that belong to their care home
CREATE POLICY "Users can view visits"
  ON visits
  FOR SELECT
  TO authenticated
  USING (
    (carer_id = auth.uid())
    OR
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
        AND profiles.role = 'admin'::text
    )
    OR
    EXISTS (
      SELECT 1 FROM shifts s
      WHERE s.id = visits.shift_id
        AND s.client_organisation_id = (
          SELECT profiles.client_organisation_id FROM profiles
          WHERE profiles.id = auth.uid()
        )
        AND s.client_organisation_id IS NOT NULL
    )
    OR
    (organisation_id IS NULL)
  );