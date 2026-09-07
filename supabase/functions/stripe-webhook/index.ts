// ============================================================
// Edge Function: stripe-webhook
//
// Verified Stripe webhook endpoint. Handles:
//   checkout.session.completed          -> set org status from the
//                                          ACTUAL subscription status
//                                          (trialing for trial signups,
//                                          active for paid signups)
//   customer.subscription.created       -> mirror Stripe status
//   customer.subscription.updated       -> mirror Stripe status
//   customer.subscription.deleted       -> canceled
//   invoice.payment_succeeded           -> active
//   invoice.payment_failed              -> past_due
//
// Organisation id is read from subscription/customer metadata (set
// by start-trial / create-checkout). Every event is appended to
// stripe_events for debugging.
//
// Configure the endpoint in the Stripe Dashboard to
//   https://<project-ref>.supabase.co/functions/v1/stripe-webhook
// and store the webhook signing secret (whsec_...) in
//   STRIPE_WEBHOOK_SECRET
// (NOT SUPABASE_* - the CLI rejects secrets whose name starts with
// "SUPABASE_".)
// ============================================================
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import Stripe from 'https://esm.sh/stripe@14?dts=false';
import { corsHeaders, json, handleOptions } from '../_shared/cors.ts';

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  { auth: { autoRefreshToken: false, persistSession: false } },
);

const stripeSecret = Deno.env.get('STRIPE_SECRET_KEY');
// NOTE: the Supabase CLI reserves the SUPABASE_* prefix, so secrets
// CANNOT be named SUPABASE_STRIPE_WEBHOOK_SECRET. Stripe's standard
// name is STRIPE_WEBHOOK_SECRET - set it in the dashboard/CLI.
const webhookSecret = Deno.env.get('STRIPE_WEBHOOK_SECRET');
if (!stripeSecret) throw new Error('STRIPE_SECRET_KEY is not set');
if (!webhookSecret) throw new Error('STRIPE_WEBHOOK_SECRET is not set');
const stripe = new Stripe(stripeSecret);

type OrgUpdate = {
  subscription_status?: string;
  trial_started_at?: string | null;
  trial_ends_at?: string | null;
  stripe_subscription_id?: string;
  subscription_plan?: string | null;
};

async function applyToOrganisation(organisationId: string, update: OrgUpdate) {
  if (update.subscription_status === 'active' || update.subscription_status === 'trialing') {
    await supabase.from('profiles').update({
      subscription_status: update.subscription_status,
      trial_started_at: update.trial_started_at ?? null,
      trial_ends_at: update.trial_ends_at ?? null,
    }).eq('organisation_id', organisationId);
  }
  return supabase.from('organisations').update(update).eq('id', organisationId);
}

async function resolveOrgId(event: Stripe.Event): Promise<string | null> {
  const obj = event.data.object as Record<string, any>;
  const metadata: Record<string, string> = obj?.metadata ?? {};
  if (metadata.organisation_id) return metadata.organisation_id;

  const customerId = obj.customer;
  if (typeof customerId === 'string') {
    const customer = await stripe.customers.retrieve(customerId);
    if (!customer.deleted && customer.metadata?.organisation_id) {
      return customer.metadata.organisation_id;
    }
    if (!customer.deleted && customer.id) {
      const { data: org } = await supabase
        .from('organisations')
        .select('id')
        .eq('stripe_customer_id', customer.id)
        .maybeSingle();
      if (org) return org.id;
    }
  }
  return null;
}
Deno.serve(async (req) => {
  const options = handleOptions(req);
  if (options) return options;

  // ─── Dev/ops helpers (test-env; REMOVE before production) ───
  // x-debug:1        → report Stripe webhook config + DB state
  // x-bootstrap:1    → if no endpoint points at us, create it in
  //                    Stripe and return the signing secret to store
  // x-recreate:1     → DELETE the existing endpoint then create fresh;
  //                    guarantees the returned secret matches (fixes
  //                    secret-mismatch / wrong-mode endpoints)
  const isDebug = req.headers.get('x-debug') === '1';
  const isBootstrap = req.headers.get('x-bootstrap') === '1';
  const isRecreate = req.headers.get('x-recreate') === '1';
  if (isDebug || isBootstrap || isRecreate) {
    try {
      const baseUrl = (Deno.env.get('SUPABASE_URL') ?? '').replace(/\/$/, '');
      const thisUrl = `${baseUrl}/functions/v1/stripe-webhook`;
      let endpoints = await stripe.webhookEndpoints.list({ limit: 100 });

      // x-recreate: delete our matching endpoint(s) first so the
      // fresh create below returns a secret that definitely matches.
      if (isRecreate) {
        const matches = endpoints.data.filter((e) => e.url === thisUrl);
        for (const ep of matches) {
          await stripe.webhookEndpoints.del(ep.id);
        }
        endpoints = await stripe.webhookEndpoints.list({ limit: 100 });
      }

      const existing = endpoints.data.find(
        (e) => e.url === thisUrl && e.status === 'enabled',
      );

      let createdEndpoint: Stripe.WebhookEndpoint | null = null;
      let newSecret: string | null = null;
      if ((isBootstrap || isRecreate) && !existing) {
        createdEndpoint = await stripe.webhookEndpoints.create({
          url: thisUrl,
          enabled_events: [
            'checkout.session.completed',
            'customer.subscription.created',
            'customer.subscription.updated',
            'customer.subscription.deleted',
            'invoice.payment_succeeded',
            'invoice.payment_failed',
          ],
        });
        newSecret = createdEndpoint.secret ?? null;
      }

      const { data: recentEvents } = await supabase
        .from('stripe_events')
        .select('event_type, organisation_id, created_at')
        .order('created_at', { ascending: false })
        .limit(10);

      const { data: recentOrgs } = await supabase
        .from('organisations')
        .select('name, subscription_status, stripe_subscription_id')
        .order('created_at', { ascending: false })
        .limit(5);

      return json({
        debug: true,
        thisUrl,
        webhookSecretSet: !!webhookSecret,
        webhookSecretPrefix: webhookSecret ? webhookSecret.slice(0, 7) : null,
        endpoints: endpoints.data.map((e) => ({
          id: e.id,
          url: e.url,
          status: e.status,
          eventCount: e.enabled_events?.length ?? 0,
          enabledEvents: e.enabled_events ?? [],
        })),
        existingEndpoint: existing
          ? { id: existing.id, url: existing.url, status: existing.status }
          : null,
        bootstrap: (isBootstrap || isRecreate)
          ? {
              created: !!createdEndpoint,
              endpointId: createdEndpoint?.id ?? null,
              newSecret,
            }
          : undefined,
        recentEvents: recentEvents ?? [],
        recentOrgs: recentOrgs ?? [],
      });
    } catch (e) {
      return json({ error: e instanceof Error ? e.message : String(e) }, 500);
    }
  }
  // ─── End dev/ops helpers ──────────────────────────────────────

  const signature = req.headers.get('stripe-signature');
  if (!signature) return json({ error: 'Missing stripe-signature header' }, 400);

  let event: Stripe.Event;
  try {
    // Stripe v14 on Deno/Supabase Edge uses the WebCrypto (SubtleCrypto)
    // provider, which is ASYNC-ONLY. The synchronous constructEvent()
    // therefore throws CryptoProviderOnlySupportsAsyncError and no webhook
    // event can ever be processed. Must use the async variant here.
    event = await stripe.webhooks.constructEventAsync(
      await req.text(),
      signature,
      webhookSecret,
    );
  } catch (e) {
    return json({
      error: `Webhook signature verification failed: ${e instanceof Error ? e.message : e}`,
    }, 400);
  }

  try {
    const organisationId = await resolveOrgId(event);
    const evtObj = event.data.object as Record<string, any>;

    await supabase.from('stripe_events').insert({
      stripe_event_id: event.id,
      event_type: event.type,
      payload: event.data.object as unknown as Record<string, unknown>,
      organisation_id: organisationId,
      // Debug fields so an otherwise-silent handler leaves a trace.
      customer_email: typeof evtObj?.customer_email === 'string'
        ? evtObj.customer_email
        : typeof evtObj?.customer === 'string'
          ? evtObj.customer
          : null,
      session_id: typeof evtObj?.id === 'string' ? evtObj.id : null,
    });

    switch (event.type) {
      case 'checkout.session.completed': {
        const session = event.data.object as Stripe.Checkout.Session;
        if (organisationId) {
          // Do NOT blindly set 'active' - a trial checkout has a
          // subscription whose status is 'trialing'. Fetch the real
          // subscription so the organisation lands in the correct state.
          let status: string = 'incomplete';
          let plan: string | null = null;
          let subId: string | undefined = undefined;
          const subRef = session.subscription;
          if (typeof subRef === 'string') {
            subId = subRef;
            try {
              const sub = await stripe.subscriptions.retrieve(subRef);
              status = sub.status; // e.g. 'trialing' | 'active' | 'incomplete'
              const items = sub.items?.data ?? [];
              if (items.length > 0) {
                const period = items[0]?.plan?.interval ?? null;
                plan = period === 'year' ? 'annual' : period === 'month' ? 'monthly' : null;
              }
            } catch {
              status = session.subscription ? 'active' : 'incomplete';
            }
          }
          await applyToOrganisation(organisationId, {
            subscription_status: status,
            stripe_subscription_id: subId,
            subscription_plan: plan,
          });
        }
        break;
      }

      case 'customer.subscription.created':
      case 'customer.subscription.updated': {
        const sub = event.data.object as Stripe.Subscription;
        if (organisationId) {
          await applyToOrganisation(organisationId, {
            subscription_status: sub.status,
            trial_started_at: sub.trial_start
              ? new Date(sub.trial_start * 1000).toISOString()
              : null,
            trial_ends_at: sub.trial_end
              ? new Date(sub.trial_end * 1000).toISOString()
              : null,
            stripe_subscription_id: sub.id,
          });
        } else if (typeof sub.customer === 'string') {
          const customer = await stripe.customers.retrieve(sub.customer);
          if (!customer.deleted && customer.id) {
            const { data: org } = await supabase.from('organisations')
              .select('id').eq('stripe_customer_id', customer.id).maybeSingle();
            if (org) {
              await applyToOrganisation(org.id, {
                subscription_status: sub.status,
                trial_started_at: sub.trial_start
                  ? new Date(sub.trial_start * 1000).toISOString()
                  : null,
                trial_ends_at: sub.trial_end
                  ? new Date(sub.trial_end * 1000).toISOString()
                  : null,
                stripe_subscription_id: sub.id,
              });
            }
          }
        }
        break;
      }

      case 'customer.subscription.deleted': {
        if (organisationId) {
          await applyToOrganisation(organisationId, { subscription_status: 'canceled' });
        }
        break;
      }

      case 'invoice.payment_succeeded': {
        const invoice = event.data.object as Stripe.Invoice;
        if (invoice.subscription && organisationId) {
          await applyToOrganisation(organisationId, { subscription_status: 'active' });
        }
        break;
      }

      case 'invoice.payment_failed': {
        const invoice = event.data.object as Stripe.Invoice;
        if (invoice.subscription && organisationId) {
          await applyToOrganisation(organisationId, { subscription_status: 'past_due' });
        }
        break;
      }

      default:
        // Ignore other event types (product.updated, etc.)
        break;
    }

    return json({ received: true });
  } catch (e) {
    return json({ error: e instanceof Error ? e.message : 'Webhook handler failed' }, 500);
  }
});