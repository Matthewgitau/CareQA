# Shifts Architecture Report — CareQA (Client-App ↔ Admin-App)

**Date:** 9 Aug 2026
**Author:** Cline
**Purpose:** Document the current shift-related code across client-app, admin-app, the shared `shifts` database table, and the gap that prevents the admin-app from seeing shifts created by the client-app. This report is intended so you can write a concise, precise follow-up prompt to get exactly what you want.

---

## 1. Executive Summary

| Question | Answer |
|----------|--------|
| Is there a shared `shifts` table? | **Yes** — both apps write to/read from `public.shifts` in Supabase. |
| Does the client-app create shifts? | **Yes** — `client-app/lib/services/shift_service.dart` → `createShift()`. |
| Does the admin-app currently see them? | **No** — the admin-app reads through `DatabaseService.getShifts()` which uses a **legacy `Shift` model** that maps the **old `date` column**, but client-app writes to **`scheduled_date`**. The schemas are misaligned. |
| Is there an explicit API between the two apps? | **No** — both apps talk directly to Supabase (no custom REST/API gateway in between). The "API" is effectively Supabase/PostgREST. |
| Is there a second, newer shift service in admin-app? | **Yes** — `admin-app/lib/services/shift_service.dart` was added (Phase 3) but its `_getClientOrgId()` is a **placeholder returning `null`**, so it is not yet wired to the UI. |

---

## 2. The Shared Database Table

### `public.shifts`

This is the single source of truth. The **client-app writes** to it, and the **admin-app must read** from it.

Fields written by client-app (`createShift`):

| Column | Type (as written) | Notes |
|--------|-------------------|-------|
| `client_organisation_id` | UUID string | Scoping key — identifies the care home/client org |
| `scheduled_date` | `YYYY-MM-DD` string | **Date column used by client-app** |
| `start_time` | `HH:MM:00` string | Time as string |
| `end_time` | `HH:MM:00` string | Time as string |
| `status` | `'scheduled'` | Default status |
| `location` | string? | Optional |
| `staff_required` | int | Defaults to 1 |
| `staff_type` | string? | `'carer'`, `'senior_carer'`, `'team_leader'` |
| `carer_id` | UUID? | Set later on assignment (via `assignCarer`) |
| `service_user_id` | UUID? | From client-app `Shift.fromJson` (currently often empty from booking form) |

Related tables used in joins by admin-app:
- `service_users` (join: `service_users.name`)
- `carers` (join: `carers.name`)

Interface/API = **Supabase PostgREST** (`supabase_flutter` SDK). No custom backend between the Flutter apps.

---

## 3. Client-App (Writes Shifts)

### 3.1 `client-app/lib/models/shift.dart`
**Location:** `client-app/lib/models/shift.dart`
**Contains:** `Shift` model for the **client side**.
- Fields: `id`, `serviceUserId`, `carerId`, `scheduledDate`, `startTime`/`endTime` (as `TimeOfDay`), `status`, `organisationId`, `agencyClientId`, `agencyBillingRate`, `clientOrganisationId`, `location`, `staffRequired`, `staffType`, `notes`, `createdAt`, `updatedAt`.
- `fromJson()` / `toJson()` — maps **camelCase** Dart fields to **snake_case** DB columns: `service_user_id`, `carer_id`, `scheduled_date`, `start_time`, `end_time`, `client_organisation_id`, `location`, `staff_required`, `staff_type`, `organisation_id`, `agency_client_id`, `agency_billing_rate`, `notes`.

### 3.2 `client-app/lib/services/shift_service.dart`
**Location:** `client-app/lib/services/shift_service.dart`
**Contains:** `ShiftService` class using `SupabaseManager.instance.client`.
- `getShifts(clientOrganisationId)` → `SELECT * FROM shifts WHERE client_organisation_id = ? ORDER BY scheduled_date`
- `getShiftsByLocation(clientOrganisationId, location)` → filtered by `location`
- `getShiftsByStaffType(clientOrganisationId, staffType)` → filtered by `staff_type`
- `getShiftById(id)` → single shift
- **`createShift(...)`** → `INSERT INTO shifts (client_organisation_id, scheduled_date, start_time, end_time, status, location, staff_required, staff_type)` → returns new shift. **This is the function that writes the shifts you want the admin-app to see.**
- `updateShift(shift)` → `UPDATE shifts SET ... WHERE id = ?`
- `deleteShift(id)`
- `updateShiftStatus(shiftId, status)`
- `assignCarer(shiftId, carerId)` → sets `carer_id` + `status = 'confirmed'`

### 3.3 UI that calls it
- **`client-app/lib/ui/shifts/book_shift_screen.dart`** — calls `ShiftService().createShift(...)` inside `_submit()` with `auth.clientOrganisationId`.
- **`client-app/lib/ui/shifts/booking_diary_screen.dart`** — calls `ShiftService().getShifts(clientOrgId)` and displays them in the diary. Shifts are clickable and open `shift_detail_bottom_sheet.dart` (which assigns/unassigns carers via direct Supabase updates).

---

## 4. Admin-App (Should Read Shifts — Currently Broken)

### 4.1 Legacy Path (Wired to UI, Wrong Schema)
**Model:** `admin-app/lib/models/shift.dart`
**Contains:** `Shift` model with **legacy fields**:
- `id`, `serviceUserId`, `carerId`, `date` (**DateTime**), `startTime` (**DateTime**), `endTime` (**DateTime**), `status`, `notes`.
- `toMap()` writes: `service_user_id`, `carer_id`, `date`, `start_time`, `end_time`, `status`, `notes`.
- **Problem:** uses `date`, **not** `scheduled_date`. This does **not** match the client-app's schema.

**Service:** `admin-app/lib/services/database_service.dart`
- `addShift(shift)` → `INSERT INTO shifts` (with `_withOrgId` auto-attaching `organisation_id` using legacy map)
- `updateShift(shift)` → `UPDATE shifts`
- `deleteShift(shiftId)`
- **`getShifts()`** → `SELECT *, service_users(name), carers(name) FROM shifts ORDER BY date` — **uses `date` column which doesn't exist in the current schema and does not filter by `client_organisation_id`.** This is the function the UI currently calls.

**UI:** `admin-app/lib/ui/shift/shift_list_screen.dart`
- Calls `context.read<DatabaseService>().getShifts()` in `_load()`.
- Displays each shift via `Shift.fromMap(...)` → uses `shift.date` / `shift.startTime.hour` etc.
- **Because of the schema mismatch, this screen fails / cannot display client-app-created shifts.**

### 4.2 New Path (Correct Schema, Not Wired to UI)
**File:** `admin-app/lib/services/shift_service.dart`
**Contains a local `Shift` model matching the current DB schema** plus a `ShiftService` class:
- `Shift` model fields: `id`, `clientOrganisationId`, `serviceUserId`, `carerId`, `scheduledDate` (DateTime), `startTime`/`endTime` (**String** `HH:MM:SS`), `status`, `location`, `staffRequired`, `staffType`, `notes`.
- `fromJson`/`toJson` map exactly to the DB columns the client-app writes: `client_organisation_id`, `service_user_id`, `carer_id`, `scheduled_date`, `start_time`, `end_time`, `status`, `location`, `staff_required`, `staff_type`, `notes`.
- `getShiftsForDate(DateTime date)` → `SELECT ... WHERE client_organisation_id = ? AND scheduled_date = ?`
- `getShiftsForMonth(DateTime month)` → `WHERE client_organisation_id = ? AND scheduled_date >= ? AND scheduled_date <= ?`
- `updateShift(shift)`
- `assignCarerToShift(shiftId, carerId)` / `unassignCarerFromShift(shiftId)`
- `sendShiftReminder(shiftId)` — placeholder
- **`_getClientOrgId()` — returns `null` (placeholder!).** It fetches `auth.currentUser` but does not yet look up the user's `client_organisation_id`. This must be implemented for the service to work.

**Not currently referenced from any UI screen.**

---

## 5. The Gap (Why Admin-App Can't See Client-App Shifts)

There are three concrete problems:

1. **Wrong model/column:** `admin-app/lib/models/shift.dart` + `DatabaseService.getShifts()` use `date`, but the client-app writes `scheduled_date`. The admin DB query will fail or return nothing.
2. **Missing org filter:** `DatabaseService.getShifts()` does not filter by `client_organisation_id`, so even if the column were fixed, it would not scope to the right organisation.
3. **Unwired new service:** The correctly-scoped `admin-app/lib/services/shift_service.dart` (`getShiftsForDate`/`getShiftsForMonth`) exists but:
   - `_getClientOrgId()` returns `null`
   - `shift_list_screen.dart` still uses `DatabaseService` instead of `ShiftService`

There is **no dedicated "API" layer**; both apps use the Supabase PostgREST API directly. To make the admin-app pull client-app shifts you either:
- (A) Fix the existing admin-app `DatabaseService`/model to match the current `shifts` schema, **or**
- (B) Wire `admin-app/lib/services/shift_service.dart` into the admin UI and implement `_getClientOrgId()` (fetch `client_organisation_id` from the `profiles` table or user metadata).

---

## 6. How the Data Flows (Diagram)

```
[Client-App]
  book_shift_screen.dart
     │  _submit()
     ▼
  ShiftService.createShift(...)
     │  INSERT INTO shifts
     │    (client_organisation_id, scheduled_date, start_time, end_time,
     │     status='scheduled', location, staff_required, staff_type)
     ▼
┌──────────────────────────────────────────────┐
│         Supabase (PostgREST API)             │
│         public.shifts  (single source)       │
│         + service_users, carers              │
└──────────────────────────────────────────────┘
     ▲
     │  SELECT ... WHERE client_organisation_id = ?
     │
[Admin-App]
  shift_list_screen.dart
     │  currently: DatabaseService.getShifts()  ← BROKEN (uses legacy 'date')
     │  should be: ShiftService.getShiftsForDate/getShiftsForMonth  ← exists, unwired
     ▼
  Shift model (needs to map scheduled_date/start_time/end_time strings)
```

---

## 7. Suggested Next Prompt (Concise)

To get exactly what you want, you could give a prompt like this:

> "Wire up the admin-app to display shifts created by the client-app."
>
> **Tasks:**
> 1. Update `admin-app/lib/services/shift_service.dart` so `_getClientOrgId()` fetches the authenticated user's `client_organisation_id` from the `profiles` table (fallback to user metadata).
> 2. Replace the usage of `DatabaseService.getShifts()` and the legacy `admin-app/lib/models/shift.dart` model in `admin-app/lib/ui/shift/shift_list_screen.dart` with the new `ShiftService` (`getShiftsForDate` or `getShiftsForMonth`) and its local `Shift` model so columns match (`scheduled_date`, `start_time`, `end_time` as strings).
> 3. Ensure the shift list screen accepts/navigates with a selected date and displays client-org shift time slots.
> 4. Keep `DatabaseService` as-is for other tables (carers, service users, visits) but stop using it for shifts.

---

## 8. File/Table Quick Reference

### Files (shifts)
| File | Role | Functions | DB Table(s) |
|------|------|-----------|-------------|
| `client-app/lib/models/shift.dart` | Client Shift model | `fromJson`, `toJson` | — |
| `client-app/lib/services/shift_service.dart` | **Writes/reads shifts** | `createShift`, `getShifts`, `updateShift`, `deleteShift`, `updateShiftStatus`, `assignCarer`, `getShiftById`, `getShiftsByLocation`, `getShiftsByStaffType` | `shifts` |
| `client-app/lib/ui/shifts/book_shift_screen.dart` | Creates shifts | `_submit` → `createShift` | `shifts` |
| `client-app/lib/ui/shifts/booking_diary_screen.dart` | Views shifts | `getShifts` | `shifts` |
| `client-app/lib/ui/shifts/shift_detail_bottom_sheet.dart` | Assign/unassign/remind | direct Supabase `update` + `debugPrint` | `shifts`, `carers` |
| `admin-app/lib/models/shift.dart` | **Legacy admin model (broken)** | `toMap`, `fromMap` | — |
| `admin-app/lib/services/database_service.dart` | Legacy CRUD | `addShift`, `updateShift`, `deleteShift`, **`getShifts`** (broken) | `shifts`, `service_users`, `carers` |
| `admin-app/lib/services/shift_service.dart` | **New correct service (unwired)** | `getShiftsForDate`, `getShiftsForMonth`, `updateShift`, `assignCarerToShift`, `unassignCarerFromShift`, `sendShiftReminder` | `shifts` |
| `admin-app/lib/ui/shift/shift_list_screen.dart` | Admin shift UI | `_load` → `DatabaseService.getShifts` | `shifts` |

### Database tables
| Table | Used By | Purpose |
|-------|---------|---------|
| `shifts` | Both apps | Single source of truth for shifts |
| `service_users` | Admin join | Display `name` |
| `carers` | Admin join + assignment | Display/assign carer `name` |
| `profiles` | Both apps | Resolve `organisation_id` / `client_organisation_id` for the current user |
| `client_organisation_psl` | Client-app | Agency broadcasting (Phase 4) |
| `shift_broadcasts` | Client-app | Multi-agency broadcast tracking (Phase 4) |