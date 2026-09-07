-- ============================================================
-- MIGRATION 143: Audit log for planned-call flags
--
-- service_user_call_log is the definitive legal record for why a
-- planned call was omitted from the rota (e.g. a hospital stay),
-- covering duty-of-care documentation and billing justification.
-- It records every toggle of the respite / hospital / holiday flags
-- on service_user_calls, with a timestamp and the user who changed it.
--
-- Intentionally SEPARATE from route_change_log: that table tracks what
-- ACTUALLY happened (visit execution), whereas this table tracks changes
-- to the PLANNED schedule (exclusions).
-- ============================================================

CREATE TABLE IF NOT EXISTS public.service_user_call_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    call_id UUID NOT NULL REFERENCES public.service_user_calls(id) ON DELETE CASCADE,
    changed_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    flag_type TEXT NOT NULL CHECK (flag_type IN ('respite', 'hospital', 'holiday')),
    old_value BOOLEAN,
    new_value BOOLEAN NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    organisation_id UUID REFERENCES public.organisations(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_service_user_call_log_call_id ON public.service_user_call_log(call_id);
CREATE INDEX IF NOT EXISTS idx_service_user_call_log_created_at ON public.service_user_call_log(created_at);

ALTER TABLE public.service_user_call_log ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view service user call logs for their org" ON public.service_user_call_log;
CREATE POLICY "Users can view service user call logs for their org" ON public.service_user_call_log
    FOR SELECT TO authenticated
    USING (
        organisation_id = (
            SELECT organisation_id FROM public.profiles WHERE id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Users can insert service user call logs for their org" ON public.service_user_call_log;
CREATE POLICY "Users can insert service user call logs for their org" ON public.service_user_call_log
    FOR INSERT TO authenticated
    WITH CHECK (
        organisation_id = (
            SELECT organisation_id FROM public.profiles WHERE id = auth.uid()
        )
    );

NOTIFY pgrst, 'reload schema';