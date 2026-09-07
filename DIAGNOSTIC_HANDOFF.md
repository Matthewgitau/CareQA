# Paywall / Signup Diagnostic Handoff

**Project:** CareQA admin-app (Flutter Web, Supabase, Stripe)
**Stripe project:** `acct_1U6R4MLZNCdxsglR` (test mode)
**Supabase project:** `aucflsskbhaloutsdlwc`
**Deployed functions (latest):**
- `signup` v15 (2026-09-03 15:57 UTC)
- `create-checkout` v15 (2026-09-03 18:57 UTC)
- `start-trial` v15 (2026-09-03 18:57 UTC)
- `subscription-status` v15 (2026-09-03 18:57 UTC)
- `stripe-webhook` v19 (2026-09-04 20:16 UTC)

---

## What works ✅

1. **Signup** creates auth user + org + profile with `subscription_status='incomplete'`.
2. **Stripe Checkout** opens successfully with the test card `4242 4242 4242 4242`. Confirmed in Stripe logs:
   - `payment_status: "paid"`, `status: "complete"`, `state: "succeeded"`
   - `mode: "subscription"`, `currency: "gbp"`, £750.00
3. **JWT attach fix** in `create-checkout`/`start-trial`/`subscription-status` is **live** — the session was created (so org was resolved by the user lookup).
4. **Web redirect** back to the app's own origin now works (`success_url: http://localhost:51371/?status=success&source=checkout`).
5. **App poll for access** runs after return, shows the green "Payment received — checking your subscription…" banner.
6. **Stripe webhook endpoint exists** in the dashboard, is **enabled**, with **all 6 required events subscribed** (verified by `x-debug:1` helper below).
7. **Stripe webhook signing secret** in Supabase env matches the endpoint's secret (both start `whsec_S…`).

---

## What is broken ❌

### Symptom 1 — "No organisation linked to this account" (HTTP 400)
- **Resolved by Update #3 / JWT fix.** Should be gone after the redeploy of `create-checkout`/`start-trial`/`subscription-status` (Sept 3 18:57 UTC). If you still see it, the running app bundle is stale (rebuild).

### Symptom 2 — "Payment received but access is not confirmed yet" (poll timeout)
- **The poll times out ~30s after return because `subscription-status` keeps returning `hasAccess: false`.**
- The poll is doing the right thing — the org never flipped to `active`/`trialing` server-side.
- **This is a webhook delivery / processing problem**, not a Flutter bug.

### Symptom 3 — Dev console errors on / after a successful payment
```
Uncaught TypeError: Cannot read properties of null (reading 'removeChild')
at HTMLDocument.<anonymous> (main.dart.js:71:22)
...
supabase.auth: INFO: Received broadcast event: SIGNED_OUT
supabase.auth: INFO: Received broadcast event: SIGNED_IN
```
- `removeChild` on `null` is from `main.dart.js:71` — a `MutationObserver`/`document.head` interaction in the Flutter web entry. Often caused by Flutter tearing down a sub-tree while a DOM mutation is queued.
- The repeated `SIGNED_OUT` / `SIGNED_IN` events suggest **`AuthWrapper` is being rebuilt and `signOut()` is being called during the build** (we previously had a "setState during build" exception). This is consistent with the app cycling through sign-in/sign-out because:
  - Either `hasAccess` flips true → dashboard mounts → some sub-widget triggers `signOut()` immediately (race).
  - Or the auth listener is firing twice during the boot of the paywall return.

### Symptom 4 — Stuck on signup, no nav to login
- `signup_screen.dart`'s `_submit()` flow: `signup` → `signInWithEmailPassword` → if success, **do nothing** (AuthWrapper reacts to auth state). The on-failure branch is **inverted** (shows "Please sign in" when sign-in actually fails, and does nothing on success). Not a blocker, but causes confusion.
- Combined with Symptom 3 (SIGNED_OUT after sign-in), the user lands back on login.

### Symptom 5 — Polling never unlocks dashboard
- `subscription-service.pollUntilAccess()` exits after ~30s. If `stripe_events` is empty, **the webhook is not delivering events to our function**. The org stays `incomplete` → `hasAccess = false` → paywall stays. **This is the primary blocker.**

---

## Verification SQL (run in Supabase SQL editor)

```sql
-- 1. Did ANY webhook event ever land?
SELECT event_type, organisation_id, customer_email, session_id, created_at
FROM public.stripe_events ORDER BY created_at DESC LIMIT 10;

-- 2. Org state
SELECT name, subscription_status, stripe_subscription_id, trial_ends_at
FROM public.organisations ORDER BY created_at DESC LIMIT 5;

-- 3. Profile state for the current account
SELECT u.email, p.role, p.organisation_id, p.subscription_status
FROM auth.users u
LEFT JOIN public.profiles p ON p.id = u.id
ORDER BY u.created_at DESC LIMIT 5;
```

Expected: rows in `stripe_events`, the org `active` or `trialing`, and `profile.organisation_id` set.

---

## Diagnostic helpers (deployed, live)

### A. `x-debug: 1` — full ground truth
```powershell
$r = Invoke-RestMethod -Method Post `
  -Uri "https://aucflsskbhaloutsdlwc.supabase.co/functions/v1/stripe-webhook" `
  -Headers @{ "x-debug" = "1"; "Content-Type" = "application/json" } `
  -Body "{}"
$r | ConvertTo-Json -Depth 10
```
Returns: `webhookSecretSet`, `webhookSecretPrefix`, `endpoints[]` (with `enabledEvents`), `existingEndpoint`, `recentEvents`, `recentOrgs`. Use this to confirm endpoint + secret + subscribed events in one call.

### B. `x-recreate: 1` — guarantees a fresh endpoint
```powershell
$r = Invoke-RestMethod -Method Post `
  -Uri "https://aucflsskbhaloutsdlwc.supabase.co/functions/v1/stripe-webhook" `
  -Headers @{ "x-recreate" = "1"; "Content-Type" = "application/json" } `
  -Body "{}"
$secret = $r.bootstrap.newSecret          # the brand-new whsec_...
supabase secrets set STRIPE_WEBHOOK_SECRET=$secret
supabase functions deploy stripe-webhook --no-verify-jwt --use-api
```

---

## Most-likely root causes (ranked)

### Cause A — Test-mode vs Live-mode endpoint mismatch
**Probability:** HIGH

The Stripe log shows `livemode: false` on every event. If the configured endpoint in the dashboard is on a **live** mode Stripe account (or vice-versa), test events go nowhere.

**How to verify:** in `x-debug: 1` response, the endpoint's `id` and `url` are present but the dashboard "Recent deliveries" tab on the endpoint shows **no deliveries** despite a successful test payment. Then this is the cause.

**Fix:** ensure the endpoint is in **Test mode** (top-right toggle in the dashboard) and the dashboard's account matches `acct_1U6R4MLZNCdxsglR`.

### Cause B — Signing secret mismatch (less likely now)
**Probability:** MEDIUM

If the env secret `STRIPE_WEBHOOK_SECRET` doesn't match the endpoint's actual signing secret, every event delivery returns **HTTP 400** (signature verification fails) and the function never writes to `stripe_events`. The endpoint's secret can be revealed in the dashboard.

**How to verify:** `x-debug: 1` shows the env secret prefix; the dashboard shows the endpoint's secret. They must match exactly.

**Fix:** re-create the endpoint with `x-recreate: 1` and store the new secret (as shown above). This was done on 2026-09-04 and the prefix now matches (`whsec_S…`).

### Cause C — Stripe CLI used wrong sandbox
**Probability:** MEDIUM (if user re-runs `stripe trigger` for tests)

The `stripe` CLI in the dev environment was logged in to a **different sandbox** (`acct_1U6R4jLGfHfwI0vM`), not the one the app uses (`acct_1U6R4MLZNCdxsglR`). `stripe trigger` in the wrong account never reaches our endpoint.

**Fix:** for testing, use the **Stripe Dashboard** → Webhooks → "Send test webhook" on the **correct** endpoint (or re-authorise the CLI with the right account).

### Cause D — `organisation_id` metadata missing
**Probability:** MEDIUM

`stripe-webhook` resolves the org from `session.metadata.organisation_id`, then from `customer.metadata.organisation_id`, then from a `stripe_customer_id` lookup. If the checkout session was created by an **old app bundle** that didn't pass `organisation_id` in metadata, the org can't be matched and the update is skipped.

**How to verify:** the `stripe_events` row exists, but `organisation_id` is `NULL`. The org stays `incomplete`.

**Fix example** (TypeScript, in `create-checkout`/`start-trial`):
```ts
// create-checkout/index.ts
const session = await stripe.checkout.sessions.create({
  mode: 'subscription',
  customer: customerId,
  line_items: [{ price: priceId, quantity: 1 }],
  success_url: successUrl,
  cancel_url: cancelUrl,
  allow_promotion_codes: true,
  metadata: { organisation_id: profile.organisation_id },   // <-- THIS
  subscription_data: {
    metadata: { organisation_id: profile.organisation_id },   // <-- AND THIS
  },
});
```
The live deployed function already does this — but an old bundle from before the fix wouldn't. Re-verify with a fresh app build.

### Cause E — `removeChild` DOM error in Flutter web
**Probability:** MEDIUM (orthogonal to paywall)

`main.dart.js:71 removeChild on null` is a known Flutter-web issue when a widget is disposed while a `MutationObserver`/`dart:html` interaction is still queued. Triggers: hot-restart during a route transition, an unhandled exception in `build`, or a parent widget rebuilding and unmounting a child mid-frame.

**Fix options to try:**
1. Make `main.dart` boot **after** `WidgetsFlutterBinding.ensureInitialized()` and use `runApp(ProviderScope(child: ...))`; never call `signOut()` from `build`.
2. Wrap the post-payment poll in a `Future.microtask` (or `WidgetsBinding.instance.addPostFrameCallback`) so it never runs inside `build`.
3. Add `debugDefaultTargetPlatformOverride` and avoid mounting `MaterialApp.home` and calling `Navigator.push` in the same frame.
4. In Flutter web, prefer `flutter build web --release` for production; dev builds have the `extension-debug` connection that can be torn down at the same time as a route change — which is exactly the trace in the error (`_launchCommunicationWithDebugExtension`).

### Cause F — `AuthWrapper` cycles SIGNED_OUT / SIGNED_IN
**Probability:** HIGH (related to Cause E)

The repeating `SIGNED_OUT` / `SIGNED_IN` events in the log suggest the `onAuthStateChange` listener in `SupabaseAuthService` is being torn down and re-created. The most common cause is that `MultiProvider`/`MaterialApp` is being rebuilt (e.g. by a hot-restart or by an error in `build`). The sign-out happens via the AppBar's `onSignOut` callback chain in the paywall.

**Fix example (Dart):**
```dart
// In SupabaseAuthService constructor, store the subscription and never
// re-attach on every rebuild:
class SupabaseAuthService extends ChangeNotifier {
  StreamSubscription<AuthState>? _sub;
  SupabaseAuthService(this._supabase) {
    _sub = _supabase.auth.onAuthStateChange.listen((data) {
      _currentUser = data.session?.user;
      notifyListeners();
    });
  }
  @override
  void dispose() { _sub?.cancel(); super.dispose(); }
}
```
And in `auth_wrapper.dart`:
```dart
// Replace any in-build signOut / refresh with:
WidgetsBinding.instance.addPostFrameCallback((_) async {
  if (!mounted) return;
  await context.read<SubscriptionService>().refresh(force: true);
});
```

### Cause G — Inverted error branch in `signup_screen.dart`
**Probability:** LOW (UX only)

```dart
// WRONG (current):
if (!result.success) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Account created. Please sign in.')),
  );
}
// On success: nothing.

// CORRECT:
if (!result.success) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Sign-in failed: ${result.errorMessage ?? 'unknown'}')),
  );
  return;
}
// On success: AuthWrapper reacts to the auth state and routes to paywall.
```

---

## Files most likely to need changes

(For a developer who doesn't have the codebase — these are the file paths and what to look at.)

| File | Purpose | Current state |
|------|---------|---------------|
| `supabase/functions/stripe-webhook/index.ts` | Receives Stripe events, flips org status | Has debug helpers; uses `resolveOrgId` |
| `supabase/functions/create-checkout/index.ts` | Creates Stripe session | JWT-attach fix applied |
| `supabase/functions/start-trial/index.ts` | Creates trial session | JWT-attach fix applied |
| `supabase/functions/subscription-status/index.ts` | Returns `hasAccess` | JWT-attach fix applied |
| `supabase/functions/signup/index.ts` | Creates user + org + profile | Upsert fix applied |
| `supabase/migrations/159_fix_carer_double_booking_trigger.sql` | Fixes broken `check_carer_double_booking` trigger | Created (not yet applied to DB) |
| `supabase/migrations/160_stripe_events_debug.sql` | Adds `customer_email`, `session_id` to `stripe_events` | Created (not yet applied to DB) |
| `admin-app/lib/services/subscription_service.dart` | Edge function client + polling | `_deferNotify` + `pollUntilAccess` added |
| `admin-app/lib/services/supabase_auth_service.dart` | Auth state + signOut | `signOut` hardened; **suspect: `_sub` may be re-attached on rebuild** |
| `admin-app/lib/ui/auth/auth_wrapper.dart` | Routes between login/paywall/dashboard | Post-frame callback for first refresh; **suspect: rebuilds during auth state change** |
| `admin-app/lib/ui/paywall/paywall_screen.dart` | Paywall UI | "Check payment status" button; poll on return |
| `admin-app/lib/main.dart` | Boot | `_handleWebPaywallRedirect` for web deep-link |

---

## Runbook to attempt a fix

### 1. Apply the two new migrations
In Supabase SQL editor, paste and run:
- `supabase/migrations/159_fix_carer_double_booking_trigger.sql`
- `supabase/migrations/160_stripe_events_debug.sql`

### 2. Redeploy the webhook
```powershell
cd "C:\Users\matth\src\XP Software\CareQA"
supabase functions deploy stripe-webhook --no-verify-jwt --use-api
```

### 3. Re-create the webhook endpoint (idempotent)
```powershell
$r = Invoke-RestMethod -Method Post `
  -Uri "https://aucflsskbhaloutsdlwc.supabase.co/functions/v1/stripe-webhook" `
  -Headers @{ "x-recreate" = "1"; "Content-Type" = "application/json" } `
  -Body "{}"
$secret = $r.bootstrap.newSecret
supabase secrets set STRIPE_WEBHOOK_SECRET=$secret
supabase functions deploy stripe-webhook --no-verify-jwt --use-api
```

### 4. Rebuild the app (clean state, **release** preferred)
```powershell
cd "C:\Users\matth\src\XP Software\CareQA\admin-app"
flutter run -d chrome           # dev
# or
flutter build web --release    # release, no devtools tearing down DOM
```

### 5. New signup, new payment
Sign up a fresh email and pay `4242 4242 4242 4242`. **Do not reuse the previous session.**

### 6. Verify
```sql
SELECT event_type, organisation_id, customer_email, session_id, created_at
FROM public.stripe_events ORDER BY created_at DESC LIMIT 10;
```
- Rows appear with `organisation_id` non-null → webhook works → org flips → dashboard unlocks.
- Rows appear with `organisation_id = NULL` → event delivered but couldn't match (Cause D). Fix the metadata in `create-checkout`/`start-trial`.
- No rows → Stripe didn't deliver. Go to **Dashboard → Webhooks → we_1UC3Ws… → "Recent deliveries"**. That tab is ground truth.

---

## Key code snippets (for the remote developer)

### `create-checkout/index.ts` — must include metadata
```ts
const session = await stripe.checkout.sessions.create({
  mode: 'subscription',
  customer: customerId,
  line_items: [{ price: priceId, quantity: 1 }],
  success_url: successUrl,
  cancel_url: cancelUrl,
  allow_promotion_codes: true,
  metadata: { organisation_id: profile.organisation_id },
  subscription_data: {
    metadata: { organisation_id: profile.organisation_id },
  },
});
```

### `stripe-webhook/index.ts` — must always log to `stripe_events`
```ts
await supabase.from('stripe_events').insert({
  stripe_event_id: event.id,
  event_type: event.type,
  payload: event.data.object as Record<string, unknown>,
  organisation_id: organisationId,
  customer_email: typeof evtObj?.customer_email === 'string' ? evtObj.customer_email : null,
  session_id: typeof evtObj?.id === 'string' ? evtObj.id : null,
});
```

### `subscription-service.dart` — `_deferNotify` (build-phase safe)
```dart
void _deferNotify() {
  scheduleMicrotask(notifyListeners);
}
```
Use `_deferNotify()` instead of `notifyListeners()` everywhere in `refresh()` to avoid `setState() called during build`.

### `auth_wrapper.dart` — never run async in `build()`
```dart
void _ensureChecksStarted() {
  if (_checksStarted) return;
  final authService = context.read<SupabaseAuthService>();
  if (!authService.isAuthenticated || authService.userRole == null) return;
  _checksStarted = true;
  final subscriptionService = context.read<SubscriptionService>();
  subscriptionService.startPeriodicChecks();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;
    subscriptionService.refresh(force: true);
  });
}
```

---

## Ask the remote developer for advice on

1. Why `removeChild` throws in `main.dart.js:71` after a successful payment — is this a known Flutter web regression, or are we tearing down the root element incorrectly from a hot restart?
2. Why `SIGNED_OUT` / `SIGNED_IN` broadcast events alternate rapidly in the dev console — is the auth listener being re-attached on every `AuthWrapper` rebuild, and is the correct pattern a single subscription stored on the service?
3. Given the `x-debug: 1` evidence (endpoint enabled, secret matches, events subscribed) and an empty `stripe_events` table, what is the cheapest, deterministic test to know whether Stripe is delivering or not? (Dashboard "Recent deliveries" is the user's next move; if the user has done that and reports no deliveries, the question is "why is Stripe not delivering to this endpoint when the URL and event list are correct?")

---

## ⚠️ NOTE FOR THE REMOTE DEVELOPER — DO NOT "FIX" WITH A JWT AUTH BYPASS

A proposed fix of "add a JWT auth bypass to `stripe-webhook`" is **WRONG** for this codebase. The function is already deployed with `--no-verify-jwt`, and the source code (lines 180–181) already checks for `stripe-signature` (not Supabase JWT). Verified by a live test (2026-09-04 23:xx UTC):

```powershell
# POST without ANY headers (mimics Stripe's first attempt):
STATUS: 400
BODY: {"error":"Missing stripe-signature header"}
```

That is the **correct** behaviour: a 400 (not 401) telling Stripe to send the signature. The Supabase auth-gateway in front of functions would return 401 `UNAUTHORIZED_NO_AUTH_HEADER` for *any* invocation, and the gateway is bypassed precisely by `--no-verify-jwt`. So if a 401 was observed, it was coming from:
- the **Flutter client** calling `subscription-status` (etc.) without an anon JWT attached (e.g. right after signOut), or
- a **second layer** (CDN / auth proxy / something else) **before** the function URL.

The right next investigation is **Stripe Dashboard → Webhooks → `we_1UC3Ws…` → "Recent deliveries"**. Each row there shows the literal HTTP status our function returned, plus the request body sent. That's the single source of truth.

---

## End of handoff
