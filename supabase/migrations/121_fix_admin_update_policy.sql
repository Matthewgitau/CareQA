-- Fix admin update policy for shifts table
-- The policy needs a WITH CHECK clause to allow updates

-- Drop the existing policy
DROP POLICY IF EXISTS "Admins can manage all shifts" ON shifts;

-- Recreate with proper USING and WITH CHECK clauses
CREATE POLICY "Admins can manage all shifts"
  ON shifts
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM profiles
      WHERE (profiles.id = auth.uid() AND profiles.role = 'admin'::text)
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM profiles
      WHERE (profiles.id = auth.uid() AND profiles.role = 'admin'::text)
    )
  );