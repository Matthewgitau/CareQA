# Route Schedule — Data Flow Audit & Implementation Report

**Date:** 2026-08-17  
**App:** admin-app  
**Feature:** Route schedule screen

---

## Executive Summary

The Route Schedule screen in the **admin-app** has been rebuilt around a new **`route_visits`** table (Option B — the long-term, recommended structure). This gives a proper per-service-user visit schedule with **independent visit times**, **carer assignment per visit**, **route merging/splitting for last-minute changes**, and a **full change-log audit trail**.

---

## 1. What the screen currently does (after fix)

**File:** `admin-app/lib/ui/shift/shift_list_screen.dart` → `RouteService`

### Data sources

| Data | Table | Notes |
|------|-------|-------|
| Client Shifts tab | `shifts` | Existing behaviour |
| Route Schedule visits | **`route_visits`** (new) | Per-service-user visits with `visit_time`, `duration_minutes`, `carer_id`, `status`, `respite` |
| Route containers | `routes` | Now lightweight named groups of visits (`name`, `route_date`, `merged_into_route_id`) |
| Service users | `service_users` | Names joined via `service_users(name)` |
| Carers | `carers` | Names joined via `carers(name)` |
| Change history | **`route_change_log`** (new) | Full audit trail |

### UI capabilities

1. **Grouped by route** — visits listed under their route container with `{{name}}` + `N visits · total mins`
2. **Edit visit time** — per-visit date/time/duration picker (`Edit Time` in ⋮ menu)
3. **Assign carer** — per-visit dropdown (writes `route_visits.carer_id`)
4. **Respite toggle** — per-visit switch
5. **Move visit to route** — move a visit between routes (handles last-minute merges)
6. **Split visit to new route** — pull a visit out into its own route
7. **Merge routes** — move all visits from source to target route (source marked `merged`)
8. **Cancel visit** — soft-cancel with confirm, logged
9. **Build from Preferences** — reads `care_plan.visit_preferences` per service user and creates / updates route_visits on configured days
10. **Create Route** — dialog to add a new route + visit
11. **Change History** — bottom sheet listing today's changes with icons/types/timestamps

---

## 2. Schema changes (Migration 137)

### 2.1 `routes` — now a route container
```sql
ALTER TABLE public.routes ALTER COLUMN service_user_id DROP NOT NULL;
ALTER TABLE public.routes ALTER COLUMN proposed_start_time DROP NOT NULL;
ALTER TABLE public.routes ALTER COLUMN proposed_end_time DROP NOT NULL;
ALTER TABLE public.routes ADD COLUMN IF NOT EXISTS name TEXT;
ALTER TABLE public.routes ADD COLUMN IF NOT EXISTS route_date DATE;
ALTER TABLE public.routes ADD COLUMN IF NOT EXISTS merged_into_route_id UUID REFERENCES public.routes(id) ON DELETE SET NULL;
```

### 2.2 `route_visits` — the core visit schedule
```sql
CREATE TABLE IF NOT EXISTS public.route_visits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_organisation_id UUID NOT NULL REFERENCES public.client_organisations(id) ON DELETE CASCADE,
    route_id UUID REFERENCES public.routes(id) ON DELETE SET NULL,
    service_user_id UUID NOT NULL REFERENCES public.service_users(id) ON DELETE CASCADE,
    carer_id UUID REFERENCES public.carers(id) ON DELETE SET NULL,
    visit_date DATE NOT NULL,
    visit_time TIMESTAMPTZ NOT NULL,
    duration_minutes INTEGER NOT NULL DEFAULT 60,
    status TEXT NOT NULL DEFAULT 'scheduled'
        CHECK (status IN ('scheduled', 'in_progress', 'completed', 'cancelled', 'merged')),
    respite BOOLEAN NOT NULL DEFAULT FALSE,
    requires_two_carers BOOLEAN NOT NULL DEFAULT FALSE,
    sort_order INTEGER NOT NULL DEFAULT 1,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```
Indexes: `client_organisation_id`, `route_id`, `service_user_id`, `carer_id`, `(client_organisation_id, visit_date, visit_time)`  
RLS: enabled with org-scoped select/insert/update/delete policies + `updated_at` trigger.

### 2.3 `route_change_log` — audit trail
```sql
CREATE TABLE IF NOT EXISTS public.route_change_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_organisation_id UUID NOT NULL REFERENCES public.client_organisations(id) ON DELETE CASCADE,
    visit_id UUID REFERENCES public.route_visits(id) ON DELETE SET NULL,
    route_id UUID REFERENCES public.routes(id) ON DELETE SET NULL,
    changed_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    change_type TEXT NOT NULL
        CHECK (change_type IN (
            'visit_created', 'visit_deleted',
            'time_adjusted', 'date_changed',
            'carer_assigned', 'carer_unassigned',
            'route_created', 'route_merged', 'route_split',
            'cancelled', 'respite_toggled'
        )),
    description TEXT,
    old_value JSONB,
    new_value JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```
Indexes: `(client_organisation_id, created_at)`, `visit_id`, `route_id`  
RLS: enabled with org-scoped select/insert policies.

---

## 3. Files changed

| File | Change |
|------|--------|
| `supabase/migrations/137_route_visits_and_change_log.sql` | NEW — route_visits + route_change_log + routes container |
| `admin-app/lib/models/route_visit.dart` | NEW — `RouteVisit` + `RouteChangeLogEntry` models |
| `admin-app/lib/services/route_service.dart` | Rebuilt — visit CRUD w/ change logging, merge/split, build-from-prefs, getVisitLog |
| `admin-app/lib/ui/shift/shift_list_screen.dart` | Rebuilt — grouped visit cards, edit time, assign carer, move/split/merge/cancel, change history sheet |
| `admin-app/lib/models/service_user.dart` | Added `VisitPreferences` + `visitPreferences` getter on `ServiceUser` |
| `admin-app/lib/ui/service_user/service_user_form_screen.dart` | Added "Visit Preferences" section (time picker, duration, visit days, two-carers toggle, notes) |
| `supabase/migrations/136_route_schedule_enhancements.sql` | Added `requires_two_carers` to `routes` |

---

## 4. To apply

Run migration 137 (and 136 if not yet applied) against the Supabase database:

```bash
supabase db push
# or via the SQL editor paste the contents of:
#   supabase/migrations/136_route_schedule_enhancements.sql
#   supabase/migrations/137_route_visits_and_change_log.sql
```

---

## 5. Where next (suggestions)

- **Multi-visit route creation** — `createRouteWithVisits()` already supports creating a route with several visits at once; wire the `_CreateRouteDialog` to it on demand.
- **Confirm / In-progress / Completed** status buttons per visit.
- **Filter by carer / user** on the route schedule screen.
- **Push the change-log watch** to a real-time indicator (Supabase Realtime) so last-minute changes are instantly visible.

---

## 6. Summary of the fix

| What | Before | After |
|------|--------|-------|
| Visit times per service user | One proposed start/end per route row | Per-visit `visit_time` + `duration_minutes` |
| Carer assignment | Only on shifts | Per-visit `carer_id` with dropdown |
| Last-minute merges | Not supported | Merge/split/move with change log |
| Audit trail | None | Every change logged to `route_change_log` |
| Route definition | Tied to single user | Lightweight named route container |

---

## 7. Shift Rota page fix (Migration 138)

### 7.1 Data source mix-up corrected

| Tab | Before (wrong) | After (correct) |
|-----|----------------|-----------------|
| **Care Home** | `shift_rotas` | **`public.shifts`** |
| **Dom Care Routes** | `shift_rotas` | **`public.service_user_calls`** |
| **Warehouse** | `shift_rotas` | `shift_rotas` (unchanged) |

### 7.2 New columns on `service_user_calls` (Migration 138)

```sql
ALTER TABLE public.service_user_calls
  ADD COLUMN IF NOT EXISTS respite BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS hospital BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS holiday BOOLEAN NOT NULL DEFAULT FALSE;
```

### 7.3 Dom Care Routes UI

- **Daily Summary card** — service user count, total calls, planned hours, billable hours, non-billable count
- **Per-user cards** — service user name, calls/day, call times (chips), and **Respite / Hospital / Holiday** toggle buttons
- **Non-billable logic** — when any flag is toggled ON, the user's hours are **excluded from the billable total** but still tracked for documentation/invoicing
- **Warning banner** — shows "X hrs excluded from billable total (Y hrs billable)" when flagged

### 7.4 Files changed

| File | Change |
|------|--------|
| `supabase/migrations/138_service_user_calls_flags.sql` | NEW — respite/hospital/holiday columns |
| `admin-app/lib/models/service_user_call.dart` | NEW — `ServiceUserCall` model with billable-hours logic |
| `admin-app/lib/services/shift_rota_service.dart` | Care Home → `public.shifts`, Dom Care → `public.service_user_calls`, `toggleServiceUserCallFlag()` |
| `admin-app/lib/ui/shift_rota/shift_rota_screen.dart` | Rebuilt — per-tab data sources, Dom Care summary + toggle cards, Care Home shift cards |

---

## 8. Route Formation (Route Clusters) — Migration 139

### 8.1 Concept

A **Dom Care Route** is a **named cluster** of service users that can be grouped and ordered. This enables carers to be assigned to the cluster (route) **day-by-day**, with the ability to flag the assigned carer as the **driver** so mileage can later be attributed to the correct person for invoicing.

### 8.2 Schema changes

```sql
ALTER TABLE public.routes
  ADD COLUMN IF NOT EXISTS carer_id UUID REFERENCES public.carers(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS is_driver BOOLEAN NOT NULL DEFAULT FALSE;

CREATE INDEX IF NOT EXISTS idx_routes_carer_id ON public.routes(carer_id);
```

### 8.3 UI capabilities (Route Schedule screen)

| Feature | Description |
|---------|-------------|
| **Named route cluster** | Each route is a named group of service users |
| **Rename route** | Tap edit icon on the route header to rename |
| **Day-by-day carer assignment** | Route-level carer dropdown assigns a carer to the whole cluster for that day |
| **Driver flag** | Car icon toggle marks the assigned carer as the driver (for mileage attribution) |
| **Ordered visits** | Visits within a route are sorted by time and numbered (1, 2, 3…) showing the visit sequence |
| **One-time additions/subtractions** | Visits can be moved between routes, merged, split, or cancelled |

### 8.4 Files changed

| File | Change |
|------|--------|
| `supabase/migrations/139_route_carers_and_driver.sql` | NEW — `carer_id` + `is_driver` on `routes` |
| `admin-app/lib/services/route_service.dart` | Added `renameRoute()`, `assignCarerToRouteCluster()`, `setRouteDriverFlag()` (all change-logged) |
| `admin-app/lib/ui/shift/shift_list_screen.dart` | Route group header now shows: rename edit, route-level carer dropdown, driver toggle, numbered ordered visits |

---

## 9. Add/Edit Route Form — Migration 140

### 9.1 Concept

The **Add Route** button (FAB) now opens a full **Route Form** screen (NOT the "Add Shift" form which was incorrectly booking visits as shifts with a service user client). The new form is purpose-built for **creating/editing route clusters**.

### 9.2 Form features

| Section | What's available |
|---------|------------------|
| **Route Details** | Route name (required, editable), route date picker |
| **Carer Assignment** | Primary carer dropdown, **Second carer** dropdown (optional), **"Who was driving?"** segmented control (Primary / Second / Both) |
| **Service Users (Visits)** | Add service users from the pool, each with: order number, **visit time picker**, **duration picker** (30/45/60/90/120 min), remove button |
| **Auto-order** | Toggle: auto-sort visits by time OR manually reorder with ▲/▼ arrows |
| **Save** | Create Route / Update Route (edit mode) |

### 9.3 Schema changes

```sql
ALTER TABLE public.routes
  ADD COLUMN IF NOT EXISTS second_carer_id UUID REFERENCES public.carers(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS second_carer_is_driver BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS driver_mode TEXT NOT NULL DEFAULT 'primary'
    CHECK (driver_mode IN ('primary', 'second', 'both'));

CREATE INDEX IF NOT EXISTS idx_routes_second_carer ON public.routes(second_carer_id);
```

### 9.4 Files changed

| File | Change |
|------|--------|
| `supabase/migrations/140_route_second_carer_driver_mode.sql` | NEW — second_carer_id, driver_mode on routes |
| `admin-app/lib/ui/shift/route_form_screen.dart` | NEW — full Add/Edit Route form |
| `admin-app/lib/services/route_service.dart` | Added `getRouteWithVisits()`, `updateRouteWithVisits()`, `assignSecondCarerToRouteCluster()`, `setRouteDriverMode()` |
| `admin-app/lib/ui/shift/shift_list_screen.dart` | FAB now shows **"Add Route"** → opens RouteFormScreen; edit (✏️) on route header → opens RouteFormScreen in edit mode |

---

## 10. Bug Fixes — PostgrestException, Service User Dropdown, Shift Rota FAB

### 10.1 PostgrestException: "Could not embed because more than one relationship was found for 'routes' and 'carers'"

**Root cause:** After adding `second_carer_id` to the `routes` table (migration 140), the `routes` table now has **two** foreign keys to `carers`:
- `routes.carer_id` → `carers(id)` (FK: `routes_carer_id_fkey`)
- `routes.second_carer_id` → `carers(id)` (FK: `routes_second_carer_id_fkey`)

When PostgREST tries to embed `carers(name)` without specifying which FK to use, it throws `PGRST201` because the relationship is ambiguous.

**Fix:** Disambiguated the embed by specifying the FK name explicitly:
- `getRoutesForDate()`: `carers!routes_carer_id_fkey(name), carers!routes_second_carer_id_fkey(name)`
- `getRouteWithVisits()`: `carers!routes_carer_id_fkey(name), carers!routes_second_carer_id_fkey(name)`

### 10.2 Service users not displaying in the Add Route dropdown

**Root cause:** `getActiveServiceUsers()` in `RouteService` was filtering by `organisation_id` using the value from `_getClientOrgId()`, which returns `client_organisation_id` (from the `client_organisations` table). But the `service_users` table uses `organisation_id` (referencing the `organisations` table), **not** `client_organisation_id`. These are two different tables with different IDs, so the filter returned zero results.

**Fix:** Added a new `_getOrganisationId()` method that returns the correct `organisation_id` from the profile (not `client_organisation_id`). `getActiveServiceUsers()` now uses this to filter `service_users` by the correct column. Falls back to unfiltered (RLS-secured) if no org ID is found.

### 10.3 Add Route form added to Shift Rota screen

**Change:** The Shift Rota screen's FAB is now **context-aware**:
- **Dom Care Routes tab** → FAB shows **"Add Route"** (route icon) → opens `RouteFormScreen`
- **Care Home / Warehouse tabs** → FAB shows **"Add Shift"** (plus icon) → opens `ShiftFormScreen`

This ensures the Add Route form is accessible from the Shift Rota screen where users expect it.

### 10.4 Files changed (bug fixes)

| File | Change |
|------|--------|
| `admin-app/lib/services/route_service.dart` | Fixed `getRoutesForDate()` and `getRouteWithVisits()` embeds; added `_getOrganisationId()`; fixed `getActiveServiceUsers()` to use correct org ID |
| `admin-app/lib/ui/shift_rota/shift_rota_screen.dart` | FAB now context-aware: "Add Route" on Dom Care tab, "Add Shift" on others; imported `RouteFormScreen` |

---

## 11. Service User Dropdown + Visit Times from `service_user_calls` — Fix

### 11.1 Problem

The "Add Service User to Route" dropdown in the Add Route form was **empty** — no service users appeared. Additionally, the visit times for each service user were not being pulled from the `service_user_calls` table.

### 11.2 Root cause

1. **Empty dropdown:** `getActiveServiceUsers()` was filtering by `organisation_id` using a value from `_getOrganisationId()`, but the `service_users` table's `organisation_id` column may not match the admin user's organisation. RLS already handles row-level security, so the org filter was redundant and caused zero results.

2. **No visit times:** The form was creating visits with a hardcoded 09:00 time instead of reading the `call_times` from `public.service_user_calls`.

### 11.3 Fix

| Change | Details |
|--------|---------|
| **`getActiveServiceUsers()`** | Removed the `organisation_id` filter entirely. Now queries `public.service_users` directly (RLS handles security). Also removed the `is_active` filter from the SQL query (filtered in Dart instead) to handle schemas where the column may not exist or all records have it set to false. |
| **`getServiceUsersWithCalls()`** | NEW method. Fetches service users from `public.service_users` AND their call schedule from `public.service_user_calls`, merging them into a single list. Each entry includes `id`, `name`, `calls_per_day`, `call_times` (parsed from JSON), and `has_calls`. |
| **`_addServiceUser()`** | Now reads `call_times` from the service user data. If the user has call times (e.g., `["06:14", "11:14"]`), it creates **one visit per call time** at the correct times. If no call times exist, it creates a single visit at 09:00 as a fallback. |
| **Dropdown items** | Now show the call times next to each service user name, e.g., "John Smith (2 calls: 06:14, 11:14)" so the user can see what times are configured before adding. |
| **`_removeVisit()`** | Restores the original user data (with call times) from `_allUsers` when a visit is removed, so the user can be re-added with their call times intact. |
| **`_allUsers` field** | NEW. Stores the full list of service users (with call data) loaded from `getServiceUsersWithCalls()` so that removed visits can restore the original user data. |

### 11.4 Data flow

```
public.service_users  ──┐
                        ├──→ getServiceUsersWithCalls() ──→ _availableUsers (dropdown)
public.service_user_calls ─┘                                        │
                                                                    ▼
                                                           _addServiceUser()
                                                                    │
                                                    ┌───────────────┴───────────────┐
                                                    ▼                               ▼
                                          has call_times?                    no call_times
                                                    │                               │
                                                    ▼                               ▼
                                          1 visit per call_time            1 visit at 09:00
                                          (e.g., 06:14, 11:14)             (default fallback)
```

### 11.5 Files changed

| File | Change |
|------|--------|
| `admin-app/lib/services/route_service.dart` | Removed org filter from `getActiveServiceUsers()`; added `getServiceUsersWithCalls()` that joins `service_users` with `service_user_calls` |
| `admin-app/lib/ui/shift/route_form_screen.dart` | Uses `getServiceUsersWithCalls()`; `_addServiceUser()` creates one visit per call time; dropdown shows call times; `_allUsers` stores full user data for restore on remove |

---

## 12. RLS 403 Error on Route Save — Multi-tenant Fix (Migration 141)

### 12.1 Problem

Saving a new route threw:
```
PostgrestException(message: new row violates row-level security policy for table "routes", code: 42501)
```

Dev console showed `POST /rest/v1/routes?select=id 403 (Forbidden)`.

### 12.2 Root cause

The `routes` (and `route_visits`, `route_change_log`) tables used **only** `client_organisation_id`, and their RLS policies checked `client_organisation_id = profiles.client_organisation_id`.

But **ADMIN/STAFF** users (admin-app) have:
- `client_organisation_id = NULL`
- `organisation_id` = a valid organisation UUID (e.g. `135d2ac7-...`)

**CLIENT** users (client-app) have:
- `client_organisation_id` = a valid client organisation UUID
- `organisation_id` = `11111111-...` (shared placeholder)

So admin/staff could NEVER insert routes — their `client_organisation_id` was NULL, and `client_organisation_id = NULL` is never true in RLS.

### 12.3 Correct multi-tenant architecture

| App | Uses | RLS matches |
|-----|------|-------------|
| **admin-app** | `organisation_id` → `organisations` | `profiles.organisation_id` |
| **client-app** | `client_organisation_id` → `client_organisations` | `profiles.client_organisation_id` |

### 12.4 Fix — Migration 141 (`141_routes_admin_organisation.sql`)

1. Added `organisation_id UUID REFERENCES public.organisations(id) ON DELETE CASCADE` to `routes`, `route_visits`, `route_change_log`.
2. Made `client_organisation_id` **nullable** on all three (so admin rows can have it NULL).
3. Added indexes on `organisation_id`.
4. **Rewrote RLS policies** on all three tables to accept EITHER:
```sql
(organisation_id IS NOT NULL AND organisation_id = (
    SELECT organisation_id FROM public.profiles WHERE id = auth.uid()
))
OR
(client_organisation_id IS NOT NULL AND client_organisation_id = (
    SELECT client_organisation_id FROM public.profiles WHERE id = auth.uid()
))
```
This lets admin/staff (organisation_id) AND client-app (client_organisation_id) coexist.

### 12.5 Fix — `RouteService` (admin-app/lib/services/route_service.dart)

Introduced an org-context so the service uses the correct column per user type:

- **`_getOrgContext()`** — queries `profiles` for BOTH `organisation_id` and `client_organisation_id`.
- **`_getOrgId()`** — returns `organisation_id` first (admin/staff), falling back to `client_organisation_id` (client-app).
- **`_orgInsertColumns()`** — returns `{ 'organisation_id': ... }` for admin/staff, or `{ 'client_organisation_id': ... }` for client-app, so INSERTs populate the correct column.
- All queries now filter by the correct org column (`.eq('organisation_id', ...)` for admin, `.eq('client_organisation_id', ...)` for client).
- All inserts into `routes`, `route_visits`, `route_change_log` set the correct org column.

This means **admin-app uses `organisation_id`** and **client-app continues to use `client_organisation_id`**.

### 12.6 To apply (SQL you must run)

Run migration **141** against Supabase (via `supabase db push` or the SQL editor):

```sql
-- supabase/migrations/141_routes_admin_organisation.sql
```

Then verify the admin user's profile has `organisation_id` set:
```sql
SELECT id, email, organisation_id, client_organisation_id
FROM profiles
WHERE id = auth.uid();
```

Admin/staff should have `organisation_id` populated and `client_organisation_id` NULL — which now works end-to-end.

---

## 13. Route Schedule — Current Data Flow & Correction Recommendations

> Requested: a breakdown of how the Route schedule currently pulls and displays
> data (which tables, which writes), whether it is a dummy page, and what to
> correct so the admin can manage service users, their visit times, route
> creation, and per-day carer assignments.

### 13.1 Verdict — Is it a "dummy" page?

**No.** Every screen reads from **real database tables**. Nothing is hard-coded
demo data. However the feature is **incomplete and blocked in places** because
the data model evolved from an old "one row per user per call" design into a
modern "route container + route_visits" design without fully cleaning up the
legacy columns. This is what produces the current save error and the confusing
overlap between two screens.

### 13.2 The two overlapping Route screens

There are currently **two** separate route/rota UIs that read from **different**
tables, which is a large part of the confusion:

| Screen | Entry point | Reads from |
|--------|-------------|------------|
| **Shift & Rota → shift_list_screen.dart** (View Mode **1 = Route Schedule**) | `_buildRouteList()` | `routes`, `route_visits`, joined `service_users`/`carers` |
| **Shift & Rota → shift_rota_screen.dart** (**Dom Care Routes** tab) | `getDomCareRoutes()` | `service_user_calls` only (a *plan*, not a schedule) |

**The "Route Schedule" (viewMode 1 in shift_list_screen) is the primary screen
for managing actual routes and visits.** The "Dom Care Routes" tab in
shift_rota_screen shows the *planned call schedule* per service user
(`service_user_calls`), not day-by-day assigned routes.

### 13.3 How the Route Schedule (viewMode 1) currently works

On load (`_load()`) it calls two service methods in parallel:

1. `RouteService.getRouteVisitsForDate(date)` →
   `SELECT ..., service_users(name), carers(name), routes(name) FROM route_visits`
   filtered by `visit_date = date`, `status != 'cancelled'`, then org-scoped.
2. `RouteService.getRoutesForDate(date)` →
   `SELECT ..., route_visits(...), carers(...) FROM routes`
   filtered by `route_date = date`, org-scoped.
3. `RouteService.getCarers()` → `SELECT ... FROM carers WHERE is_active`.

**Display** (`_buildRouteList` → `_buildRouteGroup`):
- Visits are **grouped by `routes.id`**.
- Each card shows the **route name**, primary carer, second carer, driver mode
  flag, total visit count & duration, and the visits **sorted by time**.
- Each visit row shows the **service-user name** (`route_visits.service_users.name`),
  **visit time** (`route_visits.visit_time`), duration, a **carer dropdown**, and a
  **respite toggle**.

**Actions available on this screen:**
- **Add Route** (`_openAddRoute` → `RouteFormScreen`, the "+" button)
- **Build from Prefs** — auto-generates routes/visits from each
  `service_users.care_plan.visit_preferences` (`buildRoutesFromPreferences`)
- **Merge Routes / Split Visit / Change History / Edit Route**
- Date navigation (prev/next/today), per-visit time editing (`updateVisitTime`),
  carer assign/unassign, respite toggle, visit cancel.
**Route creation form** (`RouteFormScreen`, the "Add Route" flow):
- Loads carers (`getCarers` → `carers`) and the service-user picker
  (`getServiceUsersWithCalls` → merges **`service_users`** + **`service_user_calls`**).
- When a service user is added, **`_addServiceUser()` reads their
  `call_times`** from `service_user_calls` and creates **one visit per call time**
  (fallback to 09:00 if no times). So visit times ARE being pulled from the call
  schedule — this is already implemented (Section 11).
- On save it calls `createRouteWithVisits` → inserts one `routes` row (the
  container) then the `route_visits` rows.

### 13.4 Tables involved (single source of truth)

| Table | Role | Org columns |
|-------|------|-------------|
| `service_users` | Master directory of service users (name, address, care_plan) | org-scoped via RLS |
| `service_user_calls` | Each user's **planned** call times (`call_times` JSON, `calls_per_day`, respite/hospital/holiday flags) | `organisation_id` |
| `routes` | **Route container** for a day (name, date, status, carer_id, second_carer_id, is_driver, driver_mode) | `organisation_id` XOR `client_organisation_id` |
| `route_visits` | The **actual scheduled visit** (route_id, user, carer, time, duration, status, sort_order) | `organisation_id` XOR `client_organisation_id` |
| `route_change_log` | Audit trail of every change | `organisation_id` XOR `client_organisation_id` |
| `carers` | Carer directory | — |
| `shifts` / `shift_rotas` | Care-home / warehouse (other rota types) | — |

The **object model**: a **route** is a named cluster of **visits** for a day;
the visit times come from `route_visits.visit_time`, and `service_user_calls`
is only the *seed/source* for those times when building a route.

### 13.5 Why "create a new route" currently fails (the live error)

```
Failed to save route: PostgrestException(
  message: null value in column "call_number" of relation "routes"
           violates not null constraints, code: 23502, ...)
```

**Root cause:** the `routes` table (migrations 104/116) still contains
`call_number INTEGER NOT NULL` (no default) plus a legacy
`UNIQUE(client_organisation_id, service_user_id, route_date, call_number)`.
Migration 137 converted `routes` into a container and made the other legacy
`NOT NULL` columns nullable, but **forgot `call_number`**. The modern Dart code
never sends `call_number`, so every insert into `routes` violates NOT NULL.

**Fix:** migration **142** (`142_routes_drop_legacy_call_number.sql`) drops
`NOT NULL` on `call_number`, drops the legacy unique constraint, and adds a
partial unique index on `(organisation_id, route_date, name)` to prevent
duplicate route names per day. Run it after 141.

### 13.6 Confirmed gaps / recommendations (for your consideration)

1. **Apply migration 142** to unblock route creation (call_number blocker).
   Confirm 141 is also applied (RLS multi-tenant fix, Section 12).

2. **One route home, not two.** The overlap between `shift_list_screen.dart`
   (viewMode 1 "Route Schedule") and `shift_rota_screen.dart` ("Dom Care
   Routes") is confusing. Recommend making the **Route Schedule** the single
   place to create routes, assign carers per route per day, adjust visit times,
   and view the daily schedule — and either deprecate the `service_user_calls`-
   only "Dom Care Routes" tab or repurpose it as a read-only "Visit Plan" page.

3. **Carer FK mismatch (latent bug).** Migration 104 defined
   `routes.carer_id REFERENCES profiles(id)`, but migration 139's
   `ADD COLUMN IF NOT EXISTS carer_id ... REFERENCES carers(id)` was a **no-op**
   (column already existed), so `routes.carer_id` still points at `profiles`,
   not `carers`. Assign a carer that isn't a profile row and the FK will fail.
   Recommend a migration to drop & recreate `carer_id` as
   `REFERENCES carers(id) ON DELETE SET NULL` (and repoint `route_visits.carer_id`
   which was correct from the start).

4. **`service_user_calls.call_times` is a JSON string** in many rows
   (e.g. `"[\\"06:14\\", \\"11:14\\"]"`), not a Postgres array. The Dart code
   already handles this robustly, but normalising the column to `text[]` would
   simplify joins/reporting.

5. **Visit time editing already exists** (`updateVisitTime`) on the Route
   Schedule; consider surfacing it more explicitly beside each visit, and adding
   bulk "apply call times from service_user_calls" when a visit is added later.

6. **Per-day carer assignment** is already supported on the route container
   (`carer_id`, `second_carer_id`, `is_driver`, `driver_mode`) — verify it ties
   to migration 142 + the carer FK fix in #3 before relying on it end to end.

7. **Data quality:** confirm `profiles.organisation_id` is set for all admin/staff
   (Section 12.6) and that `service_users` / `service_user_calls` rows belong to
   the same organisation so the picker and route build stay within the tenant.

### 13.7 Migration status to apply

```sql
-- 141_routes_admin_organisation.sql   (org-scoped RLS — REQUIRED)
-- 142_routes_drop_legacy_call_number.sql  (unblocks route creation — REQUIRED)
```

Verify after running:
```sql
SELECT column_name, is_nullable
FROM information_schema.columns
WHERE table_name = 'routes' AND column_name IN ('call_number','organisation_id','client_organisation_id');
```
`call_number` must be `YES` (nullable), `organisation_id` present.

---

## 14. Data model & screen map (routes) — quick reference

### 14.1 Tables that store route-related data

| Table | Role | Key columns (active) | Legacy/NULL for admin |
|-------|------|----------------------|------------------------|
| `routes` | **Route container** — a named cluster of visits for one day | `id`, `name`, `route_date`, `status`, `carer_id`, `second_carer_id`, `is_driver`, `second_carer_is_driver`, `driver_mode`, `merged_into_route_id`, `organisation_id` / `client_organisation_id` | `service_user_id`, `proposed_start_time`, `proposed_end_time`, `call_number`, `respite`, `actual_start_time`, `actual_end_time` are **NULL by design** (pre-137 single-call columns) |
| `route_visits` | The **actual scheduled visits** (one row per service-user visit) | `id`, `route_id`, `service_user_id`, `carer_id`, `visit_date`, `visit_time`, `duration_minutes`, `status`, `respite`, `requires_two_carers`, `sort_order`, `notes`, `organisation_id` / `client_organisation_id` | `client_organisation_id` is NULL for admin (uses `organisation_id`) |
| `route_change_log` | Audit trail (`old_value` → `new_value` JSON) | `id`, `visit_id`, `route_id`, `changed_by`, `change_type`, `description`, `old_value`, `new_value`, `created_at` | `client_organisation_id` NULL for admin |
| `service_users` | Master directory of service users | `id`, `name`, `address`, `care_plan` etc. | — |
| `service_user_calls` | Each user's **planned call schedule** (the *source* of visit times) | `id`, `service_user_id`, `calls_per_day`, `call_times` (JSON string), `respite`, `hospital`, `holiday`, `organisation_id` | — |
| `carers` | Carer directory (for assignment dropdowns) | `id`, `name`, `employee_number`, `job_role`, `photo_url`, `is_active` | — |
| `profiles` + `organisations` / `client_organisations` | Tenancy: RLS scoping decides which org's routes/visits a user sees | `organisation_id` (admin) XOR `client_organisation_id` (client) | — |

**Object model:** `routes` (1) ─── (*) `route_visits` (each points to one `service_users` and optionally one `carers`). `service_user_calls` is the *recurring plan* that seeds `route_visits.visit_time`; it is **not** the day-by-day schedule.

### 14.2 Which screen shows what

| Screen | File | Reads | Writes | Purpose |
|--------|------|-------|--------|---------|
| **Shifts → Route Schedule** (View Mode 1) | `ui/shift/shift_list_screen.dart` | `routes` (`getRoutesForDate`, now embeds `route_visits` + `service_users(name)` + `carers(name)`), `route_visits` (`getRouteVisitsForDate`), `carers` (`getCarers`) | `assignCarerToRouteCluster`, `setRouteDriverFlag`, `assignCarerToVisit`, `updateVisitTime`, `toggleVisitRespite`, `cancelVisit`, merge/split | View + manage the day's route containers, **day-by-day carer assignment** (route-level = whole day; **visit-level = one-off override**), visit times, respite, cancel |
| **Add/Edit Route** form | `ui/shift/route_form_screen.dart` | `carers` (`getCarers`), `service_users` + `service_user_calls` (`getServiceUsersWithCalls`); `getRouteWithVisits` when editing | `createRouteWithVisits` / `updateRouteWithVisits` → `routes`, `route_visits`, `route_change_log` | Create a route container + its visits (one visit per `call_times` entry); assign primary/second carer + driver mode |
| **Shift & Rota → Dom Care Routes** tab | `ui/shift_rota/shift_rota_screen.dart` | `service_user_calls` joined `service_users` (`getDomCareRoutes`) | `toggleServiceUserCallFlag` (respite/hospital/holiday) | Show the **planned call plan** per user (calls/day + times). Distinct from the assigned day-by-day schedule |

---

## 15. Carer assignment — complete trace (where & how it's saved)

> Purpose: definitive reference of every carer-assignment code path,
> what table/column receives the write, and whether it cascades to visits.

### 15.1 The two levels of carer assignment

| Level | Where you see it | UI handler | Service method | Writes to |
|-------|------------------|------------|----------------|-----------|
| **Route-level** (day-by-day) | Card header dropdown on Route Schedule | `shift_list_screen._assignCarerToRouteCluster` | `route_service.assignCarerToRouteCluster` | `routes.carer_id` |
| **Visit-level** (single visit override) | Individual visit card dropdown on Route Schedule | `shift_list_screen._assignCarerToVisit` | `route_service.assignCarerToVisit` | `route_visits.carer_id` |

Plus a third path at **creation time**:

| Path | What happens |
|------|-------------|
| `createRouteWithVisits` | Route is created; each visit receives `carer_id` from the visit payload OR the route-level `carerId` parameter (line 417: `carerId: v['carer_id'] as String? ?? carerId`) |
| `_save()` in the Add Route form | The `visitsPayload` list does **not** include `carer_id` per visit → all visits get `carerId = _primaryCarerId` via the fallback in `createRouteWithVisits` line 417 |

### 15.2 Detailed write flows — Route-level

**UI:** `_assignCarerToRouteCluster(route, carerId)` (shift_list_screen.dart line 391)
**Service:** `assignCarerToRouteCluster(routeId, carerId)` (route_service.dart line 215)

**Write:** `UPDATE public.routes SET carer_id = <carerId> WHERE id = <routeId>;`

**Audit log (route_change_log):**
```
change_type: 'carer_assigned' or 'carer_unassigned'
description: 'Carer assigned to route cluster' / 'Carer unassigned from route cluster'
old_value: {"carer_id": null}   ← hardcoded null — does NOT read the previous value!
new_value: {"carer_id": <carerId>}
route_id: <routeId>, visit_id: null
```

### 15.3 Detailed write flows — Visit-level

**UI:** `_assignCarerToVisit(visit, carerId)` (shift_list_screen.dart line 183)
**Service:** `assignCarerToVisit(visitId, carerId)` (route_service.dart line 632)

**Write:**
1. Reads current value: `SELECT carer_id FROM route_visits WHERE id = <visitId>`
2. `UPDATE public.route_visits SET carer_id = <carerId> WHERE id = <visitId>;`

**Audit log:**
```
change_type: 'carer_assigned' / 'carer_unassigned'
description: 'Carer assigned to visit' / 'Carer unassigned from visit'
old_value: {"carer_id": <actual previous carer_id>}  ← actually read from DB
new_value: {"carer_id": <carerId>}
visit_id: <visitId>, route_id: null
```

### 15.4 Second carer + driver mode (route-level only)

| Method | Writes to | Column(s) | Audit? |
|--------|-----------|-----------|--------|
| `assignSecondCarerToRouteCluster` | `routes` | `second_carer_id` | ✅, oldValue hardcoded null |
| `setRouteDriverMode` | `routes` | `driver_mode` | ✅ |
### 15.5 Creation-time carer assignment

`createRouteWithVisits` (route_service.dart line 383):
- The route container (`routes`) is created **without** `carer_id` (line 397-405).
- The Add Route form then separately calls `assignCarerToRouteCluster` + `assignSecondCarerToRouteCluster` / `setRouteDriverMode` after creation (route_form_screen.dart lines 296-302).
- So route-level carer is a **two-step write**: create route without carer → assign carer via update.

For the visits:
- `_insertVisit` (line 853) writes `carer_id` into `route_visits.carer_id`.
- The value comes from `v['carer_id'] ?? _primaryCarerId` (line 417).
- The current Add Route form's `visitsPayload` does NOT include `carer_id` (line 264-271).
- Therefore every visit receives `carerId = _primaryCarerId` from the form.

### 15.6 ⚠️ DOES NOT CASCADE — the critical gap

**Assigning a carer at the route level does NOT propagate to individual visits.**

When you use the route-card dropdown (`assignCarerToRouteCluster`):
- Only `routes.carer_id` is updated.
- `route_visits.carer_id` rows are **untouched**.
- Previously-created visits retain their existing `carer_id` (NULL from creation, or whatever was set at insert).

Similarly, `assignCarerToVisit` only touches one `route_visits` row; it does NOT sync `routes.carer_id`.

**Consequence:** if you create a route without a carer, then later assign a carer via the route-card dropdown, the header shows the name but every visit card still shows "Carer: Unassigned" — the visits were inserted with `carer_id = NULL`.

### 15.7 Tables involved

| Table | Column | FK target | Notes |
|-------|--------|-----------|-------|
| `routes` | `carer_id` | originally `profiles(id)` (m.104); migration 139's `ADD COLUMN IF NOT EXISTS…REFERENCES carers(id)` was a **no-op** because the column already existed | ⚠️ Verify in your DB: if it still points to `profiles`, assigning a carer who isn't a profile row will FK-fail |
| `routes` | `second_carer_id` | `carers(id)` (m.140) | ✅ |
| `route_visits` | `carer_id` | `carers(id) ON DELETE SET NULL` (m.137) | ✅ correct from the start |
| `route_change_log` | — | — | Audit for both levels |

### 15.8 One-line summary

**The carer IS saved to each visit at creation time** (from the form's primary carer). But **after creation**, the route-level dropdown only updates `routes.carer_id` — it does not cascade to `route_visits.carer_id`. To change a visit's carer after creation, you must use the per-visit dropdown on each visit individually.

### 14.3 Crash & `routes_carers_1` duplicate-alias fixed (2026-08-20)

`'null' is not a subtype of 'string'` came from `RouteVisit.fromJson` / `RouteChangeLogEntry.fromJson`
casting `client_organisation_id as String` — but migration 141 made that column **nullable for admin**.
Fixed by making the Dart fields `String?` and parsing `as String?` (`lib/models/route_visit.dart`).

PostgREST `ierror table name "routes_carers_1" specified more than once` came from embedding the
`carers` relationship **multiple times** on the `routes` query (`!routes_carer_id_fkey` +
`!routes_second_carer_id_fkey`, plus a nested visit-level `carers(name)`). Fix: **no `carers` embeds**
in `getRoutesForDate` (now `.select('*')`) or `getRouteWithVisits` (now `'*, route_visits(*, service_users(name))'`).
Route-header carer names are resolved **client-side** in `shift_list_screen._buildRouteGroup` from the
already-loaded `_carers` list (`getCarers()`). Visit cards still get their carer name from
`getRouteVisitsForDate` (single-FK `service_users(name), carers(name), routes(name)` — no collision).
