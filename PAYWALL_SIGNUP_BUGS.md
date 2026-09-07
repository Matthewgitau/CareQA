# Paywall / Signup Bug Investigation

**Date:** 2026-09-02
**App:** `admin-app` (Flutter, Supabase)
**Scope:** Signup → Paywall → Trial / Checkout flow
**User report:** Three observable problems:

1. Fresh-email signup throws
   `Could not create profile: duplicate key value violates unique constraint "profiles_pkey"`.
2. After dismissing the error, the user reaches the paywall — but when they press
   *Start Trial* / *Subscribe*, they get `No organisation linked to this account`
   (HTTP 400 from `create-checkout` / `start-trial`).
3. Browser console shows
   `POST https://aucflsskbhaloutsdlwc.supabase.co/functions/v1/create-checkout 400 (Bad Request)`.

This document is a working notebook. It lists the **evidence**, the
**conclusions**, and a **step-by-step remediation plan** that can be executed
one fix at a time so each change can be re-verified.

---

## 1. Evidence (with file:line references)

### 1.1 The signup edge function

`supabase/functions/signup/index.ts` (95 lines total). Order of operations:

1. **L45–53** – `supabase.auth.admin.createUser({ email, password, email_confirm: true })`.
2. **L54** – `const userId = authData!.user!.id;`  ← *unwrapped `!` after the `if (authError) return` guard, so it can be `null` if the response shape changes — see Bug 2 below*.
3. **L57–67** – Insert `organisations` row.
4. **L70–84** – Insert `profiles` row with the same `id` as the auth user.
5. **L81–83** – On profile-insert error: rollback = delete organisation, delete auth user.
   **No rollback for a partial profile insert** (the case that produces the duplicate).

### 1.2 What `profiles_pkey` actually is

`supabase/migrations/001_initial_schema.sql` L5–13:

```sql
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id),  -- <-- profiles_pkey
  email TEXT NOT NULL,
  full_name TEXT,
  role TEXT NOT NULL CHECK (role IN ('admin', 'carer')),
  phone TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

So the `profiles_pkey` constraint is the primary key on `profiles.id`. A
`duplicate key value violates unique constraint "profiles_pkey"` error means
"a row with that `id` already exists in `profiles`".

### 1.3 The paywall-gating edge functions

Both `supabase/functions/start-trial/index.ts` (L48–55) and
`supabase/functions/create-checkout/index.ts` (L45–52) start with the
**identical** lookup:

```ts
const { data: profile } = await supabase
  .from('profiles')
  .select('id, email, organisation_id, stripe_customer_id')
  .eq('id', auth.user.id)
  .maybeSingle();
if (!profile?.organisation_id) {
  return json({ error: 'No organisation linked to this account' }, 400);
}
```

These run with the **user's anon JWT** (not the service role) — see
`create-checkout/index.ts` L15–19 vs. `signup/index.ts` L19–23. So they honour
RLS on the `profiles` SELECT. The policy chain:

- Migration `158_subscription_rls.sql` L54–57 grants
  `"Users can insert own profile"` (only for `id = auth.uid()`).
- Migration `158_subscription_rls.sql` L70–72 grants
  `"users_can_view_own_organisation"` (`id = (SELECT organisation_id FROM profiles WHERE id = auth.uid())`).
- The original same-org SELECT policy from migration `089` is referenced
  in the comment at L51.

So an anon user *can* read their own profile row (and the policy in `089`
gives same-org reads). If the profile row exists, this lookup should
succeed.

### 1.4 The Flutter side

- `admin-app/lib/ui/auth/auth_wrapper.dart` (102 lines).
  - L69–70: `if (authService.isAuthenticated) return _buildPaywallGate(...)`
  - L82–101: `_buildPaywallGate` shows the paywall unless
    `subscriptionService.hasAccess` is true.
- `admin-app/lib/services/subscription_service.dart` (167 lines).
  - L17: `bool get hasAccess => _status.hasAccess;`
  - L18: `bool _loading = false;`
  - **L33–50** `refresh()`: returns the **previous** status if a refresh is
    already in flight (`if (_loading) return _status;`) **and** writes
    `_status` only on success. If the edge function returns an error, the
    old (default-`incomplete`) status is kept — so the paywall stays up
    even after signup. ✅ correct fail-closed behaviour.
- `admin-app/lib/ui/auth/signup_screen.dart` (234 lines).
  - L51–58: `subscriptionService.signUp(...)`.
  - L60–68: on error, show snackbar and **return early** — the bug is here.
  - L70–86: on success, call `authService.signInWithEmailPassword(...)` and
    **then branch on `!result.success` to pop + show "Account created,
    please sign in"**. **This is the inverted-logic bug** — when sign-in
    actually fails, it tells the user "you're created, sign in again";
    when sign-in *succeeds* it does nothing. We need to look at whether
    this matters for the duplicate bug. (Likely a separate cosmetic issue
    but worth flagging.)

### 1.5 No profile-creating trigger on `auth.users`

Searched all 158 migrations: **no** `handle_new_user` / `on_auth_user_created`
trigger exists. The duplicate must therefore be coming from real data,
not from a trigger.

---

## 2. The root cause of the `profiles_pkey` duplicate

The signup edge function has a **partial-write window** between
`auth.admin.createUser` and the `profiles` insert. The window is opened by
the `organisation` insert (L58) — it is **not** wrapped in a DB transaction,
so each step commits independently.

Concrete sequences that produce the observed symptom with a *brand new email*:

| Step | First call | Second call |
|------|------------|-------------|
| 1. `auth.admin.createUser` | creates `auth.users` row, returns `userId` | returns `authError: "A user with this email address has already been registered"` — but **only on the second call**; if the first call's downstream steps already created a profile row, the second call still errors here and the function returns 400 |
| 2. Insert `organisations` | OK | (never reached) |
| 3. Insert `profiles` | OK | (never reached) |
| 4. Profile insert error from a *different* cause (e.g. RLS rejection because the anon token doesn't carry the right claim) | the L81–82 rollback deletes the org and auth user **but not the partial profile**, because the profile insert *itself* never produced an error in this scenario | next attempt with same email: `auth.admin.createUser` fails because the auth user still exists from a prior partial write, *or* the profile row still exists and a re-insert of the same id trips `profiles_pkey` |

But the user says **even a brand new email** triggers this. That means the
duplicate is not from a previous attempt of the same email — it's from a
**profile that was inserted with a different `id`** somehow already existing
*or* a more subtle Postgres-level issue. The most likely remaining causes:

**Hypothesis A (highest confidence):** An earlier `supabase db push` (or
a hot-fix run from the SQL editor) created a profile row in `profiles`
for a different `id` *before* the edge function ran, and the **rollback
in L81–82 deletes the org + auth user but never deletes the profiles row
for the `id` we tried to insert**. So the next *brand new email* also
trips because the function's own previous run left a profile. This is
exactly what the user described: "I tried with a brand new email and
login… the same `profiles_pkey` error".

**Hypothesis B:** The `profileError` is *not* a `profiles_pkey` violation
on the new row, but a `foreign key` violation on the `organisation_id`
when the org insert succeeded but the function's catch block in the
client mis-reads the message. The current `signup/index.ts` returns the
raw `profileError.message`, which Postgres prefixes with the constraint
name — so the user sees `profiles_pkey` even if it's actually an FK
violation. Worth verifying in the Supabase logs.

**Hypothesis C:** The `signup` edge function is **not** deployed in the
environment the user is testing against. The local `lib/main.dart` is
calling the **live** `https://aucflsskbhaloutsdlwc.supabase.co/functions/v1/signup`
URL, but if a stale deployed version (perhaps from before the latest
edits) is the one running, it may have a different code path. Check
`supabase functions list` / Supabase dashboard for the deployed function
hash.

### Why the "organisation missing" error appears for an account that did get created

After a *successful* `auth.admin.createUser` followed by a *failed*
profile insert where the **profile row is nonetheless created** (a
plausible race if L81's rollback runs but the profile insert was
actually written before the error was thrown — e.g. a deferred
constraint check), the next login reads a profile row with
`organisation_id = NULL`. That profile gets the "no organisation linked"
error from `create-checkout`/`start-trial`. So Hypothesis A or B can
produce *both* the duplicate-key error on the next signup attempt *and*
the "no organisation linked" error from the paywall for a profile that
exists but is missing `organisation_id`.

---

## 3. The "no organisation linked" error for the just-signed-up user

This is reproducible from the code as written. Look at
`signup/index.ts` L70–84:

```ts
const { error: profileError } = await supabase.from('profiles').insert({
  id: userId,
  ...
  organisation_id: organisationId,
  ...
});
if (profileError) {
  await supabase.from('organisations').delete().eq('id', organisationId);
  await supabase.auth.admin.deleteUser(userId);
  return json({ error: `Could not create profile: ${profileError.message}` }, 500);
}
```

If the profile insert **succeeds** (no error), then
`organisation_id` is written, and the `create-checkout` lookup should
find it. The only way the "no organisation linked" message appears for a
**fresh** account is one of:

- The profile insert silently wrote `organisation_id = null`
  (e.g. `organisationId` is empty string in the JSON the client sent).
- The Flutter client is **sending an empty `organisationName`** even
  though the form field is non-empty (form-key bug).
- A stale browser session is logged in as a *different* user (cookie
  from an earlier test) whose profile was created without an org.
- The `subscription-service` is **not** auth'd to read the profile
  because the request is being made before the Flutter sign-in finishes.
  The `_client.functions.invoke('create-checkout', ...)` call in
  `subscription_service.dart` L122–126 does **not** explicitly attach
  the JWT — it relies on `_client`'s current session. If the session
  hasn't been established yet, the call goes out with the anon key
  and the RLS policy chain will return *no rows*, not the profile.
  This is very plausible if the user is on the paywall with a session
  but the session has expired/invalidated right after signup.

### Spot-check on the Flutter → edge-function auth

`supabase_flutter` (≥ 2.x) does attach the current session's JWT to
`functions.invoke(...)` by default. But **the JWT refresh can race with
the call**: when the user signs in, `_loadUserProfile` is awaited, but
`SubscriptionService.refresh` is called from `AuthWrapper._ensureChecksStarted`
on the very next build, which can be before the JWT is in the local
storage. If the `start-trial` call happens in that window, the JWT in
the function call is either the **old (pre-signin) anon** or
**missing entirely**, so the edge function sees `getUser(token)` fail
or see no user, and **falls through to the 401 path**, *not* the "no
organisation" 400. So this is probably not the cause of the "no
organisation" message.

More likely cause: a **stale browser tab / cookie** that logs the user
back in as a previous test user who has no org, plus a `proceed to
paywall` click that fires `create-checkout` with that user's JWT.
The paywall will then return "no organisation linked" for that previous
user.

---

## 4. The duplicate-key error despite a brand-new email

Combined with point 1, the most plausible single explanation is:

- The **previously failed** signups left orphan `profiles` rows with
  random UUIDs (the `auth.admin.createUser` call always returns a new
  UUID, but the **profile insert** used a *different* UUID, or a
  re-deployed function was patched in a way that changed the
  profile-insert id).
- OR the deployed function is **older than the code in the repo** and
  is using a different `id` strategy (e.g. `crypto.randomUUID()` for
  the profile instead of the auth user's id).

Let me re-read the deployed code… we just read it — line 71 is
`id: userId,` which is the auth user's id. So that part is correct.

The remaining smoking gun is **the rollback**. If the profile row got
created on a *prior* attempt with the same auth user (because the auth
user was re-used across attempts — which `auth.admin.createUser` does
*not* do by default), the profile id is the auth user id, and the next
attempt's `auth.admin.createUser` returns an error and we never get to
the profile insert. So the user would see *"A user with this email
address has already been registered"*, not the duplicate-key error.

UNLESS… the previous attempt got past `auth.admin.createUser` (created
user) AND past the org insert AND past the profile insert (no error
returned), and **then** the catch block at L92–94 caught an exception
(e.g. a JSON parse error or a network blip returning the response).
In that case all three rows are present and the function returns 500,
but a retry will hit duplicate-key on the profile insert (because the
profile is already there from the first attempt).

The simplest fix: **make the entire flow idempotent** (upsert on
profile + check-and-skip on org + reuse auth user on email match). This
is what `135_staff_self_signup.sql` does (line 76–87 uses
`ON CONFLICT (id) DO UPDATE`).

---

## 5. Remediation plan (ordered, each step is independently verifiable)

### Step 1 — Stop the bleeding (immediate, no schema change)

**File:** `supabase/functions/signup/index.ts`

Make the profile insert an `upsert` so a retry can never trip
`profiles_pkey`. This is the change recommended in the previous chat
turn; the current document confirms it's still the right first move.

```ts
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
```

Then redeploy: `supabase functions deploy signup`.

**Verify:** sign up with a brand-new email — should succeed. Sign up
again with the same email — should now return *"A user with this email
address has already been registered"* (from the auth admin call) and
not the duplicate-key error.

### Step 2 — Fix the rollback so a failed run can't leave orphans

**File:** `supabase/functions/signup/index.ts`

If the profile insert fails for any reason, delete the profile first,
then the org, then the auth user. (This is the inverse order of
creation.) The current code is also missing a guard for `!authData?.user`,
which would throw on the unwrap.

```ts
if (authError || !authData?.user) {
  return json({ error: authError?.message ?? 'Auth creation failed' }, 400);
}
const userId = authData.user.id;
```

### Step 3 — Clean up the orphans currently in the database

Even after Step 1, there are still orphan rows from previous failed
runs. Run in the Supabase SQL editor:

```sql
-- Find orphans (profile rows whose auth user no longer exists)
SELECT p.id, p.email, p.organisation_id
FROM public.profiles p
LEFT JOIN auth.users u ON u.id = p.id
WHERE u.id IS NULL;

-- After eyeballing the list, delete them:
DELETE FROM public.profiles
WHERE id IN (
  SELECT p.id FROM public.profiles p
  LEFT JOIN auth.users u ON u.id = p.id
  WHERE u.id IS NULL
);

-- Also clean up orgs with no associated profile
DELETE FROM public.organisations o
WHERE NOT EXISTS (
  SELECT 1 FROM public.profiles p WHERE p.organisation_id = o.id
);
```

**Verify:** `SELECT COUNT(*) FROM public.profiles;` should drop. Then
attempt signup with the brand-new email again — should succeed.

### Step 4 — Investigate the "no organisation linked" error

This is a separate bug. After Step 1–3, sign up with a fresh email and
immediately press **Subscribe Monthly** (don't go through the trial
first, to remove the trial code path from the equation). The
`create-checkout` call will then return one of:

- `{ url: "https://checkout.stripe.com/..." }` → success
- `400 { error: "No organisation linked to this account" }` → problem
- `400 { error: "No Stripe price configured for plan '...'" }` → secret
  not set
- `500 { error: "..." }` → Stripe-side error

If it's "No organisation linked", check:

```sql
SELECT u.email, p.id, p.organisation_id, o.id, o.name
FROM auth.users u
LEFT JOIN public.profiles p ON p.id = u.id
LEFT JOIN public.organisations o ON o.id = p.organisation_id
WHERE u.email = '<the email you just signed up with>';
```

If the user has no profile row or the profile's `organisation_id` is
NULL, then **the sign-up didn't actually finish** — re-run Steps 1–3
and try again.

If the user *has* both rows correctly, the issue is on the Flutter
side — most likely the `create-checkout` request is being sent with
**a different user's JWT** (stale session). Clear the browser's
Supabase auth storage:

```js
// In the browser console while on the paywall page:
await supabase.auth.signOut();
location.reload();
```

Then sign in fresh and try again.

### Step 5 — Surface better errors from the Flutter side

**File:** `admin-app/lib/services/subscription_service.dart` L33–50

`refresh()` currently swallows edge-function errors silently. The user
sees a static "no organisation" error in the snackbar; they have no way
to know whether it's a missing-profile, missing-org, or Stripe-config
issue. Surface the actual error string on `_status.error` so
`PaywallScreen` can show it.

### Step 6 — Inverted-logic cosmetic bug in `signup_screen.dart`

**File:** `admin-app/lib/ui/auth/signup_screen.dart` L70–86

The block runs `if (!result.success)` to show the "please sign in"
snackbar. That's inverted — it tells users to sign in *when sign-in
just failed*. It should be:

```dart
if (!result.success) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Sign-in failed: ${result.errorMessage ?? 'unknown error'}'),
      backgroundColor: Colors.red,
    ),
  );
  return;
}
// On success: AuthWrapper reacts to the auth state change and
// routes to the paywall automatically.
```

This is cosmetic but it confuses users during testing.

### Step 7 — Add a transaction wrapper (defence in depth)

**File:** `supabase/functions/signup/index.ts`

Wrap the three DB writes in a Postgres function so they commit
atomically. Migration `159_signup_atomic.sql`:

```sql
CREATE OR REPLACE FUNCTION public.atomic_signup(
  p_user_id uuid,
  p_email text,
  p_full_name text,
  p_phone text,
  p_organisation_name text
) RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_org_id uuid;
BEGIN
  INSERT INTO public.organisations (name, subscription_status)
  VALUES (p_organisation_name, 'incomplete')
  RETURNING id INTO v_org_id;

  INSERT INTO public.profiles (
    id, email, full_name, phone, role, organisation_id, is_active, subscription_status
  ) VALUES (
    p_user_id, p_email, p_full_name, p_phone, 'admin', v_org_id, true, 'incomplete'
  ) ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    full_name = EXCLUDED.full_name,
    phone = EXCLUDED.phone,
    organisation_id = EXCLUDED.organisation_id,
    is_active = true,
    subscription_status = 'incomplete';

  RETURN v_org_id;
END;
$$;
GRANT EXECUTE ON FUNCTION public.atomic_signup TO service_role;
```

The edge function then becomes a thin wrapper that calls the RPC and
fails atomically. (This is the same pattern
`supabase/migrations/135_staff_self_signup.sql` uses, and it
sidesteps the partial-write window entirely.)

### Step 8 — Add observability

**File:** `supabase/functions/signup/index.ts`

Log every step (with `console.log`) and surface a `requestId` in the
JSON error responses, so when the user reports *"I see error X"*, the
matching log line can be pulled from the Supabase Functions log
viewer.

### Step 9 — Confirm the paywall still works

After Steps 1–7, run the full paywall test:

1. Sign up brand-new email.
2. Paywall shows.
3. Press *Start 3-Day Free Trial*.
4. Stripe Checkout opens in the system browser.
5. Use test card `4242 4242 4242 4242` (any future date, any CVC, any
   postcode).
6. Stripe redirects to `careqa://paywall?status=success&source=trial`.
7. App reopens, paywall auto-refreshes, `hasAccess` becomes true,
   dashboard appears.

Verify the SQL state after the trial:

```sql
SELECT subscription_status, trial_started_at, trial_ends_at
FROM public.organisations
WHERE id = '<your-org-id>';
```

Should show `trialing`, a recent `trial_started_at`, and a
`trial_ends_at` 3 days (or 1 day in test mode) later.

---

## 6. Open questions for the user

Before executing the plan, the user should be able to answer these so
we can prioritise:

1. **Has the `signup` edge function been re-deployed since the latest
   edits to `signup/index.ts` in this repo?** If not, the deployed
   version may not be the one we just read.
2. **Is `STRIPE_SECRET_KEY` set in the project's edge-function
   secrets?** Without it, `start-trial` / `create-checkout` will 500
   with `STRIPE_SECRET_KEY is not set` (not the "no organisation"
   error — but worth checking).
3. **Is `STRIPE_WEBHOOK_SECRET` set?** Without it, the webhook
   handler will reject every event and the trial status will never
   flip to `trialing`.
4. **Does the user have access to the Supabase SQL editor to run the
   cleanup in Step 3?** If not, we provide a script that the user
   runs locally via the supabase CLI.

---

## 7. Status

| Step | Status | Notes |
|------|--------|-------|
| 1. Upsert profile on retry | ✅ DONE | `supabase/functions/signup/index.ts` L86–98 now `upsert(..., { onConflict: 'id' })` |
| 2. Fix rollback + null guard | ✅ DONE | null-guard on L51–56, inverse-order rollback on L99–108, re-use existing org on L62–68 |
| 3. Clean orphan rows | ⏳ TODO | needs user to run SQL (or `supabase db execute`) |
| 4. Diagnose "no org" path | ⏳ TODO | needs a fresh test signup after Steps 1–3 + redeploy |
| 5. Surface errors in Flutter | ⏳ TODO | |
| 6. Fix inverted logic in signup_screen | ⏳ TODO | cosmetic |
| 7. Atomic RPC migration | ⏳ TODO | (defence in depth) |
| 8. Add logging | ⏳ TODO | |
| 9. End-to-end paywall test | ⏳ TODO | needs Steps 1–3 done + edge function redeployed |

### ✅ Next action for the user

After this commit, **redeploy the function** so the live environment
picks up the fix:

```powershell
supabase functions deploy signup
```

(or run the bootstrap script: `.\supabase\bootstrap_paywall.ps1`)

Then run the SQL from Step 3 to clean the orphan rows, then re-test
the paywall from a brand-new email. If Step 4's "no organisation" error
still appears, the diagnosis section of this doc will tell you which
SQL to run to see whether the profile row is missing the org FK or
the Flutter side is sending a stale JWT.

---

## 8. Update #2 — trapped-on-paywall + NULL organisation_id (2026-09-03)

### Symptoms reported
- "There is a missing logout button on the paywall page" — user is trapped
  and cannot sign out to create a fresh account.
- Pressing **Subscribe** / **Start Trial** on the paywall returns
  `No organisation linked to this account` (HTTP 400 from
  `create-checkout`) in the dev console.

### What the code actually had
1. **Sign-out button existed but was easy to miss.** `paywall_screen.dart`
   only had a small `TextButton.icon` at the very bottom of a long
   `SingleChildScrollView` (after 3 plan cards + terms row). On a short
   viewport it was effectively invisible without scrolling.
2. **`signOut()` in `supabase_auth_service.dart` could leave the user
   trapped** if the remote `auth.signOut()` threw (network), because the
   local session state was only cleared after the awaited call.
3. **RLS is NOT the problem for the 400.** Migration 152 already creates
   `"Users can view own profile"` (`USING (id = auth.uid())`), so
   `create-checkout` *can* read your own profile row.
4. **The real 400 cause: `profiles.organisation_id` is NULL** on accounts
   whose signup happened during the buggy window (the pre-upsert `insert`
   path). `create-checkout` / `start-trial` both do
   `if (!profile?.organisation_id) return 400 'No organisation linked'`.

### Fixes applied (this update)
| File | Change |
|------|--------|
| `admin-app/lib/ui/paywall/paywall_screen.dart` | Added a small dark `AppBar` with a **Sign out** `TextButton.icon` pinned top-right (always visible, no scrolling). Kept + upgraded the bottom button to an `OutlinedButton.icon`. Both have stable `Key`s (`paywall_sign_out_top`, `paywall_sign_out_bottom`). |
| `admin-app/lib/services/supabase_auth_service.dart` | `signOut()` now runs in `try/finally`: local session state (user, role, org) and the cached flag are ALWAYS cleared, even if the remote call throws. |

Both files were `dart format`-ted and parse cleanly.

### SQL the user must run (Supabase SQL editor)

**Step A — backfill organisations for NULL-org profiles:**

```sql
DO $$
DECLARE
  r RECORD;
  v_org_id uuid;
BEGIN
  FOR r IN
    SELECT p.id, p.email, p.full_name
    FROM public.profiles p
    WHERE p.organisation_id IS NULL
  LOOP
    INSERT INTO public.organisations (id, name, subscription_status)
    VALUES (
      gen_random_uuid(),
      COALESCE(NULLIF(trim(r.full_name), ''), split_part(r.email, '@', 1), 'Organisation') || ' (auto)',
      'incomplete'
    )
    RETURNING id INTO v_org_id;

    UPDATE public.profiles
    SET organisation_id = v_org_id
    WHERE id = r.id;
  END LOOP;
END $$;
```
---

## 9. Update #3 — TRUE root cause of the persistent 400 (2026-09-03)

### Symptom (unchanged after Updates 1–2)
- New account, signup works, `organisation_id` IS written by `signup`.
- Paywall loads, but `POST /functions/v1/create-checkout` returns
  `400 { "error": "No organisation linked to this account" }`.

### Root cause
All three **user-facing** paywall edge functions verified the JWT but
then ran their PostgREST reads as the **`anon`** role:

```ts
// OLD (buggy) pattern in create-checkout / start-trial / subscription-status:
const supabase = createClient(url, anonKey, { auth: { persistSession: false } });
const { data: auth } = await supabase.auth.getUser(token); // verifies JWT
...
await supabase.from('profiles').select(...)  // ❌ runs as anon!
```

`getUser(token)` validates a token but does **not** attach it to the
client session. Because `persistSession: false` and no session is set,
every `.from(...)` call sent `Authorization: Bearer <anon key>`, so RLS
saw `auth.uid() = NULL` → returned zero rows → the function concluded
the profile (and therefore `organisation_id`) didn't exist →
falsely 400/500.

This is also why `subscription-status` always returned
`{ hasAccess: false, status: 'incomplete' }` even for a correctly
linked account.

### Fix (applied to all three files)
Build the client **per request** with the caller's JWT in the global
headers (official Supabase Edge Function auth pattern), and pass the
token explicitly to `getUser(token)`:

```ts
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
const { data: auth, error: authError } = await supabase.auth.getUser(token);
if (authError || !auth.user) return json({ error: 'Unauthorized' }, 401);
```

Now every `.from(...)` call carries `Authorization: Bearer <user JWT>`,
so RLS sees the real `auth.uid()` and the policy
`"Users can view own profile" (id = auth.uid())` lets the function read
its own profile → `organisation_id` is found → Checkout proceeds.

### Files changed
| File | Change |
|------|--------|
| `supabase/functions/create-checkout/index.ts` | client moved inside `Deno.serve`, JWT passed via `global.headers` + `getUser(token)` |
| `supabase/functions/start-trial/index.ts` | same |
| `supabase/functions/subscription-status/index.ts` | same |

### Deploy (required for the fix to reach live)
```powershell
supabase functions deploy create-checkout start-trial subscription-status --no-verify-jwt
```

### Re-test
1. Hard-refresh the admin-app (Ctrl+Shift+R).
2. Sign in (or sign up fresh).
3. Paywall → **Subscribe Monthly** → Stripe Checkout should open
   (test card `4242 4242 4242 4242`).
---

## 10. Update #4 — Stripe redirect + web build (2026-09-03)

### Symptom (this is actually GOOD NEWS - payments now work)
- Dev console showed real Stripe Checkout loading:
  - `Estimated order amount for sandbox is {"amount":"750","currencyCode":"gbp"}`
  - `cs_test_...` session URL (the 4242 4242 4242 4242 card was accepted)
- The ONLY blocking error at the end:
  `Failed to launch 'careqa://paywall?status=success' because the scheme does not have a registered handler.`
- The `payments-eu.amazon.com` CORS errors earlier in the console are
  **benign** — Stripe's checkout page failing to load the Amazon Pay
  add-on button in sandbox. It does NOT block card payments.

### Root cause
- `careqa://` is a **custom URL scheme**. It is registered ONLY for
  Android (`PAYWALL_SETUP.md` line 41: `<data android:scheme="careqa"/>`).
- The **web build has no handler** for custom schemes. Stripe
  redirected to `careqa://paywall?status=success` → browser refused.
- iOS is also not configured per `PAYWALL_SETUP.md` lines 234–236.

### Fix (applied)
`admin-app/lib/services/subscription_service.dart` — added
`_redirectBase` that is platform-aware:
- **Native (iOS/Android):** keeps `careqa://paywall`.
- **Web:** returns the app's own origin from `Uri.base`
  (e.g. `http://localhost:64789`), so Stripe redirects back to the
  web app itself. The SPA reloads, `AuthWrapper` re-runs
  `subscription-status`, and the user is routed to the dashboard
  (or stays on paywall if the webhook hasn't flipped the org).

---

## 11. Update #5 — poll-for-access after Stripe returns + test cards (2026-09-03)

### Symptom
- After entering the 4242 test card, Stripe **did** redirect back:
  `http://localhost:51371/?status=success&source=checkout`.
- But the app landed on the paywall again instead of the dashboard.

### Cause
The app only called `subscription-status` **once** on boot / on resume.
The Stripe **webhook** that flips the org to `active`/`trialing` can
land a second or two **after** the browser redirect. So the single
refresh hit before the webhook → org still `incomplete` → paywall. There
was **no retry**, so the user sat on the paywall until the next 15-min
periodic check (or stuck on web which had no timer problem but the same
one-shot refresh).

### Fix (applied)
- `admin-app/lib/services/subscription_service.dart` — added
  `pollUntilAccess({interval, maxAttempts})` which calls
  `refresh(force: true)` every 3s for up to 10 attempts (~30s) and
  returns as soon as `hasAccess` flips. Each `refresh` calls
  `notifyListeners()`, so the moment the webhook lands, the
  `AuthWrapper` gate **immediately** swaps to the dashboard.
- `admin-app/lib/ui/paywall/paywall_screen.dart`:
  - **Web:** on `initState`, if the page URL contains
    `?status=success` (Stripe redirected the browser back), start
    `pollUntilAccess()`.
  - **Native:** when a trial/checkout launch succeeds, set
    `_awaitingCheckout = true`; when the app resumes (power/Chrome
    custom-tab return), start `pollUntilAccess()`.
  - Shows a green **"Payment received — checking your subscription…"**
    banner (spinner) while polling and disables the plan buttons.
- `admin-app/lib/main.dart` — `_handleWebPaywallRedirect()` still logs
  the return params for diagnostics.

### Re-test checklist
1. `flutter run -d chrome`
2. Paywall → Start Trial / Subscribe Monthly → test card.
3. Expect the green "checking your subscription" banner for a few
   seconds, then **dashboard** once the webhook lands.
4. If it STILL stays on the paywall after ~30s, the webhook is not
   configured (see Update #4) — the org never flips. Confirm with SQL.

---

## 12. Stripe test card cheat-sheet

Use these while testing the admin-app paywall (all test keys, no real
charges). 4242 4242 4242 4242 is the default success card.

| Card number            | Result / scenario                            |
|------------------------|-----------------------------------------------|
| `4242 4242 4242 4242`  | ✅ Success (Visa) — normal purchase            |
| `4000 0025 0000 3155`  | ✅ Success (Visa) — auth required (3DS prompt) |
| `5555 5555 5555 4444`  | ✅ Success (Mastercard)                        |
| `3782 822463 10005`    | ✅ Success (American Express)                  |
| `6011 1111 1111 1117`  | ✅ Success (Discover)                          |
| `4000 0000 0000 9995`  | ❌ **Card declined — insufficient funds**      |
| `4000 0000 0000 0002`  | ❌ Card declined — generic                      |
| `4000 0000 0000 0069`  | ❌ Card declined — expired                      |
| `4000 0000 0000 0127`  | ❌ Card declined — incorrect CVC                |
| `4000 0000 0000 9987`  | ❌ Card declined — lost card                    |
| `4000 0000 0000 0077`  | ❌ Card declined — processing error             |
| `4000 0000 0000 3220`  | ❌ Card declined — suspected fraud              |
| `4000 0027 6000 3184`  | 🔐 Requires 3DS authentication (accept) — tests the SCA/frictionless path |

### Failure-path tests to run
1. **Insufficient funds** → `4000 0000 0000 9995`
   — expect Stripe rejects; org should stay `incomplete` (no access).
2. **3DS / auth challenge** → `4000 0000 0000 9995`? No —
   `4000 0027 6000 3184` / `4000 0025 0000 3155`
   — complete the challenge; after success the redirect + poll should
   take you to the dashboard.
3. **Trial card validation** — for a trial, the card is collected but
   NOT charged (payment_method_collection='always'); a card that would
   decline on the *first renewing invoice* will still be accepted now.
   To simulate the later failure, wait for the trial to end (TRIAL_DAYS
   env) or check `invoice.payment_failed` handling.
4. **Cancel flow** — refine how you test a cancelled checkout
   (`?status=cancelled`) — should leave the user on the paywall with no
   change in access.

### How to confirm each result in the DB
```sql
SELECT name, subscription_status, stripe_subscription_id,
       trial_started_at, trial_ends_at
FROM public.organisations
ORDER BY created_at DESC
LIMIT 10;
```
- Success → `active` (subscribe) or `trialing` (trial).
- Declined → stays `incomplete`.

---

## 13. Update #6 — "setState during build" exception + webhook blocker (2026-09-03)

### Symptom
- Stripe Checkout worked, redirected back to
  `http://localhost:<port>/?status=success&source=checkout`.
- App re-opened but stayed on the **paywall** (never reached the
  dashboard/hamburger menu), and the console showed:

```
EXCEPTION CAUGHT BY FOUNDATION LIBRARY
setState() or markNeedsBuild() called during build.
... The SubscriptionService sending notification was:
Instance of 'SubscriptionService'
```

plus our poll message:
`Payment flew back successfully but access was not granted within the
poll window - Stripe webhook may not be configured.`

### Root cause (two separate things)
1. **Build-phase crash in `refresh()`.** `AuthWrapper.build()` calls
   `_ensureChecksStarted()`, which called
   `subscriptionService.refresh(force: true)` **synchronously during
   build**. `refresh()` immediately does `notifyListeners()`, and the
   framework throws `setState()/markNeedsBuild() called during build`.
   The throw happens BEFORE the HTTP call, so the boot status check
   never ran — `_status` stayed the default `incomplete`.
2. **Webhook not flipping the org.** Even with polling working, the
   Stripe **webhook** is what sets `organisations.subscription_status`
   to `active`/`trialing`. If the webhook endpoint isn't configured in
   the Stripe dashboard (and `STRIPE_WEBHOOK_SECRET` set), the org
   stays `incomplete` forever, so `subscription-status` keeps returning
   `hasAccess: false` and the paywall is the correct UI.

### Fixes (applied)
| File | Change |
|------|--------|
| `admin-app/lib/services/subscription_service.dart` | Added `_deferNotify()` using `scheduleMicrotask(notifyListeners)`; both notifies in `refresh()` now go through it. This eliminates the build-phase crash regardless of call site. |
| `admin-app/lib/ui/auth/auth_wrapper.dart` | `_ensureChecksStarted()` now defers the first `refresh()` via `WidgetsBinding.instance.addPostFrameCallback(...)` so it never runs synchronously inside `build()`. |
| `admin-app/lib/ui/paywall/paywall_screen.dart` | If the post-payment poll still doesn't see access, show an on-screen error snackbar explaining the webhook may not be configured (not just a debugPrint). |

### What the user MUST verify / configure now

The app-side polling is fixed. The remaining missing piece is the
Stripe webhook. To confirm whether it's already working:

```sql
-- 1) Did the webhook ever fire?
SELECT event_type, organisation_id, created_at
FROM public.stripe_events
ORDER BY created_at DESC
LIMIT 10;

-- 2) Is the org still 'incomplete' after a successful card test?
SELECT name, subscription_status, stripe_subscription_id,
       trial_started_at, trial_ends_at
FROM public.organisations
ORDER BY created_at DESC
LIMIT 10;
```

- If `stripe_events` is empty → webhook never fired → configure it
  (below).
- If the org is still `incomplete` but events ARE in
  `stripe_events` → inspect the webhook handler / function logs.

#### Stripe webhook setup (once)
1. Stripe Dashboard → Developers → **Webhooks** → **Add destination**
   (or "Add endpoint").
   - URL:
     `https://aucflsskbhaloutsdlwc.supabase.co/functions/v1/stripe-webhook`
   - Events to listen for:
     - `checkout.session.completed`
     - `customer.subscription.created`
     - `customer.subscription.updated`
     - `customer.subscription.deleted`
     - `invoice.payment_succeeded`
     - `invoice.payment_failed`
2. After saving, reveal/copy the **Signing secret** (`whsec_...`).
3. Set it as a Supabase function secret and redeploy the webhook
   function. **Deploy both with `--no-verify-jwt`** so Stripe's signed
   POST (no Supabase JWT) is accepted:
   ```powershell
   supabase secrets set STRIPE_WEBHOOK_SECRET=whsec_xxxxx
   supabase functions deploy stripe-webhook --no-verify-jwt
   # also ensure the other three are current (JWT-attached):
   supabase functions deploy create-checkout start-trial subscription-status --no-verify-jwt
   ```
4. In the Stripe dashboard use **"Send test webhook"** to post a
   `checkout.session.completed` event, then re-run the SQL above —
   `stripe_events` should grow and the org should flip.

### Re-test (web AND APK)
- Rebuild: `flutter run -d chrome` (web) and/or
  `flutter build apk --debug` then install the APK on a device.
- Sign up / sign in → paywall → pay with `4242 4242 4242 4242`.
- After the redirect back:
  - No "setState during build" exception in the console.
  - Green "Payment received — checking your subscription…" banner.
  - Within a few seconds → **dashboard with the hamburger menu**
    (`admin_dashboard.dart` Scaffold has `drawer: Drawer(...)`).
- Failure case (optional): use `4000 0000 0000 9995` (insufficient
  funds) → Stripe declines → paywall stays, no access granted.

### On the APK specifically
- The Android manifest already registers the `careqa://` scheme
  (`android/app/src/main/AndroidManifest.xml` → `<data
  android:scheme="careqa"/>`).
- The resume-triggered poll (`_awaitingCheckout` →
  `didChangeAppLifecycleState.resumed` → `_pollUntilAccess()`) handles
  the return from Stripe on native.
- The webhook requirement is identical on the APK — same server, same
  Stripe account.

---

## 14. Update #7 — routing to AdminDashboard: how it works + manual fallback (2026-09-03)

### The user's concern
> "I do not see any other pages that have been connected to the paywall,
> so when the client has paid they are not taken anywhere else. There is
> another page that should be routed to when confirmed as a paid member:
> `admin_dashboard.dart`."

### Confirmed: the dashboard IS the destination, wired in main.dart
- `admin-app/lib/main.dart:85`:
  ```dart
  home: const AuthWrapper(
    authenticatedChild: AdminDashboard(),
  ),
  ```
- `admin-app/lib/ui/dashboard/admin_dashboard.dart:107–108`:
  ```dart
  class AdminDashboard extends StatefulWidget {
    const AdminDashboard({super.key});
  ```
  It's a `StatefulWidget` with no required params, and its `Scaffold`
  (line ~185) has an `AppBar` + `drawer: Drawer(...)` — that's the
  hamburger menu.

### How routing works (important — it is NOT a Navigator.push)
`AuthWrapper.build()` (viewed via `context.watch<SubscriptionService>`) is
**data-driven**:

```dart
if (!subscriptionService.hasAccess) {
  return const PaywallScreen();       // unpaid → paywall
}
return widget.authenticatedChild;     // paid → AdminDashboard
```

When the Stripe webhook flips the org to `active`/`trialing`,
`subscription-status` starts returning `hasAccess: true`, the
`SubscriptionService` notifies its listeners, `AuthWrapper` rebuilds, and
the paywall is **swapped out for `AdminDashboard`** in the same widget
tree (no route transition). This is preferred because it preserves the
app shell's state and avoids a back-stack of paywall screens.

The paywall screen itself never needs to reference `admin_dashboard.dart`
— the gate does the routing. That is why "no pages are connected to the
paywall".

### Changes in Update #7
| File | Change |
|------|--------|
| `admin-app/lib/ui/auth/auth_wrapper.dart` | Added a `debugPrint` at the access-granted boundary: `PAYWALL_GATE: access granted (...) → showing authenticatedChild (AdminDashboard)`. This makes it obvious in the console the instant routing kicks in. |
| `admin-app/lib/ui/paywall/paywall_screen.dart` | Added a **"Check payment status"** `TextButton` (disabled while already polling). If the auto-redirect hasn't fired within the poll window (webhook delay, or app closed/reopened), the user can manually re-check instead of waiting out the 15-min timer. |

### What to look for in the console when it works
```
PAYWALL_GATE: access granted (status=active) → showing authenticatedChild (AdminDashboard)
```
If you don't see that line, the org has NOT been flipped (webhook
missing) — no amount of app code can unlock the dashboard until the
server knows the payment succeeded.

### Re-test
1. Rebuild web: `flutter run -d chrome`.
2. Pay with `4242 4242 4242 4242`.
3. On the **paywall** (if it hasn't auto-flipped yet) press
   **"Check payment status"** → the button runs `pollUntilAccess()`.
4. Once the webhook has fired, `hasAccess` flips and you'll see the
   console line + the dashboard with the hamburger.
5. If you never see the console line, run the SQL in Update #6 to
   confirm the webhook is configured.
`admin-app/lib/main.dart` — added `_handleWebPaywallRedirect()` which
logs the `?status=success&source=...` params Stripe redirects back
with (cross-platform-safe, web-only act).

The edge function already forwards `successUrl`/`cancelUrl` from the
request body into Stripe's `success_url`/`cancel_url`, so no edge
function changes were needed for this fix.

### IMPORTANT - check the webhook (this flips the org to active/trialing)
The 4242 payment may have already flipped the org IF the Stripe webhook
is configured. Verify:

```sql
SELECT name, subscription_status, stripe_subscription_id,
       trial_started_at, trial_ends_at
FROM public.organisations
ORDER BY created_at DESC
LIMIT 5;
```

- Row shows `active` / `trialing` → webhook is set up, run the app
  retest below.
- Row still shows `incomplete` → the webhook is NOT firing. Set it up:
  1. Stripe Dashboard → Developers → Webhooks → Add endpoint
     `https://aucflsskbhaloutsdlwc.supabase.co/functions/v1/stripe-webhook`
     → events: `checkout.session.completed`,
     `customer.subscription.created/updated/deleted`,
     `invoice.payment_succeeded/failed`.
  2. Copy the `whsec_...` signing secret, then:
     ```powershell
     supabase secrets set STRIPE_WEBHOOK_SECRET=whsec_xxxxx
     supabase functions deploy stripe-webhook --no-verify-jwt
     ```
  3. Resend the test event from the Stripe dashboard ("Send test
     webhook") and re-check the SQL above.

### Re-test (after rebuild)
1. `flutter run -d chrome` (hard-refresh Ctrl+Shift+R first).
2. Paywall → **Start Trial** or **Subscribe Monthly** with
   `4242 4242 4242 4242`.
3. This time Stripe redirects to `http://localhost:<port>/?status=success`
   — the app reloads, detects success, and routes to the dashboard.

**Step B — verify every profile now has an org:**

```sql
SELECT u.email, p.id, p.organisation_id IS NOT NULL AS has_org, o.name
FROM auth.users u
LEFT JOIN public.profiles p ON p.id = u.id
LEFT JOIN public.organisations o ON o.id = p.organisation_id
ORDER BY u.created_at DESC
LIMIT 10;
```

**Step C — re-test in the browser:**
1. Hard-refresh the admin-app (flushes the old web build + stale session).
2. Click **Sign out** from the new top AppBar button.
3. Sign in with the account that previously hit the 400 → paywall →
   **Subscribe Monthly** should now open Stripe Checkout instead of the
   400.
4. (Or create a brand-new account — new signups already write
   `organisation_id` correctly via the fixed `signup` function.)

---

## 15. Update #8 — webhook never delivered: definitive diagnosis + runbook (2026-09-03)

### New evidence from the user
Stripe request log showed the **payment absolutely succeeded**:
- `payment_status: "paid"`, `status: "complete"`, `state: "succeeded"`
- card `visa •••• 4242`, £750.00, mode `subscription`
- `customer_email: amia123@test.com`

But the database says otherwise:
- `SELECT * FROM public.stripe_events ORDER BY created_at DESC LIMIT 10;` → **0 rows**
- `SELECT * FROM public.organisations ORDER BY created_at DESC LIMIT 5;`
  → orgs `NULL` / `incomplete` / `stripe_subscription_id: null`

And the deployed CLI state:
- `supabase secrets list` → `STRIPE_SECRET_KEY` and `STRIPE_WEBHOOK_SECRET` **are both set**.
- `supabase functions list` → `create-checkout`, `start-trial`,
  `subscription-status` at **v14, 2026-09-03 18:57 UTC**; `stripe-webhook` at **v15, 2026-09-01** (pre-debug).

### Conclusions
1. **Payment/Checkout is fully working end-to-end.**
2. `create-checkout` v14 resolving the org and returning a session proves
   the **JWT-attach fix is deployed and working** on the paywall
   functions.
3. The session's `success_url: "careqa://paywall?status=success"` (no
   `&source=checkout`) shows the **running app bundle is the OLD code**
   (not rebuilt). Matters for the web redirect; but the dashboard unlock
   is webhook-driven, so the webhook is the real blocker.
4. **`stripe_events` empty = Stripe never delivered a webhook event to
   the function** (or signature check rejected it). Because
   `STRIPE_WEBHOOK_SECRET` IS set, likely causes: no endpoint registered,
   or endpoint signing secret ≠ env secret.

### What was added to `stripe-webhook/index.ts`
Two dev-only helper branches (gated by request headers):

| Header | Behaviour |
|--------|-----------|
| `x-debug: 1` | Returns `{ endpoints[], existingEndpoint, webhookSecretSet, recentEvents[], recentOrgs[] }` — tells us in one call whether Stripe has our endpoint and what the DB holds. |
| `x-bootstrap: 1` | If no enabled endpoint points at
  `https://<project>.supabase.co/functions/v1/stripe-webhook`, **creates
  it** in Stripe with the six required events and returns the generated
  **signing secret** to store. |

> ⚠️ Dev-tool only — remove or gate before production.

### Runbook (run in YOUR terminal — the sandbox shell can't read the
CLI token file to create functions)

```powershell
# 1) Deploy the webhook function with the new debug/bootstrap helpers.
#    --use-api skips the Docker bundler if Docker isn't running.
cd "C:\Users\matth\src\XP Software\CareQA"
supabase functions deploy stripe-webhook --no-verify-jwt --use-api
```

```powershell
# 2) Debug: ask Stripe what webhook endpoints exist + see DB state.
$r = Invoke-RestMethod -Method Post `-Uri "https://aucflsskbhaloutsdlwc.supabase.co/functions/v1/stripe-webhook" `-Headers @{ "x-debug" = "1"; "Content-Type" = "application/json" } `-Body "{}"
$r | ConvertTo-Json -Depth 10
```

Interpret:
- `existingEndpoint` **non-null** → enabled endpoint exists; env secret
  may still not match → Stripe Dashboard → Webhooks → reveal signing
  secret → set it exactly → redeploy.
- `existingEndpoint: null` **and** `endpoints: []` → no endpoint → run
  bootstrap next.
- `endpoints` shows our URL but `status: disabled` → enable in dashboard.

```powershell
# 3) If no endpoint, auto-create it and capture the signing secret.
$r2 = Invoke-RestMethod -Method Post `-Uri "https://aucflsskbhaloutsdlwc.supabase.co/functions/v1/stripe-webhook" `-Headers @{ "x-bootstrap" = "1"; "Content-Type" = "application/json" } `-Body "{}"
$r2.bootstrap.newSecret   # whsec_... freshly generated for our endpoint
```

```powershell
# 4) Store that exact secret and redeploy.
supabase secrets set STRIPE_WEBHOOK_SECRET=<paste from step 3>
supabase functions deploy stripe-webhook --no-verify-jwt --use-api
```

```powershell
# 5) Re-run the debug: webhookSecretSet=true, existingEndpoint=non-null,
#    recentEvents should grow after the next payment.
$r3 = Invoke-RestMethod -Method Post `-Uri "https://aucflsskbhaloutsdlwc.supabase.co/functions/v1/stripe-webhook" `-Headers @{ "x-debug" = "1"; "Content-Type" = "application/json" } `-Body "{}"
$r3 | ConvertTo-Json -Depth 10
```

### Re-test
1. Rebuild the app (the running bundle is old):
   ```powershell
   cd "C:\Users\matth\src\XP Software\CareQA\admin-app"
   flutter run -d chrome      # web test
   # or
   flutter build apk --debug  # Android
   ```
2. Pay with `4242 4242 4242 4242`.
3. Verify DB (this time it MUST flip):
   ```sql
   SELECT event_type, organisation_id, created_at
   FROM public.stripe_events ORDER BY created_at DESC LIMIT 10;

   SELECT name, subscription_status, stripe_subscription_id
   FROM public.organisations ORDER BY created_at DESC LIMIT 5;
   ```
4. App console shows the access-granted line and the dashboard appears.

---

## 16. Update #9 — webhook endpoint EXISTS, secret set, but no events delivered (2026-09-03)

### Key debug output (from x-debug:1)
```json
{
  "webhookSecretSet": true,
  "webhookSecretPrefix": "whsec_h",
  "endpoints": [{
    "id": "we_1UAei3LZNCdxsglROaPLYEGO",
    "url": "https://aucflsskbhaloutsdlwc.supabase.co/functions/v1/stripe-webhook",
    "status": "enabled",
    "eventCount": 10
  }],
  "existingEndpoint": { "id": "we_1UAei3LZNCdxsglROaPLYEGO", "url": "...", "status": "enabled" },
  "recentEvents": [],
  "recentOrgs": [ ... incomplete/null ... ]
}
```

### What this tells us
1. A webhook endpoint **exists** and is **enabled**, pointing at our
   exact URL, with 10 enabled events.
2. `STRIPE_WEBHOOK_SECRET` **is set** (starts `whsec_h`).
3. `stripe_events` is **still empty** → NOT A SINGLE event has been
   delivered (or accepted) since the endpoint was created.
4. The orgs remain `incomplete`/`NULL` → consistent with no delivery.

### Root cause (one of two)
- **(A) Test vs Live mode mismatch.** The endpoint might be registered
  under a **Live** key while the app only creates **Test** events
  (`livemode: false` on the sessions). Test events only go to
  test-mode endpoints.
- **(B) Signing-secret mismatch.** The old `whsec_h…` stored in
  `STRIPE_WEBHOOK_SECRET` might not match the secret the endpoint was
  created with (e.g. rotated/recreated in the dashboard). Every
  delivered event then fails `constructEvent` → function returns 400 →
  no `stripe_events` row.

Third red herring: the user's **Stripe CLI** authorized to a DIFFERENT
sandbox: `Covenant House Studios sandbox · acct_1U6R4jLGfHfwI0vM`
while the app + endpoint live on `acct_1U6R4MLZNCdxsglR`.
`stripe trigger` in the wrong sandbox will never hit our endpoint.

### Fix implemented: `x-recreate: 1` helper
`stripe-webhook/index.ts` now supports three headers:
- `x-debug: 1` — full config + DB state (incl. the endpoint's
  enabled events so we can see if the required ones are listening).
- `x-bootstrap: 1` — create endpoint if missing (returns secret).
- `x-recreate: 1` — **DELETE** any existing endpoint at our URL, then
  create a fresh one, returning the **new signing secret**. This
  guarantees the env secret matches the endpoint, and (because the
  secret key `STRIPE_SECRET_KEY` is the test key) the endpoint is
  created in **TEST mode** matching the app's test events.

### PowerShell runbook (all PS — the user prefers PS)
```powershell
# 1) Deploy the updated webhook function (with --use-api, no Docker)
cd "C:\Users\matth\src\XP Software\CareQA"
supabase functions deploy stripe-webhook --no-verify-jwt --use-api

# 2) Recreate the endpoint deterministically (deletes existing + fresh)
$r = Invoke-RestMethod -Method Post `
  -Uri "https://aucflsskbhaloutsdlwc.supabase.co/functions/v1/stripe-webhook" `
  -Headers @{ "x-recreate" = "1"; "Content-Type" = "application/json" } `
  -Body "{}"
$secret = $r.bootstrap.newSecret          # whsec_... freshly created
$secret

# 3) Store that exact secret and redeploy
supabase secrets set STRIPE_WEBHOOK_SECRET=$secret
supabase functions deploy stripe-webhook --no-verify-jwt --use-api

# 4) Verify: webhookSecretSet=true, existingEndpoint=non-null,
#    enabledEvents includes checkout.session.completed etc.
$r2 = Invoke-RestMethod -Method Post `
  -Uri "https://aucflsskbhaloutsdlwc.supabase.co/functions/v1/stripe-webhook" `
  -Headers @{ "x-debug" = "1"; "Content-Type" = "application/json" } `
  -Body "{}"
$r2 | ConvertTo-Json -Depth 10
```

### Then send a test event on the CORRECT account
Use the **Stripe Dashboard** (not the CLI's wrong sandbox):
1. Stripe Dashboard → Developers → **Webhooks** → open our endpoint.
2. Make sure the **Test mode** toggle is on.
3. Click **"Send test webhook"** → choose `checkout.session.completed`.
4. Re-run the x-debug call or the SQL below — `stripe_events` should
   now grow.

### Re-test the full flow
1. Rebuild the app (running bundle is old):
   `flutter run -d chrome` or `flutter build apk --debug`.
2. Pay 4242 4242 4242 4242.
3. SQL:
   ```sql
   SELECT event_type, organisation_id, created_at
   FROM public.stripe_events ORDER BY created_at DESC LIMIT 10;
   SELECT name, subscription_status, stripe_subscription_id
   FROM public.organisations ORDER BY created_at DESC LIMIT 5;
   ```
4. Expect `stripe_events` rows + org `active`/`trialing` + the app
   console `PAYWALL_GATE: access granted (...) → showing
   authenticatedChild (AdminDashboard)` and the dashboard with the
   hamburger.

### Note about the repo-root `supabase.exe`
The project root has a 9-byte `supabase.exe` (from CLI init). In CMD on
Windows it resolves to this stub and fails with "not compatible with the
version of Windows". In PowerShell `supabase` resolves to the npm/global
one. To avoid the CMD confusion you can delete the stub:
```powershell
Remove-Item "C:\Users\matth\src\XP Software\CareQA\supabase.exe" -Force
```

---

## 17. Update #10 — webhook re-created & configured, still no events: forensic next steps (2026-09-04)

### Latest debug (x-debug:1) after re-creating the endpoint
```json
{
  "webhookSecretSet": true,
  "webhookSecretPrefix": "whsec_S",          // <- matches the fresh endpoint secret
  "existingEndpoint": { "id": "we_1UC3WsLZNCdxsglRqqin42Ll", "status": "enabled" },
  "enabledEvents": [
    "checkout.session.completed",
    "customer.subscription.created",
    "customer.subscription.updated",
    "customer.subscription.deleted",
    "invoice.payment_succeeded",
    "invoice.payment_failed"
  ],
  "recentEvents": [],                         // <- STILL EMPTY
  "recentOrgs": [ ... "incomplete"/null ... ]
}
```

### What this proves
- Endpoint is **enabled**, has **exactly the 6 required events**, and the
  env secret starts `whsec_S` — **matching** the endpoint's fresh secret.
- `stripe_events` is **empty** → **no event has been delivered since the
  re-create**.
- The app-level poll timing out with "Payment received but access is not
  confirmed yet" is **expected** when the org never flips — the frontend
  is NOT the problem.

### The two remaining possibilities
1. **The successful payment hit BEFORE the endpoint was re-created.**
   Stripe only sends events to the endpoint that exists at event time.
   Need a **fresh payment after the re-create** to test properly.
2. **Events are delivered but the handler silently doesn't write.**
   Old handler may have signature-failed 400, or `resolveOrgId` returned
   null and the update didn't happen.

### Forensic fix added: always log every delivered event
- `stripe-webhook/index.ts` now inserts `customer_email` and
  `session_id` into `stripe_events` alongside `organisation_id`, so even
  an unresolved event leaves a visible trace.
- New migration `160_stripe_events_debug.sql` adds those columns:
  `customer_email TEXT`, `session_id TEXT`.

### Runbook (user's PowerShell)
```powershell
# 1) Apply migrations 159 + 160 (SQL editor, since Docker unavailable).
#    In Supabase SQL editor:
#      - paste contents of 159_fix_carer_double_booking_trigger.sql
#      - paste contents of 160_stripe_events_debug.sql

# 2) Redeploy the webhook with forensic logging
cd "C:\Users\matth\src\XP Software\CareQA"
supabase functions deploy stripe-webhook --no-verify-jwt --use-api

# 3) Rebuild/restart the app so it's the post-fix bundle
cd "C:\Users\matth\src\XP Software\CareQA\admin-app"
flutter run -d chrome

# 4) NEW signup (do NOT reuse the earlier session) + pay 4242 4242 4242 4242

# 5) Verify
SELECT event_type, organisation_id, customer_email, session_id, created_at
FROM public.stripe_events ORDER BY created_at DESC LIMIT 10;
```
- Rows with `customer_email` + an `organisation_id` → webhook works;
  org should be `active`/`trialing`.
- Rows with `organisation_id = NULL` → event delivered but couldn't map
  to an org → check the `resolveOrgId` path (metadata missing).
- Still empty → Stripe Dashboard → the `we_1UC3Ws...` endpoint →
  **"Recent deliveries"** tab. That is GROUND TRUTH: it shows whether
  Stripe sent the event and what our function returned (200/400/5xx).

