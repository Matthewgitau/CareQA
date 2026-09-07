-- ============================================================
-- 160_stripe_events_debug.sql
--
-- Adds debug columns to stripe_events so the webhook handler can
-- leave a trace of WHICH customer/session it received when it
-- can't resolve an organisation_id. Helps diagnose:
--   * "payment succeeded but org never unlocked"
--   * empty stripe_events despite Stripe delivering events
-- ============================================================
ALTER TABLE public.stripe_events
  ADD COLUMN IF NOT EXISTS customer_email TEXT,
  ADD COLUMN IF NOT EXISTS session_id TEXT;

NOTIFY pgrst, 'reload schema';