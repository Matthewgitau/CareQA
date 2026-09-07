# CareQA — Inter-App Data Flow Diagnosis: Why the Staff-App Cannot See Shifts or Routes

**Date:** 22 August 2026
**Author:** AI Code Analysis
**Audience:** External consultant / developer — no prior codebase knowledge needed
**Scope:** Full trace of how client-app ↔ admin-app ↔ staff-app share shift & route data, and a root-cause analysis of why the staff-app shows blank shift/route views.

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [High-Level Architecture](#2-high-level-architecture)
3. [The Data Flow That WORKS (Client ↔ Admin)](#3-the-data-flow-that-works-client--admin)
4. [The Two "Shift" Systems (Legacy + New)](#4-the-two-shift-systems-legacy--new)
5. [The Route System (Route Container + Route Visits)](#5-the-route-system-route-container--route-visits)
6. [Root-Cause #1: Identity-Linkage Breakdown — carers.id vs auth.uid()](#6-root-cause-1-identity-linkage-breakdown--carersid-vs-authuid)
7. [Root-Cause #2: route_visits RLS Policies Block Staff Users](#7-root-cause-2-route_visits-rls-policies-block-staff-users)
8. [Root-Cause #3: Staff-App ShiftService Ignores organisation_id Scoping](#8-root-cause-3-staff-app-shiftservice-ignores-organisation_id-scoping)
9. [Root-Cause #4: Admin-App Route Service May Write carer_id From Wrong Source](#9-root-cause-4-admin-app-route-service-may-write-carer_id-from-wrong-source)
10. [Complete Data-Flow Diagram (All Three Apps)](#10-complete-data-flow-diagram-all-three-apps)
11. [Solutions (Prioritised for Longevity)](#11-solutions-prioritised-for-longevity)
12. [Appendix: Key Files & Migration Reference](#12-appendix-key-files--migration-reference)

---

## 1. Executive Summary

| Question | Answer |
|---|---|
| Does the client-app write shifts that the admin-app can see? | **Yes.** Both apps share `public.shifts` in the same Supabase Postgres database. The client writes shifts with `client_organisation_id`, and the admin reads them (when the admin uses the correct `ShiftService`, not the legacy `DatabaseService`). |
| Does the admin-app assign carers that become visible to the client-app? | **Yes.** Admin calls `assignCarerToShift()` which updates `shifts.carer_id` + `shifts.status = 'confirmed'`. The client-app can query shifts for its `client_organisation_id` and see the assigned carer. |
| Does the staff-app see assigned shifts? | **No — and this is the primary bug.** The staff-app queries `shifts WHERE carer_id = auth.uid()`, but the `carer_id` stored on the shift often does NOT equal the logged-in carer's `auth.uid()`. This is an **identity-linkage** problem between the `carers` table and `auth.users`. |
| Does the staff-app see routes? | **No — a compound of two bugs.** (a) The same identity-linkage issue applies to `route_visits.carer_id` and `routes.carer_id`. (b) The RLS policies on `route_visits` were originally gated on `client_organisation_id` (which staff users do NOT have set), and while a carer-specific policy was added in migration 146, it only works if the identity linkage is correct. |

**The root cause is NOT a missing API or a missing UI screen — the staff-app's `ShiftsScreen` and `ShiftService.getRouteCallsForCurrentCarer()` already call the correct endpoints. The problem is that the data written by the admin-app (carer IDs on shifts/routes/route_visits) does not correctly reference the authenticated staff user's identity.**

---

## 2. High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                   Supabase (Single Instance)                     │
│                                                                  │
│  ┌───────────┐  ┌──────────────┐  ┌─────────────────────────┐  │
│  │ Auth      │  │ Postgres DB  │  │ RLS (Row-Level Security) │  │
│  │ (GoTrue)  │  │              │  │                          │  │
│  │           │  │  • profiles  │  │  Per-table policies that │  │
│  │ auth.users│  │  • shifts    │  │  govern which rows each  │  │
│  │           │  │  • routes    │  │  authenticated user can  │  │
│  │           │  │  • route_    │  │  SELECT/INSERT/UPDATE    │  │
│  │           │  │    visits    │  │                          │  │
│  │           │  │  • carers    │  │                          │  │
│  │           │  │  • organi-   │  │                          │  │
│  │           │  │    sations   │  │                          │  │
│  └─────┬─────┘  └──────┬───────┘  └────────────┬────────────┘  │
│        │               │                       │                │
└────────┼───────────────┼───────────────────────┼────────────────┘
         │               │                       │
         ▼               ▼                       ▼
    ┌─────────┐    ┌───────────┐          ┌──────────┐
    │ Client  │    │  Admin    │          │  Staff   │
    │  App    │    │   App     │          │   App    │
    │(Flutter)│    │ (Flutter) │          │(Flutter)│
    └─────────┘    └───────────┘          └──────────┘
```

**Key architectural points:**
- There is **no custom API gateway** — all three Flutter apps talk directly to Supabase via the `supabase_flutter` SDK (PostgREST under the hood).
- The "API" between apps is the **shared Postgres database** plus **RLS policies**.
- Auth is handled by Supabase GoTrue. Every logged-in user has a `auth.users.id` UUID.
- `profiles` table extends `auth.users` (`profiles.id REFERENCES auth.users(id)`).
- `carers` table extends `profiles` (`carers.id REFERENCES profiles(id)`).
- **Therefore:** `auth.users.id` = `profiles.id` = `carers.id` — this one-to-one chain is the intended identity model.
> **Quote from migration 001** (`supabase/migrations/001_initial_schema.sql`, lines 5–17):
> ```sql
> CREATE TABLE profiles (
>   id UUID PRIMARY KEY REFERENCES auth.users(id),
>   email TEXT NOT NULL,
>   full_name TEXT,
>   role TEXT NOT NULL CHECK (role IN ('admin', 'carer')),
>   ...
> );
> 
> CREATE TABLE carers (
>   id UUID PRIMARY KEY REFERENCES profiles(id),
>   employee_number TEXT UNIQUE,
>   ...
> );
> ```

---

## 3. The Data Flow That WORKS (Client ↔ Admin)

### 3.1 Client Creates a Shift

**File:** `client-app/lib/services/shift_service.dart`

The client-app's `createShift()` inserts a row into `public.shifts`:

```dart
// client-app/lib/services/shift_service.dart, lines ~131-165
await _client
    .from('shifts')
    .insert({
      'client_organisation_id': clientOrganisationId,  // <-- scoping key
      'scheduled_date': scheduledDate,
      'start_time': startTimeStr,
      'end_time': endTimeStr,
      'status': 'scheduled',
      'staff_required': staffRequired,
      'staff_type': staffType,
    })
    .select()
    .single();
```

**Key columns written:** `client_organisation_id`, `scheduled_date`, `start_time`, `end_time`, `status='scheduled'`.  
**Notably absent:** `carer_id` is NOT set at creation — it is `NULL` until admin assigns a carer.

### 3.2 Client Broadcasts the Shift (Optional)

**File:** `client-app/lib/services/shift_broadcast_service.dart`

The client may broadcast a shift to agencies via `ShiftBroadcastService.broadcastShift()`, inserting into `public.shift_broadcasts`. This is stored in a separate table and not relevant to the staff-app problem.

### 3.3 Admin Views the Shift

**File:** `admin-app/lib/services/shift_service.dart`

```dart
// admin-app/lib/services/shift_service.dart, lines 137-173
Future<List<Shift>> getShiftsForDate(DateTime date) async {
  final profile = await _client
      .from('profiles')
      .select('role, organisation_id, client_organisation_id')
      .eq('id', user.id)
      .single();

  final dateStr = date.toIso8601String().split('T')[0];
  
  dynamic query = _client
      .from('shifts')
      .select('*, service_users(name), carers(name)');
  
  query = query.eq('scheduled_date', dateStr);
  
  if (role != 'admin' && role != 'super_admin' && clientOrgId != null) {
    query = query.eq('client_organisation_id', clientOrgId);
  }
  
  query = query.order('start_time', ascending: true);
  final response = await query;
  return (response as List).map((json) => Shift.fromJson(json as Map<String, dynamic>)).toList();
}
```

**This works because:** Admin users have `profiles.role = 'admin'`, so the RLS policy "Admins can manage all shifts" passes, and `getShiftsForDate()` returns all client-created shifts for that date.

### 3.4 Admin Assigns a Carer to the Shift

**File:** `admin-app/lib/services/shift_service.dart`, lines ~275-294

```dart
Future<void> assignCarerToShift(String shiftId, String carerId) async {
  await _client.from('shifts').select('id, carer_id, status').eq('id', shiftId).single();
  await _client.from('shifts')
      .update({'carer_id': carerId, 'status': 'confirmed'})
      .eq('id', shiftId)
      .select();
}
```

**The `carerId` comes from the admin UI** where the admin selects a carer from the `carers` table. After this update, `shifts.carer_id` is set to the selected carer's UUID.

> **Quote from SHIFTS_SCREEN_ANALYSIS_REPORT.md, lines 165-175:**
> ```
> ### 5.1 Assigning a Carer (the main write path)
> When the user taps a shift card, _showAssignCarerBottomSheet() is invoked:
> 1. Loads carers via _shiftService.getCarers() (queries public.carers).
> 2. Shows a bottom sheet listing carers.
> 3. On carer selection, calls:
>    await _shiftService.assignCarerToShift(shift.id!, carerId);
> ```

### 3.5 Client Sees the Assigned Carer

The client-app queries shifts via `getShifts(clientOrganisationId)` and sees the updated `carer_id` + `carer_name` (via the `carers.name` join). This is working.

---
## 4. The Two "Shift" Systems (Legacy + New)

There are **two separate shift data structures** in the database, which is a source of confusion:

### 4.1 `public.shifts` (the "new" table — used by client-app)

**Created in:** Migration 001 (`supabase/migrations/001_initial_schema.sql`, lines 52-63)

```sql
CREATE TABLE shifts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  service_user_id UUID REFERENCES service_users(id) ON DELETE CASCADE,
  carer_id UUID REFERENCES carers(id) ON DELETE SET NULL,
  scheduled_date DATE NOT NULL,
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  status TEXT DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'in_progress', 'completed', 'cancelled')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**Later extensions** (migration 119, `119_add_shift_booking_columns.sql`):
```sql
ALTER TABLE shifts ADD COLUMN IF NOT EXISTS client_organisation_id UUID REFERENCES organisations(id);
ALTER TABLE shifts ADD COLUMN IF NOT EXISTS location TEXT;
ALTER TABLE shifts ADD COLUMN IF NOT EXISTS staff_required INTEGER DEFAULT 1;
ALTER TABLE shifts ADD COLUMN IF NOT EXISTS staff_type TEXT DEFAULT 'carer';
ALTER TABLE shifts ADD COLUMN IF NOT EXISTS notes TEXT;
ALTER TABLE shifts ADD COLUMN IF NOT EXISTS shift_type TEXT DEFAULT 'care';
ALTER TABLE shifts ADD COLUMN IF NOT EXISTS recurring BOOLEAN DEFAULT FALSE;
ALTER TABLE shifts ADD COLUMN IF NOT EXISTS recurring_pattern JSONB;
ALTER TABLE shifts ADD COLUMN IF NOT EXISTS created_by UUID;
ALTER TABLE shifts ADD COLUMN IF NOT EXISTS rate DECIMAL(10,2);
ALTER TABLE shifts ADD COLUMN IF NOT EXISTS broadcast_agency_ids JSONB DEFAULT '[]'::jsonb;
```

This table is the **single source of truth** that client-app writes to and admin-app reads from.

### 4.2 `public.shift_rotas` (the "legacy" table)

**Created in:** Migration 027 (`027_shift_rota.sql`)

```sql
CREATE TABLE IF NOT EXISTS shift_rotas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    service_user_id UUID REFERENCES service_users(id),
    carer_id UUID REFERENCES carers(id),
    start_date TIMESTAMP WITH TIME ZONE NOT NULL,
    end_date TIMESTAMP WITH TIME ZONE NOT NULL,
    shift_type VARCHAR(50) NOT NULL CHECK (shift_type IN ('Morning', 'Lunch', 'Tea', 'Evening')),
    day_of_week VARCHAR(20) NOT NULL,
    week_range VARCHAR(50) NOT NULL,
    is_recurring BOOLEAN DEFAULT false,
    ...
);
```

**The staff-app does NOT read from `shift_rotas` at all.** It only reads from `shifts` and `route_visits`.

### 4.3 The Staff-App's `Shift` Model

**File:** `staff-app/lib/models/shift.dart`

The staff-app defines its own `Shift` model that can parse from BOTH:
- `shifts` rows (via `Shift.fromMap()`) — standard booked shifts
- `route_visits` rows (via `Shift.fromRouteCall()`) — route calls created by admin

> **Quote from the model file (lines 62-98):**
> ```dart
> /// Builds a Shift-like card from a route_visits row (the Dom Care call
> /// record written by the ADMIN app). Staff see these as "route calls".
> factory Shift.fromRouteCall(Map<String, dynamic> map) {
>   final visitTime = map['visit_time'] as String?;
>   final duration = (map['duration_minutes'] as num?)?.toInt() ?? 60;
>   final start = visitTime?.substring(11, 16);
>   ...
>   return Shift(
>     id: map['id'] as String? ?? '',
>     ...
>     source: 'route',
>   );
> }
> ```

### 4.4 RLS Policies on `public.shifts`

**Original (migration 001):**
```sql
CREATE POLICY "Carers can view assigned shifts"
  ON shifts FOR SELECT
  USING (carer_id = auth.uid() OR auth.uid() IN (
    SELECT id FROM profiles WHERE role = 'admin'
  ));
```

**Updated (migration 028):**
```sql
CREATE POLICY "Carers can view assigned shifts" ON shifts
FOR SELECT USING (
  carer_id = auth.uid() OR 
  auth.uid() IN (SELECT id FROM profiles WHERE role = 'admin') OR
  organisation_id IS NULL
## 5. The Route System (Route Container + Route Visits)

This is a **two-tier** system redesigned across multiple migrations:

### 5.1 `public.routes` — the Route Container

**Created in:** Migration 104, then redesigned in 116, 137, 139, 140, 141.

A **route** is a named grouping of visits on a given day:
```sql
-- From migration 137 (route_visits_and_change_log.sql, lines 22-28):
ALTER TABLE public.routes ALTER COLUMN service_user_id DROP NOT NULL;
ALTER TABLE public.routes ADD COLUMN IF NOT EXISTS name TEXT;
ALTER TABLE public.routes ADD COLUMN IF NOT EXISTS route_date DATE;
```

**Carer assignment on routes** (migrations 139, 140):
```sql
ALTER TABLE public.routes
  ADD COLUMN IF NOT EXISTS carer_id UUID REFERENCES public.carers(id),
  ADD COLUMN IF NOT EXISTS is_driver BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS second_carer_id UUID REFERENCES public.carers(id),
  ADD COLUMN IF NOT EXISTS second_carer_is_driver BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS driver_mode TEXT NOT NULL DEFAULT 'primary';
```

### 5.2 `public.route_visits` — the Per-Visit Schedule

**Created in:** Migration 137 (`137_route_visits_and_change_log.sql`, lines 33-50)

```sql
CREATE TABLE IF NOT EXISTS public.route_visits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_organisation_id UUID NOT NULL REFERENCES public.client_organisations(id),
    route_id UUID REFERENCES public.routes(id) ON DELETE SET NULL,
    service_user_id UUID NOT NULL REFERENCES public.service_users(id),
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
    ...
);
```

> **Critical observation:** `route_visits.carer_id` references `public.carers(id)`, NOT `auth.users(id)` directly. The identity chain is: `route_visits.carer_id` → `carers.id` → `profiles.id` → `auth.users.id`. If any link in this chain is broken, staff cannot see their visits.

### 5.3 How Staff App Reads Routes

**File:** `staff-app/lib/services/shift_service.dart`, lines 71-123

```dart
Future<List<Shift>> getRouteCallsForCurrentCarer() async {
  final user = _client.auth.currentUser;
  if (user == null) return [];

  // 1. Visits where this carer is the assigned (primary) carer.
  final primary = await _client
      .from('route_visits')
      .select('*, service_users(name), carers(name), routes(name)')
      .eq('carer_id', user.id)           // <-- compares against auth.uid()
      .not('status', 'eq', 'cancelled')
      .order('visit_time', ascending: true);

  // 2. Visits for routes where this carer is the SECOND carer.
  final secondRoutes = await _client
      .from('routes')
      .select('id')
      .eq('second_carer_id', user.id);   // <-- compares against auth.uid()

  final routeIds = (secondRoutes as List)
      .cast<Map<String, dynamic>>()
      .map((r) => r['id'])
      .whereType<String>()
      .toList();

  if (routeIds.isNotEmpty) {
    final viaRoute = await _client
        .from('route_visits')
        .select('*, service_users(name), carers(name), routes(name)')
        .inFilter('route_id', routeIds)
        .not('status', 'eq', 'cancelled');
    // merge into visitRows...
  }
  // ...
}
```

**The staff-app `ShiftsScreen` merges both data sources:**

> **Quote from `staff-app/lib/ui/dashboard/shifts_screen.dart`, lines 33-62:**
> ```dart
> Future<void> _loadShifts() async {
>   // TWO data sources power this screen:
>   //  1. public.shifts  - client-app bookings, confirmed by admin
>   //  2. public.route_visits - ongoing/one-off ROUTE calls written by admin
>   final results = await Future.wait([
>     _shiftService.getShiftsForCurrentCarer(),
>     _shiftService.getRouteCallsForCurrentCarer(),
>   ]);
>   final combined = <Shift>[...results[0], ...results[1]]
>     ..sort((a, b) { ... });
>   setState(() { _shifts = combined; });
> }
> ```

This code is architecturally correct — the data layer is wired up. The problem is that both queries return **empty lists** because the underlying data or RLS doesn't pass.
);
```

**Key observation:** The RLS policy for shifts is **carer-friendly** — it allows `carer_id = auth.uid()`. The blocker is not the RLS; it's the data not matching.
## 6. Root-Cause #1: Identity-Linkage Breakdown — carers.id vs auth.uid()

### The Intended Identity Model

```
auth.users.id  ←→  profiles.id  ←→  carers.id
     ↑                                     ↑
  staff logs in                  admin assigns this
  as user X                      UUID to the shift
```

### Where It Breaks

The staff-app `ShiftService` uses **`auth.uid()`** as the query parameter:

```dart
// staff-app/lib/services/shift_service.dart, line 17
.eq('carer_id', user.id)   // user.id = auth.uid()
```

The admin-app assigns **`carers.id`** as the `carer_id` on the shift.  

**For this to work, the following MUST all be the same UUID value:**

1. The staff member's `auth.users.id`
2. The staff member's `profiles.id`
3. The staff member's `carers.id`
4. The value written to `shifts.carer_id` (or `routes.carer_id` or `route_visits.carer_id`)

### Evidence This Chain Is Often Broken

**A — Legacy carer records have no auth users:**
> From migration 001: `carers.id UUID PRIMARY KEY REFERENCES profiles(id)`. If admin manually created carer records without corresponding auth users, those profiles may not correspond to any auth user who can log in.

**B — Staff self-signup creates new users with possibly different IDs:**
> From `staff-app/lib/services/supabase_auth_service.dart`, lines 94-111:
> ```dart
> Future<AuthResult> signUpAsStaff({...required String carerId...}) async {
>   await _supabase.rpc('staff_signup', params: {
>     'p_email': email.trim(),
>     'p_password': password,
>     'p_carer_id': carerId,
>     ...
>   });
> }
> ```

**C — `_loadUserProfile` creates a profile but NO carers row:**
> From `staff-app/lib/services/supabase_auth_service.dart`, lines 304-340: When no profile exists, a new one is inserted with `role='carer'`, but NO `carers` row is created. If admin tries to assign this UUID as `carer_id` on a shift, the FK constraint (`shifts.carer_id REFERENCES carers(id)`) fails — no `carers` row has that ID.

**The Real Scenario (most likely):**
- ✅ If carer created via `staff_signup` (links auth.users → profiles → carers with matching IDs), `auth.uid()` matches `carers.id`.
- ❌ If legacy carer with no auth linkage, they cannot log in at all.
- ❌ If carer self-signs up with NEW auth account but admin assigned OLD `carers.id`, IDs won't match.

### Diagnostic SQL to Verify

```sql
-- Find carers with no matching auth.users
SELECT c.id AS carer_id, c.employee_number, p.email, p.role,
       CASE WHEN au.id IS NULL THEN 'NO AUTH USER' ELSE 'OK' END AS auth_status
FROM public.carers c
JOIN public.profiles p ON p.id = c.id
LEFT JOIN auth.users au ON au.id = c.id
ORDER BY auth_status, c.employee_number;

-- Find shifts with orphan carer_id
SELECT s.id AS shift_id, s.carer_id, s.status, s.scheduled_date,
       CASE WHEN au.id IS NULL THEN 'ORPHAN CARER' ELSE 'OK' END AS carer_status
FROM public.shifts s
LEFT JOIN auth.users au ON au.id = s.carer_id
WHERE s.carer_id IS NOT NULL
ORDER BY carer_status, s.scheduled_date;

-- Find route_visits with orphan carer_id
SELECT rv.id, rv.carer_id, rv.visit_date, rv.status,
       CASE WHEN au.id IS NULL THEN 'ORPHAN CARER' ELSE 'OK' END AS carer_status
FROM public.route_visits rv
LEFT JOIN auth.users au ON au.id = rv.carer_id
WHERE rv.carer_id IS NOT NULL
ORDER BY carer_status, rv.visit_date;
```
---

## 7. Root-Cause #2: route_visits RLS Policies Block Staff Users

### The Original RLS on `route_visits` (Migration 137)

```sql
-- From 137_route_visits_and_change_log.sql, lines 60-67:
CREATE POLICY "Users can view route visits for their organisation"
    ON public.route_visits FOR SELECT TO authenticated
    USING (
        client_organisation_id = (
            SELECT client_organisation_id FROM public.profiles WHERE id = auth.uid()
        )
    );
```

### Why This Blocks Staff Users

A **staff user (carer)** has:
- `profiles.role = 'carer'`
- `profiles.organisation_id = '<org UUID>'` (the admin organisation they work for)
- `profiles.client_organisation_id = NULL` (they don't belong to a care home client org)

The RLS policy checks `client_organisation_id = profiles.client_organisation_id`. For a staff user, this becomes `client_organisation_id = NULL`. In SQL, `NULL = NULL` evaluates to `NULL` (unknown), which is **not TRUE**, so **the row is blocked**.

### The Fix That Was Applied (Migration 146)

> **From `supabase/migrations/146_route_reads_for_carers.sql`, lines 31-43:**
> ```sql
> CREATE POLICY "Carers can view their own route visits"
>   ON public.route_visits FOR SELECT TO authenticated
>   USING (
>     (carer_id = auth.uid())
>     OR
>     (route_id IS NOT NULL AND EXISTS (
>       SELECT 1 FROM public.routes r
>       WHERE r.id = route_id
>         AND (r.carer_id = auth.uid() OR r.second_carer_id = auth.uid())
>     ))
>   );
> ```

**This policy IS in place.** However, it only helps if `route_visits.carer_id` (or `routes.carer_id`) equals `auth.uid()`. This brings us back to Root-Cause #1 — if the identity linkage is broken, this carer-specific policy passes no rows either.

### Similarly for `routes`:

> **From migration 146, lines 57-62:**
> ```sql
> CREATE POLICY "Carers can view their own routes"
>   ON public.routes FOR SELECT TO authenticated
>   USING (
>     carer_id = auth.uid() OR second_carer_id = auth.uid()
>   );
> ```
---

## 8. Root-Cause #3: Staff-App ShiftService Ignores organisation_id Scoping

The staff-app `ShiftService.getShiftsForCurrentCarer()` ONLY filters by `carer_id`:

```dart
// staff-app/lib/services/shift_service.dart, lines 10-24
Future<List<Shift>> getShiftsForCurrentCarer() async {
  final user = _client.auth.currentUser;
  if (user == null) return [];

  final response = await _client
      .from('shifts')
      .select('*, service_users(name), carers(name)')
      .eq('carer_id', user.id)    // <-- ONLY filter
      .order('scheduled_date', ascending: true)
      .order('start_time', ascending: true);

  return (response as List)
      .map((json) => Shift.fromMap(json as Map<String, dynamic>))
      .toList();
}
```

There is **no check on `organisation_id`**. The RLS policy for shifts (migration 028) allows `carer_id = auth.uid()` regardless of `organisation_id`. So RLS is not the blocker for shifts — it's purely the data (no shift has `carer_id` matching that staff user's UUID).

**Impact:** Even with correct identity linkage, staff see only shifts where `carer_id` matches their exact UUID. There is no fallback to see unassigned shifts in their organisation.

---

## 9. Root-Cause #4: Admin-App Route Service May Write carer_id From Legacy Source

The admin-app `RouteService.assignCarerToRouteCluster()` and `assignCarerToVisit()` write `carer_id` values to `routes.carer_id` and `route_visits.carer_id`. If the admin selects a carer from the `carers` table and that `carers.id` does not correspond to an active auth user (legacy record), then:

1. The write succeeds (RLS allows admins to update routes)
2. The staff-app query `WHERE carer_id = auth.uid()` returns nothing
3. The carer sees an empty shift/route list

**Key files involved:**
- `admin-app/lib/services/route_service.dart` — `assignCarerToRouteCluster()`, `assignCarerToVisit()`
- `admin-app/lib/ui/shift/shift_list_screen.dart` — admin UI that triggers carer assignment
- `admin-app/lib/services/shift_service.dart` — `assignCarerToShift()` for shifts table
---

## 10. Complete Data-Flow Diagram (All Three Apps)

```
CLIENT-APP                                        ADMIN-APP
─────────                                        ─────────

BookShiftScreen ──→ createShift()                shift_list_screen.dart
       │                  │                             │
       │          INSERT INTO public.shifts             │ getShiftsForDate(date)
       │          (client_organisation_id,              │ SELECT FROM shifts
       │           scheduled_date, start_time,          │ WHERE scheduled_date = ?
       │           end_time, status='scheduled')        │
       ▼                  │                             ▼
┌──────────────────┐      │                 ┌──────────────────┐
│  public.shifts   │◄─────┘                 │  public.shifts   │
│  carer_id = NULL │                        │  carer_id = ?    │
│  status=scheduled│                        │  status=confirmed│
└──────────────────┘                        └────────┬─────────┘
       ▲                                              │
       │ getShifts(clientOrgId)        assignCarerToShift(shiftId, carerId)
       │                                      │
  BookingDiaryScreen                UPDATE shifts SET carer_id = ?,
                                     status = 'confirmed'
                                              │
                                              ▼
                                     ┌──────────────────┐
                                     │  public.routes    │
                                     │  carer_id = ?     │
                                     └────────┬─────────┘
                                              │
                                     ┌──────────────────┐
                                     │ public.route_    │
                                     │ visits            │
                                     │ carer_id = ?     │
                                     └──────────────────┘
                                              ▲
                                              │
                                      STAFF-APP
                                      ─────────

                            ShiftsScreen._loadShifts()
                                 │
                      ┌──────────┴──────────┐
                      │                     │
             getShiftsFor            getRouteCalls
             CurrentCarer()          ForCurrentCarer()
                      │                     │
             WHERE carer_id          WHERE carer_id
             = auth.uid()            = auth.uid()
                      │                     │
                      ▼                     ▼
                 ❌ EMPTY              ❌ EMPTY
            (if carer_id ≠          (if carer_id ≠
             auth.uid())             auth.uid())

           Combined result:
    "No shifts assigned for this day"
```

**This perpetuates the identity problem** — admin keeps assigning legacy carer UUIDs to shifts/routes, and staff with new auth accounts never see them.
---

## 11. Solutions (Prioritised for Longevity)

### Solution A: Fix the Identity Linkage (CRITICAL — Must Do First)

**What:** Ensure every `carers` row is linked to a valid `auth.users` row with consistent UUIDs across the chain.

**Steps:**

1. **Audit existing data** with the diagnostic SQL from Section 6.
2. **For legacy carers without auth accounts:**
   - **Option A (preferred):** Admin invites them via the `staff_signup` RPC. The RPC must update `carers.id` to match `auth.users.id`.
   - **Option B:** Create auth users via Supabase Admin API with their carer UUID as the ID, then set a temporary password.
3. **For orphan shifts/routes:** Reassign `carer_id` to valid auth-linked carers.

### Solution B: Add organisation_id Fallback Filter in Staff-App (High Priority)

**File:** `staff-app/lib/services/shift_service.dart` — modify `getShiftsForCurrentCarer()` to fall back to `organisation_id`-scoped unassigned shifts when the direct `carer_id` query returns empty.

### Solution C: Database View for Staff Work (Sustainable, Scalable)

Create a Postgres VIEW (`staff_work_view`) that unions `shifts` + `route_visits` into a single query surface, indexed by `carer_id` and `organisation_id`. Staff-app queries this single view instead of merging two sources in Dart.

```sql
CREATE OR REPLACE VIEW public.staff_work_view AS
SELECT s.id, s.carer_id, s.scheduled_date, s.start_time, s.end_time,
  s.status, s.organisation_id, su.name AS service_user_name,
  c.name AS carer_name, 'shift' AS source
FROM public.shifts s
LEFT JOIN public.service_users su ON su.id = s.service_user_id
LEFT JOIN public.carers c ON c.id = s.carer_id
UNION ALL
SELECT rv.id, rv.carer_id, rv.visit_date AS scheduled_date,
  (rv.visit_time)::time AS start_time,
  (rv.visit_time + (rv.duration_minutes || ' minutes')::interval)::time AS end_time,
  rv.status, rv.organisation_id,
  su.name AS service_user_name, c.name AS carer_name, 'route' AS source
FROM public.route_visits rv
LEFT JOIN public.service_users su ON su.id = rv.service_user_id
LEFT JOIN public.carers c ON c.id = rv.carer_id;
```

### Solution D: Database Trigger to Prevent Orphan carer_id (Defensive)

Triggers on `shifts`, `routes`, and `route_visits` that reject any INSERT or UPDATE where `carer_id` does not exist in `auth.users`. This prevents the problem at the database level.

### Solution E: Consolidate Admin-App Shift Service Layer (Tech Debt)

Phase out the legacy `DatabaseService.getShifts()` (broken, uses old `date` column) and wire `shift_list_screen.dart` to use the new `ShiftService` exclusively.
---

## 12. Appendix: Key Files & Migration Reference

### Database Schema (Supabase Migrations)

| File | Purpose |
|---|---|
| `supabase/migrations/001_initial_schema.sql` | Profiles, carers, shifts, visits, RLS policies |
| `supabase/migrations/027_shift_rota.sql` | Legacy shift_rotas table (NOT used by staff-app) |
| `supabase/migrations/028_add_organisation_id.sql` | Multi-tenancy: adds `organisation_id` to all tables; updates shifts RLS |
| `supabase/migrations/104_create_routes_table.sql` | Initial routes table |
| `supabase/migrations/116_create_routes_table.sql` | Revised routes table |
| `supabase/migrations/117_create_shift_broadcasts.sql` | Broadcast system for multi-agency shifts |
| `supabase/migrations/119_add_shift_booking_columns.sql` | client_organisation_id, location, staff_type on shifts |
| `supabase/migrations/137_route_visits_and_change_log.sql` | route_visits + route_change_log + routes→container redesign |
| `supabase/migrations/139_route_carers_and_driver.sql` | carer_id, is_driver on routes |
| `supabase/migrations/140_route_second_carer_driver_mode.sql` | second_carer_id, driver_mode on routes |
| `supabase/migrations/141_routes_admin_organisation.sql` | Dual RLS: organisation_id OR client_organisation_id |
| `supabase/migrations/146_route_reads_for_carers.sql` | Carer RLS policies for routes and route_visits |

### Staff-App Source Files

| File | Role |
|---|---|
| `staff-app/lib/main.dart` | App entry — initialises Supabase |
| `staff-app/lib/services/supabase_auth_service.dart` | Auth + profile loading; auto-creates profiles with `role='carer'` |
| `staff-app/lib/services/shift_service.dart` | **Key** — `getShiftsForCurrentCarer()` and `getRouteCallsForCurrentCarer()` |
| `staff-app/lib/models/shift.dart` | Staff-side `Shift` model with `fromMap()` and `fromRouteCall()` |
| `staff-app/lib/ui/dashboard/shifts_screen.dart` | **Key UI** — merges shifts + route_visits results |
| `staff-app/lib/ui/dashboard/staff_dashboard.dart` | Shell embedding `ShiftsScreen` |

### Admin-App Source Files

| File | Role |
|---|---|
| `admin-app/lib/services/shift_service.dart` | Admin's `Shift` model + `ShiftService` class |
| `admin-app/lib/services/route_service.dart` | CRUD for routes and route_visits; carer assignment |
| `admin-app/lib/services/database_service.dart` | Legacy CRUD — `getShifts()` is broken (old `date` column) |
| `admin-app/lib/ui/shift/shift_list_screen.dart` | Admin shift/route list UI |

### Client-App Source Files

| File | Role |
|---|---|
| `client-app/lib/services/shift_service.dart` | `createShift()`, `getShifts()`, `assignCarer()` |
| `client-app/lib/services/shift_broadcast_service.dart` | Multi-agency broadcast |
| `client-app/lib/services/route_service.dart` | Client-side route CRUD |

---

## Summary of Root Causes

| # | Root Cause | Impact | Fix Priority |
|---|---|---|---|
| 1 | **Identity linkage broken:** `shifts.carer_id` / `route_visits.carer_id` / `routes.carer_id` do not match staff user's `auth.uid()` because legacy carers have no auth accounts | Staff sees zero shifts/routes | **CRITICAL** |
| 2 | `route_visits` original RLS checks `client_organisation_id` (NULL for staff). Migration 146 added carer-policy but it requires identity linkage from #1 | Route visibility blocked | **High** |
| 3 | Staff-app `getShiftsForCurrentCarer()` has no `organisation_id` fallback | No unassigned shift visibility | **Medium** |
| 4 | Admin-app writes legacy carer UUIDs to shifts/routes with no auth linkage | Perpetuates identity problem | **Medium** |

**Recommended action order:**
1. Run diagnostic SQL (Section 6) to understand the scale
2. Fix identity linkage for all carers (Solution A)
3. Reassign orphan-shift `carer_id` values to valid auth-linked carers
4. Add database triggers (Solution D) to prevent future regressions
5. Add `organisation_id` fallback in staff-app (Solution B)
6. Consider the VIEW approach (Solution C) for long-term scalability
7. Consolidate admin-app's shift service layer (Solution E)