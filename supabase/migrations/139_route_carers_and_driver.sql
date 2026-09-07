-- ============================================================
-- MIGRATION 139: Route container carer assignment & driver flag
--
-- A Dom Care Route is a named cluster of service users. A carer
-- is assigned to the route per day (day-by-day) and can be tagged
-- as the DRIVER so mileage can later be attributed to the right
-- person for invoicing.
-- ============================================================

ALTER TABLE public.routes
  ADD COLUMN IF NOT EXISTS carer_id UUID REFERENCES public.carers(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS is_driver BOOLEAN NOT NULL DEFAULT FALSE;

CREATE INDEX IF NOT EXISTS idx_routes_carer_id ON public.routes(carer_id);

NOTIFY pgrst, 'reload schema';