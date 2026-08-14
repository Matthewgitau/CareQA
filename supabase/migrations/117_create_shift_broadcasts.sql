-- ============================================================
-- MIGRATION 117: Create shift_broadcasts table for multi-agency broadcasting
-- ============================================================

-- 1. Add broadcast_type to shifts table
ALTER TABLE public.shifts 
  ADD COLUMN IF NOT EXISTS broadcast_type TEXT DEFAULT 'single'
    CHECK (broadcast_type IN ('single', 'multiple', 'all'));

-- 2. Create shift_broadcasts table
CREATE TABLE IF NOT EXISTS public.shift_broadcasts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    shift_id UUID NOT NULL REFERENCES public.shifts(id) ON DELETE CASCADE,
    agency_id UUID NOT NULL REFERENCES public.organisations(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending', 'accepted', 'declined', 'expired')),
    responded_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(shift_id, agency_id)
);

-- 3. Add indexes
CREATE INDEX idx_shift_broadcasts_shift_id ON public.shift_broadcasts(shift_id);
CREATE INDEX idx_shift_broadcasts_agency_id ON public.shift_broadcasts(agency_id);
CREATE INDEX idx_shift_broadcasts_status ON public.shift_broadcasts(status);

-- 4. Enable RLS
ALTER TABLE public.shift_broadcasts ENABLE ROW LEVEL SECURITY;

-- 5. RLS Policies
CREATE POLICY "Clients can manage their shift broadcasts"
    ON public.shift_broadcasts
    FOR ALL
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.shifts
            WHERE shifts.id = shift_broadcasts.shift_id
            AND shifts.client_organisation_id = (
                SELECT client_organisation_id FROM public.profiles WHERE id = auth.uid()
            )
        )
    );

-- 6. Trigger to auto-update updated_at
CREATE OR REPLACE FUNCTION update_shift_broadcasts_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_shift_broadcasts_updated_at
    BEFORE UPDATE ON public.shift_broadcasts
    FOR EACH ROW
    EXECUTE FUNCTION update_shift_broadcasts_updated_at();

-- 7. Notify PostgREST of schema change
NOTIFY pgrst, 'reload schema';