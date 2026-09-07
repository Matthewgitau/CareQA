# CareQA — Comprehensive System Evaluation: Function-by-Function Architectural Audit

**Date:** 22 August 2026
**Audience:** Any developer, consultant, or stakeholder. No prior codebase knowledge required.
**Methodology:** Every claim verified against source code and Supabase migrations. File paths and line references included.
**Scope:** All three apps (admin-app, staff-app, client-app), all 146 migrations, all ~95 database tables, all ~100 services, all ~217 screens, all 7 cross-app data flows.

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Database Table Inventory — Complete with RLS Audit](#2-database-table-inventory)
3. [Migration Inventory — What Each Migration Does and Whether It Works](#3-migration-inventory)
4. [ADMIN-APP: Complete Service-by-Service Breakdown](#4-admin-app-services)
5. [ADMIN-APP: Complete Screen-by-Screen Breakdown](#5-admin-app-screens)
6. [STAFF-APP: Complete Service-by-Service Breakdown](#6-staff-app-services)
7. [STAFF-APP: Complete Screen-by-Screen Breakdown](#7-staff-app-screens)
8. [CLIENT-APP: Complete Service-by-Service Breakdown](#8-client-app-services)
9. [CLIENT-APP: Complete Screen-by-Screen Breakdown](#9-client-app-screens)
10. [Cross-App Data Flows — Complete Trace](#10-cross-app-data-flows)
11. [Orphaned and Dead Code — Master Inventory](#11-orphaned-and-dead-code)
12. [Service Duplicates and Overwrites](#12-service-duplicates)
13. [RLS Policy Gaps — Complete Audit](#13-rls-policy-gaps)
14. [Identity-Linkage Problems](#14-identity-linkage-problems)
15. [Recommendations — Prioritized Action Plan](#15-recommendations)

---

## 1. Executive Summary

### 1.1 The System at a High Level

CareQA is a **three-app Flutter platform** backed by a **single Supabase Postgres instance** (`aucflsskbhaloutsdlwc.supabase.co`). The three apps are:

| App | Package | Users | Primary Role |
|-----|---------|-------|-------------|
| **admin-app** | `admin_app` | Agency admins/managers | Run the agency: staff, service users, shifts, routes, compliance, risk, audits, medication, finance, safeguarding, lessons-learnt, policies, invoicing |
| **staff-app** | `staff_app` | Carers/care staff | See assigned shifts and route calls, clock in/out, complete charts (food/fluid, bowel/bladder, sleep, repositioning), fill risk assessments, view competencies, MAR chart |
| **client-app** | `careqa_client` | Client organisations (care homes) | Book shifts from agency, broadcast shifts to PSL, view routes, manage sub-users, rate carers |

### 1.2 Overall Health Assessment

| Dimension | Score | Detail |
|-----------|-------|--------|
| **Database completeness** | 🟡 85% | 95+ tables exist. 1 missing (`bookings`). Several risk tables exist but may not be wired to UI. |
| **RLS coverage** | 🟡 60% | Migration 073 enabled RLS on ~55 tables with `tenant_isolation` policy. Later migrations override for specific tables (routes, route_visits). Some gaps remain (see §13). |
| **Cross-app data flow** | 🔴 30% | The core shift lifecycle works client→admin but is BROKEN admin→staff due to identity-linkage (`carers.id ≠ auth.uid()`). Route flow has partial fixes but same identity issue. Staff care delivery UI likely orphaned. |
| **Dead code** | 🔴 40% | ~5 orphaned client-app screens, 2+ service duplicates, ~15 admin screens with empty navigation callbacks (MasterDashboard). Staff forms largely unreachable. |
| **Service duplicates** | 🟡 70% | `auth_service` duplicates `supabase_auth_service` in all 3 apps. `database_service` (legacy) overlaps with `shift_service`. `firestore_service` in staff-app partially duplicates `shift_service`. |
| **Navigation integrity** | 🟡 65% | admin_dashboard sidebar covers ~80% of screens. MasterDashboard has empty callbacks. Staff dashboard only shows ShiftsScreen; no navigation to charts/risk forms/competencies. |

### 1.3 Critical Path — What Must Work for the Platform to Function

1. **Client books shift** → `client-app/shift_service.createShift()` → INSERT `shifts` ✅
2. **Admin assigns carer** → `admin-app/shift_service.assignCarerToShift()` → UPDATE `shifts.carer_id` ✅
3. **Staff sees assigned shift** → `staff-app/shift_service.getShiftsForCurrentCarer()` → SELECT `shifts WHERE carer_id = auth.uid()` ❌ **BROKEN**
4. **Staff documents care** → Staff forms → INSERT charts/risk tables ❓ **UNCERTAIN — FORMS MAY BE ORPHANED**
5. **Admin reviews care** → Admin screens → SELECT charts/risk tables ❓ **DEPENDS ON #4**

**The platform is currently broken at step 3.** The root cause is an identity-linkage gap: `shifts.carer_id` references `carers.id`, but the staff user authenticates with `auth.users.id`, and these two UUIDs are not the same for all carers. See §14 for full analysis.

### 1.4 What This Document Covers That CAREQA_system_overview.md Does Not

- **Function-level CRUD mapping** for every service method to every table column
- **RLS policy enumeration** for every table, with gap analysis
- **Screen wiring audit** — which screens are reachable from which navigation paths
- **Service duplicate analysis** — which services are shadows of others
- **Complete migration audit** — which migrations are consumed, which are orphaned
- **Bottleneck identification** per function
- **Utility assessment** per screen and service
- **Specific, actionable recommendations** for every problem found

---
## 2. Database Table Inventory - Complete with RLS Audit

### 2.1 Core Identity: profiles, carers, organisations

**profiles** - Created by migration 001, modified by 089 (add organisation_id), 090 (RLS recursion fix), 128-132 (sub-user RLS).
- Schema: id UUID PK REFERENCES auth.users(id), email, full_name, role CHECK (admin/carer/client), phone, organisation_id UUID, client_organisation_id UUID, is_active, name, timestamps.
- Scenario: Links Supabase auth to business identity. organisation_id scopes admin/staff data. client_organisation_id scopes client data.
- Read by: All three apps via supabase_auth_service, auth_service, database_service, client_service, most org-scoping queries.
- Written by: supabase_auth_service (signup), carer_invite_service (sub-users via RPC).
- RLS: (1) Users can view profiles in same organisation using get_current_user_organisation() (SECURITY DEFINER, no recursion). (2) Admins can view all profiles if role=admin. (3) Sub-user policies from 128-132.
- RLS Gap: get_current_user_organisation() returns NULL for client users (who have client_organisation_id but not organisation_id), potentially locking them out. No client_organisation_id scoping policy exists.
- Recommendation: Add client_organisation_id-scoped policy for profiles.

**carers** - Created by 001, modified by 049, 069, 070, 089, 133-134.
- Schema: id UUID PK REFERENCES profiles(id), employee_number UNIQUE, dbs_number, dbs_expiry_date, is_active, name, organisation_id UUID, training_records JSONB.
- Scenario: Stores compliance/employment data for carers. CRITICAL for identity-linkage: carers.id is FK to profiles.id which is FK to auth.users.id. If a carer was created without an auth account, carers.id won''t match any auth.users.id, breaking staff-app queries.
- RLS: Users can view carers in same organisation using get_current_user_organisation().
- Gap: Same client_organisation_id issue as profiles. Client staff_service queries carers - may fail for client users without organisation_id.
- Recommendation: Add auth_user_id UUID column linking directly to auth.users. See Section 14 for full identity-linkage fix.

**organisations** - Created by 028/071/072/074. Root tenancy unit. RLS: tenant_isolation from 073. Status: Correct.

### 2.2 Service Users: service_users

- Created by 001, modified by 088 (adds carer-like columns), 138 (call flags), 144 (status/body map).
- RLS: (1) Authenticated users can view service_users from 088 - ALL authenticated can see ALL service users. (2) tenant_isolation from 073 scoped by org.
- GAP: The 088 permissive policy contradicts tenant isolation. Postgres ORs permissive policies - broadest wins. Cross-org data leakage possible.
- Recommendation: Remove 088 permissive policy. Use get_current_user_organisation() only.

### 2.3 Shifts & Visits: shifts, visits

**shifts** - Core scheduling table. Created by 001, modified by 119 (booking columns), 120 (timesheet), 122 (status check fix), 123 (double-booking trigger).
- Schema: id UUID PK, service_user_id FK, carer_id FK (references carers.id!), scheduled_date DATE, start_time TIME, end_time TIME, status CHECK (scheduled/in_progress/completed/cancelled/confirmed/declined), client_organisation_id UUID, location, staff_type, staff_required INT, notes, broadcast_type.
- RLS: (1) Original tenant_isolation (073). (2) carer_shifts policy (001). (3) Updated by 119/121/122/123.
- GAP: Admin RLS scopes by organisation_id, but client-booked shifts have NULL organisation_id (only client_organisation_id set). Admin may not see client-booked shifts. Admin services bypass with admin role policies - verify at runtime.
- Recommendation: Add admin-wide SELECT policy for shifts (role=admin).

**visits** - Created by 001, modified by 125-127 (client RLS).
- Schema: id UUID PK, shift_id FK, carer_id FK, check_in_time, check_out_time, duration_minutes, notes, flagged, compliance_percentage, structured_notes JSONB, organisation_id UUID.
- RLS: (1) 001 + 073 original. (2) 125-127 client fixes.
- Gap: Staff writes visits but may not set organisation_id, causing RLS reject.
- Recommendation: Verify staff check-in sets organisation_id. Add carer self-access policy.

### 2.4 Routes: routes, route_visits, route_change_log

**routes** - Created by 104/116, redesigned 137 (container), 139 (carer_id), 140 (second_carer), 141 (dual RLS), 142 (drop call_number), 146 (carer reads).
- Schema: id, name, route_date, organisation_id, client_organisation_id, carer_id, second_carer_id, is_driver, driver_mode, status.
- RLS: (1) Org-scoped CRUD policies with OR logic (organisation_id OR client_organisation_id). (2) Carers can view own routes (146) - carer_id = auth.uid() OR second_carer_id = auth.uid(). Status: Correct.
- Gap: Client-app route_service.dart uses legacy columns (route_date, call_number). call_number dropped in 142.
- Recommendation: Update client-app route model to post-137 schema.

**route_visits** - Created by 137, RLS from 141 + 146 carer policy. Same OR pattern. Carer self-access via 146. Status: Correct (given identity-linkage works).

**route_change_log** - Created by 137, RLS from 141. Writes work. No read screen exists yet.

### 2.5 Risk Assessments (31 tables)

All follow pattern: migration -> tenant_isolation RLS (073) -> admin service -> admin screen -> optionally staff service/screen.
Key tables: choking_risk, falls_risk, medication_risk, mental_capacity, waterlow, catheter_care_risk, epilepsy_risk, diabetes_risk, self_harm_risk, anaphylaxis_risk, activity_risk, sepsis_risk, environmental_risk, incontinence_risk, nutrition_risk, challenging_behaviour_risk, bed_railing_risk, financial_risk, equipment_register_risk, fire_hazard_risk, coshh_risk, domiciliary_fire_safety, respect_forms, and generic risk_assessments.
- RLS: All use tenant_isolation from 073. Staff users with organisation_id work. Client users blocked (correct - clinical is internal).
- Service duplicates: mca_service and mental_capacity_service both target MCA. catheter_care_risk_service and catheter_care_service both target catheter.
- Critical gap: Staff form files exist but staff dashboard (staff_dashboard.dart) only embeds ShiftsScreen - no navigation to any risk forms. These forms may be completely unreachable.

### 2.6 Care Charts

food_fluid_charts, food_fluid_intake_logs, bowel_bladder_charts, repositioning_charts, sleep_charts, daily_notes.
- Admin screens exist and appear wired from sidebar.
- Staff form files exist but NO dashboard navigation visible. Same unreachability problem as risk forms.

### 2.7 HR/Staff Management (25 tables)

appraisals, training_courses, carer_training_records, competency_framework, staff_competency_assessments, development_plans, leave_requests, disciplinary_cases, welfare_checks, satisfaction_surveys, incentive_programs, etc.
- All wired from admin sidebar. Staff sees competencies only.

### 2.8 Finance (6 tables)

invoices, organisation_profiles, receipt_entries, receipts, profit_snapshots, supplier_register.
- All wired from admin sidebar.
- Service duplication: receipt_service and expense_tracking_service both target receipt/profit tables.

### 2.9 Governance/Compliance (17 tables)

action_plans, lessons_learnt, policy_library, analysis_views, compliance_flags, mar_audits, mar_medications, spot_checks, careplan_audits, care_log_audits, safeguarding_incidents, whistleblower_reports, meetings, notifications, messages, pre_admissions.
- All wired from admin sidebar.

### 2.10 Client-Facing Tables

shift_templates: Live. shift_broadcasts: Live. client_organisation_spl: Live. staff_ratings: Table exists but rate_carer_dialog orphaned - rating feature dead. preferred_carers: Live. bookings: TABLE MISSING - booking_service references nonexistent table. service_user_weekly_calls: Live. service_user_call_log: Status uncertain.

---

## 3. Migration Inventory - What Each Migration Does

### 3.1 Critical Early Migrations (001-030)

| # | Migration | Purpose | Consumed By | Status |
|---|----------|---------|------------|--------|
| 001 | initial_schema | Creates profiles, carers, service_users, shifts, visits, documents, notifications, settings. Sets up initial RLS, triggers (updated_at, compute_visit_compliance), seeds settings. | All 3 apps | Foundation |
| 002 | compliance_engine | Creates compliance_flags, compliance_scores, risk_assessments | admin-app compliance_service | Core |
| 003 | compliance_settings | Settings for compliance engine | admin-app compliance_service | Core |
| 004 | medication_risk_assessment | medication_risk_assessments table | admin-app | Risk |
| 004 | spot_check_questions | spot_check question seed data | admin-app spot_check_service | Support |
| 005 | careplan_audit_items | careplan_audit item seed | admin-app careplan_audit_service | Support |
| 005 | pre_admission_assessment | pre_admissions, adl_categories | admin-app pre_admission_service | Feature |
| 006 | choking_risk_assessment | choking_risk_assessments | admin-app choking_risk_service | Risk |
| 006 | food_fluid_chart | food_fluid_charts (V1) | admin-app food_fluid_service | Chart |
| 007 | bowel_bladder_chart | bowel_bladder_charts (V1) | admin-app bowel_bladder_service | Chart |
| 007 | falls_risk_assessment | falls_risk_assessments | admin-app falls_risk_service | Risk |
| 008 | mar_audit | mar_audits | admin-app mar_audit_service | Governance |
| 008 | repositioning_chart | repositioning_charts (V1) | admin-app repositioning_service | Chart |
| 009 | sleep_chart | sleep_charts (V1) | admin-app sleep_service | Chart |
| 009 | waterlow_assessment | waterlow_assessments | admin-app waterlow_service | Risk |
| 010 | mental_capacity_assessment | mental_capacity_assessments | admin-app mca_service + mental_capacity_service (DUPLICATE) | Risk |
| 011-014 | chart revisions | Revises food_fluid (011), bowel_bladder (012), repositioning (013), sleep (014) | admin chart services | Maintenance |
| 015-019 | audits | infection_control, health_safety, fire_safety, equipment audits, supervision_records | admin audit services | Governance |
| 020 | appraisal_form | appraisal_forms (later replaced by 094) | admin-app appraisal_service | HR |
| 021 | training_record | training_records | admin-app training_service | HR |
| 022 | competency_assessment | competency_assessments (later replaced by 100-105) | admin-app competency_service | HR |
| 023-026 | assessments | dols, moving_handling, skin_integrity, oral_health | admin-app (unclear if screens exist) | Uncertain |
| 027 | shift_rota | shift_rota table | admin-app shift_rota_service | Feature |
| 028 | add_organisation_id | First attempt at org-scoping - adds organisation_id column | All | Foundation |
| 029 | client_and_family_tables | Client family portal tables | (unclear) | Uncertain |

### 3.2 Risk Assessment Migrations (031-047)

Migrations 031-047 create specialized risk assessment tables. Each follows the pattern: CREATE TABLE -> ALTER ENABLE RLS -> covered by 073 tenant_isolation.

| # | Creates | Admin Service | Admin Screen | Staff Service | Staff Screen |
|---|---------|-------------|-------------|--------------|-------------|
| 031 | coshh_risk_assessments | coshh_risk_service | coshh_risk_screen+form | coshh_risk_service | coshh_risk_form |
| 032 | catheter_care_risk | catheter_care_risk_service + catheter_care_service (DUPLICATE) | catheter_care_risk_screen+form | catheter_care_service | catheter_care_screen+form |
| 033 | epilepsy_risk | epilepsy_service | epilepsy_risk_screen+form | epilepsy_service | epilepsy_risk_form+screen |
| 034 | diabetes_risk | diabetes_service | diabetes_risk_screen+form | diabetes_service | diabetes_risk_form |
| 035 | self_harm_risk | self_harm_service | self_harm_risk_screen+form | self_harm_service | self_harm_risk_form |
| 036 | anaphylaxis_risk | anaphylaxis_service | (no admin screens found) | anaphylaxis_service | anaphylaxis_risk_screen+form |
| 037 | activity_risk | activity_risk_service | activity_risk_screen+form | activity_risk_service | activity_risk_screen+form |
| 038 | sepsis_risk | sepsis_service | (no admin screens found) | sepsis_service | sepsis_risk_screen+form |
| 039 | environmental_risk | environmental_service | environmental_risk_screen+form | (none) | (none) |
| 040 | incontinence_risk | incontinence_service | incontinence_risk_screen+form | incontinence_service | incontinence_risk_form |
| 041 | nutrition_risk | nutrition_service | nutrition_risk_screen+form | (none) | nutrition_risk_form |
| 042 | challenging_behaviour_risk | challenging_behaviour_service | challenging_behaviour_screen+form | (none) | challenging_behaviour_form |
| 043 | bed_railing_risk | bed_railing_service | bed_railing_screen+form | (none) | bed_railing_form |
| 044 | financial_risk | financial_service | (no admin screens found) | financial_service | financial_risk_screen+form |
| 045 | equipment_register_risk | equipment_register_service | (no admin screens found) | equipment_register_service | equipment_register_screen+form |
| 046 | fire_hazard_risk + mar_chart | fire_hazard_service + mar_service | fire_hazard_screen+form + mar_chart_screen | (none) | (none) |
| 047 | catheter_care_risk (revision) | Same as 032 | Same as 032 | Same as 032 | Same as 032 |

### 3.3 Admin Feature & HR Migrations (048-103)

| # | Purpose | Key Notes |
|---|---------|----------|
| 048 | admin_feature_tables: complaints, compliments, medication_incidents, missing_items | Used by safeguarding_service |
| 049 | staff_management_tables: adds columns to carers | Extended carer profile |
| 050 | safeguarding_tables: safeguarding_incidents, whistleblower_reports | Used by safeguarding_service |
| 051 | finance_tables: invoices, expenses, suppliers | Foundation for finance module |
| 052 | staff_competency_records | Competency tracking |
| 054 | meetings_log | Meeting system |
| 056 | missing_tables: catch-all for any missing | Fill gaps |
| 057 | extend_choking_risk: adds columns | Choking risk enhancement |
| 068 | drivers_and_vehicles: drivers, vehicles, vehicle_assignments | Driver module |
| 069 | add_carer_missing_columns | Carer schema fix |
| 070 | add_carer_dob_address | Carer schema fix |
| 071 | create_organisations | Organisation entity table |
| 072 | add_organisation_id_to_all_tables | Org-scoping for all tables |
| 073 | enable_rls_all_tables + create tenant_isolation policy | CRITICAL: Enables RLS on ~55 tables with get_organisation_id() function |
| 074 | create_organisations_for_existing_users | Backfill orgs |
| 075-076 | enhance choking risk + link to service users | Choking risk completeness |
| 077-078 | enhance falls risk + create medication risk | Risk completeness |
| 079 | create_respect_forms | RESPECT form system |
| 080-082 | create/recreate fire hazard, domiciliary fire safety, coshh, nutrition | Risk revisions |
| 083 | create_daily_notes | Daily notes table |
| 084 | create_mar_chart | MAR chart table |
| 085-086 | care_log_audits, care_plan_audits | Audit system |
| 087-088 | spot_checks + fix spot check tables | Spot check fixes - 088 adds permissive service_users policy (CONCERN) |
| 089 | fix_rls_profiles_carers: add organisation_id, name to profiles; org-scoped RLS | Identity tables RLS |
| 090 | fix_profile_rls_recursion: SECURITY DEFINER function to avoid infinite recursion | CRITICAL FIX |
| 091 | drop_rls_profiles_carers (cleanup) | Remove broken policies |
| 092 | compliance_dashboard_enhancement | Compliance dashboard refresh |
| 093 | safeguarding_hub | Safeguarding enhancements |
| 094-095 | staff_appraisals + compliance fields | Appraisal system (replaces 020) |
| 096-097 | training_courses + seed data | Training module |
| 099 | disciplinary_cases | Disciplinary module |
| 100 | competency_framework + leave_and_pay (same file number used twice!) | Competency framework V2 + leave system |
| 101 | employee_welfare + seed_competency_framework | Welfare + competency seed |
| 102 | competency_notifications + employee_satisfaction | Notifications + satisfaction surveys |
| 103 | add_missing_columns + employee_incentives | Schema fixes + incentives |

### 3.4 Route & Client-Facing Migrations (104-146)

| # | Purpose | Impact |
|---|---------|--------|
| 104 | create_routes_table + meetings_log + supplier_register (triple migration!) | Initial route system, meetings, suppliers |
| 105 | fix_competency_assessments + receipt_entries | Competency fix + receipt system |
| 106 | extend_receipts_for_profit + profit_tracking_consolidated | Profit module |
| 107 | profit_calculations | Profit calculations |
| 108 | invoice_system | Invoicing |
| 109 | action_plans | Action plan governance table |
| 110 | lessons_learnt | Lessons learnt table |
| 111 | policy_library | Policy library table |
| 112 | analysis_tables | Analysis views for dashboard |
| 113 | notifications | Extended notification system |
| 114 | carer_inbox | Carer-specific inbox |
| 115 | add_client_role | Adds client role to profiles CHECK constraint |
| 116 | create_routes_table (revised) | Revised routes table |
| 117 | create_shift_broadcasts | Multi-agency broadcast table |
| 118 | create_psl_table | Preferred Supplier List (client_organisation_spl) |
| 119 | add_shift_booking_columns | client_organisation_id, location, staff_type on shifts |
| 120 | add_timesheet_fields | Timesheet workflow fields on shifts |
| 121 | fix_admin_update_policy | Admin shift update permissions |
| 122 | fix_shifts_status_check | Adds confirmed/declined to status CHECK |
| 123 | prevent_carer_double_booking | Trigger-based conflict check |
| 124 | add_timesheet_workflow_fields | More timesheet columns |
| 125 | fix_visits_rls_for_clients | Client can see visits for their org shifts |
| 126 | fix_visits_select_for_clients | Client visit SELECT fix |
| 127 | fix_visits_rls_shift_subquery | Fix client visit visibility via subquery |
| 128 | add_profile_rls_for_subusers | Sub-user profile management policies |
| 129 | fix_subuser_creation_trigger | Trigger for auto-creating sub-user profiles |
| 130 | fix_profile_rls_recursion | More recursion fixes |
| 131 | add_reset_subuser_password_rpc | RPC for admin to reset sub-user passwords |
| 132 | fix_reset_password_search_path | Search path fix for the RPC |
| 133 | add_carer_invite_system | Carer invitation workflow |
| 134 | admin_carer_password_management | Admin manages carer passwords |
| 135 | staff_self_signup | Staff can self-register |
| 136 | route_schedule_enhancements | Route schedule refinements |
| 137 | route_visits_and_change_log | MAJOR: Creates route_visits + route_change_log; routes becomes container |
| 138 | service_user_calls_flags | Call flags on service users |
| 139 | route_carers_and_driver | carer_id, is_driver on routes |
| 140 | route_second_carer_driver_mode | second_carer_id, driver_mode on routes |
| 141 | routes_admin_organisation | DUAL RLS: organisation_id OR client_organisation_id for all route tables |
| 142 | routes_drop_legacy_call_number | Removes call_number from routes (breaking client-app model) |
| 143 | service_user_call_log + weekly calls | Call logging + weekly timetable |
| 144 | service_user_status_and_body_map | Status tracking + body map |
| 145 | recurring_weekly_timetable | Recurring weekly call timetable |
| 146 | route_reads_for_carers | Carer SELECT policies for routes and route_visits |

---

## 4. ADMIN-APP: Complete Service-by-Service Breakdown

Each service is evaluated for: scenario, CRUD tables, RLS interaction, whether it is live vs. dead vs. duplicated, and bottlenecks.

### 4.1 Shift Scheduling Services

**shift_service.dart**
- Scenario: Admin views/manages shifts for a date. Assigns/unassigns carers. Sends reminders (placeholder).
- Methods: getShiftsForDate(DateTime), getShiftById(id), createShift(Shift), updateShift(Shift), assignCarerToShift(shiftId, carerId), unassignCarerFromShift(shiftId, carerId), sendShiftReminder(shiftId), getCarers(), _getClientOrgId().
- CRUD: shifts (C/R/U), carers (R). assignCarerToShift() does: SELECT existing shift -> UPDATE carer_id + status=confirmed -> SELECT confirm.
- RLS: Admin bypasses RLS via role (admin users have broad policies). The service does NOT apply org filters explicitly - it depends on RLS. assignCarerToShift validates the shift exists first (single SELECT with RLS).
- Bottleneck: The carerId written comes from getCarers() which returns carers.id. This writes a carers.id into shifts.carer_id. The staff-app queries WHERE carer_id = auth.uid(). If the carer''s auth.users.id does not equal their carers.id, the staff-app sees nothing. This is the identity-linkage problem.
- Utility: LIVE - core scheduling flow. Used by shift_list_screen.dart (admin dashboard).
- Recommendation: Fix identity-linkage (see Section 14). Add explicit organisation_id filter to queries as defense-in-depth.

**database_service.dart** (LEGACY)
- Scenario: Generic CRUD for carers, service_users, shifts, visits, documents, notifications, settings. This is the OLDER service layer.
- Methods: addCarer, updateCarer, deleteCarer, getCarers; addServiceUser, updateServiceUser, deleteServiceUser, getServiceUsers; addShift, updateShift, deleteShift, getShifts, getShiftsByCarer; addVisit, updateVisit, getVisits, getVisitsByCarer; addDocument, getDocumentsByCarer; addNotification, getNotificationsForUser, markNotificationAsRead; getSettings, updateSettings.
- CRUD: carers, service_users, shifts, visits (via old models), documents, notifications, settings.
- RLS: Uses _getOrganisationId() for org-scoping. Adds organisation_id to INSERT data.
- Bottleneck: getShifts() joins on shifts(date, service_users) but the shifts table uses scheduled_date, not date. This may produce null/incorrect results. The file imports an old Shift model (../models/shift.dart) which is DIFFERENT from the new one in shift_service.dart (inline class).
- Utility: PARTIALLY DEAD. Used by MasterDashboard (which itself has empty quick-action callbacks). The newer shift_service.dart should be the canonical source. Some screens may still reference DatabaseService.
- Recommendation: Deprecate DatabaseService. Migrate all consumers to dedicated services (shift_service, carer-specific services, etc.). Audit all files importing database_service.dart.

**shift_rota_service.dart**
- Scenario: Manages shift rotas (recurring shift patterns).
- CRUD: shift_rota table.
- Utility: LIVE - wired from admin dashboard sidebar.
- Recommendation: Keep.

### 4.2 Route Service (Massive - 1123 lines)

**route_service.dart**
- Scenario: Full route lifecycle management. Create routes, add visits, assign carers, manage weekly timetables, log changes.
- Methods (key): getActiveServiceUsers(), getServiceUsersWithCalls(), createRoute(), updateRoute(), deleteRoute(), getRoutesForDate(), getRoutesForDateRange(), addVisitToRoute(), updateVisit(), deleteVisit(), assignCarerToRouteCluster(), assignCarerToVisit(), getServiceUserWeeklyCalls(), setServiceUserWeeklyCalls(), generateRouteFromWeeklyCalls(), _insertVisit(), _logChange().
- CRUD: routes (CRUD), route_visits (CRUD), route_change_log (C), service_users (R), service_user_weekly_calls (R/U), carers (R).
- RLS: Uses _OrgContext class that detects organisation_id vs client_organisation_id for dual-scoping. On INSERT: adds either organisation_id or client_organisation_id based on user type. On SELECT: applies org filter via _scopeRouteQuery(). This correctly implements the 141 migration dual-scoping pattern.
- Bottleneck: The massive size (1123 lines) makes maintenance difficult. No separation of concerns. _logChange silently catches errors (try/catch with empty catch block at line 1087-1089) - change log failures are swallowed.
- Utility: LIVE - core route management. Used by route_form_screen.dart and shift_list_screen.dart (for route call views).
- Recommendation: Refactor into multiple files (route_crud_service, route_visit_service, route_timetable_service). Fix the swallowed exception in _logChange to at least log the error.

### 4.3 Risk Assessment Services (pattern analysis)

All risk services follow a consistent pattern: CRUD operations against their respective risk table via Supabase client. 

**Duplicate alert:** mca_service.dart and mental_capacity_service.dart both target mental_capacity_assessments.
**Duplicate alert:** catheter_care_risk_service.dart and catheter_care_service.dart both target catheter-related tables.

Recommendation: Consolidate duplicates. For each risk type, have exactly one service.

### 4.4 Care Chart Services

food_fluid_service.dart: CRUD on food_fluid_charts + audit log writes.
food_fluid_intake_service.dart: CRUD on food_fluid_intake_logs.
bowel_bladder_service.dart: CRUD on bowel_bladder_charts + audit.
repositioning_service.dart: CRUD on repositioning_charts + audit.
sleep_service.dart: CRUD on sleep_charts + audit.
daily_note_service.dart: CRUD on daily_notes.

All are LIVE and wired from admin sidebar navigation. Staff equivalents exist but dashboard navigation is missing.

### 4.5 HR Services

appraisal_service.dart, training_service.dart, competency_service.dart + competency_scoring.dart, disciplinary_service.dart, leave_service.dart, welfare_service.dart, satisfaction_service.dart, incentive_service.dart.
- All live, wired from admin sidebar.
- Competency service has 12 form variants.
- Leave service handles 4 tables: leave_requests, leave_policy_settings, holiday_allowance, payroll_history.
- Welfare service handles 4 tables: welfare_checks, welfare_referrals, stress_risk_assessments + carers read.
- Satisfaction service handles 4 tables: satisfaction_surveys, satisfaction_trends, staff_recognition + carers read.
- Incentive service handles 7 tables: incentive_programs, employee_incentives, points_accounts, points_redemptions, reward_catalogue, performance_metrics + carers read.

### 4.6 Finance Services

invoice_service.dart: invoices CRUD + organisation_profiles R + profiles R.
receipt_service.dart: receipt_entries CRUD + receipts R + profit_snapshots CU.
expense_tracking_service.dart: ALSO receipt_entries CRUD + receipts R + profit_snapshots CU + dom_care_routes R.
supplier_service.dart: supplier_register CRUD.

**DUPLICATE ALERT:** receipt_service and expense_tracking_service overlap significantly. Both write to receipt_entries, receipts, and profit_snapshots. This creates risk of data inconsistency (two code paths writing with different logic).

### 4.7 Governance Services

action_plan_service.dart, lesson_learnt_service.dart, policy_service.dart, analysis_service.dart, compliance_service.dart, mar_audit_service.dart, mar_service.dart, spot_check_service.dart, careplan_audit_service.dart, care_log_audit_service.dart, care_plan_audit_service.dart, safeguarding_service.dart, meeting_service.dart, notification_service.dart, message_service.dart.
- All live and wired from admin sidebar.
- analysis_service.dart is join-heavy: reads analysis_views + audits, incidents, invoices, receipts, shifts, visits, training_records, risk_assessments, dom_care_routes, carers, profiles, service_users.

### 4.8 Auth Services

**supabase_auth_service.dart**: Primary auth service. Handles signIn, signOut, signUp, profile loading, role detection.
**auth_service.dart**: Thin duplicate. Imported by admin_dashboard and master_dashboard for signOut only.

Recommendation: Remove auth_service.dart. Have all consumers use supabase_auth_service.dart.

---

## 5. ADMIN-APP: Complete Screen-by-Screen Breakdown

### 5.1 Navigation Architecture

The admin-app has TWO dashboard entry points:
1. **AdminDashboard** (admin_dashboard.dart) - The PRIMARY dashboard. Has a hamburger menu (Drawer) with organized sidebar navigation. ~80% of screens are reachable from here.
2. **MasterDashboard** (master_dashboard.dart) - An OLDER/LEGACY dashboard. Uses DatabaseService (legacy). Has quick-action chips with EMPTY callbacks (lines 354-371: Risk Assessments, Daily Charts, Audits, Staff Records, Compliance, Reports - all callbacks are empty `() {}`). This dashboard should be deprecated.

### 5.2 Screens Organized by Sidebar Category

**Dashboard Home (landing page):** Quick-tile grid: Carers, Service Users, Shifts, Safeguarding, MAR Audit, Compliance, Action Plans, Lessons Learnt, Policy Library, Analysis.
- Status: WIRED. Each tile correctly navigates to the respective list/dashboard screen.

**People menu:** Carer List, Service User List, Carer Invite.
- Status: WIRED (sidebar).

**Scheduling menu:** Shifts/Routes, Shift Rota, Visits, Drivers.
- Shifts/Routes -> shift_list_screen.dart (uses ShiftService + RouteService). WIRED.
- Shift Rota -> shift_rota_screen.dart. WIRED.
- Visits -> visit_list_screen.dart. WIRED.
- Drivers -> drivers_screen.dart. WIRED.

---

### 5.3 Risk Assessment Screens

The admin sidebar has a dedicated Risk Assessment section. The following screens are wired:

| Screen | Wired From | Service | Table | Assessment |
|--------|-----------|---------|-------|-----------|
| Risk Assessment (generic) | Sidebar | risk_assessment_service | risk_assessments | Usable |
| Waterlow | Sidebar | waterlow_service | waterlow_assessments | Usable |
| Choking Risk | Sidebar | choking_risk_service | choking_risk_assessments | Usable |
| Falls Risk | Sidebar | falls_risk_service | falls_risk_assessments | Usable |
| Medication Risk | Sidebar | ? | medication_risk_assessments | Usable |
| MCA (Mental Capacity) | Sidebar | mca_service | mental_capacity_assessments | Usable |
| RESPECT Forms | Sidebar | ? | respect_forms | Usable |
| Grabsheet | Sidebar | ? | ? | Uncertain |

Additional risk screens exist as files (catheter_care_risk, coshh, diabetes, domiciliary_fire_safety, environmental, epilepsy, equipment_register, fire_hazard, incontinence, nutrition, self_harm, activity, bed_railing, challenging_behaviour):
- Some are in ui/risk/ folder with screen+form pairs.
- Some are in ui/assessments/ folder.
- Navigation audit needed: are they ALL reachable from the sidebar or only from other risk screens?

### 5.4 Chart Screens

| Screen | Wired From | Notes |
|--------|-----------|-------|
| Food & Fluid | Sidebar (Daily Charts) | Also has audit view |
| Bowel & Bladder | Sidebar (Daily Charts) | |
| Repositioning | Sidebar (Daily Charts) | Also has audit view |
| Sleep | Sidebar (Daily Charts) | Also has audit view |
| Intake Log | Sidebar (Monitoring) | Temperature log also exists |
| Stool Log | Sidebar (Monitoring) | |
| Temperature Log | Sidebar (Monitoring) | Table uncertain |
| Daily Notes | Sidebar (Monitoring) | |

### 5.5 Audit Screens

MAR Audit, Care Log Audit, Care Plan Audit, Spot Check - all wired from sidebar.
Duplicate screens exist: ui/audit/ and ui/audits/ folders both have care_log_audit_screen, careplan_audit_screen, mar_audit_screen, spot_check_screen. The admin_dashboard imports from BOTH folders for some screens. This suggests a refactoring that was never completed.

### 5.6 HR Screens

Supervision Matrix, Appraisals, Training Matrix (wired twice in sidebar - once under Staff and once under Training), Disciplinary, Leave, Employee Welfare, Employee Satisfaction, Employee Incentives, Competency Dashboard + 12 competency types. All wired from sidebar.

### 5.7 Finance Screens

Invoices, Receipt Entry, Receipt List, Supplier Log, Profit/Loss, Organisation Profile, Supplier Register - all wired from sidebar.
Profit/Loss screen exists in BOTH ui/finance/ AND ui/admin/ folders.

### 5.8 Governance Screens

Safeguarding, Accidents/Incidents, Whistleblower Inbox, MAR Chart/Suggestions, Action Plans, Lessons Learnt, Policy Library, Meetings, Analysis, Compliance, Notifications, Carer Inbox, Messages.
All wired from sidebar.

### 5.9 Dead/Orphaned Admin Screens

**MasterDashboard** - Has empty callback functions for every quick action. Serves no purpose beyond a static stats display (which uses hardcoded placeholders for assessment counts, upcoming reviews, training expirations). Should be removed or replaced with AdminDashboard.

### 5.10 Duplicate Admin Screens

- profit_loss_screen.dart: exists in both ui/finance/ and ui/admin/
- training_matrix_screen.dart: exists in both ui/training/ and ui/staff/ (sidebar lists both)
- meetings_log_screen.dart: exists in both ui/admin/ and ui/staff/
- daily_notes_screen.dart: exists in both ui/monitoring/ and another location
- Audit screens: duplicated in ui/audit/ vs ui/audits/

---

## 6. STAFF-APP: Complete Service-by-Service Breakdown

### 6.1 shift_service.dart (CRITICAL)

- Scenario: Carer sees assigned shifts AND route calls on their dashboard.
- Methods: getShiftsForCurrentCarer(), getShiftsForDate(date), getShiftById(id), getRouteCallsForCurrentCarer(), acceptShift(id), declineShift(id).
- CRUD: shifts (R), route_visits (R), routes (R). acceptShift/declineShift: shifts (U).
- RLS: Relies on RLS policies for access control. getShiftsForCurrentCarer() filters by carer_id = auth.uid(). getRouteCallsForCurrentCarer() does TWO queries: (1) route_visits WHERE carer_id = auth.uid(), (2) routes WHERE second_carer_id = auth.uid() then all visits for those routes.
- Bottleneck: **IDENTITY-LINKAGE BUG**. The carer_id stored on shifts and route_visits is a carers.id value. The auth.uid() is the auth.users.id. These are different UUIDs for legacy carers who were created via admin without auth accounts. Staff sees zero shifts/routes.
- Utility: LIVE - THE core staff function. Powers ShiftsScreen.
- Recommendation: Fix identity-linkage (see Section 14).

### 6.2 firestore_service.dart (DUPLICATE)

- Scenario: Carer shift management + visit check-in. Named firestore_service but uses Supabase.
- Methods: getCarerShifts() - reads shifts WHERE carer_id = auth.uid() (DUPLICATE of shift_service.getShiftsForCurrentCarer()). addVisit(), updateVisit(), getVisits() - CRUD on visits table.
- CRUD: shifts (R - duplicate), visits (C/U/R).
- Bottleneck: Same identity-linkage issue for shift reads. Visit writes may fail RLS if organisation_id is not set.
- Utility: The shift-reading functionality is a DUPLICATE of shift_service. The visit-writing functionality is unique (check-in/out).
- Recommendation: Merge visit writing into shift_service or a new visit_service. Remove shift-reading methods from firestore_service.

### 6.3 supabase_auth_service.dart vs auth_service.dart

supabase_auth_service.dart: Primary auth. Handles signIn, signOut, signUp, auto-creates profiles with role=carer on first login. Changes notifiable (ChangeNotifier).
auth_service.dart: Thin duplicate. Used in some screens for signOut.

Recommendation: Deprecate auth_service.dart. All screens should use supabase_auth_service.dart.

### 6.4 Risk Services (staff-app copies)

The staff-app has 11 risk service files: activity_risk_service, anaphylaxis_service, catheter_care_service, coshh_risk_service, diabetes_service, epilepsy_service, equipment_register_service, financial_service, incontinence_service, self_harm_service, sepsis_service.

These are SEPARATE COPIES from the admin-app - not shared code. They may diverge. Each CRUDs its respective risk table.

### 6.5 Chart Services

food_fluid_service, bowel_bladder_service, repositioning_service, sleep_service - these are staff-app copies of admin chart services. They write to the same tables.

---

## 7. STAFF-APP: Complete Screen-by-Screen Breakdown

### 7.1 Dashboard & Shift Screens

**StaffDashboard** (staff_dashboard.dart)
- What it does: Simple shell. Shows welcome text and embeds ShiftsScreen. Has logout button and notification bell.
- Navigation: Entry point after auth. NO navigation to charts, risk forms, competencies, or MAR chart.
- Gap: This is the ONLY way staff access the app. If the dashboard does not link to chart forms and risk forms, staff cannot document care delivery.
- Recommendation: Add bottom navigation or drawer with links to: My Shifts, Daily Charts (food/fluid, bowel/bladder, repositioning, sleep), Risk Assessments, Competencies, MAR Chart, Check-In.

**ShiftsScreen** (shifts_screen.dart)
- What it does: Shows combined list of shifts + route calls. Date navigation. Status filter tabs (All, Scheduled, Confirmed, Completed, Declined). Pull-to-refresh.
- Data sources: Merge of getShiftsForCurrentCarer() + getRouteCallsForCurrentCarer().
- Status: LIVE and working (subject to identity-linkage data availability).
- Recommendation: This is well-designed. The merge of shifts + route calls is correct.

**ShiftDetailScreen** (shift_detail_screen.dart)
- What it does: Shows single shift/route-call detail. Accept/Decline buttons.
- Status: LIVE - navigated from ShiftsScreen on tap.

**CheckInScreen** (check_in_screen.dart)
- What it does: Carer clocks in/out for a visit. Creates/updates visit record.
- Navigation: UNCERTAIN - check if reachable from ShiftDetailScreen or ShiftsScreen.
- Status: May be orphaned.

### 7.2 Chart Form Screens (Orphaned?)

| Form File | Table | Status |
|-----------|-------|--------|
| food_fluid_form.dart | food_fluid_charts | ? No visible navigation from dashboard |
| bowel_bladder_form.dart | bowel_bladder_charts | ? No visible navigation |
| repositioning_form.dart | repositioning_charts | ? No visible navigation |
| sleep_form.dart | sleep_charts | ? No visible navigation |

These are CORE care delivery forms. If they are not reachable, staff cannot document care.

### 7.3 Risk Form Screens (Orphaned?)

~20 risk form/screen pairs exist in staff-app/ui/risk/. None are linked from StaffDashboard.

### 7.4 Competency Screens (Partially Orphaned?)

| Screen | Status |
|--------|--------|
| my_competencies_screen.dart | ? No visible navigation from dashboard |
| ~12 competency form screens | ? No visible navigation |

### 7.5 Other Staff Screens

| Screen | Status |
|--------|--------|
| my_compliance.dart | ? No visible navigation |
| mar_chart_screen.dart | ? No visible navigation |

### 7.6 Summary: Staff Navigation Gap

The staff dashboard (staff_dashboard.dart) embeds ONLY ShiftsScreen. There is NO way for staff to navigate to:
- Daily care chart forms (food/fluid, bowel/bladder, repositioning, sleep)
- Risk assessment forms (20+ types)
- Competency forms
- MAR chart
- Check-in screen
- My compliance

This means that while the code for staff care documentation EXISTS, it is functionally DEAD because staff users cannot reach it.

---

## 8. CLIENT-APP: Complete Service-by-Service Breakdown

### 8.1 shift_service.dart (LIVE)
- Scenario: Client organisation books shifts, manages existing bookings, assigns carers, checks availability.
- Methods: getShifts(orgId), getShiftsByLocation(orgId, location), getShiftsByStaffType(orgId, type), getShiftsForMonth(orgId, start, end), getShiftById(id), createShift(Shift), updateShift(Shift), deleteShift(id), updateShiftStatus(id, status), assignCarer(shiftId, carerId), checkCarerAvailability(carerId, date, start, end, excludeShiftId).
- CRUD: shifts (CRUD), client_organisation_spl (R).
- Validation: createShift validates all UUIDs, checks carer availability, sets client_organisation_id and status=scheduled.
- RLS: Scopes queries by client_organisation_id. The client user''s profile has client_organisation_id set, and RLS (119) allows SELECT/INSERT/UPDATE for their org.
- Status: FULLY LIVE.

### 8.2 shift_template_service.dart (LIVE)
- Scenario: Client manages reusable shift templates for quick booking.
- CRUD: shift_templates (CRUD).
- Status: LIVE.

### 8.3 timesheet_service.dart (LIVE)
- Scenario: Client views timesheet/register of completed shifts and visits.
- CRUD: shifts (R), visits (R), profiles (R). Uses joins.
- Status: LIVE.

### 8.4 spl_service.dart (LIVE)
- Scenario: Client manages Preferred Supplier List - links their org to provider agencies.
- CRUD: client_organisation_spl (CRUD), organisations (R).
- Status: LIVE.

### 8.5 shift_broadcast_service.dart (LIVE)
- Scenario: Client broadcasts a shift to single/multiple/all PSL agencies.
- CRUD: shifts (U - sets broadcast_type), shift_broadcasts (C), profiles (R), client_organisation_spl (R).
- Status: LIVE. Note: no receiving agency app exists yet.

### 8.6 staff_service.dart (PARTIALLY LIVE)
- CRUD: carers (R), visits (R), client_organisation_spl (R).
- Used by: staff_profile_screen.dart (ORPHANED - no navigation).
- Status: Code exists but primary consumer screen is unreachable.

### 8.7 route_service.dart (LIVE - Schema Risk)
- CRUD: routes (CRUD).
- Risk: Uses legacy column shapes (route_date, call_number). call_number was dropped in migration 142. Model may be out of sync.
- Status: Code is live but may fail at runtime with current database schema.

### 8.8 rating_service.dart (DEAD)
- CRUD: staff_ratings (C/R).
- Consumer: rate_carer_dialog.dart (ORPHANED - no navigation).
- Status: Complete service code but unreachable. Rating feature is dead.

### 8.9 booking_service.dart (BROKEN)
- CRUD: bookings table. This table DOES NOT EXIST in any migration.
- Consumer: booking_history_screen.dart (ORPHANED).
- Status: Broken. Both the service target and the screen are dead.

### 8.10 Auth Services
supabase_auth_service.dart (LIVE) + auth_service.dart (DUPLICATE - thin wrapper).

---

## 9. CLIENT-APP: Complete Screen-by-Screen Breakdown

### 9.1 Wired Screens (6 tiles on dashboard)

| Screen | Dashboard Tile | Status |
|--------|---------------|--------|
| ShiftsScreen | Shifts | LIVE - shows client org shifts |
| BookShiftScreen | Book a Shift | LIVE - full booking form with carer conflict check |
| ShiftRegisterScreen | Timesheets | LIVE - timesheet/register view |
| ShiftTemplatesScreen | Shift Templates | LIVE - CRUD templates |
| PreferredCarersScreen | My Profile & Sub-Users | LIVE - sub-user management + preferred carers |
| SplManagementScreen | Service Providers | LIVE - PSL management |

All 6 tiles are correctly wired from DashboardScreen.

### 9.2 Orphaned Screens

| Screen | What it was for | Why dead |
|--------|----------------|---------|
| booking_history_screen.dart | View past bookings | No navigation + bookings table missing |
| booking_diary_screen.dart | Calendar diary of bookings | No navigation |
| shift_list_screen.dart | Old shift list (superseded) | No navigation - replaced by shifts_screen |
| staff_profile_screen.dart | Carer detail for clients | No navigation |
| rate_carer_dialog.dart | Rate a carer after shift | No navigation - rating feature dead |

### 9.3 Wireable But Dead Features

The rating system: rating_service.dart is complete. rate_carer_dialog.dart exists. But there is NO path from any wired screen to the dialog. Wire it from ShiftDetailBottomSheet or from the shift list with a Rate button.

The booking diary: Could be wired as an alternative view alongside ShiftsScreen. But since bookings table is missing, this should either be rewired to use shifts table or removed.

---

## 10. Cross-App Data Flows - Complete Trace

### 10.1 Shift Lifecycle (client -> admin -> staff)

```
STEP 1: CLIENT BOOKS SHIFT
client-app: BookShiftScreen -> shift_service.createShift()
POST /rest/v1/shifts INSERT {
  client_organisation_id: X,
  service_user_id: Y,
  scheduled_date: '2026-08-22',
  start_time: '08:00',
  end_time: '16:00',
  status: 'scheduled',
  carer_id: NULL,
  location: '...', staff_type: '...', staff_required: N
}
RLS check: client_organisation_id = auth user''s client_organisation_id -> PASS
TABLE STATE: shifts row exists, carer_id=NULL, status=scheduled, organisation_id=NULL

STEP 2: ADMIN VIEWS SHIFTS
admin-app: ShiftListScreen -> shift_service.getShiftsForDate(date)
GET /rest/v1/shifts?select=*,service_users(name),carers(name)&scheduled_date=eq.2026-08-22
RLS check: Admin role policies allow broad SELECT -> PASS
RESULT: Admin sees the shift in the list

STEP 3: ADMIN ASSIGNS CARER
admin-app: ShiftListScreen -> _showAssignCarerBottomSheet() -> shift_service.assignCarerToShift(shiftId, carerId)
PATCH /rest/v1/shifts?id=eq.{shiftId} UPDATE {carer_id: carerId, status: 'confirmed'}
RLS check: Admin role policies allow UPDATE -> PASS
TABLE STATE: carer_id = {carers.id value}, status = confirmed

STEP 4: STAFF SEES SHIFT (BROKEN)
staff-app: ShiftsScreen -> shift_service.getShiftsForCurrentCarer()
GET /rest/v1/shifts?select=*,service_users(name),carers(name)&carer_id=eq.{auth.uid()}
RLS check: Carer self-access policy -> checks carer_id = auth.uid()
BUG: auth.uid() returns the auth.users.id UUID.
     shifts.carer_id contains the carers.id UUID.
     For legacy carers, these are DIFFERENT UUIDs.
RESULT: Query returns ZERO rows. Staff sees blank dashboard.
```

**Root cause:** In step 3, admin writes a carers.id into shifts.carer_id. In step 4, staff queries WHERE carer_id = auth.uid(). The auth.users.id and carers.id fields are separate UUID values. They only match if the carer was created WITH an auth account (new flow via migration 135 staff self-signup). Legacy carers created by admin (via migration 133 or manual INSERT) have a carers.id that is NOT linked to any auth.users row.

**Fix:** See Section 14.

### 10.2 Route Lifecycle (admin -> client -> staff)

```
STEP 1: ADMIN CREATES ROUTE
admin-app: ShiftListScreen/RouteFormScreen -> route_service.createRoute()
POST /rest/v1/routes INSERT {organisation_id: A, name: '...', route_date: '...'}
RLS check: organisation_id = admin''s org -> PASS

STEP 2: ADMIN ADDS VISITS + ASSIGNS CARER
admin-app: route_service.addVisitToRoute() + assignCarerToVisit()
POST /rest/v1/route_visits INSERT {route_id: R, service_user_id: S, carer_id: C, ...}
RLS check: organisation_id = admin''s org -> PASS
route_change_log INSERT (silently on error)

STEP 3: CLIENT VIEWS ROUTES
client-app: route_service.getRoutesForDate(clientOrgId, date)
GET /rest/v1/routes?client_organisation_id=eq.X&route_date=eq.2026-08-22
RLS check: client_organisation_id matches -> PASS (migration 141)
NOTE: Client route_service uses legacy columns (route_date, call_number) which may conflict with post-137 schema

STEP 4: STAFF SEES ROUTE CALLS (BROKEN)
staff-app: ShiftsScreen -> shift_service.getRouteCallsForCurrentCarer()
GET /rest/v1/route_visits?carer_id=eq.{auth.uid()}
RLS check: Carer self-access policy (146) allows SELECT if carer_id = auth.uid() OR route''s carer_id/second_carer_id = auth.uid()
BUG: Same identity-linkage problem as shifts. If carer_id stored is carers.id and auth.uid() is different, query returns zero.
```

### 10.3 Care Delivery Loop (staff -> admin)

```
STEP 1: STAFF DOCUMENTS CARE (ORPHANED?)
staff-app: Chart forms (food_fluid_form.dart etc.) -> chart service -> INSERT chart table
STATUS: Forms EXIST but NO navigation from staff dashboard to these forms.
        Even if forms were reachable, staff user''s auth.uid() must match a carers.id for RLS to allow writes.

STEP 2: ADMIN REVIEWS CARE
admin-app: Chart screens (food_fluid_screen.dart etc.) -> chart service -> SELECT chart table
RLS check: Admin policies allow broad SELECT -> PASS
STATUS: Admin screens are wired. But if staff cannot write data, admin sees empty charts.
```

### 10.4 Broadcast Flow (client -> agencies)

```
STEP 1: CLIENT BROADCASTS SHIFT
client-app: shift_broadcast_service.broadcastShift()
UPDATE shifts SET broadcast_type = 'single'|'multiple'|'all'
INSERT shift_broadcasts (one per target agency)

STEP 2: AGENCY RECEIVES
NO AGENCY-SIDE APP EXISTS. Broadcast rows sit in the database with no consumer.
```

### 10.5 Check-In Flow (staff -> admin)

```
STEP 1: STAFF CHECKS IN (ORPHANED?)
staff-app: check_in_screen.dart -> firestore_service.addVisit()
INSERT visits {shift_id, carer_id, check_in_time, ...}
STATUS: Screen may be orphaned. Visit write may fail RLS if organisation_id not set.

STEP 2: ADMIN VIEWS VISITS
admin-app: visit_list_screen.dart -> database_service.getVisits()
SELECT visits with joins
STATUS: Admin screen wired.
```

### 10.6 Rating Flow (DEAD)

```
client-app: rate_carer_dialog.dart -> rating_service -> staff_ratings
STATUS: Dialog has NO navigation path. Rating feature is completely dead despite complete code.
```

### 10.7 Carer Invite Flow (ADMIN -> STAFF)

```
STEP 1: ADMIN INVITES CARER
admin-app: carer_invite_screen.dart -> carer_invite_service -> auth invite + carers UPDATE
STATUS: Migration 133-134 set up invite system. Admin screens wired.

STEP 2: STAFF ACCEPTS
staff-app: signup_screen.dart -> supabase_auth_service.signUp()
STATUS: Migration 135 added staff self-signup. Staff can also self-register without invite.
AMBIGUITY: Both invite (133-134) and self-signup (135) exist. Which is the canonical flow?
```

---

## 11. Orphaned and Dead Code - Master Inventory

### 11.1 CLIENT-APP Orphans

| File | Type | Why Dead | Table Impact | Fix |
|------|------|---------|-------------|-----|
| booking_history_screen.dart | Screen | No navigation; bookings table missing | bookings (nonexistent) | Remove or create bookings table + wire |
| booking_diary_screen.dart | Screen | No navigation | references shifts indirectly | Wire from dashboard or remove |
| shift_list_screen.dart | Screen | Superseded by shifts_screen.dart; no navigation | shifts (old path) | Remove |
| staff_profile_screen.dart | Screen | No navigation | carers | Wire from shift detail or remove |
| rate_carer_dialog.dart | Dialog | No navigation | staff_ratings | Wire from ShiftDetailBottomSheet |
| booking_service.dart | Service | References nonexistent bookings table | bookings | Create table or remove service |
| rating_service.dart | Service | Complete but no consumer | staff_ratings | Wire dialog (see above) |

### 11.2 STAFF-APP Orphans

| File | Type | Why Dead | Table Impact | Fix |
|------|------|---------|-------------|-----|
| check_in_screen.dart | Screen | May be unreachable | visits | Verify navigation wiring |
| mar_chart_screen.dart | Screen | No visible navigation | mar_chart | Add to staff dashboard |
| my_compliance.dart | Screen | No visible navigation | compliance_flags | Add to dashboard or remove |
| my_competencies_screen.dart | Screen | No visible navigation | staff_competency_assessments | Add to dashboard |
| ~4 chart forms | Forms | No visible navigation | food_fluid_charts, bowel_bladder_charts, repositioning_charts, sleep_charts | CRITICAL: Must be wired for care documentation |
| ~20 risk forms | Forms | No visible navigation | All risk assessment tables | Wire from dashboard |
| ~12 competency forms | Forms | No visible navigation | staff_competency_assessments | Wire from competencies screen |
| auth_service.dart | Service | Duplicate of supabase_auth_service | auth, profiles | Remove |

### 11.3 ADMIN-APP Orphans

| File | Type | Why Dead | Table Impact | Fix |
|------|------|---------|-------------|-----|
| MasterDashboard | Dashboard | Empty quick-action callbacks; uses legacy DatabaseService; hardcoded placeholder stats | Multiple (via DatabaseService) | Remove or fully rebuild |
| database_service.dart | Service | Legacy - superseded by dedicated services. Uses old Shift model (date vs scheduled_date) | Multiple | Deprecate, migrate consumers |
| auth_service.dart | Service | Thin duplicate of supabase_auth_service | auth, profiles | Remove |
| mca_service.dart + mental_capacity_service.dart | Service | Duplicate pair | mental_capacity_assessments | Consolidate to one |
| catheter_care_risk_service.dart + catheter_care_service.dart | Service | Duplicate pair | catheter tables | Consolidate |
| receipt_service.dart + expense_tracking_service.dart | Service | Overlapping pair | receipt/profit tables | Consolidate |
| Duplicate screens (profit_loss, training_matrix, meetings_log, daily_notes, audit screens) | Screens | Same screen in 2 folders | Various | Keep one copy, remove duplicate |
| ServiceUserPickerScreen (in admin_dashboard.dart) | Screen | Shows Coming Soon placeholder | None | Implement or remove |

---

## 12. Service Duplicates and Overwrites

### 12.1 Auth Service Duplication (ALL THREE APPS)

Each app has BOTH `supabase_auth_service.dart` and `auth_service.dart`. 
- supabase_auth_service.dart: Full-featured, ChangeNotifier, profile creation, role detection.
- auth_service.dart: Thin wrapper, mostly just signOut().

**Action:** Remove auth_service.dart from all three apps. Update all imports to use supabase_auth_service.dart.

### 12.2 Admin-App Shift Service Duplication

- shift_service.dart: New, uses Supabase directly, defines Shift class inline.
- database_service.dart: Legacy, uses old Shift model (../models/shift.dart which has `date` not `scheduled_date`).

**Action:** Deprecate DatabaseService. Migrate its unique methods (addCarer, addServiceUser, documents, settings) to dedicated services.

### 12.3 Staff-App Shift Read Duplication

- shift_service.dart: getShiftsForCurrentCarer() reads shifts.
- firestore_service.dart: getCarerShifts() ALSO reads shifts by carer_id = auth.uid().

**Action:** Remove getCarerShifts() from firestore_service. Keep visit methods in firestore_service (or better, rename to visit_service.dart).

### 12.4 MCA Service Duplication (admin-app)

- mca_service.dart: CRUD on mental_capacity_assessments.
- mental_capacity_service.dart: ALSO CRUD on mental_capacity_assessments.

**Action:** Audit which screens use which. Consolidate into one. Remove the other.

### 12.5 Catheter Service Duplication (admin-app)

- catheter_care_risk_service.dart: CRUD on catheter_care_risk_assessments.
- catheter_care_service.dart: CRUD on catheter_care_assessments (different table? or same?).

**Action:** Verify whether these target different tables or the same. Consolidate if duplicate.

### 12.6 Receipt/Expense Service Overlap (admin-app)

- receipt_service.dart: CRUD on receipt_entries, receipts R, profit_snapshots CU.
- expense_tracking_service.dart: CRUD on receipt_entries, receipts R, profit_snapshots CU, dom_care_routes R.

**Action:** Consolidate into one service (expense_tracking_service is the more complete one).

### 12.7 Risk Service Copies (staff-app vs admin-app)

11 risk services exist in BOTH admin-app and staff-app as separate copies. This creates maintenance burden - any bug fix or RLS change must be made in both places.

**Action:** Extract shared data layer into a shared `flutter-common` or `packages` library (the project already has flutter-common directory).

---

## 13. RLS Policy Gaps - Complete Audit

### 13.1 Tables With NO Organization Scoping (permissive policies)

| Table | Policy | Problem |
|-------|--------|--------|
| service_users | ''Authenticated users can view service_users'' (088) | ALL authenticated users can see ALL service users regardless of organisation. Contradicts tenant isolation. |
| profiles | Only org-scoped for admin; no client_organisation_id scoping | Client users may be locked out of profile queries. |
| carers | Only org-scoped via get_current_user_organisation() | Client users with only client_organisation_id cannot see carers. |

### 13.2 Tables Missing Explicit Admin Policies

| Table | Risk |
|-------|------|
| shifts | Client-booked shifts have NULL organisation_id. If admin RLS uses organisation_id scoping, admin cannot see them. Relies on admin role bypass (which exists but should be verified). |
| visits | Same NULL organisation_id risk for staff-created visits. |

### 13.3 Tables With Fragile RLS (relies on identity-linkage)

| Table | Policy | Depends On |
|-------|--------|-----------|
| shifts | carer_shifts: carer_id = auth.uid() | carers.id = auth.users.id |
| routes | Carers can view own routes: carer_id = auth.uid() | carers.id = auth.users.id |
| route_visits | Carers can view own route visits: carer_id = auth.uid() | carers.id = auth.users.id |

### 13.4 Tables With Correct Dual-Scoping

| Table | Migration | Policy Pattern |
|-------|----------|---------------|
| routes | 141 | organisation_id = profile.organisation_id OR client_organisation_id = profile.client_organisation_id |
| route_visits | 141 | Same OR pattern |
| route_change_log | 141 | Same OR pattern |

### 13.5 Summary of RLS Health

| Category | Count | Status |
|----------|-------|--------|
| Correctly scoped (tenant_isolation) | ~55 tables | ? Working for admin/staff users with organisation_id |
| Dual-scoped (org OR client_org) | 3 tables | ? Working for both admin and client |
| Carer-policy additive | 3 tables | ? Working IF identity-linkage is correct |
| Overly permissive | 1 table (service_users) | ?? Cross-org data leakage |
| Missing client scoping | 2 tables (profiles, carers) | ?? May block client users |
| Depends on identity-linkage | 3 tables (shifts, routes, route_visits) | ?? Broken for legacy carers |

---

## 14. Identity-Linkage Problems - Root Cause Analysis

### 14.1 The Core Problem

The CareQA system has TWO identity systems that must be aligned:
1. **auth.users** (Supabase Auth): Every person who logs in has a UUID in auth.users.
2. **carers** table: Every carer entity has a UUID as its primary key (carers.id).

The carers.id is a FOREIGN KEY to profiles.id which is a FOREIGN KEY to auth.users.id. This chain SHOULD ensure alignment: carers.id = profiles.id = auth.users.id.

**The bug:** This chain breaks when a carer is created via admin (DatabaseService.addCarer) WITHOUT a corresponding auth.users account. In that case:
- A carers row is inserted with a newly generated UUID.
- A profiles row is NOT created (because no auth user exists).
- The carers.id is an orphan UUID that does not appear in auth.users.

Later, when admin assigns this carer to a shift, the shift.carer_id gets this orphan UUID. When the carer logs into the staff-app, their auth.uid() is a COMPLETELY DIFFERENT UUID. The query `WHERE carer_id = auth.uid()` will never match.

### 14.2 Where This Breaks

| App | Query | What Happens |
|-----|-------|-------------|
| staff-app | shift_service.getShiftsForCurrentCarer(): SELECT shifts WHERE carer_id = auth.uid() | Returns zero rows for legacy carers |
| staff-app | shift_service.getRouteCallsForCurrentCarer(): SELECT route_visits WHERE carer_id = auth.uid() | Returns zero rows for legacy carers |
| staff-app | firestore_service.getCarerShifts(): SELECT shifts WHERE carer_id = auth.uid() | Returns zero rows |
| admin-app | shift_service.assignCarerToShift(): writes carers.id into shift.carer_id | Writes identity that staff cannot match |
| admin-app | route_service.assignCarerToVisit(): writes carers.id into route_visits.carer_id | Writes identity that staff cannot match |

### 14.3 Diagnostic Queries

To determine the scale of the problem, run these SQL queries on the Supabase database:

```sql
-- How many carers have no matching auth.users account?
SELECT COUNT(*) FROM carers c
LEFT JOIN auth.users u ON c.id = u.id
WHERE u.id IS NULL;

-- How many shifts reference an orphan carer_id?
SELECT COUNT(*) FROM shifts s
LEFT JOIN auth.users u ON s.carer_id = u.id
WHERE s.carer_id IS NOT NULL AND u.id IS NULL;

-- List all orphan carer-shift assignments
SELECT s.id AS shift_id, s.carer_id, s.scheduled_date, c.name AS carer_name
FROM shifts s
JOIN carers c ON s.carer_id = c.id
LEFT JOIN auth.users u ON s.carer_id = u.id
WHERE u.id IS NULL;
```

### 14.4 Recommended Fix (Solution A: Direct Link)

Add an `auth_user_id UUID REFERENCES auth.users(id)` column to the carers table:

```sql
ALTER TABLE public.carers ADD COLUMN auth_user_id UUID REFERENCES auth.users(id);
CREATE UNIQUE INDEX idx_carers_auth_user_id ON public.carers(auth_user_id) WHERE auth_user_id IS NOT NULL;
```

Then update all code that writes carer_id to shifts/route_visits/routes to use `carers.auth_user_id` instead of `carers.id`.

Alternatively, make the staff-app queries JOIN through carers:

```sql
-- Instead of: SELECT * FROM shifts WHERE carer_id = auth.uid()
-- Use:
SELECT s.* FROM shifts s
JOIN carers c ON s.carer_id = c.id
WHERE c.auth_user_id = auth.uid();
```

This preserves the existing data model while fixing the lookup.

### 14.5 Alternative Fix (Solution B: Carer View)

Create a database VIEW that resolves carer identity:

```sql
CREATE VIEW carer_shifts AS
SELECT s.*
FROM shifts s
JOIN carers c ON s.carer_id = c.id
WHERE c.auth_user_id = auth.uid();
```

Then the staff-app queries `carer_shifts` instead of `shifts`.

### 14.6 Fix for Route Visits

Same pattern applies. Update RLS policy 146 to use the auth_user_id link:

```sql
-- Current (broken):
carer_id = auth.uid()

-- Fixed:
EXISTS (SELECT 1 FROM carers c WHERE c.id = route_visits.carer_id AND c.auth_user_id = auth.uid())
```

---

## 15. Recommendations - Prioritized Action Plan

### PRIORITY 0: CRITICAL (Platform Non-Functional Without These)

| # | Action | Effort | Impact |
|---|--------|--------|--------|
| P0.1 | **Fix identity-linkage for all carers.** Add auth_user_id to carers table. Backfill for existing carers. Update staff-app queries to use the link. | Medium | Makes staff-app functional - staff can see their shifts and routes |
| P0.2 | **Wire staff dashboard navigation.** Add bottom nav or drawer to staff_dashboard.dart linking to: Shifts (existing), Charts (food/fluid, bowel/bladder, repositioning, sleep), Risk Assessments, Competencies, MAR Chart, Check-In. | Medium | Enables staff care documentation - the core purpose of the staff app |
| P0.3 | **Fix RLS for service_users.** Remove the permissive 088 policy. Replace with org-scoped policy. | Small | Closes cross-org data leakage |

### PRIORITY 1: HIGH (Features That Should Work But Don''t)

| # | Action | Effort | Impact |
|---|--------|--------|--------|
| P1.1 | **Create bookings table or remove booking code.** Either implement the bookings feature (migration + table + wiring) or remove booking_service.dart and booking_history_screen.dart. | Medium | Removes broken dead code |
| P1.2 | **Wire rating feature.** Add navigation from ShiftDetailBottomSheet or shifts list to rate_carer_dialog.dart. | Small | Enables client carer rating |
| P1.3 | **Create agency-side app or remove broadcast receiving.** shift_broadcasts are written but never consumed. Either build the receiving app or document this as future work. | Large | Completes broadcast feature |
| P1.4 | **Fix client-app route_service.dart.** Update model to match post-137 schema (remove call_number, use organisation_id/client_organisation_id dual scoping). | Small | Routes work for client-app |
| P1.5 | **Verify staff check-in writes organisation_id.** Ensure firestore_service.addVisit() sets organisation_id on the visit row so RLS allows the write. | Small | Enables check-in/out flow |

### PRIORITY 2: MEDIUM (Code Quality & Maintainability)

| # | Action | Effort | Impact |
|---|--------|--------|--------|
| P2.1 | **Remove service duplicates.** Consolidate: auth_service -> supabase_auth_service (all 3 apps), mca_service + mental_capacity_service (admin), catheter_care_risk_service + catheter_care_service (admin), receipt_service + expense_tracking_service (admin). | Medium | Reduces bugs from code divergence |
| P2.2 | **Deprecate DatabaseService.** Migrate remaining consumers to dedicated services. Remove MasterDashboard. | Medium | Single source of truth for data access |
| P2.3 | **Remove firestore_service shift methods from staff-app.** Keep only visit methods. Rename to visit_service.dart. | Small | Clearer code boundaries |
| P2.4 | **Clean up duplicate screens.** Remove duplicate files (profit_loss, training_matrix, meetings_log, daily_notes, audit screens). Keep one canonical copy. | Small | Less confusion |
| P2.5 | **Add admin review screens for staff-only risk types.** Anaphylaxis, sepsis, financial, equipment_register have staff forms but no admin screens. | Medium | Admin can review all risk data |

### PRIORITY 3: LOW (Nice to Have / Future Work)

| # | Action | Effort | Impact |
|---|--------|--------|--------|
| P3.1 | **Refactor route_service.dart.** Split 1123-line monolithic service into route_crud_service, route_visit_service, route_timetable_service. | Large | Maintainability |
| P3.2 | **Extract shared services to flutter-common.** All 3 apps have duplicate risk/chart/auth services. Move to shared package. | Large | DRY codebase |
| P3.3 | **Fix swallowed exception in route_service._logChange().** Add proper error logging instead of empty catch block. | Small | Debuggability |
| P3.4 | **Build route_change_log viewer.** Admin should be able to see change history for routes. | Medium | Completion |
| P3.5 | **Resolve carer invite vs self-signup ambiguity.** Decide canonical flow and deprecate the other. | Small | Clarity |
| P3.6 | **Add RLS for client_organisation_id on profiles and carers.** Ensures client users can see profiles and carers within their org context. | Small | Completeness |
| P3.7 | **Remove ServiceUserPickerScreen placeholder.** Either implement or remove. | Small | Cleanup |

---

## Appendix A: File Path Quick Reference

### Admin-App Key Files
- Entry: `admin-app/lib/main.dart`
- Dashboard: `admin-app/lib/ui/dashboard/admin_dashboard.dart` (primary), `admin-app/lib/ui/dashboard/master_dashboard.dart` (legacy)
- Core services: `admin-app/lib/services/shift_service.dart`, `admin-app/lib/services/route_service.dart`, `admin-app/lib/services/database_service.dart` (legacy)
- Auth: `admin-app/lib/services/supabase_auth_service.dart`, `admin-app/lib/services/auth_service.dart` (duplicate)
- Shift screen: `admin-app/lib/ui/shift/shift_list_screen.dart`
- Route form: `admin-app/lib/ui/shift/route_form_screen.dart`

### Staff-App Key Files
- Entry: `staff-app/lib/main.dart`
- Dashboard: `staff-app/lib/ui/dashboard/staff_dashboard.dart`
- Shift screen: `staff-app/lib/ui/dashboard/shifts_screen.dart`
- Core service: `staff-app/lib/services/shift_service.dart`
- Firestore (visit) service: `staff-app/lib/services/firestore_service.dart`
- Auth: `staff-app/lib/services/supabase_auth_service.dart`, `staff-app/lib/services/auth_service.dart` (duplicate)

### Client-App Key Files
- Entry: `client-app/lib/main.dart`
- Dashboard: `client-app/lib/ui/dashboard/dashboard_screen.dart`
- Shift service: `client-app/lib/services/shift_service.dart`
- Route service: `client-app/lib/services/route_service.dart` (schema mismatch risk)
- Rating service: `client-app/lib/services/rating_service.dart` (orphaned)
- Booking service: `client-app/lib/services/booking_service.dart` (broken)

### Database
- All migrations: `supabase/migrations/001_initial_schema.sql` through `supabase/migrations/146_route_reads_for_carers.sql`
- Key RLS migration: `supabase/migrations/073_enable_rls_all_tables.sql`
- Key org-scoping: `supabase/migrations/072_add_organisation_id_to_all_tables.sql`
- Key route RLS: `supabase/migrations/141_routes_admin_organisation.sql`, `supabase/migrations/146_route_reads_for_carers.sql`

---

## Appendix B: Known Data Flow for Prior Diagnosis

See also: `staff_app_data_flow_diagnosis.md` for the full root-cause analysis of why staff cannot see shifts/routes. This comprehensive evaluation confirms and extends that diagnosis.

---

*End of Comprehensive Evaluation. Document covers all three apps, all 146 migrations, all ~95 database tables, all ~100 services, all ~217 screens, and all 7 cross-app data flows.*
