-- ============================================================
-- MIGRATION 157: Subscription & paywall schema
--
-- Adds Stripe subscription / trial state to profiles and
-- organisations. The ORGANISATION is the billing entity:
--   * signup         -> organisations.subscription_status='incomplete'
--   * start-trial    -> 'trialing' + trial_started_at / trial_ends_at
--   * checkout paid  -> 'active'  (webhook)
--   * payment failed -> 'past_due' (webhook)
--   * cancelled      -> 'canceled' (webhook)
--
-- profiles mirrors the owner's billing state so the mobile app can
-- gate navigation quickly, but server-side checks (edge functions
-- and has_access()) read the organisation as source of truth.
-- ============================================================

-- ---- profiles ------------------------------------------------
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS subscription_status   TEXT,
  ADD COLUMN IF NOT EXISTS trial_started_at      TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS trial_ends_at         TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS stripe_customer_id    TEXT,
  ADD COLUMN IF NOT EXISTS stripe_subscription_id TEXT,
  ADD COLUMN IF NOT EXISTS subscription_plan     TEXT;

-- ---- organisations -------------------------------------------
ALTER TABLE public.organisations
  ADD COLUMN IF NOT EXISTS subscription_status   TEXT,
  ADD COLUMN IF NOT EXISTS trial_started_at      TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS trial_ends_at         TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS stripe_customer_id    TEXT,
  ADD COLUMN IF NOT EXISTS stripe_subscription_id TEXT,
  ADD COLUMN IF NOT EXISTS subscription_plan     TEXT;

-- Valid statuses: incomplete, trialing, active, past_due,
-- canceled, incomplete_expired, unpaid.
COMMENT ON COLUMN public.organisations.subscription_status IS
  'Stripe subscription status - the paywall gate reads this.';

COMMENT ON COLUMN public.profiles.subscription_status IS
  'Mirror of the owning organisation subscription status (for app UX).';

-- ---- Stripe webhook audit log --------------------------------
-- Append-only record of every Stripe event we process. Useful for
-- debugging webhook delivery in test mode.
CREATE TABLE IF NOT EXISTS public.stripe_events (
  id               BIGSERIAL PRIMARY KEY,
  stripe_event_id  TEXT UNIQUE NOT NULL,
  event_type       TEXT NOT NULL,
  payload          JSONB NOT NULL,
  organisation_id  UUID,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_stripe_events_org
  ON public.stripe_events(organisation_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_stripe_events_type
  ON public.stripe_events(event_type, created_at DESC);

-- Rows are inserted by the SECURITY DEFINER webhook handler, so a
-- read-only grant is enough for debugging in the SQL editor.
GRANT SELECT ON public.stripe_events TO authenticated;
GRANT SELECT ON public.stripe_events TO service_role;

NOTIFY pgrst, 'reload schema';