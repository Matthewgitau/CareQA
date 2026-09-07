-- ============================================================
-- MIGRATION 137: Route Visits & Change Tracking
--
-- Introduces:
--   - route_visits       : the core per-service-user visit
--     schedule table. Visit times, duration, carer assignment,
--     status and respite are tracked per visit so last-minute
--     changes & temporary route merges are easy.
--   - route_change_log   : full audit trail of every change made
--     to visits/routes (time adjusted, carer assigned, route
--     merged/split, cancelled, respite toggled, etc.).
--
-- Also converts `routes` into a lightweight route *container*:
-- a named grouping of visits on a given day, so routes can be
-- created, merged and managed without being tied to a single
-- service user.
-- ============================================================

-- ------------------------------------------------------------
-- 1. Convert `routes` into a route container
-- ------------------------------------------------------------
ALTER TABLE public.routes ALTER COLUMN service_user_id DROP NOT NULL;
ALTER TABLE public.routes ALTER COLUMN proposed_start_time DROP NOT NULL;
ALTER TABLE public.routes ALTER COLUMN proposed_end_time DROP NOT NULL;

ALTER TABLE public.routes ADD COLUMN IF NOT EXISTS name TEXT;
ALTER TABLE public.routes ADD COLUMN IF NOT EXISTS route_date DATE;
ALTER TABLE public.routes ADD COLUMN IF NOT EXISTS merged_into_route_id UUID REFERENCES public.routes(id) ON DELETE SET NULL;

-- ------------------------------------------------------------
-- 2. route_visits — the core visit schedule
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.route_visits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_organisation_id UUID NOT NULL REFERENCES public.client_organisations(id) ON DELETE CASCADE,
    route_id UUID REFERENCES public.routes(id) ON DELETE SET NULL,
    service_user_id UUID NOT NULL REFERENCES public.service_users(id) ON DELETE CASCADE,
    carer_id UUID REFERENCES public.carers(id) ON DELETE SET NULL,
    visit_date DATE NOT NULL,
    visit_time TIMESTAMPTZ NOT NULL,
    duration_minutes INTEGER NOT NULL DEFAULT 60,
    status TEXT NOT NULL DEFAULT 'scheduled'
        CHECK (status IN ('scheduled', 'in_progress', 'completed', 'cancelled', 'merged')),
    respite BOOLEAN NOT NULL DEFAULT FALSE,
    requires_two_carers BOOLEAN NOT NULL DEFAULT FALSE,
    sort_order INTEGER NOT NULL DEFAULT 1,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_route_visits_client_org ON public.route_visits(client_organisation_id);
CREATE INDEX IF NOT EXISTS idx_route_visits_route ON public.route_visits(route_id);
CREATE INDEX IF NOT EXISTS idx_route_visits_service_user ON public.route_visits(service_user_id);
CREATE INDEX IF NOT EXISTS idx_route_visits_carer ON public.route_visits(carer_id);
CREATE INDEX IF NOT EXISTS idx_route_visits_date ON public.route_visits(client_organisation_id, visit_date, visit_time);

ALTER TABLE public.route_visits ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view route visits for their organisation" ON public.route_visits;
CREATE POLICY "Users can view route visits for their organisation"
    ON public.route_visits FOR SELECT TO authenticated
    USING (
        client_organisation_id = (
            SELECT client_organisation_id FROM public.profiles WHERE id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Users can insert route visits for their organisation" ON public.route_visits;
CREATE POLICY "Users can insert route visits for their organisation"
    ON public.route_visits FOR INSERT TO authenticated
    WITH CHECK (
        client_organisation_id = (
            SELECT client_organisation_id FROM public.profiles WHERE id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Users can update route visits for their organisation" ON public.route_visits;
CREATE POLICY "Users can update route visits for their organisation"
    ON public.route_visits FOR UPDATE TO authenticated
    USING (
        client_organisation_id = (
            SELECT client_organisation_id FROM public.profiles WHERE id = auth.uid()
        )
    )
    WITH CHECK (
        client_organisation_id = (
            SELECT client_organisation_id FROM public.profiles WHERE id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Users can delete route visits for their organisation" ON public.route_visits;
CREATE POLICY "Users can delete route visits for their organisation"
    ON public.route_visits FOR DELETE TO authenticated
    USING (
        client_organisation_id = (
            SELECT client_organisation_id FROM public.profiles WHERE id = auth.uid()
        )
    );

-- updated_at trigger
CREATE OR REPLACE FUNCTION update_route_visits_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_route_visits_updated_at ON public.route_visits;
CREATE TRIGGER update_route_visits_updated_at
    BEFORE UPDATE ON public.route_visits
    FOR EACH ROW
    EXECUTE FUNCTION update_route_visits_updated_at();

-- ------------------------------------------------------------
-- 3. route_change_log — full audit trail
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.route_change_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_organisation_id UUID NOT NULL REFERENCES public.client_organisations(id) ON DELETE CASCADE,
    visit_id UUID REFERENCES public.route_visits(id) ON DELETE SET NULL,
    route_id UUID REFERENCES public.routes(id) ON DELETE SET NULL,
    changed_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    change_type TEXT NOT NULL
        CHECK (change_type IN (
            'visit_created', 'visit_deleted',
            'time_adjusted', 'date_changed',
            'carer_assigned', 'carer_unassigned',
            'route_created', 'route_merged', 'route_split',
            'cancelled', 'respite_toggled'
        )),
    description TEXT,
    old_value JSONB,
    new_value JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_route_change_log_org ON public.route_change_log(client_organisation_id, created_at);
CREATE INDEX IF NOT EXISTS idx_route_change_log_visit ON public.route_change_log(visit_id);
CREATE INDEX IF NOT EXISTS idx_route_change_log_route ON public.route_change_log(route_id);

ALTER TABLE public.route_change_log ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view change log for their organisation" ON public.route_change_log;
CREATE POLICY "Users can view change log for their organisation"
    ON public.route_change_log FOR SELECT TO authenticated
    USING (
        client_organisation_id = (
            SELECT client_organisation_id FROM public.profiles WHERE id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Users can insert change log for their organisation" ON public.route_change_log;
CREATE POLICY "Users can insert change log for their organisation"
    ON public.route_change_log FOR INSERT TO authenticated
    WITH CHECK (
        client_organisation_id = (
            SELECT client_organisation_id FROM public.profiles WHERE id = auth.uid()
        )
    );

-- ------------------------------------------------------------
-- 4. Notify PostgREST
-- ------------------------------------------------------------
NOTIFY pgrst, 'reload schema';