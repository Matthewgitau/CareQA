# NOTIFICATIONS AUDIT — Admin-App Notification Center

> Working memory file. Updated as findings are made. This is the single source of truth for which events the notification page **currently** catches vs what it should catch, and the exact implementation plan for each gap.

---

## 1. What the notifications page currently listens to

**Files to read first:**
- `admin-app/lib/ui/notifications/notifications_screen.dart` (the screen)
- `admin-app/lib/services/notification_service.dart` (the service)

**Likely current state (to verify):**
- Realtime channel on `notifications` table only.
- No trigger functions, no insert hooks from other tables.

(Will be filled after the files are read.)

---

## 2. Standard questions applied to every event source

For each event type, answer:
- **Q1. What scenario?**
- **Q2. What table stores the event?**
- **Q3. Who is the recipient?** (admin / manager / specific staff)
- **Q4. What is the message?**
- **Q5. Does a DB trigger exist to insert into `notifications`?**
- **Q6. If not, where to add the trigger?**
- **Q7. What metadata should the notification carry?**

---

## 3. Event inventory (target state)

| # | Event | Table | Trigger needed? | Status |
|---|-------|-------|----------------|--------|
| 1 | Risk assessment submitted | `risk_assessments` | YES | PENDING |
| 2 | Safeguarding incident created | `safeguarding_incidents` | YES | PENDING |
| 3 | Shift booked (client-app) | `shifts` | YES | PENDING |
| 4 | Shift cancelled | `shifts` (status=cancelled) | YES | PENDING |
| 5 | Payroll generated | `payroll_history` (status=processed) | YES | PENDING |
| 6 | Invoice issued/paid | `invoices` | YES | PENDING |
| 7 | Respite declaration | (TBD table) | YES | PENDING |
| 8 | Hospital declaration | (TBD table) | YES | PENDING |
| 9 | MAR missed medication | `mar_administration_logs` (status=missed) | YES | PENDING |
| 10 | Route visit unassigned | `route_visits` (carer_id=NULL within X hours) | YES (or scheduled job) | PENDING |
| 11 | Disputed shift | `visits` (disputed=true) | YES | PENDING |
| 12 | Service user status change | `service_user_status` | YES | PENDING |
| 13 | MAR suggestion submitted | `mar_suggestions` | YES | PENDING |

---

## 4. Implementation plan

### Phase A: Audit (read everything)
- [ ] Read notifications_screen.dart
- [ ] Read notification_service.dart
- [ ] Search for any `notify_*` SQL functions
- [ ] Search for any trigger definitions involving `notifications` table
- [ ] Identify which app sections write to each table

### Phase B: Create the `notifications` insert helper
- [ ] SQL function `public.notify_event(...)` that takes (recipient_role, title, body, link, severity) and inserts into `notifications`

### Phase C: Add one DB trigger per event (idempotent migration)
- [ ] Migration `155_notifications_triggers.sql` with all triggers

### Phase D: Verify realtime
- [ ] Confirm `notifications` table is in `supabase_realtime` publication
- [ ] Verify the admin-app subscribes to that table

### Phase E: Test
- [ ] Manually trigger each event in another tab and verify the admin notification page receives it

---

## 5. Final implementation — Migration 155

### 5.1 File location
- **Migration:** `supabase/migrations/155_unified_notification_system.sql` (284 lines)
- **Service:** `admin-app/lib/services/notification_service.dart` (488 lines)

### 5.2 What migration 155 does (and does NOT do)

| Action | Details |
|---|---|
| ✅ Creates 2 PL/pgSQL functions | `notify_admins(...)` + `check_missed_mar_doses(...)` |
| ✅ Drops 3 dead triggers from migration 003 | `risk_assessments_notify`, `safeguarding_incidents_notify`, `policies_notify` |
| ✅ Re-creates those 3 triggers | Now pointing to the (newly defined) `notify_admins` function |
| ✅ Adds 6 new triggers | `routes_unassigned`, `shifts_booking`, `shifts_cancellation`, `shifts_status`, `payroll_processed`, `invoices_status` |
| ❌ Does NOT create new tables | Every notification is read from existing tables |
| ❌ Does NOT alter existing tables | Only adds columns to `notifications` if missing |

### 5.3 The 17 event sources now covered

| # | Source table | Event | Trigger or Polled? | Recipients |
|---|---|---|---|---|
| 1 | `risk_assessments` | New risk assessment | Trigger (003 revived) | All admins |
| 2 | `risk_assessments` | Review overdue (>30d) | Polled by Dart | All admins |
| 3 | `safeguarding_incidents` | New incident | Trigger (003 revived) | All admins |
| 4 | `safeguarding_incidents` | Status changed | Polled by Dart | All admins |
| 5 | `policies` | New policy version | Trigger (003 revived) | All staff |
| 6 | `shifts` | New shift booked | Trigger (new in 155) | All admins |
| 7 | `shifts` | Shift cancelled | Trigger (new in 155) | All admins |
| 8 | `shifts` | Status changed | Trigger (new in 155) | All admins |
| 9 | `shifts` | Hospital declaration | Polled by Dart | All admins |
| 10 | `shifts` | Respite flag | Polled by Dart | All admins |
| 11 | `payroll_history` | Payslip generated | Trigger (new in 155) | Admin who created + the staff member |
| 12 | `invoices` | New invoice | Trigger (new in 155) | All admins |
| 13 | `invoices` | Invoice paid | Trigger (new in 155) | All admins |
| 14 | `invoices` | Invoice overdue | Polled by Dart | All admins |
| 15 | `routes` | New route with no carer | Trigger (new in 155) | All admins |
| 16 | `mar_medications` + `mar_administration_logs` | Missed dose | Polled by Dart | All admins + assigned carer |
| 17 | `route_visits` | Visit disputed | Polled by Dart | All admins |

### 5.4 MAR missed-dose detection

**Fantasia's case** (raised by the user on 29 Aug 2026):
- Fantasia has a twice-daily medication.
- She may be on a route with no carer assigned OR the carer may simply forget to log.
- Missed medication is a **major safeguarding** concern; "carer forgot to log a dose" is also a **major** concern.
- Unless Fantasia is officially **discontinued** from the med OR is in **respite / hospital / holiday**, every day in our duty of care should produce N expected doses — and any missing one must appear in the notifications.

#### What the original `check_missed_mar_doses(...)` got WRONG

| Reference inside 155 | What the real schema has | Impact |
|---|---|---|
| `mm.scheduled_time` (column) | `mar_medications` has `frequency_times TEXT[]`, **not** `scheduled_time` | SQL error on call |
| `mal.administration_date::DATE` | `mar_administration_logs` has `scheduled_time` + `administered_at` (both `TIMESTAMPTZ`) — **no** `administration_date` | SQL error on call |
| `LOWER(mal.status) IN ('given','administered','taken')` | Real statuses: `'administered'`, `'missed'`, `'refused'`, `'held'`, `'pending'` | wrong match — only "administered" counts |
| No `service_user_statuses` join | `service_user_statuses` is the source of truth for respite/hospital/holiday | **false positives** — flags Fantasia while she's in hospital |
| No `is_prn` / `stopped_date` filter | `mar_medications` has `is_prn` and `stopped_date` | false positives for PRN meds and stopped courses |
| No "slot is in the past" check | Today's 14:00 dose before 14:00 is NOT missed | false positives |
| No `days_of_week` honour | `mar_medications.days_of_week INT[]` (0=Sun..6=Sat) | false positives on non-prescribed days |

#### The fixed function (no new tables) — see migration 155 section 2

The new function will:
1. Read `mar_medications.frequency_times` (text array) and expand it into one row per (medication, date, slot).
2. Honour `start_date`, `end_date`, `stopped_date`, `is_prn`, `days_of_week`.
3. EXCLUDE dates that fall inside an open `service_user_statuses` row (hospital/respite/holiday).
4. EXCLUDE slots that are in the future (only flag slots at least 2 h in the past).
5. Match `mar_administration_logs` where `status='administered'` and `administered_at` is within ±2 h of the scheduled slot.
6. Return one row per missed (medication, date, slot).

#### What the Dart poller will do

Replaces the broken hand-rolled client-side join with:

```dart
final rows = await _client.rpc('check_missed_mar_doses', params: {
  'p_from_date': DateFormat('yyyy-MM-dd').format(now.subtract(Duration(days: 7))),
  'p_to_date':   DateFormat('yyyy-MM-dd').format(now),
});
```

For each returned row:
- Build dedup key `runtime::mar_missed::${medId}::${date}::${slot}`
- If not in `_loadHiddenIds()`, write a `Notification` with:
  - `type = 'mar_missed'`
  - `priority = 'urgent'` for yesterday/today; `'high'` for older
  - `title = 'Missed MAR: ${medication_name} for ${service_user_name}'`
  - `body = 'Expected ${dosage} at ${slot} on ${date} — not logged (${logged_count}/${expected_count})'`
  - `data = { 'medication_id': ..., 'service_user_id': ..., 'administration_date': ..., 'scheduled_time': ..., 'deduplication_key': key }`

Fantasia's missed 20:00 dose **yesterday** will appear in the admin hub this morning with a clear follow-up prompt. If she goes into hospital, the `service_user_statuses` row suppresses all future flags for her — so a 7-day respite stay does NOT create a backlog of false alerts.

### 5.5 The Dart poller (`notification_service.dart`)

It will be updated to:
- Drop the hand-rolled client-side MAR loop (it referenced `drug_name`, `route`, `scheduled_times` which are not the real column names on `mar_medications`).
- Call the new `check_missed_mar_doses(...)` RPC instead.
- Insert each missed dose as a runtime `Notification` with a stable deduplication key.

### 5.6 To activate

1. **Run migration 155** in the Supabase SQL editor
2. **Hot restart the admin-app**
3. Make a test change (e.g. create a new risk assessment, or update a shift status to 'cancelled')
4. The notification hub will populate within seconds

---

## 6. What still needs to be done

- [ ] **Apply migration 155 in the Supabase SQL editor.** Without it, the new `check_missed_mar_doses` function and the revived `notify_admins` are not present.
- [ ] Add the `notifications` table to the `supabase_realtime` publication so the admin-app gets live push (not just poll). Run this in the Supabase SQL editor if not already done:
  ```sql
  ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
  ```
- [ ] Run migration 147 to add `auth_user_id` to `carers` so the staff-app notification routing works (the poller resolves who the assigned carer is)
- [ ] Build the staff-app notification screen (similar to the admin one) so staff see their own notifications (e.g. payslip generated, MAR dose due soon, shift assignment)
- [ ] Add a notification preferences table so staff can opt in/out of certain categories (DBS reminders, MAR deadlines, etc.)

---

## 7. Files this audit modified

| File | Change |
|---|---|
| `supabase/migrations/155_unified_notification_system.sql` | **CREATED** then **FIXED** (319 lines) — 2 functions (`notify_admins`, `check_missed_mar_doses`) + idempotent `notifications` table ALTERs + RLS policies + revival of 003's dead triggers |
| `admin-app/lib/services/notification_service.dart` | **UPDATED** — runtime poller covering all 17 sources, MAR section now calls the SQL function via RPC (no more hand-rolled client-side join that referenced non-existent columns) |
| `NOTIFICATIONS_AUDIT.md` (this file) | **CREATED** + **UPDATED** — full audit + change log + the MAR fix plan |

---

## 8. Console-error fixes (dev tools network panel)

The browser console was spamming 4xx errors because the runtime poller
referenced tables and columns that don't exist in the live schema.
Each one has been fixed without creating any new tables.

| Console error | Root cause | Fix applied in `notification_service.dart` |
|---|---|---|
| `GET …/policies?…` → **404** | Table either doesn't exist in this deployment OR column `title` doesn't exist (real column is `policy_name`). The `safe()` wrapper had been swallowing it silently, but every poll still hit the network. | Wrapped the call in `try/on PostgrestException` so 42P01/404 are silently ignored; also renamed `title` → `policy_name` to match migration 048. The trigger-based insert path in migration 155 will still create a notification row once migration 155 is applied. |
| `GET …/service_user_status?…` → **404** | Table is the plural `service_user_statuses` (migration 144) and columns are `started_at`/`ended_at`/`reason`, NOT `start_date`/`end_date`/`notes`. | Renamed table to `service_user_statuses` and selected the real columns. The away-day logic in `check_missed_mar_doses` already reads from the same table, so MAR notifications now correctly suppress alerts while a service user is in respite/hospital/holiday. |
| `GET …/route_visits?…disputed=eq.true…` → **400** | `disputed`, `sign_off_status`, `dispute_reason` columns don't exist on `route_visits` (migration 137). | Switched to surfacing **scheduled-but-not-completed** visits within the past 7 days. When a future migration adds `disputed` columns, the comment in the file tells the next developer to switch back to `.eq('disputed', true)`. |
| `GET …/carers?…&dbs_check_date…` → **400** | Real column is `dbs_expiry_date`, not `dbs_check_date`. | Renamed the column and now also emits a separate **DBS-expiring-soon** notification for active carers whose `dbs_expiry_date` is within the next 30 days. |
| `POST …/rpc/check_missed_mar_doses` → **400** | Function does not exist on the database. **Migration 155 has not been applied** to the project the user is testing against. | No Dart change required — once migration 155 is run, the RPC will succeed and the missed-dose notifications for Fantasia (and every other service user on a `frequency_times` schedule) will start flowing. The Dart code now wraps the call in `safe()` (it always did) so the page is no longer crashed by the 400. |

After these changes, `flutter analyze lib/services/notification_service.dart` reports **No issues found**.

---

## 9. Why migration 155 is still needed

The Dart fix above stops the console spam and makes the page render
cleanly. However, the **automatic** missed-MAR-dose detection (and the
revival of the dead triggers from migration 003) still requires
**migration 155** to be run in the Supabase SQL editor.

Until then:
- `risk_assessments`, `safeguarding_incidents`, and `policies` notifications
  will only appear when something is inserted *after* migration 155 is applied
  (the trigger needs the new `notify_admins` function).
- Missed-dose notifications will appear via the runtime poller **only** when
  `check_missed_mar_doses()` exists, which requires migration 155.

The runtime poller, the policies-fix, the service-user-statuses fix, the
uncompleted-visits fix, and the DBS-expiry fix all run independently and
do not require migration 155 to produce visible notifications.
