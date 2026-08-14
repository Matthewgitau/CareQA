-- Fix RLS policies on visits table to allow client users to submit timesheets
-- Client users (care home staff) need to INSERT/UPDATE visits for shifts in their care home

-- Drop existing restrictive INSERT policy
DROP POLICY IF EXISTS "Carers can create visits for own shifts" ON visits;

-- Create policies that allow both carers, admins, AND client users (care home staff)
-- Client users are identified by having client_organisation_id in their profiles

-- INSERT policy: carers can create for own shifts, admins all, clients for their care home
CREATE POLICY "Users can create visits"
  ON visits
  FOR INSERT
  TO authenticated
  WITH CHECK (
    (
      -- Carer inserting their own visit
      carer_id = auth.uid()
    )
    OR
    (
      -- Admin can insert any visit
      EXISTS (
        SELECT 1 FROM profiles
        WHERE profiles.id = auth.uid()
          AND profiles.role = 'admin'::text
      )
    )
    OR
    (
      -- Client user (care home) inserting for their own client_organisation_id
      client_organisation_id = (
        SELECT profiles.client_organisation_id FROM profiles
        WHERE profiles.id = auth.uid()
      )
      AND client_organisation_id IS NOT NULL
    )
  );

-- UPDATE policy: allow clients to update visits in their care home
DROP POLICY IF EXISTS "Carers can update own visits" ON visits;

CREATE POLICY "Users can update visits"
  ON visits
  FOR UPDATE
  TO authenticated
  USING (
    (
      carer_id = auth.uid()
    )
    OR
    (
      EXISTS (
        SELECT 1 FROM profiles
        WHERE profiles.id = auth.uid()
          AND profiles.role = 'admin'::text
      )
    )
    OR
    (
      client_organisation_id = (
        SELECT profiles.client_organisation_id FROM profiles
        WHERE profiles.id = auth.uid()
      )
      AND client_organisation_id IS NOT NULL
    )
  )
  WITH CHECK (
    (
      carer_id = auth.uid()
    )
    OR
    (
      EXISTS (
        SELECT 1 FROM profiles
        WHERE profiles.id = auth.uid()
          AND profiles.role = 'admin'::text
      )
    )
    OR
    (
      client_organisation_id = (
        SELECT profiles.client_organisation_id FROM profiles
        WHERE profiles.id = auth.uid()
      )
      AND client_organisation_id IS NOT NULL
    )
  );