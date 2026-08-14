-- ============================================================
-- MIGRATION 118: Create Preferred Supplier List (PSL) table
-- For multi-agency shift broadcasting
-- ============================================================

-- 1. Create client_organisation_psl table
CREATE TABLE IF NOT EXISTS public.client_organisation_psl (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_org_id UUID NOT NULL REFERENCES public.organisations(id) ON DELETE CASCADE,
    organisation_id UUID NOT NULL REFERENCES public.organisations(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'active'
        CHECK (status IN ('active', 'suspended', 'removed')),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(client_org_id, organisation_id)
);

-- 2. Add indexes for performance
CREATE INDEX idx_client_organisation_psl_client_org 
  ON public.client_organisation_psl(client_org_id);

CREATE INDEX idx_client_organisation_psl_organisation 
  ON public.client_organisation_psl(organisation_id);

CREATE INDEX idx_client_organisation_psl_status 
  ON public.client_organisation_psl(status);

-- 3. Enable RLS
ALTER TABLE public.client_organisation_psl ENABLE ROW LEVEL SECURITY;

-- 4. RLS Policies

-- Clients can view their own PSL
CREATE POLICY "Clients can view their PSL"
    ON public.client_organisation_psl
    FOR SELECT
    TO authenticated
    USING (
        client_org_id = (
            SELECT client_organisation_id 
            FROM public.profiles 
            WHERE id = auth.uid()
        )
    );

-- Clients can manage their PSL (add/remove agencies)
CREATE POLICY "Clients can manage their PSL"
    ON public.client_organisation_psl
    FOR ALL
    TO authenticated
    USING (
        client_org_id = (
            SELECT client_organisation_id 
            FROM public.profiles 
            WHERE id = auth.uid()
        )
    );

-- Agencies can view which clients have them in PSL
CREATE POLICY "Agencies can view their PSL status"
    ON public.client_organisation_psl
    FOR SELECT
    TO authenticated
    USING (
        organisation_id = (
            SELECT organisation_id 
            FROM public.profiles 
            WHERE id = auth.uid()
        )
    );

-- 5. Trigger to auto-update updated_at
CREATE OR REPLACE FUNCTION update_client_organisation_psl_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_client_organisation_psl_updated_at
    BEFORE UPDATE ON public.client_organisation_psl
    FOR EACH ROW
    EXECUTE FUNCTION update_client_organisation_psl_updated_at();

-- 6. Notify PostgREST of schema change
NOTIFY pgrst, 'reload schema';