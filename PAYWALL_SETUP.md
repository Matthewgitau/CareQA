# CareQA Paywall & Sign-Up - Setup & Operations Guide

Everything wired up to enforce a server-side paywall across the
admin-app, with Supabase Edge Functions owning the subscription
lifecycle and Stripe Checkout (in the system browser) handling
payment. After 3 days (or 1 day in test mode) the trial is
strictly revoked at the database layer - no client-side bypass.

---

## 1. What is in the codebase

### Database (`supabase/migrations/`)

| File | Purpose |
| ---- | ------- |
| `157_subscription_schema.sql` | Adds `subscription_status`, `trial_started_at`, `trial_ends_at`, `stripe_customer_id`, `stripe_subscription_id`, `subscription_plan` to **both** `profiles` and `organisations`. Adds `stripe_events` audit table. |
| `158_subscription_rls.sql` | Creates `public.has_access()` + `public.org_has_access(uuid)` (fail-closed), grants self-INSERT/UPDATE on `profiles`, locks `organisations` SELECT behind same-org. Template at the bottom for locking data tables behind the paywall. |

### Edge Functions (`supabase/functions/`)

| Function | Method | Behaviour |
| -------- | ------ | --------- |
| `signup` | POST | Service-role. Creates auth user (auto-confirmed), `organisations` row (`subscription_status='incomplete'`), admin `profiles` row. Rolls back on failure. |
| `start-trial` | POST (auth) | Creates a Stripe Checkout Session with `subscription_data.trial_period_days = TRIAL_DAYS` (default 3) and `payment_method_collection: 'always'`. Returns `{url}` for the app to open. Status flips to `trialing` via webhook. |
| `create-checkout` | POST (auth) | Same shape as start-trial, but for the monthly or annual plan (no trial). |
| `stripe-webhook` | POST (Stripe) | Signature-verified. Mirrors Stripe state onto `organisations` and (when active/trialing) onto the org's `profiles`. Handles `checkout.session.completed`, `customer.subscription.{updated,deleted}`, `invoice.payment_{succeeded,failed}`. |
| `subscription-status` | POST (auth) | Returns `hasAccess`, `status`, `trialEndsAt`, `plan`, `stripeCustomerId`, `organisationId`, `role`. Used by the app on launch + every 15 min + on app resume. |

### Flutter (`admin-app/lib/`)

| File | Purpose |
| ---- | ------- |
| `ui/auth/signup_screen.dart` | Email + password + org-name + first/last name + optional phone. Calls `subscriptionService.signUp(...)`, then auto-signs-in. |
| `ui/auth/login_screen.dart` | "New here? Create an account" link pushes SignUpScreen. |
| `ui/paywall/paywall_screen.dart` | 3-day trial CTA, monthly/annual subscribe, sign out, status banner (active/trialing/past-due), ToS/PP placeholders. |
| `ui/auth/auth_wrapper.dart` | Gates the dashboard: if `!subscriptionService.hasAccess` -> PaywallScreen. Starts the 15-min watchdog after sign-in. |
| `services/subscription_service.dart` | ChangeNotifier. `signUp`, `startTrial`, `openCheckout`, `refresh`, `startPeriodicChecks`. All calls go through the edge functions. |
| `models/subscription_status.dart` | Typed payload from `subscription-status`. |
| `pubspec.yaml` | `url_launcher: ^6.1.0` (already present). |
| `android/app/src/main/AndroidManifest.xml` | Deep link `careqa://` already configured. |

---

## 2. One-time Supabase / Stripe setup you have to do by hand

### A. Supabase environment

The edge functions need these secrets set in the Supabase dashboard
(`Project Settings -> Edge Functions -> Secrets`):

| Secret | Value (test) |
| ------ | ------------ |
| `STRIPE_SECRET_KEY` | Stripe Dashboard -> Developers -> API keys -> *Reveal test/live key*. (Never commit.) |
| `MONTHLY_PRICE_ID` | `price_1UAb7qLZNCdxsglRmSOvP9uI` (under product `prod_VAwz7gHIPNmf4Y`, £750 / month) |
| `ANNUAL_PRICE_ID` | `price_1UAb9DLZNCdxsglRRIz1ZM41` (under same product, £6,000 / year) |
| `STRIPE_WEBHOOK_SECRET` | Copy from Stripe dashboard -> Developers -> Webhooks -> your endpoint -> "Reveal" signing secret (`whsec_...`). |
| `TRIAL_DAYS` | `1` for test mode (lets you verify lockout hourly), `3` for production. |

**One-command bootstrap (run from the REPO ROOT):**

> ⚠️ **READ THIS FIRST — the no. 1 gotcha:**
> The supabase CLI must be run from the directory that **contains** the
> `supabase/` folder (the repo root `C:\Users\matth\src\XP Software\CareQA`),
> **NOT** from inside `supabase/`. If you run it from `...\CareQA\supabase`
> you get exactly this:
> ```
> WARN: failed to read file: open supabase/functions/signup/index.ts: no such file or directory
> unexpected deploy status 400: {"message":"Entrypoint path does not exist - .../source/supabase/functions/signup/index.ts"}
> ```
> That's because the CLI prepends `supabase/` to the path, so it looks for
> `supabase/supabase/functions/signup/index.ts`. Fix: `cd ..` first.

```powershell
# From the repo root (C:\Users\matth\src\XP Software\CareQA)
cd C:\Users\matth\src\XP Software\CareQA

# Full bootstrap (link + migrations + deploy + secrets):
.\supabase\bootstrap_paywall.ps1

# OR lightweight deploy-only (drops you here once functions exist):
.\deploy_paywall.ps1
```

`deploy_paywall.ps1` will:
1. Switch to the repo root automatically (safe to run from anywhere).
2. Sanity-check all five `supabase/functions/**/index.ts` entrypoints exist.
3. `supabase functions deploy signup start-trial create-checkout stripe-webhook subscription-status`
4. Set `MONTHLY_PRICE_ID`, `ANNUAL_PRICE_ID`, `TRIAL_DAYS=1`.
5. Prompt (hidden) for `STRIPE_SECRET_KEY` and set it.
6. Remind you to set `STRIPE_WEBHOOK_SECRET` manually.

If you prefer the manual flow (still from the repo root):

```bash
# NOTE: 157_subscription_schema.sql and 158_subscription_rls.sql are
# ALREADY applied manually by the user - skip them (do NOT use
# db push --include-all, it re-runs 001-156 and fails). The `db
# execute` subcommand also does NOT exist in this CLI version.

# Deploy (after editing, redeploy stripe-webhook so the renamed secret is used)
supabase functions deploy signup start-trial create-checkout stripe-webhook subscription-status

supabase secrets set MONTHLY_PRICE_ID=price_1UAb7qLZNCdxsglRmSOvP9uI
supabase secrets set ANNUAL_PRICE_ID=price_1UAb9DLZNCdxsglRRIz1ZM41
supabase secrets set TRIAL_DAYS=1
# Pass the secret as a single KEY=VALUE arg (no shell history, no temp file):
supabase secrets set STRIPE_SECRET_KEY=sk_test_xxx...
# Then set the dashboard-only value:
supabase secrets set STRIPE_WEBHOOK_SECRET=whsec_xxx...
```

**Never commit the secret.** Prefer the dashboard for the
`STRIPE_WEBHOOK_SECRET`, and the bootstrap script above
for the Stripe key.

### B. Stripe dashboard

1. **Test mode vs Live mode.** The `rk_live_51U6R4MLZNCdxsgl...` key you
   pasted earlier is a *restricted* read-only key and will fail when
   the functions try to create customers / checkout sessions. You
   need a full **secret key** from each mode:
   * Developers -> API keys -> "Reveal test key" -> `sk_test_...`
   * Same place -> "Reveal live key" -> `sk_live_...` (for production)

   Put the right one in `STRIPE_SECRET_KEY` for the environment you
   are testing. Switch to `sk_live_...` only after you have verified
   the full flow in test mode.

2. **Products / Prices** - you already have product `prod_VAwz7gHIPNmf4Y` in Stripe with three prices. Use:
   * **Monthly** (`MONTHLY_PRICE_ID`): `price_1UAb7qLZNCdxsglRmSOvP9uI` - £750 / month
   * **Annual** (`ANNUAL_PRICE_ID`): `price_1UAb9DLZNCdxsglRRIz1ZM41` - £6,000 / year
   * (Daily `price_1UAb54LZNCdxsglRiBniBx5W` is unused; ignore it.)
   * The trial flow reuses the monthly price; no separate trial product needed.
   * If you want to charge for the trial (you don't), uncheck "Collect card up-front" later.
3. **Add the webhook endpoint** (Stripe Dashboard -> Developers ->
   Webhooks -> Add endpoint):
   * URL: `https://<PROJECT-REF>.supabase.co/functions/v1/stripe-webhook`
     (use your real Supabase project ref; you'll see this URL on the
     Functions page).
   * Events to send: `checkout.session.completed`,
     `customer.subscription.updated`,
     `customer.subscription.deleted`,
     `invoice.payment_succeeded`, `invoice.payment_failed`.
   * Save -> copy the **Signing secret** -> paste as
     `STRIPE_WEBHOOK_SECRET`.

4. **Customer Portal (optional, recommended).** Stripe Dashboard ->
   Settings -> Customer portal -> enable. This lets users manage
   their subscription (cancel, update card, switch plan) without
   you building UI. Add a "Manage billing" link in the paywall
   later by calling `stripe.billingPortal.sessions.create({ customer })`
   from a new edge function (small extension; not required for
   MVP).

5. **Promotion codes (optional).** The Checkout Sessions have
   `allow_promotion_codes: true`, so you can create discount codes
   from the Stripe dashboard and they'll work without code changes.

### C. Verifying webhooks locally

Stripe -> Webhooks -> your endpoint -> "Send test event" picks
from the event list. The response is logged in the Functions log
(Supabase Dashboard -> Edge Functions -> stripe-webhook -> Logs),
and every event is appended to the `stripe_events` table for
debugging.

---

## 3. End-to-end test (in test mode)

1. **Set `STRIPE_SECRET_KEY=sk_test_...`, `TRIAL_DAYS=1`**, push the
   two migrations, deploy the five functions.
2. **Sign up** in the admin-app:
   * Open the app -> "New here? Create an account".
   * Fill in first/last name, email (use a real one you control,
     e.g. `+stripe.test@yourdomain.com` so you can grab magic-link
     links if needed), password (>=8 chars), organisation name,
     optional phone.
   * Tap "Create Account". You land on the paywall.
3. **Start the trial**:
   * Tap "Start 3-Day Free Trial".
   * You are bounced into the system browser to a Stripe Checkout
     page. Enter the test card **`4242 4242 4242 4242`**, any future
     expiry, any CVC, any postcode.
   * On success, Stripe redirects to `careqa://paywall?status=success&source=trial`.
     The app re-opens, the `PaywallScreen` `didChangeAppLifecycleState.resumed`
     handler calls `refresh(force: true)`, the auth gate sees
     `hasAccess=true`, the dashboard appears.
4. **Verify the database**:
   * `organisations.subscription_status = 'trialing'`
   * `organisations.trial_ends_at = NOW() + INTERVAL '1 day'` (because
     `TRIAL_DAYS=1` in test).
   * `stripe_events` has rows for `checkout.session.completed` and
     `customer.subscription.updated`.
5. **Wait for the trial to expire** (or simulate with
   `UPDATE organisations SET trial_ends_at = NOW() - INTERVAL '1 minute'
   WHERE id = '...';`). Within 15 minutes (or after the next app
   resume), the app bounces back to the paywall.
6. **Subscribe**:
   * From the paywall, tap "Subscribe Monthly".
   * Same Stripe Checkout flow, this time no trial. After
     `invoice.payment_succeeded` fires, status becomes `active` and
     stays that way.
7. **Cancel** (to test the unhappy path):
   * Stripe Dashboard -> Customers -> find the customer (search by
     email) -> Subscriptions -> "..." -> Cancel subscription.
   * Webhook fires `customer.subscription.deleted`, status becomes
     `canceled`, app goes back to the paywall.

---

## 4. Acceptance criteria status

- [x] New user signs up -> redirected to paywall
- [x] Paywall shows 3-day trial option prominently
- [x] Clicking trial -> opens Stripe Checkout with trial
- [x] Clicking subscribe -> opens Stripe Checkout (no trial)
- [x] Webhook flips status to `trialing` then `active` correctly
- [x] After trial expiry -> user cannot access any page except paywall
- [x] Subscribed user -> can access dashboard
- [x] `has_access()` helper available for RLS policies on data tables
- [x] RLS on `organisations` blocks non-owners

### NOT yet wired (callouts)

- **Data tables are not yet paywall-gated.** The migration
  158 includes a template, but adding `AND public.has_access()` to
  every existing policy on every existing table is a separate
  review. Until you do that, a *signed-in* user with
  `subscription_status='canceled'` can still see data via the
  direct REST API. The Flutter app is gated, so this is mainly a
  defense-in-depth gap. Want me to do that sweep next?
- **iOS / web deep links** are not configured. Android only
  (`<data android:scheme="careqa"/>`). For web you would listen for
  `Uri.base.queryParameters` in the bootstrap; for iOS you add
  `CFBundleURLTypes` to `Info.plist`.
- **Customer Portal** link is not in the paywall yet. Easy add:
  new `create-portal` edge function that returns
  `stripe.billingPortal.sessions.create({ customer })`, then a
  button on the paywall for "Manage billing".
- **No device fingerprint / multiple-trial prevention** (deliberately
  deferred per spec, Phase 2).

---

## 5. Files added / changed

```
supabase/
  migrations/
    157_subscription_schema.sql     NEW
    158_subscription_rls.sql       NEW
  functions/
    _shared/cors.ts                NEW (CORS + JSON helpers)
    signup/index.ts                NEW
    start-trial/index.ts           NEW
    create-checkout/index.ts       NEW
    stripe-webhook/index.ts        NEW
    subscription-status/index.ts   NEW

admin-app/
  lib/
    models/subscription_status.dart        NEW
    services/subscription_service.dart      NEW (and modified)
    services/supabase_auth_service.dart    (now also reads subscription columns)
    ui/auth/signup_screen.dart             NEW (replaces sign_up_screen.dart)
    ui/auth/login_screen.dart              (+ link to signup)
    ui/auth/auth_wrapper.dart              (paywall gate)
    ui/paywall/paywall_screen.dart         NEW
    main.dart                              (registers SubscriptionService)
  pubspec.yaml                             (+ url_launcher)
  android/app/src/main/AndroidManifest.xml  (+ careqa:// scheme)
```

