# Client-App Architecture & Data Flow Report

**Date:** 2026-07-30  
**Purpose:** Comprehensive handoff for developer familiar with the CareQA project  
**Covers:** Schema relationships, data flow, current capabilities, missing features

---

## Table of Contents
1. [Database Schema Overview](#1-database-schema-overview)
2. [The `client_organisation` Table](#2-the-client_organisation-table)
3. [Data Flow - Where the App Looks for Data](#3-data-flow---where-the-app-looks-for-data)
4. [Schema Mismatches - What's Broken](#4-schema-mismatches---whats-broken)
5. [Current Capabilities](#5-current-capabilities)
6. [Missing Features](#6-missing-features)
7. [Service Provider List (SPL) - How It Should Work](#7-service-provider-list-spl---how-it-should-work)
8. [Code Examples](#8-code-examples)
9. [Summary of Required Changes](#9-summary-of-required-changes)

---

## 1. Database Schema Overview

### Two Organisation Systems

There are TWO separate organisation systems in the database:

#### `public.organisations` (Admin-App)
Used by the admin-app for care staff agencies / care homes that manage staff.

```sql
CREATE TABLE organisations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  subscription_tier TEXT DEFAULT 'trial',
  settings JSONB DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### `public.client_organisation` (Client-App)
Used by the client-app for care home clients who book shifts.

```sql
CREATE TABLE client_organisation (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organisation_id UUID,          -- References the admin-app organisation (the service provider)
  name TEXT NOT NULL,
  address TEXT,
  email TEXT,
  phone TEXT,
  organisation_types JSONB DEFAULT '[]',  -- Types of care provided
  billing_rate_per_hour NUMERIC,
  shift_types JSONB DEFAULT '[]',         -- Types of shifts offered
  associated_contacts JSONB DEFAULT '[]', -- Contact people at the client organisation
  size TEXT,                              -- Organization size
  notes TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### Intended Use of `client_organisation`

The `client_organisation` table represents **care homes / care facilities that need staff**. They are the "customers" of the admin-app's organisations (staff agencies).

**Key relationships:**
- `client_organisation.organisation_id` → `public.organisations.id` (the service provider / staff agency)
- Each `client_organisation` can have an **SPL (Service Provider List)** of up to 250 service providers
- Service providers are `public.organisations` that this client can book staff from

---

## 2. The `client_organisation` Table

### Column-by-Column Breakdown

| Column | Type | Purpose | Status |
|--------|------|---------|--------|
| `id` | UUID | Primary key | ✅ |
| `organisation_id` | UUID | Links to the admin-app organisation (service provider) | ✅ |
| `name` | TEXT | Care home name | ✅ |
| `address` | TEXT | Physical address | ✅ |
| `email` | TEXT | Contact email | ✅ |
| `phone` | TEXT | Contact phone | ✅ |
| `organisation_types` | JSONB | Types of care (e.g., residential, nursing, dementia) | ✅ |
| `billing_rate_per_hour` | NUMERIC | Default hourly rate | ✅ |
| `shift_types` | JSONB | Shift types offered (e.g., day, night, weekend) | ✅ |
| `associated_contacts` | JSONB | Contact people at the organisation | ✅ |
| `size` | TEXT | Organisation size category | ✅ |
| `notes` | TEXT | Free text notes | ✅ |
| `is_active` | BOOLEAN | Soft delete / active flag | ✅ |
| `created_at` | TIMESTAMPTZ | Auto timestamp | ✅ |
| `updated_at` | TIMESTAMPTZ | Auto timestamp | ✅ |

### SPL (Service Provider List) Design

The `associated_contacts` field could be repurposed or a new table created for the SPL:

```sql
-- Proposed SPL table (does not exist yet)
CREATE TABLE client_organisation_spl (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  client_org_id UUID REFERENCES client_organisation(id),
  service_provider_id UUID REFERENCES organisations(id),
  contract_rate NUMERIC,           -- Negotiated rate with this provider
  is_preferred BOOLEAN DEFAULT FALSE,
  max_bookings_per_day INTEGER DEFAULT 10,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## 3. Data Flow - Where the App Looks for Data

### 3.1 Shift Service (`client-app/lib/services/shift_service.dart`)

**Queries:** `shifts` table  
**Filter:** `client_organisation_id`  
**Order:** `shift_date` ascending  

```dart
// Current code - what it expects:
final response = await _client
    .from('shifts')
    .select()
    .eq('client_organisation_id', organisationId)  // ← COLUMN DOESN'T EXIST
    .order('shift_date', ascending: true);           // ← COLUMN IS 'scheduled_date'
```

**Expected schema (by the code):**
```sql
shifts (
  id UUID,
  client_organisation_id UUID,  -- ← DOES NOT EXIST in DB
  location TEXT,                 -- ← DOES NOT EXIST
  shift_date DATE,               -- ← DB has 'scheduled_date'
  start_time TIME,
  end_time TIME,
  staff_required INTEGER,        -- ← DOES NOT EXIST
  staff_type TEXT,               -- ← DOES NOT EXIST
  status TEXT,
  notes TEXT,
  organisation_id UUID           -- ← DB has 'carer_id' and 'service_user_id'
)
```

**Actual DB schema (from `001_initial_schema.sql`):**
```sql
shifts (
  id UUID PRIMARY KEY,
  service_user_id UUID REFERENCES service_users(id),
  carer_id UUID REFERENCES carers(id) ON DELETE SET NULL,
  scheduled_date DATE NOT NULL,   -- ← Code expects 'shift_date'
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  status TEXT DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'in_progress', 'completed', 'cancelled')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
)
```

### 3.2 Booking Service (`client-app/lib/services/booking_service.dart`)

**Queries:** `bookings` table  
**Filter:** `client_organisation_id`  

```dart
// Current code - what it expects:
final response = await _client
    .from('bookings')
    .select()
    .eq('client_organisation_id', organisationId)  // ← TABLE MAY NOT EXIST
    .order('created_at', ascending: false);
```

**Expected schema (by the code):**
```sql
bookings (
  id UUID,
  client_organisation_id UUID,  -- References client_organisation
  shift_id UUID,                -- References shifts
  user_id UUID,                 -- References profiles (the client user who booked)
  status TEXT,
  created_at TIMESTAMPTZ
)
```

**Actual DB:** The `bookings` table **does not exist** in the migrations. It needs to be created.

### 3.3 Staff Service (`client-app/lib/services/staff_service.dart`)

**Queries:** `profiles` table  
**Filter:** `organisation_id` + `role = 'staff'`  

```dart
// Current code:
final response = await _client
    .from('profiles')
    .select()
    .eq('organisation_id', organisationId)  // ← Uses profiles.organisation_id
    .eq('role', 'staff');                    // ← 'staff' role doesn't exist
```

**Issues:**
- `profiles` has `role IN ('admin', 'carer', 'client')` - no `'staff'` role
- Staff members are in `carers` table, not `profiles`
- The `organisation_id` column exists in `profiles` (added by migration 028)

### 3.4 Timesheet Service (`client-app/lib/services/timesheet_service.dart`)

```dart
final response = await _client
    .from('visits')
    .select()
    .eq('organisation_id', organisationId)  // ← visits has no organisation_id
    .order('check_in_time', ascending: false);
```

**Issues:**
- `visits` table has `carer_id`, `shift_id` - no `organisation_id`
- The service is looking for data in the wrong table with wrong column names

### 3.5 Auth Service (`client-app/lib/services/supabase_auth_service.dart`)

**Queries:** `profiles` table  
**Filter:** `id = currentUser.id`  

```dart
final profile = await _supabase
    .from('profiles')
    .select('role, organisation_id')
    .eq('id', _currentUser!.id)
    .single();
```

**This is correct** ✅ - `profiles` table has `id`, `role`, and `organisation_id`.

---

## 4. Schema Mismatches - What's Broken

### Issue 1: `shifts` Table - Column Name Mismatch

| Expected by Code | Actual in DB | Fix |
|-----------------|--------------|-----|
| `shift_date` | `scheduled_date` | Rename or use alias |
| `client_organisation_id` | Doesn't exist | Add column to shifts table |
| `location` | Doesn't exist | Add column to shifts table |
| `staff_required` | Doesn't exist | Add column to shifts table |
| `staff_type` | Doesn't exist | Add column to shifts table |
| `organisation_id` | Doesn't exist (has `carer_id`, `service_user_id`) | Add column |

### Issue 2: `bookings` Table Does Not Exist

**Fix:** Create migration to add the `bookings` table.

### Issue 3: `StaffService` Looks at Wrong Table

**Fix:** Query `carers` table instead of `profiles`, or create a view.

### Issue 4: `visits` Table Missing `organisation_id`

**Fix:** Add `organisation_id` to visits, or join through shifts.

---

## 5. Current Capabilities

### What Already Works

| Feature | Status | Details |
|---------|--------|---------|
| Supabase initialization | ✅ | `.env` loaded with fallback credentials |
| Auth (login/logout) | ✅ | Email/password + magic link via `SupabaseAuthService` |
| Auth state management | ✅ | `AuthWrapper` with `StreamBuilder` checks auth state |
| Profile loading | ✅ | `_loadUserProfile()` fetches role + organisation_id |
| Dashboard screen | ✅ | Navigation tiles for shifts, bookings, timesheet, staff |
| Shift list screen | ✅ | UI exists, but data source is broken |
| Booking history screen | ✅ | UI exists, but data source is broken |
| Shift register screen | ✅ | UI exists, but data source is broken |
| Staff directory screen | ✅ | UI exists, but data source is broken |

### What's Half-Working

| Feature | Status | Issue |
|---------|--------|-------|
| Shift listing | 🔶 Broken | Queries wrong columns (`shift_date` vs `scheduled_date`) |
| Booking history | 🔶 Broken | `bookings` table doesn't exist |
| Staff directory | 🔶 Broken | Queries `profiles` with `role = 'staff'` which doesn't exist |
| Timesheet/visits | 🔶 Broken | Queries `visits` with wrong column names |

---

## 6. Missing Features

### Critical Database Migrations Needed

| Migration | Purpose | Priority |
|-----------|---------|----------|
| `117_create_bookings_table.sql` | Create `bookings` table for client shift bookings | 🔴 HIGH |
| `118_add_client_columns_to_shifts.sql` | Add `client_organisation_id`, `location`, `staff_required`, `staff_type` to shifts | 🔴 HIGH |
| `119_create_client_organisation_spl.sql` | Create SPL table for service provider list | 🔴 HIGH |
| `120_add_organisation_id_to_visits.sql` | Add `organisation_id` to visits table | 🟡 MEDIUM |
| `121_add_client_views.sql` | Create views for client-app data access | 🟡 MEDIUM |

### Critical App Code Changes Needed

| Change | File | Priority |
|--------|------|----------|
| Fix Shift model columns | `models/shift.dart` | 🔴 HIGH |
| Fix ShiftService queries | `services/shift_service.dart` | 🔴 HIGH |
| Fix BookingService to use correct table | `services/booking_service.dart` | 🔴 HIGH |
| Fix StaffService to query carers | `services/staff_service.dart` | 🔴 HIGH |
| Fix TimesheetService queries | `services/timesheet_service.dart` | 🟡 MEDIUM |
| Add client_user_id to ProfileService | `services/profile_service.dart` | 🟡 MEDIUM |

### Feature Gaps

| Feature | Missing | Impact |
|---------|---------|--------|
| Service Provider List (SPL) | No table exists | Can't link client_org to service providers |
| Shift booking flow | `bookings` table doesn't exist | Can't book shifts |
| Staff ratings | No `staff_ratings` table for client ratings | Can't rate staff |
| Notifications | No push notification integration | No real-time updates |
| Invoice viewing | No invoice data for client-app | Can't view bills |
| Service user management | No way for client to manage their residents | Basic CRUD missing |

---

## 7. Service Provider List (SPL) - How It Should Work

### Concept

Each `client_organisation` can have a list of up to 250 **service providers** (which are `public.organisations`). These are the staff agencies that the client can book staff from.

### Proposed Data Model

```sql
-- Service Provider List
CREATE TABLE client_organisation_spl (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  client_org_id UUID NOT NULL REFERENCES client_organisation(id),
  service_provider_id UUID NOT NULL REFERENCES organisations(id),
  contract_rate NUMERIC(10,2),       -- Negotiated hourly rate
  is_preferred BOOLEAN DEFAULT FALSE,  -- Preferred provider
  max_bookings_per_day INTEGER DEFAULT 10,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'suspended', 'terminated')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(client_org_id, service_provider_id)
);
```

### How SPL Links to Shifts

```
client_organisation (client/care home)
        │
        ├── has SPL ──→ organisations (service providers/staff agencies)
        │                       │
        │                       └── has carers (staff members)
        │
        └── requests shift ──→ shifts.shift_type = client_org.shift_types
                                shifts.location = client_org.address
                                shifts.client_organisation_id = client_org.id
```

### How the App Should Use SPL

1. **Client logs in** → gets their `client_organisation` profile
2. **Client views shifts** → sees shifts filtered by their `client_organisation_id`
3. **Client books a shift** → creates a `booking` linked to their `client_organisation_id`
4. **Staff agency receives booking** → sees the booking in admin-app
5. **Staff agency assigns a carer** → updates `shifts.carer_id` with the assigned carer

---

## 8. Code Examples

### 8.1 How Shifts Data Should Be Queried (Fixed)

```dart
// FIXED shift_service.dart
Future<List<Shift>> getShifts(String clientOrganisationId) async {
  final response = await _client
      .from('shifts')
      .select('''
        id,
        client_organisation_id,
        service_user_id,
        carer_id,
        scheduled_date,
        start_time,
        end_time,
        status,
        location,
        staff_required,
        staff_type,
        organisation_id
      ''')
      .eq('client_organisation_id', clientOrganisationId)
      .order('scheduled_date', ascending: true);

  return (response as List)
      .map((json) => Shift.fromJson(json as Map<String, dynamic>))
      .toList();
}
```

### 8.2 How Bookings Should Work (New)

```dart
// FIXED booking_service.dart
class BookingService {
  final SupabaseClient _client = SupabaseManager.instance.client;

  Future<Booking> bookShift({
    required String shiftId,
    required String clientUserId,
    required String clientOrgId,
  }) async {
    final response = await _client
        .from('bookings')
        .insert({
          'shift_id': shiftId,
          'client_user_id': clientUserId,
          'client_organisation_id': clientOrgId,
          'status': 'requested',
          'created_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();

    return Booking.fromJson(response as Map<String, dynamic>);
  }
}
```

### 8.3 How Staff Should Be Queried (Fixed)

```dart
// FIXED staff_service.dart - queries carers table, not profiles
Future<List<StaffMember>> getStaffMembers(String organisationId) async {
  final response = await _client
      .from('carers')
      .select('''
        id,
        employee_number,
        is_active
      ''')
      .eq('is_active', true);

  // Join with profiles to get names
  // Or use a database view that joins carers + profiles
  return (response as List)
      .map((json) => StaffMember.fromJson(json as Map<String, dynamic>))
      .toList();
}
```

### 8.4 How SPL Query Should Work (New)

```dart
// NEW: Service Provider List service
class SplService {
  final SupabaseClient _client = SupabaseManager.instance.client;

  Future<List<Organisation>> getServiceProviders(String clientOrgId) async {
    final response = await _client
        .from('client_organisation_spl')
        .select('''
          id,
          contract_rate,
          is_preferred,
          service_provider:organisations!inner (
            id,
            name,
            subscription_tier
          )
        ''')
        .eq('client_org_id', clientOrgId)
        .eq('status', 'active');

    return (response as List)
        .map((json) => Organisation.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
```

### 8.5 Current Auth Flow (Working)

```dart
// supabase_auth_service.dart - THIS WORKS
class SupabaseAuthService extends ChangeNotifier {
  final SupabaseClient _supabase;

  SupabaseAuthService(this._supabase) {
    // Listen for auth state changes
    _supabase.auth.onAuthStateChange.listen((data) {
      _currentUser = data.session?.user;
      if (_currentUser != null) {
        _loadUserProfile();  // Fetches role + organisation_id from profiles
      }
      notifyListeners();
    });
  }

  Future<AuthResult> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    // On success, _loadUserProfile() is called by the auth listener
    // _loadUserProfile queries: profiles(id, role, organisation_id)
    // This correctly gets the user's role and org
  }
}
```

---

## 9. Summary of Required Changes

### Database Migrations to Create

| # | Migration | File | Status |
|---|-----------|------|--------|
| 1 | Add columns to `shifts` table | `117_add_shift_columns.sql` | ❌ Missing |
| 2 | Create `bookings` table | `118_create_bookings_table.sql` | ❌ Missing |
| 3 | Create `client_organisation_spl` table | `119_create_spl_table.sql` | ❌ Missing |
| 4 | Add `organisation_id` to `visits` | `120_add_org_to_visits.sql` | ❌ Missing |
| 5 | Create client-app views | `121_create_client_views.sql` | ❌ Missing |

### App Code Changes

| # | File | Change | Status |
|---|------|--------|--------|
| 1 | `models/shift.dart` | Fix column names to match DB | ❌ Broken |
| 2 | `services/shift_service.dart` | Fix query column names | ❌ Broken |
| 3 | `services/booking_service.dart` | Fix to use correct DB schema | ❌ Broken |
| 4 | `services/staff_service.dart` | Query `carers` not `profiles` | ❌ Broken |
| 5 | `services/timesheet_service.dart` | Fix to use correct DB schema | ❌ Broken |
| 6 | `main.dart` | Fixed - has fallback credentials | ✅ Fixed |
| 7 | `services/supabase_auth_service.dart` | Working correctly | ✅ Working |
| 8 | `ui/auth/auth_wrapper.dart` | Working correctly | ✅ Working |
| 9 | `ui/auth/login_screen.dart` | Working correctly | ✅ Working |

### UI Screens Status

| Screen | File | Status |
|--------|------|--------|
| Login Screen | `ui/auth/login_screen.dart` | ✅ Working |
| Dashboard | `ui/dashboard/dashboard_screen.dart` | ✅ Working |
| Shift List | `ui/shifts/shift_list_screen.dart` | 🔶 UI exists, data broken |
| Shift Register | `ui/shifts/shift_register_screen.dart` | 🔶 UI exists, data broken |
| Booking History | `ui/bookings/booking_history_screen.dart` | 🔶 UI exists, data broken |
| Staff Directory | `ui/staff/staff_directory_screen.dart` | ❓ May not exist |
| Staff Rating | `ui/staff/staff_rating_screen.dart` | ❓ May not exist |
| Booking Shift | `ui/shifts/book_shift_screen.dart` | ❓ May not exist |

---

## 10. Quick Reference: All Tables the Client-App Interacts With

| Table | Used By | Current Status | Correctness |
|-------|---------|---------------|-------------|
| `profiles` | Auth, StaffService | Queries for role + org_id | ✅ Correct |
| `client_organisation` | Should be used for org data | Not queried by any service | ❌ Missing |
| `shifts` | ShiftService | Queries wrong columns | ❌ Broken |
| `bookings` | BookingService | Table doesn't exist | ❌ Missing |
| `carers` | Should be used for staff | Not queried | ❌ Missing |
| `visits` | TimesheetService | Queries wrong columns | ❌ Broken |
| `client_organisation_spl` | Should be used for SPL | Table doesn't exist | ❌ Missing |
| `organisations` | Should be used for SPL providers | Not queried | ❌ Missing |

---

## 11. Next Steps

### Immediate Priority
1. **Fix Shift model** to match actual DB schema (`scheduled_date` not `shift_date`)
2. **Add migration** to add `client_organisation_id` column to `shifts` table
3. **Create migration** for `bookings` table
4. **Fix ShiftService** queries to use correct column names
5. **Fix BookingService** to use correct DB schema

### Medium Priority
1. **Create SPL table** migration
2. **Fix StaffService** to query `carers` table
3. **Fix TimesheetService** to use correct column names
4. **Add `organisation_id`** to `visits` table
5. **Create database views** for client-app data access

### Low Priority
1. Staff rating feature
2. Push notifications
3. Invoice viewing
4. Service user management (CRUD for residents)