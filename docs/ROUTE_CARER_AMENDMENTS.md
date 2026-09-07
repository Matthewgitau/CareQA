# ROUTE / CARER AMENDMENTS — LIVING TRACKER

> Purpose: a single checklist the developer follows and the user can verify against,
> so nothing is forgotten or hallucinated. Each row is grounded in the **real** code
> (file + method + line). Update status as work proceeds.
>
> Legend: ✅ DONE · 🟡 PARTIAL/EXISTS · 🔲 NEW/MISSING · ❓ DECISION NEEDED

Last updated: 2026-08-20

---

## 0. User request (restated for verification)

1. Have a **place to see the routes** and **edit the carers assigned day by day** on existing routes.
2. **Edit the calls** (`service_user_calls`) **on existing routes**.
3. **Temporary one-off shift** of a single visit to another carer (carer running late, another finished
   early) — a **one-time** reassignment so hours **and mileage** tracking stay accurate.
4. Make the **service-user time cards on the Dom Care rota screen clickable/editable** (one-off **or** permanent).

---

## 1. Ground truth — the two screens & their services

| Screen | File | Data source | Key methods (verified) |
|--------|------|-------------|------------------------|
| **Route Schedule** | `admin-app/lib/ui/shift/shift_list_screen.dart` | `routes`, `route_visits`, joined `service_users`/`carers` | `_buildRouteList`, `_buildRouteGroup`, `_assignCarerToRouteCluster`, `_toggleRouteDriver`, `_assignCarerToVisit`, `_showEditVisitTime`, `_cancelVisit`, `_showSplitVisit`, `_mergeRoutes`, `_showChangeHistory`, `_openAddRoute` |
| **Dom Care Routes** (tab) | `admin-app/lib/ui/shift_rota/shift_rota_screen.dart` | `service_user_calls` (+ joined `service_users`) | `_buildDomCareCard`, `_toggleFlag` |
| Service (routes) | `admin-app/lib/services/route_service.dart` | | `getRoutesForDate`, `getRouteVisitsForDate`, `assignCarerToRouteCluster`, `setRouteDriverFlag`, `assignCarerToVisit`, `updateVisitTime`, `moveVisitToRoute`, `renameRoute`, `createRouteWithVisits`, `splitVisitToNewRoute`, `getChangeLog`, `getCarers`, `getServiceUsersWithCalls` |
| Service (dom care) | `admin-app/lib/services/shift_rota_service.dart` | | `getDomCareRoutes` (line 304), `toggleServiceUserCallFlag` (line 335) |
| Model | `admin-app/lib/models/service_user_call.dart` | | `ServiceUserCall` `callTimes`, `callsPerDay`, `isNonBillable` |

---

## 2. Change 1 — Routes viewer + edit carers day by day

**Status: 🟡 PARTIAL — the engine exists, the UI/discoverability is the gap.**

Evidence (exists today):
- `shift_list_screen.dart` `_assignCarerToRouteCluster(route, carerId)` → `route_service.assignCarerToRouteCluster` = assign/clear the carer for that **route/day**.
- `_toggleRouteDriver(route, isDriver)` → `setRouteDriverFlag`.
- `_assignCarerToVisit(visit, carerId)` → `assignCarerToVisit` = assign/clear the carer on a **single visit**.
- `_showEditVisitTime(visit)` → `updateVisitTime` (time + duration, change-logged).
- `_cancelVisit`, `_showSplitVisit`, `_mergeRoutes`, `_showChangeHistory`.

Does this genuinely cover **#3 (one-off reassignment)**? Yes at the data layer: `assignCarerToVisit`
writes `route_visits.carer_id` and logs `carer_assigned` with **old → new** in `route_change_log`, so a
visit-level override is already a "temporary" change distinct from the route-level carer.

Gaps to close:
- 🔲 **Navigation/discoverability** — confirm how the user reaches the Route Schedule (View Mode 1). If it's
  not obvious/not bookmarked, surface it clearly (e.g., a "Routes" entry from the rota screen).
- 🔲 **No Delete Route** in the UI → routes can never be removed (this caused the orphan/duplicate we
  fixed in 141/142). Add a delete action.
- ❓ Should the visit-level carer override be *visually flagged* ("override", showing original carer + who
  they're covering), and support **revert** from the change log?
---

## 3. Change 2 — Edit the calls (`service_user_calls`) on existing routes

**Status: 🔲 MISSING.**

- There is **no** `updateServiceUserCall(...)` in `shift_rota_service.dart` (only `getDomCareRoutes` and
  `toggleServiceUserCallFlag`).
- `route_form_screen.dart` reads call times via `getServiceUsersWithCalls` but nothing edits them after creation.

Work:
- 🔲 Add `ShiftRotaService.updateServiceUserCall(String callId, {int? callsPerDay, List<String>? callTimes, ...})`
  that writes `calls_per_day` and `call_times` (stored as JSON string, see `ServiceUserCall.fromJson` lines 47–70).
- 🔲 UI to edit call times/count **from the route screen** (on an existing route) and/or from the Dom Care card.
- ❓ Semantics: does "edit the calls on existing routes" mean editing **this day's visits** (route_visits) or the
  **recurring plan** (service_user_calls)? Both are legitimate; decide.

---

## 4. Change 3 — Temporary one-off visit reassignment (hours + mileage accurate)

**Status: 🟡 PARTIAL** (`assignCarerToVisit` + change log already do it). Make it usable & auditable.

Work:
- 🔲 UI affordance that clearly distinguishes **temporary (this single visit)** vs **permanent (the route for the day)**.
- 🔲 Capture **reason** (e.g., "carer running late") for the change log.
- ❓ **Mileage attribution:** today the log stores carer change but there is no field on `route_visits` to say
  this visit was covered by X (for mileage reporting). Options:
  - (a) keep it in `route_change_log` (no schema change), or
  - (b) add a migration: `route_visits.carer_override_id UUID REFERENCES carers(id)`, plus keep `carer_id` as the
    actual assigned carer — enables direct reporting.
- 🔲 Revert action: from `getVisitChangeHistory(visitId)`, restore the previous `carer_id`.

---

## 5. Change 4 — Dom Care time cards clickable/editable

**Status: 🔲 MISSING** (time chips are static).

- `_buildDomCareCard` (`shift_rota_screen.dart` lines 380–396) renders each `call.callTimes` entry as a plain
  `Container` — **not tappable**.
- Toggles (Respite/Hospital/Holiday) are already interactive via `_toggleFlag` → `toggleServiceUserCallFlag`.

Work:
- 🔲 Wrap the time chips in `InkWell`/`GestureDetector` → open an editor dialog.
- 🔲 Editor accepts: edit existing times, add/remove a time, change `calls_per_day`, and a **one-off vs permanent**
  switch:
  - **permanent** → update `service_user_calls` (recurring plan).
  - **one-off (that day)** → update that day's `route_visits.visit_time`(s) instead.
- 🔲 Wire to new `updateServiceUserCall` + existing `updateVisitTime`, then `_load()`.

---

## 6. Ordered build plan

1. **Service layer first** (no UI risk):
   - Add `updateServiceUserCall(...)` to `shift_rota_service.dart`.
   - Add `assignCarerToVisitWithReason(...)` (or extend existing) + `revertVisitCarer(...)` to `route_service.dart` (optional, if reason/mileage needed).
2. **Dom Care time cards editable** (`shift_rota_screen.dart` + new edit dialog) — Change 4, depends on (1a).
3. **Edit calls from the Routes screen** — Change 2 surface.
4. **Routes screen polish** — prominent day-by-day carer editor + temporary-override display + **Delete Route** (Change 1/3).
5. **Optional migration 143** — cascade-delete FKs (from the orphan fix) + (if mileage attribution chosen) `carer_override_id`.
6. **Verify**: `flutter analyze` clean; manual repro of each item; run 141/142 confirm SQL from audit doc.

## 7. Verification checklist (user signs off each)

- [ ] Can reach the Routes viewer and see all routes for a chosen day.
- [ ] Can change a route's carer for the day, and each visit's carer, and it appears in Change History.
- [ ] Can edit call times / call count from a route AND from the Dom Care card; one-off only affects the day, permanent updates the plan.
- [ ] One-off reassignment records original carer, replacement, and reason; shows as an override; can be reverted.
- [ ] Delete Route removes route + its visits (no orphaned `route_visits`).

---

## 8. Service-user "away" status (respite/hospital/holiday) + body-map on return

**User requirement (restated):**
1. The **Route Schedule** must reflect when a service user is away (respite / holiday / hospital).
2. The three states must be **mutually exclusive** — picking one overrides the others (one-of-three, not three independent toggles).
3. **Time-sensitive, not whole-day:** when a call time arrives while the user is away, that call is **recorded as** the status (respite/hospital/holiday) and stays so **until the user is back**.
4. On return, an **admin body-map assessment prompt** must appear so staff document a skin check ("not there before / there after") — liability protection.

**Current state (verified in code):**
- `service_user_calls.respite / hospital / holiday` are **3 independent booleans** (no mutual exclusion), with **no timestamps**.
- They only appear on the **Dom Care rota** screen; the Route Schedule (`shift_list_screen` View Mode 1) does **not** read them.
- `route_visits.respite` is a separate, isolated boolean (visit-level override) — unrelated to `service_user_calls`.
- `service_user_call_log` (migration 143) now audits flag flips — good base, but no start/end window and no body-map hook.
- **No body-map / skin-assessment module exists** (only mentions of "body maps" inside `005_careplan_audit_items.sql` as checklist strings).

**Proposed target model (DECISION NEEDED — see questions):**
- A single current status per service user: `none | respite | hospital | holiday` (mutually exclusive).
- `started_at` when flagged; `ended_at` when marked back (the "away" window).
- Route Schedule annotates each affected call-time/visit with the active status (+ optional free-text reason).
- Return (flag cleared / `ended_at` set) triggers a body-map skin-check prompt (NEW module).

**Open decisions:**
- ~~Temporal model~~ → **DECIDED: status window** (one mutually-exclusive current status, `started_at`/`ended_at`, call-times derived from the window).
- Body-map scope: **implemented as simple record** ("no new marks" + notes). A full body-diagram UI can be added later.
- Free-text reason: `reason` column exists on `service_user_statuses`; **not yet surfaced** in the UI.

**Implemented (2026-08-20):**
- `supabase/migrations/144_service_user_status_and_body_map.sql` — `service_user_statuses` (partial-unique "one open period" per user) + `body_map_assessments`, both RLS-protected.
- `shift_rota_service.dart` — `setServiceUserStatus`, `markServiceUserBack`, `getActiveStatuses`, `saveBodyMapAssessment`, plus helpers (close open period, sync `service_user_calls` flags).
- `shift_rota_screen.dart` — replaced the three independent toggles with a **single-select** status chip group (Active/Respite/Hospital/Holiday), a **Mark back** action, and a **body-map prompt** on return.
- `shift_list_screen.dart` — Route Schedule now annotates each visit with the active away status (⛔ Hospital/Respite/Holiday (away)).

**Remaining:**
- Show the "reason" field in the UI when flagging.
- (Optional) full body-diagram body-map, and surfacing body-map history.

---

## 9. Recurring routes (permanent weekly schedule)

**Model (chosen by user):**
- Each **service user** has a **global weekly timetable** (per weekday → list of call times).
- A **route** is a **permanent group of service users** and just applies each member's timetable.
- Routes are **continuous by default** (recurring 7 days a week), with an optional start date; indefinite unless deleted or a member is removed.
- Per-weekday customisation: e.g. 2 calls Monday, 4 calls Tuesday.

**Layer 1 — DONE (non-breaking):**
- `supabase/migrations/145_recurring_weekly_timetable.sql`
  - `service_user_weekly_calls` (service_user_id, weekday 1..7, call_times JSONB)
  - `route_service_users` (route_id ↔ service_user_id)
  - `routes.is_recurring / starts_on / ends_on`
- `shift_rota_service.dart`: `getServiceUserWeeklyCalls`, `saveServiceUserWeeklyCalls`, `addServiceUserToRoute`, `removeServiceUserFromRoute`.

**Layer 2 — DONE (recurring carry-forward):**
- `persistRouteMembers` — writes each route's service-user membership to `route_service_users` (called on create + update).
- `getGeneratedVisitsForDate` — derives any day's visits from recurring membership × weekly timetable × route carer; merged into the Route Schedule, deduped against stored visits.
- Carer: assigned route carer flows to generated visits; the route-level cascade (`assignCarerToRouteCluster`) already covers non-overridden visits.

**Remaining / future:**
- Full body-diagram body-map; surfacing body-map history.
- Reason prompt on status flag.
- Delete Route UI action.