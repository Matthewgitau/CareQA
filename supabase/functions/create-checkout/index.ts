// ============================================================
// Edge Function: create-checkout
//
// Creates a Stripe Checkout Session (mode=subscription) for the
// monthly or annual plan, reusing the organisation's customer.
// Returns { url } for the app to open in the system browser.
//
// On success Stripe redirects to SUCCESS_URL; the webhook
// (stripe-webhook) flips the org to 'active'.
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

  try {
    const { plan, successUrl, cancelUrl } = await req.json();

    const priceId =
      plan === 'annual'
        ? Deno.env.get('ANNUAL_PRICE_ID')
        : Deno.env.get('MONTHLY_PRICE_ID');
    if (!priceId) {
      return json({ error: `No Stripe price configured for plan '${plan}'` }, 400);
    }

    const { data: profile } = await supabase
      .from('profiles')
      .select('organisation_id, stripe_customer_id')
      .eq('id', auth.user.id)
      .maybeSingle();
    if (!profile?.organisation_id) {
      return json({ error: 'No organisation linked to this account' }, 400);
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

    const session = await stripe.checkout.sessions.create({
      mode: 'subscription',
      customer: customerId,
      line_items: [{ price: priceId, quantity: 1 }],
      success_url: successUrl || 'careqa://paywall?status=success',
      cancel_url: cancelUrl || 'careqa://paywall?status=cancelled',
      allow_promotion_codes: true,
      metadata: { organisation_id: profile.organisation_id },
    });

    return json({ url: session.url });
  } catch (e) {
    return json({ error: e instanceof Error ? e.message : 'Checkout failed' }, 500);
  }
});