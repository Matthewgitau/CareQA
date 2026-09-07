-- ============================================================
-- MIGRATION 140: Route second carer & driver mode
--
-- Supports the scenario where two carers are assigned to a route
-- and we need to track who was driving (or if both drove to the
-- location) for mileage attribution.
-- ============================================================

ALTER TABLE public.routes
  ADD COLUMN IF NOT EXISTS second_carer_id UUID REFERENCES public.carers(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS second_carer_is_driver BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS driver_mode TEXT NOT NULL DEFAULT 'primary'
    CHECK (driver_mode IN ('primary', 'second', 'both'));

CREATE INDEX IF NOT EXISTS idx_routes_second_carer ON public.routes(second_carer_id);

NOTIFY pgrst, 'reload schema';