// ============================================================
// Edge Function: subscription-status
//
// Returns the caller's subscription / trial state. The app calls
// this on startup, on resume and periodically to re-verify access.
//
// Response:
//   {
//     hasAccess, status, trialEndsAt, plan, stripeCustomerId,
//     organisationId
//   }
// ============================================================
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { corsHeaders, json, handleOptions } from '../_shared/cors.ts';

Deno.serve(async (req) => {
  const options = handleOptions(req);
  if (options) return options;

  // CRITICAL: build the client with the caller's JWT in the global
  // headers. Otherwise every PostgREST call below runs as `anon`
  // (RLS sees auth.uid() = NULL) and returns ZERO rows, making us
  // falsely report "incomplete / no organisation" even when the
  // profile's organisation_id is set.
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
    const { data: profile } = await supabase
      .from('profiles')
      .select('id, role, organisation_id, subscription_status, trial_ends_at, stripe_customer_id')
      .eq('id', auth.user.id)
      .maybeSingle();

    if (!profile?.organisation_id) {
      return json({ hasAccess: false, status: 'incomplete' });
    }

    const { data: org } = await supabase
      .from('organisations')
      .select('subscription_status, trial_started_at, trial_ends_at, subscription_plan, stripe_customer_id')
      .eq('id', profile.organisation_id)
      .maybeSingle();

    const status = org?.subscription_status ?? profile?.subscription_status ?? 'incomplete';
    const trialEndsAt = org?.trial_ends_at ?? profile?.trial_ends_at ?? null;
    const hasAccess =
      (status === 'active') ||
      (status === 'trialing' && (trialEndsAt == null || new Date(trialEndsAt).getTime() > Date.now()));

    return json({
      hasAccess,
      status,
      trialStartedAt: org?.trial_started_at ?? null,
      trialEndsAt,
      plan: org?.subscription_plan ?? null,
      stripeCustomerId: org?.stripe_customer_id ?? profile?.stripe_customer_id ?? null,
      organisationId: profile.organisation_id,
      role: profile.role,
    });
  } catch (e) {
    return json({
      hasAccess: false,
      status: 'error',
      error: e instanceof Error ? e.message : 'Status check failed',
    }, 500);
  }
});