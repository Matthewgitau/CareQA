-- ============================================================
-- MIGRATION 138: Add respite/hospital/holiday flags to service_user_calls
--
-- These toggles allow tracking of visits that should NOT count
-- toward billable/hour totals (respite, hospitalisation, holiday),
-- while still being recorded for documentation & invoicing accuracy.
-- ============================================================

ALTER TABLE public.service_user_calls
  ADD COLUMN IF NOT EXISTS respite BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS hospital BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS holiday BOOLEAN NOT NULL DEFAULT FALSE;

NOTIFY pgrst, 'reload schema';