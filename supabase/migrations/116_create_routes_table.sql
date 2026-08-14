-- ============================================================
-- MIGRATION 116: Create routes table for planned call times
-- ============================================================

-- 1. Create the routes table
CREATE TABLE IF NOT EXISTS public.routes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_organisation_id UUID NOT NULL REFERENCES public.client_organisations(id) ON DELETE CASCADE,
    service_user_id UUID NOT NULL REFERENCES public.service_users(id) ON DELETE CASCADE,
    carer_id UUID REFERENCES public.carers(id) ON DELETE SET NULL,
    proposed_start_time TIMESTAMPTZ NOT NULL,
    proposed_end_time TIMESTAMPTZ NOT NULL,
    actual_start_time TIMESTAMPTZ,
    actual_end_time TIMESTAMPTZ,
    respite BOOLEAN DEFAULT FALSE,
    call_number INTEGER NOT NULL,  -- e.g., 1st call of the day
    status TEXT NOT NULL DEFAULT 'scheduled'
        CHECK (status IN ('scheduled', 'in_progress', 'completed', 'cancelled')),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Add indexes for performance
CREATE INDEX idx_routes_client_organisation_id ON public.routes(client_organisation_id);
CREATE INDEX idx_routes_service_user_id ON public.routes(service_user_id);
CREATE INDEX idx_routes_carer_id ON public.routes(carer_id);
CREATE INDEX idx_routes_proposed_start_time ON public.routes(proposed_start_time);
CREATE INDEX idx_routes_status ON public.routes(status);

-- 3. Enable RLS
ALTER TABLE public.routes ENABLE ROW LEVEL SECURITY;

-- 4. RLS Policies
--   - Users can SELECT routes belonging to their client_organisation
--   - Users can INSERT routes for their client_organisation
--   - Users can UPDATE/ DELETE routes they own (based on client_organisation)

CREATE POLICY "Users can view their own routes"
    ON public.routes
    FOR SELECT
    TO authenticated
    USING (
        client_organisation_id = (
            SELECT client_organisation_id
            FROM public.profiles
            WHERE id = auth.uid()
        )
    );

CREATE POLICY "Users can insert routes for their organisation"
    ON public.routes
    FOR INSERT
    TO authenticated
    WITH CHECK (
        client_organisation_id = (
            SELECT client_organisation_id
            FROM public.profiles
            WHERE id = auth.uid()
        )
    );

CREATE POLICY "Users can update their own routes"
    ON public.routes
    FOR UPDATE
    TO authenticated
    USING (
        client_organisation_id = (
            SELECT client_organisation_id
            FROM public.profiles
            WHERE id = auth.uid()
        )
    )
    WITH CHECK (
        client_organisation_id = (
            SELECT client_organisation_id
            FROM public.profiles
            WHERE id = auth.uid()
        )
    );

CREATE POLICY "Users can delete their own routes"
    ON public.routes
    FOR DELETE
    TO authenticated
    USING (
        client_organisation_id = (
            SELECT client_organisation_id
            FROM public.profiles
            WHERE id = auth.uid()
        )
    );

-- 5. Trigger to auto-update updated_at
CREATE OR REPLACE FUNCTION update_routes_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_routes_updated_at
    BEFORE UPDATE ON public.routes
    FOR EACH ROW
    EXECUTE FUNCTION update_routes_updated_at();

-- 6. Notify PostgREST of schema change
NOTIFY pgrst, 'reload schema';