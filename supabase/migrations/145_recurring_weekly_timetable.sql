-- ============================================================
-- MIGRATION 145: Recurring weekly timetable + permanent route membership
--
-- Model change: a service user has a GLOBAL weekly timetable
-- (per weekday -> list of call times). A route is a PERMANENT group of
-- service users and simply applies each member's weekly timetable.
-- This makes routes recurring (continuous) by default, with per-weekday
-- customisation (e.g. 2 calls Monday, 4 calls Tuesday).
-- ============================================================

-- 1. Per-service-user weekly timetable.
--    weekday 1..7 maps to Dart's DateTime.weekday (Monday=1 .. Sunday=7).
CREATE TABLE IF NOT EXISTS public.service_user_weekly_calls (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    service_user_id UUID NOT NULL REFERENCES public.service_users(id) ON DELETE CASCADE,
    weekday SMALLINT NOT NULL CHECK (weekday BETWEEN 1 AND 7),
    call_times JSONB NOT NULL DEFAULT '[]'::jsonb,  -- e.g. ["06:14","11:14"]
    duration_minutes INTEGER NOT NULL DEFAULT 60,
    organisation_id UUID REFERENCES public.organisations(id) ON DELETE CASCADE,
    UNIQUE (service_user_id, weekday)
);

CREATE INDEX IF NOT EXISTS idx_service_user_weekly_su
    ON public.service_user_weekly_calls(service_user_id);

-- 2. Permanent route membership (which service users belong to a route).
CREATE TABLE IF NOT EXISTS public.route_service_users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    route_id UUID NOT NULL REFERENCES public.routes(id) ON DELETE CASCADE,
    service_user_id UUID NOT NULL REFERENCES public.service_users(id) ON DELETE CASCADE,
    organisation_id UUID REFERENCES public.organisations(id) ON DELETE CASCADE,
    UNIQUE (route_id, service_user_id)
);

CREATE INDEX IF NOT EXISTS idx_route_service_users_route
    ON public.route_service_users(route_id);
CREATE INDEX IF NOT EXISTS idx_route_service_users_su
    ON public.route_service_users(service_user_id);

-- 3. Recurring flags on routes (route is permanent by default).
ALTER TABLE public.routes ADD COLUMN IF NOT EXISTS is_recurring BOOLEAN NOT NULL DEFAULT TRUE;
ALTER TABLE public.routes ADD COLUMN IF NOT EXISTS starts_on DATE;
ALTER TABLE public.routes ADD COLUMN IF NOT EXISTS ends_on DATE;  -- NULL = indefinite

-- 4. RLS (organisation-scoped, matching the other tables).
ALTER TABLE public.service_user_weekly_calls ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.route_service_users ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view weekly calls for their org" ON public.service_user_weekly_calls;
CREATE POLICY "Users can view weekly calls for their org" ON public.service_user_weekly_calls
    FOR SELECT TO authenticated
    USING (organisation_id = (SELECT organisation_id FROM public.profiles WHERE id = auth.uid()));

DROP POLICY IF EXISTS "Users can insert weekly calls for their org" ON public.service_user_weekly_calls;
CREATE POLICY "Users can insert weekly calls for their org" ON public.service_user_weekly_calls
    FOR INSERT TO authenticated
    WITH CHECK (organisation_id = (SELECT organisation_id FROM public.profiles WHERE id = auth.uid()));

DROP POLICY IF EXISTS "Users can delete weekly calls for their org" ON public.service_user_weekly_calls;
CREATE POLICY "Users can delete weekly calls for their org" ON public.service_user_weekly_calls
    FOR DELETE TO authenticated
    USING (organisation_id = (SELECT organisation_id FROM public.profiles WHERE id = auth.uid()));

DROP POLICY IF EXISTS "Users can view route members for their org" ON public.route_service_users;
CREATE POLICY "Users can view route members for their org" ON public.route_service_users
    FOR SELECT TO authenticated
    USING (organisation_id = (SELECT organisation_id FROM public.profiles WHERE id = auth.uid()));

DROP POLICY IF EXISTS "Users can insert route members for their org" ON public.route_service_users;
CREATE POLICY "Users can insert route members for their org" ON public.route_service_users
    FOR INSERT TO authenticated
    WITH CHECK (organisation_id = (SELECT organisation_id FROM public.profiles WHERE id = auth.uid()));

DROP POLICY IF EXISTS "Users can delete route members for their org" ON public.route_service_users;
CREATE POLICY "Users can delete route members for their org" ON public.route_service_users
    FOR DELETE TO authenticated
    USING (organisation_id = (SELECT organisation_id FROM public.profiles WHERE id = auth.uid()));

NOTIFY pgrst, 'reload schema';