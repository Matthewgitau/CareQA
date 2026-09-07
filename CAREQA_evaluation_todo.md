# CareQA — Complete System Evaluation: TODO Master List

## Purpose
This document enumerates every file, table, migration, service, screen, and data-flow pathway that must be addressed in the comprehensive evaluation. For each item, we answer a standard set of questions (see §Q) to ensure no gap goes unnoticed.

## Standard Question Set (§Q)
For every file / table / service / screen / flow, answer:
1. **Scenario**: What concrete business / regulatory scenario does this serve?
2. **CRUD Table Mapping**: Which database table(s) does it read/write/update/delete?
3. **RLS Policy**: What RLS policies govern access to those tables? Are they correct/complete?
4. **Endpoint / Service Mapping**: Which service method (exact function name) drives this? Is the endpoint live?
5. **Cross-App Visibility**: Which apps consume this data? (admin-app / staff-app / client-app)
6. **Bottleneck / Failure Point**: What can break? (missing table, wrong column, identity-linkage, policy gap, no inbound nav)
7. **Utility Assessment**: Does this serve a real purpose? Is it overwritten/duplicated elsewhere? Is it dead/orphaned/dummy?
8. **Page Wired Check**: Is the screen reachable from navigation? If not, is there a plan to wire it?
9. **Recommendation**: What should be done? (keep, wire, fix, remove, migrate, document)

## Breakdown by Domain

### A. DATABASE TABLES (from migrations 001-146, 95+ tables)
Full inventory of every table, its migration origin, RLS status, and which apps/services touch it.

### B. ADMIN-APP SERVICES (67 files)
Every service with table mappings, duplicate checks, live/broken status.

### C. STAFF-APP SERVICES (24 files)
Every service, with special attention to shift_service and firestore_service duplicates.

### D. CLIENT-APP SERVICES (11 files)
Every service, including broken booking_service referencing non-existent bookings table.

### E. ADMIN-APP SCREENS (~160 screens)
Navigation audit: which are wired, which are orphaned, which use legacy vs new services.

### F. STAFF-APP SCREENS (~40 screens)
Navigation audit: are daily chart forms, risk forms, competency forms, and MAR chart reachable from the staff dashboard?

### G. CLIENT-APP SCREENS (17 screens)
5 orphaned screens identified: booking_history, booking_diary, shift_list, staff_profile, rate_carer_dialog.

### H. CROSS-APP DATA FLOWS (7 flows)
shift lifecycle, route lifecycle, care delivery loop, broadcast, check-in, rating, carer invite.

### I. MIGRATION INVENTORY (146 migrations)
Each assessed for idempotency, RLS correctness, and whether it's consumed by any app.