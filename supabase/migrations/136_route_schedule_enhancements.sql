-- ============================================================
-- MIGRATION 136: Route Schedule enhancements
-- Adds requires_two_carers to routes for the Route Schedule fix
-- ============================================================

ALTER TABLE public.routes
  ADD COLUMN IF NOT EXISTS requires_two_carers BOOLEAN DEFAULT FALSE;

NOTIFY pgrst, 'reload schema';