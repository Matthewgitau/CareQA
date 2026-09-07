-- ============================================================
-- MIGRATION 144: Service-user "away" status timeline + body-map assessments
--
-- service_user_statuses is the authoritative, append-only record of each
-- away period (hospital / respite / holiday) with a start and end time and
-- the staff member who opened/closed it. This is the compliance timeline an
-- inspector can read: "Mrs X was in hospital from Mon 14:00 until Thu 09:00".
--
-- body_map_assessments records the skin check that happens on RETURN, so any
-- new mark/bruise is documented as "not there before, there after" (liability).
-- ============================================================

-- 1. Away periods (one open period per service user at a time).
CREATE TABLE IF NOT EXISTS public.service_user_statuses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    service_user_id UUID NOT NULL REFERENCES public.service_users(id) ON DELETE CASCADE,
    status_type TEXT NOT NULL CHECK (status_type IN ('respite', 'hospital', 'holiday')),
    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    ended_at TIMESTAMPTZ,
    started_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    ended_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    reason TEXT,
    organisation_id UUID REFERENCES public.organisations(id) ON DELETE CASCADE
);

-- Mutual exclusivity: only one OPEN (ended_at IS NULL) period per user.
CREATE UNIQUE INDEX IF NOT EXISTS idx_service_user_statuses_one_open
    ON public.service_user_statuses(service_user_id)
    WHERE ended_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_service_user_statuses_user
    ON public.service_user_statuses(service_user_id, started_at DESC);

-- 2. Body-map skin-check on return.
CREATE TABLE IF NOT EXISTS public.body_map_assessments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    service_user_id UUID NOT NULL REFERENCES public.service_users(id) ON DELETE CASCADE,
    status_id UUID REFERENCES public.service_user_statuses(id) ON DELETE SET NULL,
    assessed_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    no_new_marks BOOLEAN NOT NULL DEFAULT TRUE,
    notes TEXT,
    marks JSONB NOT NULL DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    organisation_id UUID REFERENCES public.organisations(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_body_map_assessments_user
    ON public.body_map_assessments(service_user_id, created_at DESC);

-- 3. RLS (organisation-scoped, matching the other route/status tables).
ALTER TABLE public.service_user_statuses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.body_map_assessments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view statuses for their org" ON public.service_user_statuses;
CREATE POLICY "Users can view statuses for their org" ON public.service_user_statuses
    FOR SELECT TO authenticated
    USING (organisation_id = (SELECT organisation_id FROM public.profiles WHERE id = auth.uid()));

DROP POLICY IF EXISTS "Users can insert statuses for their org" ON public.service_user_statuses;
CREATE POLICY "Users can insert statuses for their org" ON public.service_user_statuses
    FOR INSERT TO authenticated
    WITH CHECK (organisation_id = (SELECT organisation_id FROM public.profiles WHERE id = auth.uid()));

DROP POLICY IF EXISTS "Users can update statuses for their org" ON public.service_user_statuses;
CREATE POLICY "Users can update statuses for their org" ON public.service_user_statuses
    FOR UPDATE TO authenticated
    USING (organisation_id = (SELECT organisation_id FROM public.profiles WHERE id = auth.uid()));

DROP POLICY IF EXISTS "Users can view body maps for their org" ON public.body_map_assessments;
CREATE POLICY "Users can view body maps for their org" ON public.body_map_assessments
    FOR SELECT TO authenticated
    USING (organisation_id = (SELECT organisation_id FROM public.profiles WHERE id = auth.uid()));

DROP POLICY IF EXISTS "Users can insert body maps for their org" ON public.body_map_assessments;
CREATE POLICY "Users can insert body maps for their org" ON public.body_map_assessments
    FOR INSERT TO authenticated
    WITH CHECK (organisation_id = (SELECT organisation_id FROM public.profiles WHERE id = auth.uid()));

NOTIFY pgrst, 'reload schema';