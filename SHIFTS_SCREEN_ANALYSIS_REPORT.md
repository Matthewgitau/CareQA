# In-Depth Analysis: How `admin-app`'s Shifts Screen Reads & Interacts with `public.shifts`

## 1. Overview

The admin-app's shifts functionality is split across two files:

| File | Role |
|------|------|
| `admin-app/lib/ui/shift/shift_list_screen.dart` | The **UI layer** — renders the shift list, handles date navigation, and triggers carer assignment |
| `admin-app/lib/services/shift_service.dart` | The **data layer** — contains the `Shift` model, `RouteSchedule` model, and `ShiftService` class that performs all Supabase queries against `public.shifts` |

> **Important architectural note:** The admin-app does **NOT** use the shared `packages/core/lib/models/shift.dart` model. It defines its **own local `Shift` class** inside `shift_service.dart`. This is a key divergence from the client-app, which uses the core model.

---

## 2. The `public.shifts` Table Schema

The table has **25 columns**:

| Column | Type | Nullable | Notes |
|--------|------|----------|-------|
| `id` | `uuid` | NO | Primary key |
| `service_user_id` | `uuid` | YES | FK to service_users |
| `carer_id` | `uuid` | YES | FK to carers (assigned carer) |
| `scheduled_date` | `date` | NO | The date of the shift |
| `start_time` | `time` | NO | Start time (HH:MM:SS) |
| `end_time` | `time` | NO | End time (HH:MM:SS) |
| `status` | `text` | YES | e.g. scheduled, confirmed, completed |
| `created_at` | `timestamptz` | YES | Auto-set |
| `updated_at` | `timestamptz` | YES | Auto-updated by trigger |
| `organisation_id` | `uuid` | YES | Parent organisation |
| `agency_client_id` | `uuid` | YES | Agency client reference |
| `agency_billing_rate` | `numeric` | YES | Billing rate |
| `client_organisation_id` | `uuid` | YES | **The care home** (key for RLS) |
| `location` | `text` | YES | Shift location |
| `staff_required` | `integer` | YES | Number of staff needed |
| `staff_type` | `text` | YES | carer / senior_carer / team_leader |
| `shift_date` | `date` | YES | Legacy/duplicate of scheduled_date |
| `broadcast_type` | `text` | YES | single / multiple / all |
| `notes` | `text` | YES | Free-text notes |
| `shift_type` | `text` | YES | care / warehouse / transport / admin / training |
| `recurring` | `boolean` | YES | Whether shift recurs |
| `recurring_pattern` | `jsonb` | YES | Recurrence rules |
| `created_by` | `uuid` | YES | Who created the shift |
| `rate` | `numeric` | YES | Pay rate |
| `broadcast_agency_ids` | `jsonb` | YES | Agencies the shift was broadcast to |

---

## 3. RLS Policies on `public.shifts`

There are **4 RLS policies** that govern access:

### 3.1 `Admins can manage all shifts` (ALL)
```sql
EXISTS (
  SELECT 1 FROM profiles
  WHERE profiles.id = auth.uid()
    AND profiles.role = 'admin'
)
```
- **Admins** (and super_admins, if role is set) can SELECT, INSERT, UPDATE, DELETE any shift.

### 3.2 `Carers can view assigned shifts` (SELECT)
```sql
carer_id = auth.uid()
OR auth.uid() IN (SELECT id FROM profiles WHERE role = 'admin')
OR organisation_id IS NULL
```
- A carer can see shifts **assigned to them**.
- Admins can also see them (redundant with policy 3.1).
- Shifts with `organisation_id IS NULL` are visible to everyone (legacy/global shifts).

### 3.3 `Clients can create shifts for their own care home` (INSERT)
```sql
WITH CHECK (
  client_organisation_id = (
    SELECT profiles.client_organisation_id FROM profiles WHERE profiles.id = auth.uid()
  )
)
```
- A client user can only **insert** a shift whose `client_organisation_id` matches their own care home.

### 3.4 `Clients can view their own shifts` (SELECT)
```sql
client_organisation_id = (
  SELECT profiles.client_organisation_id FROM profiles WHERE profiles.id = auth.uid()
)
```
- A client user can only **view** shifts belonging to their own care home.

### 3.5 Triggers
- `check_carer_double_booking_trigger` — prevents a carer from being double-booked on overlapping shifts.
- `update_shifts_updated_at` — auto-updates `updated_at` on any change.

---

## 4. How the Screen Reads from `public.shifts`

### 4.1 The `_load()` flow (initState → getShiftsForDate)

When the screen loads (or the date changes, or pull-to-refresh), it calls:

```dart
final shifts = await _shiftService.getShiftsForDate(_selectedDate);
```

### 4.2 `ShiftService.getShiftsForDate(DateTime date)`

This is the **primary read path**. Here's the exact sequence:

1. **Authenticate** — gets `Supabase.instance.client.auth.currentUser`; throws if null.
2. **Resolve the user's role & org** — queries `profiles`:
   ```dart
   _client.from('profiles')
     .select('role, organisation_id, client_organisation_id')
     .eq('id', user.id)
     .single();
   ```
3. **Build the query** against `public.shifts`:
   ```dart
   _client.from('shifts')
     .select('*, service_users(name), carers(name)')
   ```
   - `*` selects all 25 columns.
   - `service_users(name)` is a **foreign-key join** to get the service user's name.
   - `carers(name)` is a **foreign-key join** to get the assigned carer's name.
4. **Filter by date**:
   ```dart
   .eq('scheduled_date', dateStr)   // dateStr = 'YYYY-MM-DD'
   ```
5. **Role-based filtering**:
   - If the user is **admin/super_admin** → no org filter (sees all shifts).
   - Otherwise (client user) → `.eq('client_organisation_id', clientOrgId)`.
6. **Order** by `start_time` ascending.
7. **Map results** to the local `Shift` model via `Shift.fromJson()`.

### 4.3 The `Shift.fromJson()` mapping

The local admin `Shift` model maps these DB columns:

| DB column | Shift field |
|-----------|-------------|
| `id` | `id` |
| `client_organisation_id` | `clientOrganisationId` |
| `service_user_id` | `serviceUserId` |
| `carer_id` | `carerId` |
| `scheduled_date` | `scheduledDate` (DateTime) |
| `start_time` | `startTime` (String, e.g. "08:00") |
| `end_time` | `endTime` (String) |
| `status` | `status` |
| `location` | `location` |
| `staff_required` | `staffRequired` |
| `staff_type` | `staffType` |
| `notes` | `notes` |
| `service_users.name` (join) | `serviceUserName` |
| `carers.name` (join) | `carerName` |

> **Note:** The admin `Shift` model stores `start_time`/`end_time` as **Strings** (raw from DB), whereas the core model stores them as `DateTime`. The screen's `_formatTime()` helper splits the string on `:` to display `HH:MM`.

---

## 5. How the Screen Writes to `public.shifts`

### 5.1 Assigning a Carer (the main write path)

When the user taps a shift card, `_showAssignCarerBottomSheet()` is invoked:

1. **Loads carers** via `_shiftService.getCarers()` (queries `public.carers`).
2. Shows a bottom sheet listing carers.
3. On carer selection, calls:
   ```dart
   await _shiftService.assignCarerToShift(shift.id!, carerId);
   ```

### 5.2 `ShiftService.assignCarerToShift(shiftId, carerId)`

This performs a **two-step write**:

**Step 1 — Verify the shift exists:**
```dart
_client.from('shifts')
  .select('id, carer_id, status')
  .eq('id', shiftId)
  .single();
```

**Step 2 — Update the shift:**
```dart
_client.from('shifts')
  .update({'carer_id': carerId, 'status': 'confirmed'})
  .eq('id', shiftId)
  .select();
```

- Sets `carer_id` to the selected carer.
- Sets `status` to `'confirmed'`.
- Uses `.select()` to return the updated row (so it can verify the update succeeded).
- If the response is empty, throws `'No rows updated - shift may not exist or you do not have permission'`.

### 5.3 Other write methods (defined but not used by this screen)

- `unassignCarerFromShift()` — sets `carer_id = null`, `status = 'scheduled'`.
- `updateShift(Shift)` — generic update via `shift.toJson()`.
- `sendShiftReminder()` — placeholder (no DB write).

---

## 6. The Route Schedule View (secondary)

The screen also has a **Route Schedule** view mode that queries the `public.routes` table (not `shifts`):

```dart
_client.from('routes')
  .select('*, service_users(name), carers(name)')
  .eq('client_organisation_id', clientOrgId)
  .gte('proposed_start_time', dayStart)
  .lte('proposed_start_time', dayEnd)
  .order('proposed_start_time', ascending: true);
```

This is a separate table and is only relevant to the second view mode.

---

## 7. Data Flow Summary

```
┌─────────────────────────────────────────────────────────────┐
│  shift_list_screen.dart (UI)                                │
│  - _load() → getShiftsForDate(date)                         │
│  - _showAssignCarerBottomSheet() → assignCarerToShift()     │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│  shift_service.dart (Data Layer)                            │
│  - getShiftsForDate() → SELECT * FROM shifts                │
│      WHERE scheduled_date = ?                               │
│      [AND client_organisation_id = ?]  (non-admin)          │
│      ORDER BY start_time                                    │
│  - assignCarerToShift() → UPDATE shifts                     │
│      SET carer_id = ?, status = 'confirmed'                 │
│      WHERE id = ?                                           │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│  public.shifts (Supabase/Postgres)                          │
│  - RLS: Admins ALL, Clients SELECT/INSERT, Carers SELECT    │
│  - Triggers: double-booking check, updated_at               │
└─────────────────────────────────────────────────────────────┘
```

---

## 8. Key Observations & Potential Issues

### 8.1 Duplicate Shift model definitions
The admin-app defines its own `Shift` class in `shift_service.dart`, separate from `packages/core/lib/models/shift.dart`. This means:
- The admin `Shift` stores times as **Strings**; the core model stores them as **DateTime**.
- The admin `Shift` has fewer fields (no `shiftType`, `rate`, `recurring`, `broadcastType`, etc.).
- Any change to the core model won't automatically propagate to the admin-app.

### 8.2 RLS relies on `profiles` subqueries
All RLS policies on `shifts` reference the `profiles` table via subqueries. This is fine for `shifts`, but **the same pattern caused infinite recursion on the `profiles` table itself** (fixed in migration 130). The `shifts` policies are safe because they query `profiles` (a different table), not `shifts` recursively.

### 8.3 `organisation_id IS NULL` in carer policy
The `Carers can view assigned shifts` policy includes `OR organisation_id IS NULL`, meaning **any** authenticated user can view shifts with a NULL `organisation_id`. This is a potential data-leak concern for legacy/global shifts.

### 8.4 No explicit UPDATE policy for clients
There is **no** `UPDATE` policy for client users on `shifts`. The `Admins can manage all shifts` policy covers admins, but a client user cannot update a shift (e.g., to change status or assign a carer) — only insert and select. This is by design (clients request shifts; admins/agencies manage them).

### 8.5 The `assignCarerToShift` write path
This method updates `carer_id` and `status='confirmed'`. It relies on the caller being an **admin** (via the `Admins can manage all shifts` RLS policy). If a non-admin client user tried to call it, the RLS would block the update and the `.select()` would return empty, triggering the "No rows updated" error.

---

## 9. Conclusion

The admin-app's shifts screen reads from `public.shifts` via a single service method (`getShiftsForDate`) that:
1. Resolves the user's role/org from `profiles`
2. SELECTs all columns plus two FK joins (`service_users`, `carers`)
3. Filters by `scheduled_date` and (for non-admins) `client_organisation_id`
4. Orders by `start_time`

It writes to `public.shifts` via `assignCarerToShift`, which performs a verified UPDATE setting `carer_id` and `status='confirmed'`.

All access is governed by RLS policies that distinguish **admins** (full access), **clients** (own care home only), and **carers** (assigned shifts only), with a double-booking trigger protecting data integrity.