// ============================================================
// Edge Function: start-trial
//
// Creates a Stripe Checkout Session in subscription mode with a
// `subscription_data.trial_period_days` of TRIAL_DAYS (defaults to
// 3 for production, 1 for test mode). Returning the { url } lets
// the Flutter app open it in the system browser, just like the
// subscribe flow, so the user is bounced through the same deep
// link on success/cancel.
//
// TRIAL_DAYS env (whole days only - Stripe does not allow sub-day
// billing intervals):
//   3   in production
//   1   in test mode  (lets you verify lockout hourly)
// ============================================================
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import Stripe from 'https://esm.sh/stripe@14?dts=false';
import { corsHeaders, json, handleOptions } from '../_shared/cors.ts';

const stripeSecret = Deno.env.get('STRIPE_SECRET_KEY');
if (!stripeSecret) throw new Error('STRIPE_SECRET_KEY is not set');
const stripe = new Stripe(stripeSecret);

Deno.serve(async (req) => {
  const options = handleOptions(req);
  if (options) return options;

  // CRITICAL: build the client with the caller's JWT in the global
  // headers. Otherwise every PostgREST call below runs as `anon`
  // (RLS sees auth.uid() = NULL) and returns ZERO rows, making us
  // falsely 400 with "No organisation linked to this account" even
  // when profiles.organisation_id is set.
  const authHeader = req.headers.get('Authorization') ?? '';
  const token = authHeader.replace('Bearer ', '');
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_ANON_KEY')!,
    {
      auth: { autoRefreshToken: false, persistSession: false },
      global: { headers: { Authorization: authHeader } },
    },
  );
  // Validate the JWT explicitly AND run all PostgREST calls as the user.
  const { data: auth, error: authError } = await supabase.auth.getUser(token);
  if (authError || !auth.user) return json({ error: 'Unauthorized' }, 401);

  const trialDays = Number(Deno.env.get('TRIAL_DAYS') ?? '3');
  const monthlyPriceId = Deno.env.get('MONTHLY_PRICE_ID');
  if (!monthlyPriceId) return json({ error: 'MONTHLY_PRICE_ID is not configured' }, 500);

  try {
    const body = await req.json().catch(() => ({}));
    const successUrl = (body?.successUrl as string) || 'careqa://paywall?status=success';
    const cancelUrl = (body?.cancelUrl as string) || 'careqa://paywall?status=cancelled';

    const { data: profile } = await supabase
      .from('profiles')
      .select('id, email, organisation_id, stripe_customer_id')
      .eq('id', auth.user.id)
      .maybeSingle();
    if (!profile?.organisation_id) {
      return json({ error: 'No organisation linked to this account' }, 400);
    }

    const { data: org } = await supabase
      .from('organisations')
      .select('subscription_status, trial_ends_at')
      .eq('id', profile.organisation_id)
      .maybeSingle();

    // Idempotent: already subscribed or already trialing.
    if (org?.subscription_status === 'active') {
      return json({ status: 'active', message: 'Already subscribed' });
    }
    if (org?.subscription_status === 'trialing') {
      return json({ status: 'trialing', trialEndsAt: org?.trial_ends_at });
    }

    // Reuse (or create) the Stripe customer so subscription state
    // stays attached to the organisation.
    let customerId: string | null = profile.stripe_customer_id;
    if (!customerId) {
      const customer = await stripe.customers.create({
        email: auth.user.email,
        metadata: { organisation_id: profile.organisation_id },
      });
      customerId = customer.id;
      await supabase.from('profiles').update({ stripe_customer_id: customerId })
        .eq('id', auth.user.id);
      await supabase.from('organisations').update({ stripe_customer_id: customerId })
        .eq('id', profile.organisation_id);
    }

    // Create a Checkout Session with a trial. The webhook flips
    // status to 'trialing' (via checkout.session.completed +
    // subscription.status='trialing') and then to 'active' on first
    // successful invoice. No card is charged today.
    const session = await stripe.checkout.sessions.create({
      mode: 'subscription',
      customer: customerId,
      line_items: [{ price: monthlyPriceId, quantity: 1 }],
      subscription_data: {
        trial_period_days: trialDays,
        metadata: { organisation_id: profile.organisation_id, source: 'trial' },
      },
      payment_method_collection: 'always', // collect card for post-trial renewal
      success_url: `${successUrl}&source=trial`,
      cancel_url: `${cancelUrl}&source=trial`,
      allow_promotion_codes: true,
      metadata: { organisation_id: profile.organisation_id, source: 'trial' },
    });

    return json({
      url: session.url,
      status: 'checkout_required',
      trialDays,
    });
  } catch (e) {
    return json({ error: e instanceof Error ? e.message : 'Trial failed' }, 500);
  }
});