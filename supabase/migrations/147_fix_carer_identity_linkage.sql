-- ============================================================
-- MIGRATION 147: Fix carer identity linkage for staff-app
--
-- Problem: carers.id does not always equal auth.users.id.
-- Legacy carers created by admin have carers.id = some UUID
-- but the carer logs in with a DIFFERENT auth.users.id.
-- The staff-app queries shifts/routes/route_visits WHERE 
-- carer_id = auth.uid(), which returns nothing.
--
-- Fix: Add auth_user_id column directly linking carers to
-- auth.users. Backfill where possible. Update RLS policies.
-- ============================================================

-- 1. Add auth_user_id to carers
ALTER TABLE public.carers 
  ADD COLUMN IF NOT EXISTS auth_user_id UUID REFERENCES auth.users(id);

CREATE INDEX IF NOT EXISTS idx_carers_auth_user_id 
  ON public.carers(auth_user_id) WHERE auth_user_id IS NOT NULL;

-- 2. Backfill auth_user_id for carers who have a matching 
--    profiles row (carers.id should equal profiles.id = auth.users.id 
--    for properly created carers)
UPDATE public.carers c
SET auth_user_id = c.id
WHERE c.auth_user_id IS NULL
  AND EXISTS (SELECT 1 FROM auth.users u WHERE u.id = c.id);

-- 3. For remaining legacy carers where carers.id does not match any
--    auth.users.id, manual linking is required. Run this diagnostic
--    query to find all carers that need manual linking:
--
--    SELECT c.id AS carer_id, c.name AS carer_name, c.employee_number,
--           c.organisation_id, c.auth_user_id
--    FROM public.carers c
--    WHERE c.auth_user_id IS NULL;
--
--    For each unmatched carer, find their auth user by name/email in
--    auth.users and run:
--
--    UPDATE public.carers
--    SET auth_user_id = '<their-auth-users-id>'
--    WHERE id = '<their-carers-id>';

-- 4. Update RLS on shifts to use the resolved auth_user_id
DROP POLICY IF EXISTS "Carers can view their own shifts" ON public.shifts;
CREATE POLICY "Carers can view their own shifts" 
  ON public.shifts FOR SELECT TO authenticated
  USING (
    -- Direct match (works for properly linked carers)
    carer_id = auth.uid()
    OR
    -- Legacy carers: check through carers.auth_user_id
    EXISTS (
      SELECT 1 FROM public.carers c
      WHERE c.id = shifts.carer_id
        AND c.auth_user_id = auth.uid()
    )
    OR auth.uid() IN (SELECT id FROM public.profiles WHERE role = 'admin')
    OR organisation_id IS NULL
  );

-- 5. Update RLS on routes to use the resolved auth_user_id
DROP POLICY IF EXISTS "Carers can view their own routes" ON public.routes;
CREATE POLICY "Carers can view their own routes" 
  ON public.routes FOR SELECT TO authenticated
  USING (
    carer_id = auth.uid()
    OR second_carer_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.carers c
      WHERE c.id = routes.carer_id AND c.auth_user_id = auth.uid()
    )
    OR EXISTS (
      SELECT 1 FROM public.carers c
      WHERE c.id = routes.second_carer_id AND c.auth_user_id = auth.uid()
    )
  );

-- 6. Update RLS on route_visits to use the resolved auth_user_id
DROP POLICY IF EXISTS "Carers can view their own route visits" ON public.route_visits;
CREATE POLICY "Carers can view their own route visits" 
  ON public.route_visits FOR SELECT TO authenticated
  USING (
    -- Direct per-visit assignment
    carer_id = auth.uid()
    OR
    -- Legacy carer direct assignment
    EXISTS (
      SELECT 1 FROM public.carers c
      WHERE c.id = route_visits.carer_id AND c.auth_user_id = auth.uid()
    )
    OR
    -- Route-level assignment (primary or second carer)
    (route_id IS NOT NULL AND EXISTS (
      SELECT 1 FROM public.routes r
      WHERE r.id = route_visits.route_id
        AND (
          r.carer_id = auth.uid() 
          OR r.second_carer_id = auth.uid()
          OR EXISTS (
            SELECT 1 FROM public.carers c
            WHERE c.id = r.carer_id AND c.auth_user_id = auth.uid()
          )
          OR EXISTS (
            SELECT 1 FROM public.carers c
            WHERE c.id = r.second_carer_id AND c.auth_user_id = auth.uid()
          )
        )
    ))
  );

-- 7. Notify PostgREST
NOTIFY pgrst, 'reload schema';