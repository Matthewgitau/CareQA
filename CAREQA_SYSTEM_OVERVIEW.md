# CareQA — Complete System Overview & Architecture Reference

**Date:** 22 August 2026
**Purpose:** A complete, self-contained breakdown of the CareQA platform — every app, every page, every function, every database table touched, what is wired vs. orphaned, and what should be built next.
**Audience:** Any developer, consultant, or stakeholder. No prior codebase knowledge required.
**Method:** Every claim in this document was verified against the actual source code and Supabase migration files in this repository. File paths and line references are given throughout.

---

## Table of Contents

1. [What CareQA Is](#1-what-careqa-is)
2. [Platform Architecture at a Glance](#2-platform-architecture-at-a-glance)
3. [Technology Stack & External Dependencies](#3-technology-stack--external-dependencies)
4. [The Database — Complete Table Inventory by Domain](#4-the-database--complete-table-inventory-by-domain)
5. [Migration Status](#5-migration-status)
6. [Multi-Tenant Structure](#6-multi-tenant-structure)
7. [ADMIN-APP — Complete Page-by-Page Breakdown](#7-admin-app--complete-page-by-page-breakdown)
8. [STAFF-APP — Complete Page-by-Page Breakdown](#8-staff-app--complete-page-by-page-breakdown)
9. [CLIENT-APP — Complete Page-by-Page Breakdown](#9-client-app--complete-page-by-page-breakdown)
10. [Cross-App Data Flows](#10-cross-app-data-flows)
11. [APIs, Endpoints & External Services](#11-apis-endpoints--external-services)
12. [Dummy / Dead / Orphaned Pages — Master Inventory](#12-dummy--dead--orphaned-pages--master-inventory)
13. [Known Broken or Risky Areas](#13-known-broken-or-risky-areas)
14. [What Should Be Done Next — Prioritised Roadmap](#14-what-should-be-done-next--prioritised-roadmap)

---

## 1. What CareQA Is

CareQA is a **multi-tenant care-management platform** for the UK domiciliary and residential care sector. It is built as **three separate Flutter applications** that share **one Supabase (Postgres) backend**:

| App | Package name | Users | Purpose |
|---|---|---|---|
| **admin-app** | `admin_app` | Care-agency admins/managers | Run the agency: staff, service users, shifts, routes, compliance, risk assessments, audits, medication, finance, safeguarding, lessons-learnt, policies, invoicing. This is by far the largest app (~90 models, ~100 services, ~160 screens). |
| **staff-app** | `staff_app` | Carers / care staff | See assigned shifts and route calls, clock in/out, complete care charts (food & fluid, bowel & bladder, sleep, repositioning), risk-assessment forms, competencies, MAR chart. |
| **client-app** | `careqa_client` | Client organisations (care homes who buy care) | Book shifts from the agency, broadcast shifts to preferred service providers (PSL), view routes for their organisation, manage sub-users and preferred carers, rate carers. |

**The business model the software encodes:** a care agency (the "organisation") supplies carers to client organisations (care homes). Clients request shifts; the agency admin confirms and assigns carers; carers see their work in the staff app and document care delivery; everything is audited for CQC-style compliance (the app is saturated with risk assessments, audits, MAR charts, safeguarding, and lessons-learnt modules that map to UK care regulation).

---
## 2. Platform Architecture at a Glance

```
                        ┌──────────────────────────────────────────┐
                        │           SUPABASE (single project)      │
                        │  aucflsskbhaloutsdlwc.supabase.co        │
                        │                                          │
                        │  ┌────────────┐  ┌──────────────────┐    │
                        │  │ GoTrue     │  │ Postgres + RLS   │    │
                        │  │ (auth.users)│ │ (~150 tables)    │    │
                        │  └────────────┘  └──────────────────┘    │
                        │  ┌────────────┐  ┌──────────────────┐    │
                        │  │ PostgREST  │  │ Storage          │    │
                        │  │ (auto REST)│  │ (documents etc.) │    │
                        │  └────────────┘  └──────────────────┘    │
                        └────────────┬─────────────────────────────┘
                                     │  supabase_flutter SDK (direct)
          ┌──────────────────────────┼──────────────────────────────┐
          │                          │                              │
   ┌──────┴───────┐          ┌───────┴────────┐            ┌────────┴───────┐
   │  ADMIN-APP   │          │   STAFF-APP    │            │  CLIENT-APP    │
   │  (Flutter)   │          │   (Flutter)    │            │  (Flutter)     │
   │ ~160 screens │          │ ~60 screens    │            │ ~18 screens    │
   │ ~100 services│          │ ~22 services   │            │ ~11 services   │
   └──────────────┘          └────────────────┘            └────────────────┘
```

**Key architectural facts (verified in code):**

- **No custom backend API.** All three apps talk directly to Supabase via the `supabase_flutter` SDK, which wraps PostgREST. The "API layer" is the Postgres schema + Row Level Security.
- **One shared database, one auth realm.** A person is one row in `auth.users` and one row in `public.profiles`. Role separation is done via `profiles.role` and RLS policies, not by separate databases.
- **State management:** `provider` package in all three apps (`ChangeNotifierProvider` / `Provider`), wired in each `main.dart`.
- **Env config:** each app loads `.env` at startup via `flutter_dotenv` (`SUPABASE_URL`, `SUPABASE_ANON_KEY`).
  - `admin-app/lib/main.dart` and `staff-app/lib/main.dart` hard-require these (`!` null assertion — crash if missing).
  - `client-app/lib/main.dart` has **hardcoded fallback credentials** in source (lines 27–29: URL `https://aucflsskbhaloutsdlwc.supabase.co` plus an anon key) — a security smell worth noting.
- **Legacy naming:** `staff-app/lib/services/firestore_service.dart` is **not Firebase** — it is a Supabase-backed service class that kept its old name after a Firebase→Supabase migration (see `verify_migration.sh`, which checks staff-app for `supabase_flutter`). Both admin-app and staff-app still ship `firebase_options.dart` at their roots — vestigial from that migration; no Firebase dependency exists in any pubspec.
- **Shared code:** `client-app` depends on a local package `core` (`packages/core`) for the `Shift` model; admin-app and staff-app **duplicate** their own `Shift` models locally instead (a known divergence documented in `SHIFTS_SCREEN_ANALYSIS_REPORT.md`).

---

## 3. Technology Stack & External Dependencies

### 3.1 admin-app (`admin-app/pubspec.yaml`)

| Dependency | Version | Used for |
|---|---|---|
| `supabase_flutter` | ^2.2.0 | Database, auth, storage |
| `provider` | ^6.1.1 | State management |
| `intl` | ^0.19.0 | Date/number formatting |
| `flutter_dotenv` | ^5.1.0 | `.env` credentials |
| `local_auth` | ^2.1.8 | Biometric unlock |
| `shared_preferences` | ^2.2.2 | Session caching |
| `get_it` | ^7.6.7 | Service locator |
| `file_picker`, `image_picker` | — | Document/photo upload |
| `google_mlkit_text_recognition` | ^0.12.0 | OCR for scanning documents/forms |
| `pdf`, `printing`, `share_plus` | — | Report/PDF generation and export |
| `fl_chart` | ^0.68.0 | Dashboard charts |
| `uuid`, `logger`, `path_provider` | — | Utilities |

### 3.2 staff-app (`staff-app/pubspec.yaml`)

Same core stack minus admin extras: `supabase_flutter`, `provider`, `intl`, `flutter_dotenv`, `local_auth`, `shared_preferences`, `get_it`, `logger`. No charts, no PDF, no OCR.

### 3.3 client-app (`client-app/pubspec.yaml`)

`supabase_flutter`, `flutter_dotenv`, **`core` (local path package)**, `local_auth`, `provider`, `shared_preferences`, `intl`, `get_it`, `logger`, `timeago`, `cached_network_image`.

### 3.4 External services actually in use

| Service | Where | Evidence |
|---|---|---|
| Supabase Auth (GoTrue) | All 3 apps | `Supabase.initialize` in each `main.dart`; `SupabaseAuthService` per app |
| Supabase Postgres (PostgREST) | All 3 apps | `.from('<table>')` calls in every service file |
| Supabase RPC (Postgres functions) | staff-app: `find_carers_by_email`, `staff_signup`; client-app: sub-user password reset RPC | `_supabase.rpc(...)` calls |
| Supabase Edge Functions | **None deployed** — `supabase/functions/` contains only `compliance_rules_engine.sql` (a SQL function file, not a Deno edge function) | Directory listing |
| Firebase | **Not in use** (legacy remnants only) | No firebase dependency in any pubspec |
| Google ML Kit OCR | admin-app | `google_mlkit_text_recognition` dependency |
| Local device biometrics | All 3 apps | `local_auth` + `biometric_unlock_screen.dart` in each |

### 3.5 HTTP endpoints

There are **no custom REST endpoints**. The only "endpoints" are auto-generated PostgREST URLs:

```
https://aucflsskbhaloutsdlwc.supabase.co/rest/v1/<table_name>
https://aucflsskbhaloutsdlwc.supabase.co/auth/v1/...
https://aucflsskbhaloutsdlwc.supabase.co/storage/v1/...
```

Every service method documented below maps to one of these. There is no API gateway, no versioned REST layer, no GraphQL.

---

## 4. The Database — Complete Table Inventory by Domain

This inventory was derived from **two sources cross-checked against each other**: (a) the migration files in `supabase/migrations/` and (b) a static scan of every `.from('<table>')` call in all three apps' service layers. A table marked **[USED]** is read/written by at least one app.

### 4.1 Identity & Tenancy

| Table | Used by | Purpose | Key migrations |
|---|---|---|---|
| `profiles` [USED] | All 3 | Extends `auth.users`. Columns: `id (=auth uid)`, `email`, `full_name`, `role` (`admin`/`carer`, later `client`), `organisation_id`, `client_organisation_id` (client users), `is_active` | 001, 028, 072, 115, 128–132 |
| `carers` [USED] | admin, staff | Staff record: employee_number, DBS, training, compliance fields. `id REFERENCES profiles(id)` — the identity chain that breaks staff-app shift visibility | 001, 069, 070, 133–135 |
| `organisations` [USED] | admin, client | Care agency / provider organisations | 071 |
| `organisation_profiles` [USED] | admin | Extended org profile used by invoice service | 108 |
| `client_organisations` [USED] | client, admin | Care-home clients who buy shifts/routes | 029, 104, 116, 137 |
| `documents` [USED] | admin | Carer compliance docs (dbs/id/training/right_to_work) with expiry + verification | 001 |
| `drivers` [USED] | admin | Driver records for mileage attribution | 068 |

### 4.2 Shifts, Routes & Visits

| Table | Used by | Purpose | Migrations |
|---|---|---|---|
| `shifts` [USED] | All 3 | Single source of truth for booked shifts. ~25 columns after evolution: `scheduled_date`, `start_time/end_time`, `status`, `carer_id`, `client_organisation_id`, `organisation_id`, `broadcast_type`, `rate`, `recurring_pattern`… | 001, 028, 119, 121–123 |
| `shift_rotas` [PARTIAL] | admin only | Legacy weekly rota template. Staff-app never reads it | 027 |
| `visits` [USED] | all 3 | Check-in/out records per shift; flagged visits, structured notes JSONB | 001, 125–127 |
| `routes` [USED] | admin, client, staff(read) | Route container: named cluster of calls for a day. `carer_id`, `second_carer_id`, `driver_mode`, dual tenancy | 104, 116, 136–142 |
| `route_visits` [USED] | admin, staff(read) | Per-visit schedule: visit_time (timestamptz), duration_minutes, carer_id, status, respite | 137, 146 |
| `route_change_log` [USED] | admin | Full audit of route/visit changes | 137 |
| `service_user_calls` [USED] | admin | Recurring per-user call plan powering Dom-Care rota | 138, 142 |
| `service_user_call_log` [USED] | admin | Audit log of call-flag changes | 143 |
| `service_user_statuses` [USED] | admin | Away-status tracking (respite/hospital/holiday) | 144 |
| `body_map_assessments` [USED] | admin | Skin-check docs on return from away status | shift_rota_service.dart |
| `shift_templates` [USED] | client | Reusable templates for quick booking | shift_template_service.dart |
| `shift_broadcasts` [USED] | client | Broadcast rows (shift_id × agency_id, pending→accepted/declined) | 117 |
| `bookings` [CODE-ONLY — NO TABLE] | client-app code references it (`booking_service.dart`) but **no migration creates a `bookings` table** → feature broken/dummy | — | none found |

### 4.3 Risk Assessments (26 assessment types)

Every one follows the same pattern: a `<type>_risk_assessments` table + service class with CRUD + form screen(s).

| Table | Admin screen | Staff screen |
|---|---|---|
| `choking_risk_assessments` (+factors/scores/totals) | choking_risk_screen | — |
| `falls_risk_assessments` (+`falls_action_plans`) | falls_risk_screen | — |
| `waterlow_assessments` (+questions) | waterlow_screen | — |
| `mca_assessments` | mca_screen | — |
| `catheter_care_risk_assessments` | catheter_care_risk_screen | catheter_care_form |
| `coshh_risk_assessments` | coshh_risk_screen | coshh_risk_form |
| `epilepsy_risk_assessments` | epilepsy_risk_screen | epilepsy_risk_form |
| `diabetes_risk_assessments` | diabetes_risk_screen | diabetes_risk_form |
| `self_harm_risk_assessments` | self_harm_risk_screen | self_harm_risk_form |
| `anaphylaxis_risk_assessments` (+view) | anaphylaxis screens | anaphylaxis_risk_form |
| `activity_risk_assessments` | activity_risk_screen | activity_risk_form |
| `bed_railing_risk_assessments` | bed_railing_screen | bed_railing_form |
| `challenging_behaviour_risk_assessments` | challenging_behaviour_screen | challenging_behaviour_form |
| `environmental_risk_assessments` | environmental_risk_screen | — |
| `nutrition_risk_assessments` | nutrition_risk_screen | nutrition_risk_form |
| `incontinence_risk_assessments` | incontinence_risk_screen | incontinence_risk_form |
| `financial_risk_assessments` | — | financial_risk_form/screen |
| `equipment_register_risk_assessments` (+view) | equipment_register_screen | equipment_register_form |
| `fire_hazard_assessments` | fire_hazard_screen | — |
| `domiciliary_fire_safety_assessments` | dom fire safety form | — |
| `sepsis_risk_assessments` | — | sepsis_risk_form/screen |
| generic `risk_assessments/_questions/_answers` | risk_assessment_hub | — |

### 4.4 Daily Care Charts & Monitoring

| Table | Used by | Screens |
|---|---|---|
| `food_fluid_charts` (+audit logs) | admin, staff | food_fluid_form (staff), intake_log (admin) |
| `food_fluid_intake_logs` | admin | intake_log_screen/form |
| `bowel_bladder_charts` (+audit logs) | admin, staff | bowel_bladder_form / stool_log_screen |
| `sleep_charts` (+audit logs) | admin, staff | sleep_form |
| `repositioning_charts` (+audit logs) | admin, staff | repositioning_form |
| `daily_notes` | admin | daily_notes_screen |
| temperature/stool logs | admin | temperature_log_screen |

### 4.5 Medication (MAR)

| Table | Used by | Notes |
|---|---|---|
| `mar_medications` | admin | Prescriptions per service user |
| `mar_administration_logs` | admin; staff screen ORPHANED | Dose administration |
| `mar_audits` + questions/answers | admin | MAR audit workflow |
| `mar_suggestions` | admin | Suggestion inbox |

### 4.6 Compliance & Audits

| Table | Used by |
|---|---|
| `compliance_flags`, `compliance_scores`, `regulatory_reports`, `teaching_moments` | admin (+staff models/services exist) |
| `careplan_audit_items/_answers`, `care_plan_audits`, `care_log_audits` | admin audit screens |
| `spot_checks` | admin spot-check service |
| `pre_admissions`, `adl_categories` | admin pre-admission module |

### 4.7 Safeguarding

| Table | Used by |
|---|---|
| `accident_logs`, `incidents`, `serious_incidents`, `complaints_logs`, `whistleblower_reports` | admin safeguarding hub + whistleblower inbox |

### 4.8 Staff Management & HR

| Table | Used by |
|---|---|
| `appraisals` | admin appraisals screens |
| `disciplinary_cases` | admin |
| `leave_requests`, `leave_policy_settings`, `holiday_allowance`, `payroll_history` | admin leave/payroll |
| `training_courses`, `carer_training_records`, `carer_training_history` | training matrix |
| `competency_framework`, `role_competency_requirements`, `staff_competency_assessments`, `staff_development_plans` | competency engine |
| `welfare_checks`, `welfare_referrals`, `stress_risk_assessments` | welfare screens |
| `employee_incentives`, `employee_points_accounts`, `points_redemptions`, `reward_catalogue`, `incentive_programs`, `performance_metrics` | incentives |
| `satisfaction_surveys`, `satisfaction_trends`, `staff_recognition` | satisfaction dashboards |

### 4.9 Finance (admin only)

| Table | Used by |
|---|---|
| `supplier_register` | supplier screens |
| `receipt_entries` (+ legacy `receipts`) | receipts, profit calculator |
| `profit_snapshots` | profit/loss screens |
| `invoices` (+ items) | invoice generator/list |
| `analysis_views`, plus read-only joins to audits/incidents/training/risk | analysis dashboards |

### 4.10 Policies, Lessons, Meetings, Notifications, Client-domain

| Table | Used by |
|---|---|
| `policy_library` | policy list/detail/ack/reports |
| `lessons_learnt` | lesson screens |
| `action_plans` | action plan screens |
| `meetings` (+ templates/types) | meetings log |
| `notifications` | notification hubs |
| carer-inbox tables (114) | admin carer inbox |
| `preferred_carers` | client preferred-carers screen |
| `client_organisation_spl` | client PSL management + broadcast targeting |
| `staff_ratings` | client rate-carer dialog |
| sub-user profile machinery | client sub-user management (115, 128–132) |

---

## 5. Migration Status — What Can and Cannot Be Verified

### 5.1 Honest answer to "which migrations have been run?"

**It is not possible to determine from the repository alone which migrations were applied to the live Supabase project.** Supabase tracks applied migrations in `supabase_migrations.schema_migrations` only when run through the Supabase CLI (`supabase db push`). This repo has **no `supabase/config.toml` and no migration-lock metadata**, which strongly suggests migrations were applied manually (copy-paste into SQL Editor). In that case there is no local record at all.

**To verify definitively, run in the Supabase SQL Editor:**

```sql
SELECT * FROM supabase_migrations.schema_migrations ORDER BY version DESC LIMIT 20;
```

If that table is empty, migrations were applied manually.

### 5.2 What CAN be inferred (code-vs-migration consistency)

Cross-checking app code against migration files reveals mismatches where code expects tables/columns with **no corresponding migration**:

| Code expectation | Migration reality | Consequence |
|---|---|---|
| client-app `booking_service.dart` reads/writes a `bookings` table; `booking_history_screen.dart` renders it | **No migration ever creates `bookings`** | Booking History fails at runtime (`CLIENT_APP_ARCHITECTURE_AND_DATA_FLOW.md`: "Booking history — Broken — bookings table doesn't exist") |
| client-app staff-directory queries `profiles` with `role = 'staff'` | CHECK allows only `admin, carer` (+ `client` via 115) | Staff directory returns empty |
| admin legacy `DatabaseService.getShifts()` orders by column `date` | `shifts` has `scheduled_date`; `date` doesn't exist | That query errors; newer `ShiftService` is correct |
| staff-app `_loadUserProfile()` inserts profiles with columns `name`, `is_active` | 001 defines `full_name`, not `name` | Insert may fail depending on live schema drift |
| `body_map_assessments`, `service_user_statuses` in shift_rota_service | 143/144 exist → likely OK; verify live | If unapplied, away-status feature breaks |

### 5.3 Seed data & RLS coverage

- `supabase/seed/client_app_test_data.sql` exists for manual test seeding (per `CLIENT_APP_TESTING_GUIDE.md`), requiring a placeholder UUID swap. Not automated.
- Migration 073 bulk-enables RLS on all tables. At least **eight** later migrations patch RLS bugs (089–091 profile/carers recursion, 121 admin shift update, 125–127 visits-for-clients, 130 profile recursion, 132 search_path fix).
- **The pattern of repeated reactive RLS fixes indicates policies were iterated rather than designed.** Any new feature must be checked against both the org-based and carer-based policy families (section 6).

---

## 6. Multi-Tenant Structure

### 6.1 The two tenant axes

```
Axis 1: organisations.id            (the care AGENCY — admin & staff users)
Axis 2: client_organisations.id     (the care HOME CLIENT — client-app users)
```

- An **admin user**: `profiles.organisation_id = <agency uuid>`, `client_organisation_id = NULL`
- A **carer/staff user**: same as admin — belongs to the agency org
- A **client user**: `profiles.client_organisation_id = <care-home uuid>`, `organisation_id = NULL`

Evidence — migration 141 header:

> ```
> -- Adds organisation_id to routes, route_visits, route_change_log so
> -- ADMIN/STAFF users (who have organisation_id set but
> -- client_organisation_id = NULL) can create and manage routes.
> -- RLS policies are updated to accept EITHER:
> --   - organisation_id = profiles.organisation_id        (admin/staff)
> --   - client_organisation_id = profiles.client_organisation_id (client-app)
> ```

### 6.2 How each domain is scoped

| Domain | Scoping key(s) | Notes |
|---|---|---|
| shifts | `client_organisation_id` AND/OR `organisation_id` | RLS mixes both + `carer_id = auth.uid()` |
| routes / route_visits | dual org keys (141) + carer SELECT policies (146) | One row visible to agency, client, and assigned carers |
| service_users / carers / charts / assessments | `organisation_id` only (028/072) | Client sees care delivery only via visits patches (125–127) |
| finance | `organisation_id` only | Invisible to clients — correct |
| safeguarding / HR / compliance | `organisation_id` only | Correct isolation |

### 6.3 Cross-tenant sharing points (by design)

1. **shifts** — client creates (own scope) → admin sees (admin bypasses filter) → carer sees if assigned.
2. **routes/route_visits** — admin creates under agency org → client views rows carrying their id → carer sees own assignments.
3. **visits** — carer writes check-in/out; clients granted SELECT via 125–127.
4. **shift_broadcasts / client_organisation_spl** — client broadcasts shifts to multiple provider agencies on their PSL (117, 118).

### 6.4 Where multi-tenancy is weak

- Early tables got `organisation_id` via bulk ALTER (028/072) with **nullable** columns and a backfill function explicitly commented as a "placeholder… would need to be customized" (028 ~line 327).
- The shifts carer policy includes `OR organisation_id IS NULL`, so **any authenticated user can read NULL-org shifts** — documented data-leak concern (`SHIFTS_SCREEN_ANALYSIS_REPORT.md` §8.3).
- No enforced relationship between `organisations` and `client_organisations`; links exist only implicitly through data rows.
- Role checks are string comparisons scattered across ~100 policies with no central helper — policy drift is easy.

---

## 7. ADMIN-APP — Complete Page-by-Page Breakdown

### 7.0 Navigation architecture

The app has a single entry flow and one navigation hub:

- **AuthWrapper** (`lib/ui/auth/auth_wrapper.dart`) gates everything on Supabase session state.
- **AdminDashboard** (`lib/ui/dashboard/admin_dashboard.dart`) is the home screen after login. It contains:
  - A **grid of quick-action cards** (`_q(...)` calls, lines ~385–394): Carers, Service Users, Shifts, Safeguarding, MAR Audit, Action Plans, Lessons Learnt, Policy Library, Analysis.
  - A **navigation drawer** (`_i(context, icon, label, Screen())` calls, lines ~216–360) exposing **100+ destinations** grouped by domain.
- Navigation is done with plain `Navigator.push(MaterialPageRoute(...))` — there is **no named route table** (except `/reset-password` in staff-app). Every destination must therefore be reachable from this drawer or from another screen; anything not referenced anywhere is dead code.

The sections below mirror the drawer order. For each screen: **what it does → key functions → tables touched → CRUD**.

### 7.1 Authentication & Account

| Screen | File | Functions | Tables | Status |
|---|---|---|---|---|
| Login | `ui/auth/login_screen.dart` | Email+password sign-in via `SupabaseAuthService`; magic link; password reset email with redirect | `profiles` (role/org lookup on login) | ✅ Wired (entry) |
| Sign Up / Add New User | `ui/auth/signup_screen.dart` | Creates users; reachable from drawer as "Add New User" | `profiles`, `auth.users` via SDK | ✅ Wired |
| Biometric unlock | `ui/auth/biometric_unlock_screen.dart` | `local_auth` gate over cached session (`shared_preferences` flag) | none | ✅ Wired |
| Reset password | handled via deep link + `updateUser` | — | auth | ✅ |

### 7.2 People

| Drawer item | Screen file | What it does | Tables & CRUD |
|---|---|---|---|
| **Carers** | `ui/carer/carer_list_screen.dart` (+ carer form) | List/search carers; view compliance docs; edit records | `carers` R; `documents` R/U (verify); `profiles` R |
| **Service Users** | `service_user_list_screen.dart` / `service_user_form_screen.dart` | Full service-user management incl. **Visit Preferences** editor (call times/duration/two-carers) feeding route planning | `service_users` CRUD; `service_user_calls` CRUD (via form); `route_service_users` |
| **Add New User** | `signup_screen.dart` | Create admin/carer accounts | `profiles` C |
| **Care Home Details** | `carehome_details_screen.dart` | Client-organisation profile maintenance | `client_organisations` RU |
| **Drivers** | `drivers_screen.dart` | Driver register for mileage attribution | `drivers` CRUD (`driver_service.dart`) |

### 7.3 Scheduling & Care Delivery

| Drawer item | Screen | Functions | Tables & CRUD |
|---|---|---|---|
| **Shifts** | `ui/shift/shift_list_screen.dart` | Two view modes: (1) Route Schedule, (2) client-booked shift list. Assign carer to shift (`assignCarerToShift`: verify row exists → UPDATE `carer_id`,`status='confirmed'`). Route mode: assign carer to route cluster or single visit, edit visit time, cancel/split/merge routes, view change history, driver toggle | `shifts` R/U; `routes` CRUD; `route_visits` CRUD; `route_change_log` C(auto); `carers`,`service_users` R(joins) |
| Shift form | `ui/shift/shift_form_screen.dart` | Manual shift creation | `shifts` C |
| Add Route (FAB) | `ui/shift/route_form_screen.dart` | Build a route from service users' call preferences; creates one visit per call time | `routes` C; `route_visits` bulk C |
| **Shift Rota** | `ui/shift_rota/shift_rota_screen.dart` | Weekly rota grid + **Dom-Care tab** reading `service_user_calls`; clickable time cards; flag toggles | `shift_rotas` CRUD; `service_user_calls` RU; `service_user_call_log` C; `body_map_assessments` C; `service_user_statuses` RU |
| **Visits** | `ui/visit/visit_list_screen.dart` | Review check-in/out records; flagged visits | `visits` R/U(flag) |

### 7.4 Clinical Risk Assessment Hub

All risk items open through `_showRiskAssessmentPicker(...)` which first asks which **service user** the assessment is for, then pushes the type-specific screen. Each screen = list of existing assessments for that user + create/edit form; each service class performs standard CRUD against its table (see §4.3 mapping). Wired items:

Choking Risk · Falls Risk · Medication Risk · MCA · Waterlow · ReSPECT Form · Grab Sheet · Fire Hazard · COSHH · Catheter Care Risk · Epilepsy · Diabetes · Self Harm · Activity Risk · Bed Railing · Challenging Behaviour · Environmental Risk · Nutrition Risk · Incontinence Risk.

Supporting modules:
- `risk_assessment_hub_screen.dart` — generic question-bank assessments (`risk_assessments/_questions/_answers`).
- Falls risk additionally writes **`falls_action_plans`**.
- Choking writes to 4 related tables (factors/scores/totals/extended questions).

### 7.5 Monitoring & Daily Logs

| Item | Screen | Tables |
|---|---|---|
| Food & Fluid Log | intake_log_screen/form | `food_fluid_intake_logs` CRUD |
| Stool Log | stool_log_screen/form | `bowel_bladder_charts` CRUD |
| Temperature Log | temperature_log_screen/form | temperature log tables |
| Daily Notes | daily_notes_screen/form | `daily_notes` CRUD |

### 7.6 Medication

| Item | Screen | Functions | Tables |
|---|---|---|---|
| MAR Audit | mar audit screens (question/answer flow) | Audit questionnaire per round | `mar_audits` + `_questions` + `_answers` CRUD |
| MAR Chart | `mar_chart_screen/view`, `mar_medication_form` | Prescribe meds; record administration; print chart (pdf/printing pkgs) | `mar_medications` CRUD; `mar_administration_logs` CRUD |
| MAR Suggestions | mar_suggestions_screen | Triage suggestions inbox | `mar_suggestions` RU |
| Care Log Audit | care_log_audit screens | Audit care logs | `care_log_audits` CRUD; joins `daily_notes`,`service_users` |
| Care Plan Audit | care plan audit screens | Checklist-based audits | `care_plan_audits`, `careplan_audit_items/_answers` CRUD |

### 7.7 Compliance, Competencies & Training

| Item | Screen | Functions | Tables |
|---|---|---|---|
| Compliance dashboard | compliance screens + `ComplianceService` | Aggregates flags/scores; regulatory reports; teaching moments | `compliance_flags`, `compliance_scores` RU; `regulatory_reports` C/R; `teaching_moments` CRUD |
| Competency framework | per-subject screens (Medication, Fire Safety, First Aid, Moving & Handling, Safeguarding, Dignity & Respect, Communication, Pressure Prevention, Infection Control, Catheter Care) | Framework-driven assessments with scoring engine (`competency_scoring.dart`) | `competency_framework` R; `role_competency_requirements` R; `staff_competency_assessments` CRUD |
| Training matrix | training_matrix_screen (two copies: `ui/training/`, `ui/staff/`) | Course catalogue + per-carer records/history | `training_courses` CRUD; `carer_training_records` CRUD; `carer_training_history` R |
| Matrix Dashboard | matrix_dashboard_screen | Cross-carer competency+training heatmap | read joins |

### 7.8 Safeguarding

| Item | Screen | Functions | Tables |
|---|---|---|---|
| Accidents & Incidents | accidents_incidents_form, incident_detail_screen, safeguarding_screen | Report & triage accidents/incidents/serious incidents/complaints | `accident_logs`, `incidents`, `serious_incidents`, `complaints_logs` CRUD |
| Whistleblower Inbox | whistleblower_inbox_screen | Confidential reports inbox | `whistleblower_reports` RU |

### 7.9 Staff Management & HR

| Item | Screen(s) | Tables |
|---|---|---|
| Appraisals | appraisals_screen, appraisal_detail/form | `appraisals` CRUD |
| Disciplinary | disciplinary_screen/form | `disciplinary_cases` CRUD |
| Leave / Payroll | leave_screen, leave_request_form | `leave_requests` CRUD; `leave_policy_settings`; `holiday_allowance`; `payroll_history` |
| Meetings Log | meetings_log_screen (+templates/types) | meetings tables CRUD |
| Supervision matrix | supervision_matrix_screen | supervision records (019) |
| Welfare / Stress risk | employee_welfare_screen, welfare_check_form, stress_risk_assessment_form | `welfare_checks`, `welfare_referrals`, `stress_risk_assessments` CRUD |
| Satisfaction | satisfaction_survey_form, trends dashboard | `satisfaction_surveys` C; `satisfaction_trends` R |
| Recognition | staff_recognition_form | `staff_recognition` CRUD |

### 7.10 Incentives & Points

| Item | Screen | Tables |
|---|---|---|
| Performance incentives | performance_incentives_screen, incentive_form | `incentive_programs`, `employee_incentives` CRUD |
| Points management | points_management_screen | `employee_points_accounts` RU; `points_redemptions` CRUD |
| Reward catalogue | reward_catalogue_screen | `reward_catalogue` CRUD |

### 7.11 Quality & Governance

| Item | Screen | Functions | Tables |
|---|---|---|---|
| Action Plans | action plan list/detail/reports (**two parallel sets exist**) | Create plans linked to audit/risk findings | `action_plans` CRUD |
| Lessons Learnt | lesson_list/detail/form/reports | Capture lessons; link to actions | `lessons_learnt` CRUD |
| Root Cause Analysis | root_cause_analysis_screen | Analysis over incidents/lessons | read joins |
| Policy Library | policy_list/detail/form/ack/reports | Publish policies; track acknowledgments | `policy_library` CRUD |
| Analysis | analysis_screen + analysis_dashboard_screen (**both labelled "Analysis" in drawer**) | Cross-domain analytics via DB views | `analysis_views` R + read joins to audits/incidents/invoices/receipts/shifts/visits/risk/training/dom_care_routes |

> ⚠️ **Duplication evidence:** drawer lines 331/340 both say "Analysis" (different screens); 332/350 both "Action Plans"; 334/351 both "Lessons Learnt"; 337/352 both "Policy Library". An unfinished migration from an old module set to a new one — both sets are live in navigation.

### 7.12 Finance

| Item | Screen | Functions | Tables |
|---|---|---|---|
| Supplier Register | supplier_register/log/form | Supplier CRUD | `supplier_register` CRUD |
| Receipts | receipt_list/view/entry | Capture receipts for profit calc | `receipt_entries` CRUD (legacy `receipts` still referenced) |
| Profit Calculator / P&L | profit_calculator_screen, profit_loss_screen | Margin computation; snapshots | `profit_snapshots` C/R |
| Invoices | invoice_screen/list | Invoice client organisations | `invoices` CRUD; `organisation_profiles` R |
| Onboarding Import | import_screen | Bulk import on onboarding | bulk inserts |
| Organisation Profile | organisation_profile_screen | Agency profile | `organisation_profiles` RU |

### 7.13 Communication & Notifications

| Item | Screen | Functions | Tables |
|---|---|---|---|
| Notification Hub / Settings | notification_hub/settings screens | Central notifications; preferences | `notifications` CRUD |
| Carer Inbox | CarerInboxScreen | Two-way inbox with carers (migration 114) | carer-inbox tables CRUD |
| Recordings | recordings_screen | Media list | storage-backed |

**Admin-app health summary:** the main problem is **duplication of parallel module sets**, not orphaning. Nearly every screen is reachable from the drawer.

---

## 8. STAFF-APP — Complete Page-by-Page Breakdown

### 8.0 Navigation architecture (and the app's central problem)

The staff-app's entire reachable UI is **four screens deep**:

```
Login ──> AuthWrapper ──> StaffDashboard ──> ShiftsScreen ──> ShiftDetailScreen
                                                        └─> (accept / decline only)
```

- `main.dart` provides `SupabaseAuthService` + `FirestoreService` and sets `home: AuthWrapper(authenticatedChild: StaffDashboard())`.
- `StaffDashboard` (lines 33–51) renders a welcome title, a `NotificationBell`, a logout button, and embeds **`ShiftsScreen`** — nothing else.
- `ShiftsScreen` navigates only to `ShiftDetailScreen`.
- `ShiftDetailScreen` performs exactly two writes: `acceptShift()` (UPDATE status→'confirmed') and `declineShift()` (UPDATE status→'declined'), plus a check-in path that is currently unreachable (see 8.2).

**Everything else in the app — ~40 screens and 20+ services — is orphaned code with no navigation path to it.** This was verified by scanning every Dart file for cross-references: the following screens have **zero inbound imports/navigations**:

`check_in_screen`, `mar_chart_screen`, `my_competencies_screen`, `my_compliance`, all 12 competency forms, all risk screens/forms (activity, anaphylaxis, catheter, coshh, diabetes, epilepsy, equipment, financial, incontinence, nutrition, self-harm, sepsis, bed-railing, challenging-behaviour), and all 4 daily chart forms (food_fluid, bowel_bladder, sleep, repositioning).

### 8.1 Wired screens (the complete list)

| Screen | File | Functions | Tables & CRUD | Status |
|---|---|---|---|---|
| Login | `ui/auth/login_screen.dart` | Email/password, magic link, staff self-signup flow (`findCarersByEmail` RPC → `staff_signup` RPC) | `carers` (via RPC), `profiles`, auth | ✅ |
| Signup | `ui/auth/signup_screen.dart` | Identity-confirm against existing carer record, then `staff_signup` RPC creates auth user + profile + links carer | `auth.users`, `profiles`, `carers` | ✅ |
| Biometric unlock | `biometric_unlock_screen.dart` | `local_auth` over cached session | none | ✅ |
| Dashboard | `staff_dashboard.dart` | Shell only | — | ✅ |
| **My Shifts** | `dashboard/shifts_screen.dart` | Loads TWO sources and merges: `getShiftsForCurrentCarer()` (shifts WHERE carer_id=auth.uid) + `getRouteCallsForCurrentCarer()` (route_visits by carer + second-carer routes). Date navigation, status filters, pull-to-refresh | `shifts` R; `route_visits` R; `routes` R; `carers`,`service_users` joins | ✅ (but returns empty when identity linkage broken — see diagnosis doc) |
| Shift detail | `dashboard/shift_detail_screen.dart` | Show shift info; Accept / Decline buttons | `shifts` U(status) | ✅ |

### 8.2 Semi-wired / broken

| Screen | File | Problem |
|---|---|---|
| Check-in / clock-in-out | `dashboard/check_in_screen.dart` | Fully implemented (writes `visits` via `FirestoreService.addVisit/updateVisit` with check_in/out times, duration, notes) **but nothing navigates to it** — it is not reachable from ShiftDetailScreen or anywhere else. The clock-in/out feature therefore does not function for users. |
| Reset password | `main.dart` (inline `ResetPasswordScreen`) | Wired via `/reset-password` named route + deep link; functional. |

### 8.3 Orphaned feature modules (built, migrated, but unreachable)

Each of these has a working service class performing real CRUD against real tables — they are one `Navigator.push` away from being usable:

| Module | Screens | Service → Table(s) | CRUD |
|---|---|---|---|
| Daily charts | food_fluid_form, bowel_bladder_form, sleep_form, repositioning_form | food_fluid_service → `food_fluid_charts`; bowel_bladder_service → `bowel_bladder_charts`; sleep_service → `sleep_charts`; repositioning_service → `repositioning_charts` (all write audit logs too) | C/U/R |
| Risk assessments | 15 form/screen pairs | matching `*_service.dart` → matching `*_risk_assessments` tables | C/R/U |
| MAR chart | mar_chart_screen | mar service → `mar_charts`, `mar_administration_logs` | C/R/U |
| Competencies | my_competencies_screen + 12 subject forms | competency_service → `staff_competency_assessments`, `competency_framework` | C/R/U |
| Compliance | my_compliance | compliance_service → `compliance_scores`, `compliance_flags` | R |
| Notifications | notification_bell (wired in dashboard) + notification_service | `notifications` | R/U(read) |
| Visits | visit model + firestore_service | `visits` | C/U/R |
| Teaching moments | model + service | `teaching_moments` | R |

### 8.4 Staff-app verdict

The staff-app is a **shell with a working shift list** and a **warehouse of finished, orphaned features**. The two highest-value unlocks are: (1) fixing the carer-identity linkage so shifts/routes actually appear, and (2) wiring Check-In and the daily-chart forms into ShiftDetailScreen so carers can document care — the data model and services already fully support it.

---

## 9. CLIENT-APP — Complete Page-by-Page Breakdown

### 9.0 Navigation architecture

`main.dart` → `AuthWrapper` → `DashboardScreen`. The dashboard is a **6-tile grid** (verified lines 36–76):

| Tile label | Destination screen |
|---|---|
| Shifts | `ShiftsScreen` |
| Book a Shift | `BookShiftScreen` |
| Timesheets | `ShiftRegisterScreen` |
| Shift Templates | `ShiftTemplatesScreen` |
| My Profile & Sub-Users | `PreferredCarersScreen` |
| Service Providers | `SplManagementScreen` |

### 9.1 Wired screens

| Screen | File | Functions | Tables & CRUD | Status |
|---|---|---|---|---|
| Login / Signup / Biometric | auth screens + `supabase_auth_service.dart` | Client-user login; profile load (`client_organisation_id` resolution) | `profiles` R/U | ✅ |
| Dashboard | dashboard_screen.dart | 6-tile launcher | — | ✅ |
| **Shifts** | shifts_screen.dart | List org's booked shifts via `ShiftService.getShifts(clientOrganisationId)`; month/date filters | `shifts` R | ✅ |
| **Book a Shift** | book_shift_screen.dart | Create shift: validates UUIDs, inserts with `client_organisation_id`, `status='scheduled'`; conflict check vs carer availability (`checkCarerAvailability` reads existing shifts and tests time overlap) | `shifts` C/R | ✅ |
| Timesheets (register) | shift_register_screen.dart | Views/edits timesheet entries; `timesheet_service` joins `shifts`+`visits`; workflow fields from migrations 120/124 | `shifts` R, `visits` R, `profiles` R | ✅ |
| Shift Templates | shift_templates_screen.dart | CRUD reusable templates | `shift_templates` CRUD | ✅ |
| My Profile & Sub-Users | preferred_carers_screen.dart | Manage organisation sub-users (create/reset password via RPC, migration 128–132) AND preferred-carers list | `profiles` CRUD(sub-users); `preferred_carers` CRUD | ✅ |
| Service Providers (PSL) | spl_management_screen.dart | Maintain Preferred Supplier List: link org to provider agencies (`client_organisation_spl` × `organisations`) | `client_organisation_spl` CRUD; `organisations` R | ✅ |
| Broadcast (from shift flow) | shift_broadcast_service.dart + UI hooks | Broadcast shift to single/multiple/all PSL agencies; writes broadcast rows | `shifts` U(broadcast_type); `shift_broadcasts` C; `client_organisation_spl` R; `profiles` R | ✅ |

### 9.2 Orphaned screens (verified zero inbound navigation)

| Screen | File | What it was meant to do | Why it's dead |
|---|---|---|---|
| Booking History | booking_history_screen.dart | Render past bookings from a `bookings` table | Not navigable **and** the underlying `bookings` table doesn't exist in any migration |
| Booking Diary | booking_diary_screen.dart | Calendar diary of bookings; opens `ShiftDetailBottomSheet` (which supports assign/unassign/remind actions) | No inbound nav |
| Old shift list | shift_list_screen.dart | Superseded by shifts_screen | No inbound nav (it also contains a working FAB → BookShiftScreen) |
| Staff profile | staff_profile_screen.dart | Carer detail view for clients | No inbound nav |
| Rate Carer dialog | widgets/rate_carer_dialog.dart | Writes `staff_ratings` | No inbound nav — the client rating feature is therefore unusable despite `rating_service.dart` being complete |

### 9.3 Client-app services inventory

| Service | Table(s) | Verdict |
|---|---|---|
| shift_service | `shifts` (+`client_organisation_spl`) | Live — full CRUD incl. assignCarer/updateStatus/conflict-check |
| shift_template_service | `shift_templates` | Live |
| timesheet_service | `shifts`,`visits`,`profiles` | Live |
| spl_service | `client_organisation_spl`,`organisations` | Live |
| shift_broadcast_service | `shifts`,`shift_broadcasts`,`profiles`,`client_organisation_spl` | Live |
| staff_service | `carers`,`visits`,`client_organisation_spl` | Partially live (used by screens that exist) |
| route_service | `routes` | Live code; note client-side model expects legacy column shapes (`route_date`,`call_number`) vs post-137 container shape — verify at runtime |
| rating_service | `staff_ratings` | Complete but unreachable (orphan dialog) |
| client_service | `profiles` | Live |
| supabase_auth_service / auth_service | auth + `profiles` | Live (auth_service is a thin duplicate of supabase_auth_service) |
| booking_service | `bookings` (**table missing**) | Broken |

---

## 10. Cross-App Data Flows

### 10.1 The shift lifecycle (client → admin → staff)

```
CLIENT-APP                     ADMIN-APP                      STAFF-APP
──────────                     ─────────                      ─────────
BookShiftScreen
   │ INSERT shifts
   │  client_organisation_id=X
   │  status='scheduled'
   │  carer_id=NULL
   ▼
[shifts row visible to] ───> ShiftListScreen
                              │ getShiftsForDate()
                              │ admin RLS bypasses org filter
                              │
                              │ _showAssignCarerBottomSheet()
                              │ UPDATE shifts SET
                              │   carer_id=<carers.id>,
                              │   status='confirmed'
                              ▼
ShiftsScreen ◄──────────── [same row, now assigned]
(getShifts by org)              │
(sees confirmed + carer name)   │                       My Shifts
                                │                    WHERE carer_id = auth.uid()
                                ├────────────────────► ⚠ works ONLY if
                                                        carers.id == auth.uid()
```

**Known failure point:** the `carer_id` written here is a `carers.id`. If that UUID is not also the carer's `auth.users.id`, the staff-app query returns nothing. Full analysis: `STAFF_APP_DATA_FLOW_DIAGNOSIS.md`.

### 10.2 The route lifecycle (admin creates → client views → staff delivers)

```
ADMIN-APP                          CLIENT-APP                 STAFF-APP
route_form_screen / shift_list     routes view via            route calls merged into
  createRoute / addVisit           route_service              My Shifts list
  assignCarerToRouteCluster          .getRoutesForDate(org)   (getRouteCallsForCurrentCarer)
  assignCarerToVisit               scoped by                  scoped by
       │                           client_organisation_id     carer_id = auth.uid()
       ▼                                │                          │
routes + route_visits ─────────────► visible if row carries ──► visible only if
(+ route_change_log audit)           their client_org id       visit.carer_id or
                                     (migration 141 policy)    route.carer_id/second_carer_id
                                                               == auth.uid() (migration 146)
```

### 10.3 Care delivery loop (staff writes → admin/client read)

```
STAFF check-in (currently orphaned UI) ──INSERT visits──┐
                                                        ▼
                                        ADMIN VisitListScreen (review/flag)
                                        CLIENT ShiftRegister/timesheets (SELECT granted by migrations 125–127)
```

### 10.4 Broadcast flow (client → agencies)

`broadcastShift()` sets `shifts.broadcast_type` (`single|multiple|all`) and inserts `shift_broadcasts` rows per agency (from explicit selection or the whole active PSL). Status lifecycle: pending → accepted/declined/expired. **No agency-side app exists yet to accept broadcasts** — the receiving side is unimplemented.

### 10.5 What does NOT cross apps

- All risk assessments, charts, HR, finance, safeguarding data are **agency-internal only** (`organisation_id` scoping; clients have no SELECT).
- Client sub-users see only their own organisation's shifts/routes/visits.

---

## 11. APIs, Endpoints & External Services

### 11.1 Auto-generated PostgREST surface

Every service method resolves to:

```
GET/POST/PATCH/DELETE https://aucflsskbhaloutsdlwc.supabase.co/rest/v1/<table>?select=...&<filters>
```

There is no versioning layer, no BFF, no GraphQL. Consequences worth knowing:
- **Schema changes instantly affect all three apps.** A column rename breaks any app still using the old name at runtime (this already happened with shifts `date`→`scheduled_date`, and routes' pre/post-137 shapes).
- **Authorization is entirely RLS.** App-level role checks (e.g., admin-app checking `profiles.role`) are UX conveniences, not security boundaries.

### 11.2 Auth endpoints used

- Password sign-in, magic link (`/auth/v1/otp`), password reset with redirect (`careqa://reset-password` on mobile, `${origin}/reset-password` on web), PKCE code exchange for reset links, `updateUser` for password change — all in the three `supabase_auth_service.dart` files.

### 11.3 RPCs (Postgres functions called from apps)

| RPC | Called from | Purpose |
|---|---|---|
| `find_carers_by_email` | staff-app signup | Identity confirmation against existing carer records |
| `staff_signup` | staff-app signup | Atomically create auth user + profile + link carer (see STAFF_APP_ARCHITECTURE_REPORT.md §325 for `create_carer_with_auth` variant) |
| sub-user password reset | client-app | Admin-initiated reset for org sub-users (migration 131/132) |

### 11.4 Edge Functions

None. `supabase/functions/compliance_rules_engine.sql` is SQL (a rules function), not a deployed Deno function. Any "server-side" logic currently lives in triggers/RPCs inside migrations (e.g., updated_at triggers, prevent-double-booking constraint in 123, sub-user creation trigger fixes in 129).

### 11.5 Device/OS capabilities

Biometrics (`local_auth`), file/photo pickers, OCR (`google_mlkit_text_recognition`, admin), PDF/print/share (admin), charts (`fl_chart`, admin), cached images & relative time (client).

---

## 12. Dummy / Dead / Orphaned Pages — Master Inventory

Legend: 🔴 orphaned (no navigation path) · 🟡 wired but broken at runtime · ⚪ duplicated legacy set

### 12.1 staff-app (~80% of UI unreachable)

🔴 `check_in_screen.dart` — clock-in/out fully implemented against `visits`, unreachable
🔴 `mar_chart_screen` + MAR service
🔴 `my_competencies_screen` + 12 competency forms
🔴 `my_compliance`
🔴 All daily chart forms: food_fluid, bowel_bladder, sleep, repositioning (+ services)
🔴 All risk forms/screens: activity, anaphylaxis, catheter care, coshh, diabetes, epilepsy, equipment register, financial, incontinence, nutrition, self-harm, sepsis, bed railing, challenging behaviour (+ services)
🟡 Shift list/detail work only when carer-identity linkage holds (see diagnosis doc)
⚪ `firestore_service.dart` duplicates shift/visit logic vs `shift_service.dart`; `auth_service.dart` duplicates `supabase_auth_service.dart`

### 12.2 client-app (5 dead screens, 1 missing table)

🔴 `booking_history_screen` — 🟡 also broken (`bookings` table never created)
🔴 `booking_diary_screen` (contains functional `ShiftDetailBottomSheet`)
🔴 `shift_list_screen` (superseded by shifts_screen)
🔴 `staff_profile_screen`
🔴 `rate_carer_dialog` → makes `rating_service` and carer-rating unusable
🟡 route_service client model may mismatch post-137 routes schema (`route_date`/`call_number` vs container shape)

### 12.3 admin-app (healthy reachability; duplication instead)

⚪ Two parallel module sets both live in drawer: Analysis ×2 (lines 331 vs 340), Action Plans ×2 (332/350), Lessons Learnt ×2 (334/351), Policy Library ×2 (337/352)
⚪ Legacy `DatabaseService.getShifts()` still referenced by older screens; newer `ShiftService` is correct
🟡 Legacy `models/shift.dart` maps non-existent `date` column
⚪ `firebase_options.dart` files in both apps — dead weight from migration

---

## 13. Known Broken or Risky Areas

| # | Area | Evidence | Severity |
|---|---|---|---|
| 1 | Staff cannot see shifts/routes | Identity-linkage breakdown (`STAFF_APP_DATA_FLOW_DIAGNOSIS.md`) | Critical |
| 2 | Client Booking History crashes | No `bookings` table exists | High |
| 3 | Hardcoded Supabase credentials fallback | `client-app/lib/main.dart` lines 27–29 | High |
| 4 | Any authenticated user can read NULL-org shifts | RLS clause `OR organisation_id IS NULL` (migration 028); flagged in SHIFTS_SCREEN_ANALYSIS_REPORT §8.3 | High |
| 5 | Clock-in/out impossible for users | check_in_screen orphaned | High |
| 6 | Carer ratings impossible for clients | rate_carer_dialog orphaned | Medium |
| 7 | No receiver for shift broadcasts | Agencies have no surface to accept `shift_broadcasts` | Medium |
| 8 | Manual migrations, no CLI metadata | Absence of config.toml / migration lock | Medium |
| 9 | Reactive RLS patching, profile recursion bugs | Migrations 089–091, 121, 125–127, 130, 132 | Medium |
| 10 | Duplicated models/services drift apart | Admin local Shift model ≠ core model ≠ staff model | Medium |
| 11 | Duplicate drawer entries to different screens | admin_dashboard lines 331/340, 332/350, 334/351, 337/352 | Low |
| 12 | `.env` hard-crash on missing file | `dotenv.env['SUPABASE_URL']!` in admin/staff mains | Low |

---

## 14. What Should Be Done Next — Prioritised Roadmap

### Phase 0 — Stop the bleeding (days)
1. **Fix staff shift/route visibility** (identity-linkage audit SQL + reassignment + defensive triggers). Full plan in `STAFF_APP_DATA_FLOW_DIAGNOSIS.md`.
2. **Remove hardcoded credentials** from client-app main.dart; fail loudly like the other two apps.
3. **Close the NULL-org RLS hole** on shifts (and audit all tables for the same clause).
4. **Delete or fully wire** the legacy `DatabaseService.getShifts()` path.

### Phase 1 — Unlock already-built value (1–2 weeks)
5. Wire staff-app **Check-In** into ShiftDetailScreen (service code is done).
6. Wire staff-app **daily charts** (food/fluid, bowel/bladder, sleep, repositioning) into an active-shift context.
7. Wire client-app **Rate Carer dialog** into a reachable surface.
8. Resolve the **client bookings feature**: create the `bookings` table or retire booking_history/diary screens in favour of the working shifts flow.
9. Consolidate duplicate admin modules (Analysis / Action Plans / Lessons / Policies) to one set each.

### Phase 2 — Structural sustainability (2–4 weeks)
10. **Adopt Supabase CLI** with a clean baseline migration so `schema_migrations` becomes authoritative; add CI diffing of live schema vs migrations.
11. **Unify the Shift model** in `packages/core`, consumed by all three apps.
12. Centralise RLS helpers (e.g., a security-definer `has_org_role()` function) and rewrite policies against it; add policy tests.
13. Introduce **go_router/named routes** per app so reachability is statically auditable — prevents future orphaned screens.

### Phase 3 — Scale & product completeness (ongoing)
14. Build the **agency-side broadcast acceptance** flow, or simplify the broadcast schema if targeting internal carers only.
15. Realtime subscriptions on `shifts`/`route_visits` so staff dashboards update without pull-to-refresh.
16. Observability: structured logging, crash reporting, RLS-denied-query monitoring.
17. Data lifecycle: index review for hot paths, partitioning strategy for append-only logs.

### Guiding principle
The platform's biggest asset is that **most features are already built and migrated** — the recurring failure mode is *wiring*: identity linkage, navigation, duplicated module sets, and missing tables. Prioritise connecting what exists over building anything new until Phases 0–2 are complete; every feature added before then inherits the same wiring debt.

---

*End of report.*
*Cross-references: `STAFF_APP_DATA_FLOW_DIAGNOSIS.md` (deep-dive on issue #1), `SHIFTS_SCREEN_ANALYSIS_REPORT.md`, `SHIFTS_ARCHITECTURE_REPORT.md`, `docs/ROUTE_CARER_AMENDMENTS.md`, `CLIENT_APP_ARCHITECTURE_AND_DATA_FLOW.md`, `STAFF_APP_ARCHITECTURE_REPORT.md`.*

---

## Appendix A — Service → Table CRUD Matrix (admin-app)

Derived from static analysis of every `.from('<table>')` call in `admin-app/lib/services/*.dart`. Operations listed are those observed in code (C=insert, R=select, U=update, D=delete).

| Service | Tables (observed operations) |
|---|---|
| `database_service.dart` (LEGACY) | carers CRU · documents RU · profiles R · service_users CRUD · settings R · shifts CRUD(⚠ broken `date` col) · visits CRUD |
| `shift_service.dart` (CURRENT) | shifts R/U(assign,status) · routes R · carers/service_users/profiles R |
| `route_service.dart` | routes CRUD · route_visits CRUD · route_change_log C/R · route_service_users R · service_user_weekly_calls R · carers/service_users R |
| `shift_rota_service.dart` | shift_rotas CRUD · service_user_calls RU · service_user_call_log C/R · service_user_statuses RU · body_map_assessments C · dom_care_routes R · routes/shifts R |
| `safeguarding_service.dart` | accident_logs CRUD · incidents R · serious_incidents CRUD · complaints_logs CRUD · whistleblower_reports RU |
| `compliance_service.dart` | compliance_flags RU · compliance_scores CRUD · regulatory_reports C/R · teaching_moments CRUD |
| `mar_audit_service.dart` | mar_audits CRUD · mar_audit_questions R · mar_audit_answers CRUD |
| `mca_service.dart` | mca_assessments CRUD |
| `risk_assessment_service.dart` | risk_assessments CRUD · risk_assessment_questions CRUD · risk_assessment_answers CRUD |
| `waterlow_service.dart` | waterlow_assessments CRUD · waterlow_questions R |
| `falls_risk_service.dart` | falls_risk_assessments CRUD · falls_action_plans CRUD |
| `choking_risk_service.dart` | choking_risk_assessments CRUD + factors/scores/totals/extended_questions |
| Per-type risk services (activity, anaphylaxis, bed_railing, catheter×2, challenging_behaviour, coshh, diabetes, domiciliary_fire_safety, environmental, epilepsy, equipment_register(+view), financial, fire_hazard, incontinence, nutrition, self_harm, sepsis) | matching `<type>_risk_assessments` CRUD each |
| `food_fluid_service.dart` / `food_fluid_intake_service.dart` | food_fluid_charts CRUD + audit C/R · food_fluid_intake_logs CRUD |
| `bowel_bladder_service.dart` / repositioning / sleep | charts CRUD + audit logs |
| `daily_note_service.dart`, `care_log_audit_service.dart`, `care_plan_audit_service.dart`, `careplan_audit_service.dart` | daily_notes CRUD · care_log_audits CRUD (+joins) · care_plan_audits CRUD · careplan_audit_items/_answers CRUD |
| `appraisal_service.dart` | appraisals CRUD · carers R |
| `disciplinary_service.dart` | disciplinary_cases CRUD · carers/profiles R |
| `leave_service.dart` | leave_requests CRUD · leave_policy_settings RU · holiday_allowance RU · payroll_history CR |
| `training_service.dart` | training_courses CRUD · carer_training_records CRUD · carer_training_history R |
| `competency_service.dart` / `competency_scoring.dart` | competency_framework R · role_competency_requirements R · staff_competency_assessments CRUD · staff_development_plans CRUD · carers U |
| `welfare_service.dart` | welfare_checks CRUD · welfare_referrals CRUD · stress_risk_assessments CRUD · carers R |
| `incentive_service.dart` | incentive_programs CRUD · employee_incentives CRUD · employee_points_accounts RU · points_redemptions CRUD · reward_catalogue CRUD · performance_metrics R |
| `satisfaction_service.dart` | satisfaction_surveys C/R · satisfaction_trends R · staff_recognition CRUD · carers R |
| `spot_check_service.dart` | spot_checks CRUD · carers/service_users R |
| `pre_admission_service.dart` | pre_admissions CRUD · adl_categories R |
| `invoice_service.dart` | invoices CRUD · organisation_profiles R · profiles R |
| `receipt_service.dart` / `expense_tracking_service.dart` | receipt_entries CRUD · receipts R · profit_snapshots CU · dom_care_routes R |
| `supplier_service.dart` | supplier_register CRUD |
| `action_plan_service.dart` | action_plans CRUD · profiles R |
| `lesson_learnt_service.dart` | lessons_learnt CRUD · profiles R |
| `policy_service.dart` | policy_library CRUD · profiles R |
| `analysis_service.dart` | analysis_views R + read joins (audits, incidents, invoices, receipts, shifts, visits, training_records, risk_assessments, dom_care_routes, carers, profiles, service_users) |
| `meeting_service.dart` | meetings CRUD · carers R |
| `notification_service.dart` / `message_service.dart` | notifications CRUD · messages CRUD · profiles R |
| `carer_invite_service.dart` | carers RU(invite status) · auth invites |
| `auth/supabase_auth_service.dart` | profiles R/U · auth flows |

## Appendix B — Service → Table Matrix (staff-app & client-app)

**staff-app** (`staff-app/lib/services/`): shift_service (shifts R; route_visits R; routes R; accept/decline U) · firestore_service (shifts R ⚠duplicate; visits C/U/R) · supabase_auth_service (auth; profiles R/C) · notification_service (notifications R/U) · competency_service (framework/staff_competency_assessments) · compliance_service (flags/scores R) · per-chart services (food_fluid/bowel_bladder/sleep/repositioning → tables + audit logs C/U/R) · per-risk services (13 types → matching tables C/R/U) · teaching_moment model (R).

**client-app**: shift_service (shifts CRUD + client_organisation_spl R) · shift_template_service (shift_templates CRUD) · timesheet_service (shifts/visits/profiles R) · spl_service (client_organisation_spl CRUD; organisations R) · shift_broadcast_service (shifts U; shift_broadcasts C; PSL/profiles R) · staff_service (carers/visits/PSL R) · route_service (routes CRUD — ⚠ schema-shape mismatch risk post-137) · rating_service (staff_ratings C/R — unreachable UI) · client_service (profiles R) · booking_service (`bookings` — **no such table**) · auth services (profiles).

---

*End of appendices.*

