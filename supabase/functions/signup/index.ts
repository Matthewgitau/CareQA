// ============================================================
// Edge Function: signup
//
// Creates the auth user (auto-confirmed so they can log in
// immediately), an `organisations` row (the billing entity) and
// their `profiles` row with role='admin' and
// subscription_status='incomplete' (paywall state).
//
// Returns the user + organisation ids. The Flutter app then signs
// the user in with email/password and the AuthWrapper routes them
// to the paywall.
//
// Uses the service role (bypasses RLS) - never expose this
// function's results to unauthenticated callers.
// ============================================================
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { corsHeaders, json, handleOptions } from '../_shared/cors.ts';

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  { auth: { autoRefreshToken: false, persistSession: false } },
);

Deno.serve(async (req) => {
  const options = handleOptions(req);
  if (options) return options;

  try {
    const { email, password, fullName, organisationName, phone } = await req.json();

    const cleanEmail = (email ?? '').toString().trim().toLowerCase();
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(cleanEmail)) {
      return json({ error: 'A valid email address is required.' }, 400);
    }
    if (typeof password !== 'string' || password.length < 8) {
      return json({ error: 'Password must be at least 8 characters.' }, 400);
    }
    if (!organisationName || organisationName.toString().trim().length < 2) {
      return json({ error: 'Organisation name is required.' }, 400);
    }

    // 1. Create the auth user, auto-confirmed so login works right
    //    away (email verification emails can be layered on later).
    const { data: authData, error: authError } = await supabase.auth.admin.createUser({
      email: cleanEmail,
      password,
      email_confirm: true,
      user_metadata: { full_name: fullName ?? '', organisation_name: organisationName },
    });
    if (authError || !authData?.user) {
      return json(
        { error: authError?.message ?? 'Auth creation failed' },
        authError ? 400 : 500,
      );
    }
    const userId = authData.user.id;

    // 2. Create the billing entity. We re-use an existing organisation
    //    row if one already exists with the same name (idempotent for
    //    retries that got partway through and were retried).
    const trimmedOrgName = organisationName.toString().trim();
    const { data: existingOrg } = await supabase
      .from('organisations')
      .select('id')
      .eq('name', trimmedOrgName)
      .maybeSingle();
    let organisationId = existingOrg?.id as string | undefined;
    if (!organisationId) {
      organisationId = crypto.randomUUID();
      const { error: orgError } = await supabase.from('organisations').insert({
        id: organisationId,
        name: trimmedOrgName,
        subscription_status: 'incomplete',
      });
      if (orgError) {
        // Roll back the auth user to avoid orphaned accounts.
        await supabase.auth.admin.deleteUser(userId);
        return json({ error: `Could not create organisation: ${orgError.message}` }, 500);
      }
    }

    // 3. Create the admin profile. Idempotent upsert so a retry that
    //    succeeded in the previous attempt (but failed to return a
    //    response) never trips profiles_pkey.
    const { error: profileError } = await supabase.from('profiles').upsert(
      {
        id: userId,
        email: cleanEmail,
        full_name: fullName ? fullName.toString().trim() : null,
        role: 'admin',
        phone: phone ? phone.toString().trim() : null,
        organisation_id: organisationId,
        is_active: true,
        subscription_status: 'incomplete',
      },
      { onConflict: 'id' },
    );
    if (profileError) {
      // Delete in the inverse order of creation so a retry of the same
      // email can't trip a profiles_pkey on a stale row.
      await supabase.from('profiles').delete().eq('id', userId);
      if (organisationId) {
        await supabase.from('organisations').delete().eq('id', organisationId);
      }
      await supabase.auth.admin.deleteUser(userId);
      return json({ error: `Could not create profile: ${profileError.message}` }, 500);
    }

    return json({
      userId,
      organisationId,
      subscriptionStatus: 'incomplete',
      message: 'Account created. Please sign in.',
    }, 201);
  } catch (e) {
    return json({ error: e instanceof Error ? e.message : 'Unexpected error' }, 500);
  }
});