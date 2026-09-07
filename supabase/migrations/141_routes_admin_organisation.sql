-- ============================================================
-- MIGRATION 141: Multi-tenant organisation support for routes
--
-- Adds `organisation_id` to routes, route_visits, and
-- route_change_log so ADMIN/STAFF users (who have
-- `organisation_id` set but `client_organisation_id` = NULL)
-- can create and manage routes.
--
-- RLS policies are updated to accept EITHER:
--   - organisation_id = profiles.organisation_id  (admin/staff)
--   - client_organisation_id = profiles.client_organisation_id  (client-app)
--
-- existing client-app rows keep client_organisation_id.
-- ============================================================

-- ------------------------------------------------------------
-- 1. routes — add organisation_id, make client_organisation_id nullable
-- ------------------------------------------------------------
ALTER TABLE public.routes
  ADD COLUMN IF NOT EXISTS organisation_id UUID REFERENCES public.organisations(id) ON DELETE CASCADE;

ALTER TABLE public.routes ALTER COLUMN client_organisation_id DROP NOT NULL;

CREATE INDEX IF NOT EXISTS idx_routes_organisation_id ON public.routes(organisation_id);

-- ------------------------------------------------------------
-- 2. route_visits — add organisation_id, make client_organisation_id nullable
-- ------------------------------------------------------------
ALTER TABLE public.route_visits
  ADD COLUMN IF NOT EXISTS organisation_id UUID REFERENCES public.organisations(id) ON DELETE CASCADE;

ALTER TABLE public.route_visits ALTER COLUMN client_organisation_id DROP NOT NULL;

CREATE INDEX IF NOT EXISTS idx_route_visits_organisation_id ON public.route_visits(organisation_id);

-- ------------------------------------------------------------
-- 3. route_change_log — add organisation_id, make client_organisation_id nullable
-- ------------------------------------------------------------
ALTER TABLE public.route_change_log
  ADD COLUMN IF NOT EXISTS organisation_id UUID REFERENCES public.organisations(id) ON DELETE CASCADE;

ALTER TABLE public.route_change_log ALTER COLUMN client_organisation_id DROP NOT NULL;

CREATE INDEX IF NOT EXISTS idx_route_change_log_organisation_id ON public.route_change_log(organisation_id);

-- ------------------------------------------------------------
-- 4. RLS policies on routes
-- ------------------------------------------------------------
DROP POLICY IF EXISTS "Users can view their own routes" ON public.routes;
CREATE POLICY "Users can view their own routes"
    ON public.routes FOR SELECT TO authenticated
    USING (
        (organisation_id IS NOT NULL AND organisation_id = (
            SELECT organisation_id FROM public.profiles WHERE id = auth.uid()
        ))
        OR
        (client_organisation_id IS NOT NULL AND client_organisation_id = (
            SELECT client_organisation_id FROM public.profiles WHERE id = auth.uid()
        ))
    );

DROP POLICY IF EXISTS "Users can insert routes for their organisation" ON public.routes;
CREATE POLICY "Users can insert routes for their organisation"
    ON public.routes FOR INSERT TO authenticated
    WITH CHECK (
        (organisation_id IS NOT NULL AND organisation_id = (
            SELECT organisation_id FROM public.profiles WHERE id = auth.uid()
        ))
        OR
        (client_organisation_id IS NOT NULL AND client_organisation_id = (
            SELECT client_organisation_id FROM public.profiles WHERE id = auth.uid()
        ))
    );

DROP POLICY IF EXISTS "Users can update their own routes" ON public.routes;
CREATE POLICY "Users can update their own routes"
    ON public.routes FOR UPDATE TO authenticated
    USING (
        (organisation_id IS NOT NULL AND organisation_id = (
            SELECT organisation_id FROM public.profiles WHERE id = auth.uid()
        ))
        OR
        (client_organisation_id IS NOT NULL AND client_organisation_id = (
            SELECT client_organisation_id FROM public.profiles WHERE id = auth.uid()
        ))
    )
    WITH CHECK (
        (organisation_id IS NOT NULL AND organisation_id = (
            SELECT organisation_id FROM public.profiles WHERE id = auth.uid()
        ))
        OR
        (client_organisation_id IS NOT NULL AND client_organisation_id = (
            SELECT client_organisation_id FROM public.profiles WHERE id = auth.uid()
        ))
    );

DROP POLICY IF EXISTS "Users can delete their own routes" ON public.routes;
CREATE POLICY "Users can delete their own routes"
    ON public.routes FOR DELETE TO authenticated
    USING (
        (organisation_id IS NOT NULL AND organisation_id = (
            SELECT organisation_id FROM public.profiles WHERE id = auth.uid()
        ))
        OR
        (client_organisation_id IS NOT NULL AND client_organisation_id = (
            SELECT client_organisation_id FROM public.profiles WHERE id = auth.uid()
        ))
    );

-- ------------------------------------------------------------
-- 5. RLS policies on route_visits
-- ------------------------------------------------------------
DROP POLICY IF EXISTS "Users can view route visits for their organisation" ON public.route_visits;
CREATE POLICY "Users can view route visits for their organisation"
    ON public.route_visits FOR SELECT TO authenticated
    USING (
        (organisation_id IS NOT NULL AND organisation_id = (
            SELECT organisation_id FROM public.profiles WHERE id = auth.uid()
        ))
        OR
        (client_organisation_id IS NOT NULL AND client_organisation_id = (
            SELECT client_organisation_id FROM public.profiles WHERE id = auth.uid()
        ))
    );

DROP POLICY IF EXISTS "Users can insert route visits for their organisation" ON public.route_visits;
CREATE POLICY "Users can insert route visits for their organisation"
    ON public.route_visits FOR INSERT TO authenticated
    WITH CHECK (
        (organisation_id IS NOT NULL AND organisation_id = (
            SELECT organisation_id FROM public.profiles WHERE id = auth.uid()
        ))
        OR
        (client_organisation_id IS NOT NULL AND client_organisation_id = (
            SELECT client_organisation_id FROM public.profiles WHERE id = auth.uid()
        ))
    );

DROP POLICY IF EXISTS "Users can update route visits for their organisation" ON public.route_visits;
CREATE POLICY "Users can update route visits for their organisation"
    ON public.route_visits FOR UPDATE TO authenticated
    USING (
        (organisation_id IS NOT NULL AND organisation_id = (
            SELECT organisation_id FROM public.profiles WHERE id = auth.uid()
        ))
        OR
        (client_organisation_id IS NOT NULL AND client_organisation_id = (
            SELECT client_organisation_id FROM public.profiles WHERE id = auth.uid()
        ))
    )
    WITH CHECK (
        (organisation_id IS NOT NULL AND organisation_id = (
            SELECT organisation_id FROM public.profiles WHERE id = auth.uid()
        ))
        OR
        (client_organisation_id IS NOT NULL AND client_organisation_id = (
            SELECT client_organisation_id FROM public.profiles WHERE id = auth.uid()
        ))
    );

DROP POLICY IF EXISTS "Users can delete route visits for their organisation" ON public.route_visits;
CREATE POLICY "Users can delete route visits for their organisation"
    ON public.route_visits FOR DELETE TO authenticated
    USING (
        (organisation_id IS NOT NULL AND organisation_id = (
            SELECT organisation_id FROM public.profiles WHERE id = auth.uid()
        ))
        OR
        (client_organisation_id IS NOT NULL AND client_organisation_id = (
            SELECT client_organisation_id FROM public.profiles WHERE id = auth.uid()
        ))
    );

-- ------------------------------------------------------------
-- 6. RLS policies on route_change_log
-- ------------------------------------------------------------
DROP POLICY IF EXISTS "Users can view change log for their organisation" ON public.route_change_log;
CREATE POLICY "Users can view change log for their organisation"
    ON public.route_change_log FOR SELECT TO authenticated
    USING (
        (organisation_id IS NOT NULL AND organisation_id = (
            SELECT organisation_id FROM public.profiles WHERE id = auth.uid()
        ))
        OR
        (client_organisation_id IS NOT NULL AND client_organisation_id = (
            SELECT client_organisation_id FROM public.profiles WHERE id = auth.uid()
        ))
    );

DROP POLICY IF EXISTS "Users can insert change log for their organisation" ON public.route_change_log;
CREATE POLICY "Users can insert change log for their organisation"
    ON public.route_change_log FOR INSERT TO authenticated
    WITH CHECK (
        (organisation_id IS NOT NULL AND organisation_id = (
            SELECT organisation_id FROM public.profiles WHERE id = auth.uid()
        ))
        OR
        (client_organisation_id IS NOT NULL AND client_organisation_id = (
            SELECT client_organisation_id FROM public.profiles WHERE id = auth.uid()
        ))
    );

-- ------------------------------------------------------------
-- 7. Notify PostgREST
-- ------------------------------------------------------------
NOTIFY pgrst, 'reload schema';