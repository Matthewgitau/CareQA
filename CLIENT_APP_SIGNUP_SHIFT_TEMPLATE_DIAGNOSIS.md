# Client-App Signup & Shift Template Data Flow - Diagnosis Report

**Date:** 2026-08-03  
**Audience:** Developer with NO prior access to the codebase  
**Purpose:** Explain the 406 error, how signup data flows to shift templates, and provide precise diagnosis + fixes.

---

## Table of Contents
1. [The 406 Error - Root Cause](#1-the-406-error---root-cause)
2. [How Signup Data Flows to Shift Templates](#2-how-signup-data-flows-to-shift-templates)
3. [The Tables Involved](#3-the-tables-involved)
4. [Where the Data is Written vs Where it's Read](#4-where-the-data-is-written-vs-where-its-read)
5. [The Mismatch - Why "Organisation Not Found" Persists](#5-the-mismatch---why-organisation-not-found-persists)
6. [Precise Fixes](#6-precise-fixes)
7. [Code Reference](#7-code-reference)

---

## 1. The 406 Error - Root Cause

### The Error
```
GET https://aucflsskbhaloutsdlwc.supabase.co/rest/v1/profiles?select=role%2Corg…ion_id%2Cclient_organisation_id&id=eq.5db831cf-a895-487f-b8fc-2fa4293b4554 406 (Not Acceptable)
```

### What This Means
The URL decodes to:
```
GET /rest/v1/profiles?select=role,organisation_id,client_organisation_id&id=eq.5db831cf-a895-487f-b8fc-2fa4293b4554
```

**HTTP 406 Not Acceptable** from Supabase's PostgREST means: **one of the columns in the `select` clause does not exist in the `profiles` table.**

### The Specific Problem
The query requests `client_organisation_id` from the `profiles` table. **If this column does not exist**, PostgREST returns 406 instead of a normal error.

### The Code That Causes It
In `client-app/lib/services/supabase_auth_service.dart`, the `_loadUserProfile()` method:

```dart
final profile = await _supabase
    .from('profiles')
    .select('role, organisation_id, client_organisation_id')  // ← client_organisation_id may not exist
    .eq('id', _currentUser!.id)
    .single();
```

### How to Verify
Run this in Supabase SQL Editor:
```sql
SELECT column_name FROM information_schema.columns 
WHERE table_name = 'profiles' 
ORDER BY ordinal_position;
```

If `client_organisation_id` is NOT in the list, that's the cause.

---

## 2. How Signup Data Flows to Shift Templates

### The Intended Flow

```
[Signup Form]
    │  User enters: org_name, org_type, org_address, org_phone
    ▼
[signUpAsClient() in supabase_auth_service.dart]
    │  Packs into data metadata
    ▼
[POST /auth/v1/signup]
    │  Supabase creates auth user
    ▼
[Database Trigger: handle_new_client_signup()]
    │  Reads raw_user_meta_data
    │  Creates client_organisations record
    │  Creates profiles record (role='client', client_organisation_id)
    ▼
[Login]
    │  _loadUserProfile() reads profiles
    ▼
[Dashboard]
    │  Uses organisationId from auth service
    ▼
[Shift Templates Screen]
    │  ShiftTemplateService.getTemplates(organisationId)
    ▼
[shift_templates table]
```

### The Key Question: Is the data written to the same place it's read from?

**NO - this is the core problem.**

| Data Written To (by trigger) | Data Read From (by shift templates) |
|------------------------------|--------------------------------------|
| `client_organisations` table | `shift_templates` table |
| `profiles.client_organisation_id` | `shift_templates.organisation_id` |

The trigger writes the org ID to `profiles.client_organisation_id`, but the shift template service reads `shift_templates.organisation_id` using `auth.organisationId` (which comes from `profiles.organisation_id`).

---

## 3. The Tables Involved

### `client_organisations` (written by trigger)
```sql
client_organisations (
  id UUID PRIMARY KEY,           -- The org ID
  name TEXT NOT NULL,            -- "Sunshine Care Home"
  organisation_types JSONB,      -- ["Care Home"]
  address TEXT,
  phone TEXT,
  email TEXT,
  is_active BOOLEAN DEFAULT true
)
```

### `profiles` (written by trigger, read by auth)
```sql
profiles (
  id UUID PRIMARY KEY,           -- = auth.users.id
  email TEXT,
  full_name TEXT,
  name TEXT,
  role TEXT,                     -- 'client'
  client_organisation_id UUID,   -- ← Written by trigger
  organisation_id UUID,          -- ← Also written by trigger (same value)
  is_active BOOLEAN
)
```

### `shift_templates` (read by shift template screen)
```sql
shift_templates (
  id UUID PRIMARY KEY,
  organisation_id UUID,          -- ← Read by ShiftTemplateService
  name TEXT,
  code TEXT,
  start_time TIME,
  end_time TIME,
  is_active BOOLEAN
)
```

---

## 4. Where the Data is Written vs Where it's Read

### The Trigger Writes (Step 1 SQL you ran):
```sql
INSERT INTO public.profiles (
  id, email, full_name, name, role, 
  client_organisation_id, organisation_id, is_active
)
VALUES (
  NEW.id, NEW.email, user_full_name, user_full_name,
  'client', new_org_id, new_org_id, true
);
```
- Writes `client_organisation_id` = new_org_id
- Writes `organisation_id` = new_org_id (same value)

### The Auth Service Reads:
```dart
final profile = await _supabase
    .from('profiles')
    .select('role, organisation_id, client_organisation_id')  // ← 406 if column missing
    .eq('id', _currentUser!.id)
    .single();
```

### The Shift Template Service Reads:
```dart
final response = await _client
    .from('shift_templates')
    .select()
    .eq('organisation_id', organisationId)  // ← Uses auth.organisationId
    .eq('is_active', true)
    .order('name', ascending: true);
```

### The Shift Template Screen Gets the Org ID:
```dart
final auth = context.read<SupabaseAuthService>();
final orgId = auth.organisationId;  // ← From profiles.organisation_id
```

---

## 5. The Mismatch - Why "Organisation Not Found" Persists

### Problem 1: `client_organisation_id` column may not exist in `profiles`

The auth service queries `client_organisation_id` but if the column was never added to the `profiles` table, PostgREST returns **406 Not Acceptable**. This causes `_loadUserProfile()` to throw, which triggers the auth guard to sign the user out.

**Fix:**
```sql
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS client_organisation_id UUID;
```

### Problem 2: The trigger may not have run

If the trigger `handle_new_client_signup()` was never created (or was dropped), the signup creates the auth user but NO `client_organisations` or `profiles` records. The user then can't log in properly.

**Fix:** Run the Step 1 SQL again to create the trigger.

### Problem 3: `organisation_id` vs `client_organisation_id` confusion

The shift template service uses `auth.organisationId` which comes from `profiles.organisation_id`. But the trigger writes the org ID to BOTH `organisation_id` AND `client_organisation_id`. If the trigger only wrote to `client_organisation_id` (older version), then `organisation_id` would be null, and shift templates would find nothing.

**Fix:** Ensure the trigger writes to BOTH columns (the Step 1 SQL you ran does this correctly).

### Problem 4: The `shift_templates` table may not exist

If the `shift_templates` table was never created, the ShiftTemplateService will throw "Failed to load shift templates".

**Fix:**
```sql
CREATE TABLE IF NOT EXISTS shift_templates (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organisation_id UUID REFERENCES organisations(id),
  name TEXT NOT NULL,
  code TEXT NOT NULL,
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## 6. Precise Fixes

### Fix 1: Add the missing column (MOST LIKELY FIX for 406)
```sql
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS client_organisation_id UUID;
```

### Fix 2: Verify the trigger exists
```sql
SELECT tgname FROM pg_trigger WHERE tgname = 'on_auth_user_created_client';
```
If empty, re-run the Step 1 SQL.

### Fix 3: Verify the shift_templates table exists
```sql
SELECT * FROM shift_templates LIMIT 1;
```
If error, create the table.

### Fix 4: Test the profile query manually
```sql
SELECT role, organisation_id, client_organisation_id
FROM profiles
WHERE id = '5db831cf-a895-487f-b8fc-2fa4293b4554';
```
If this errors, the column is missing. If it returns nulls, the trigger didn't populate it.

---

## 7. Code Reference

### The Auth Service Query (causes 406 if column missing)
```dart
// client-app/lib/services/supabase_auth_service.dart
final profile = await _supabase
    .from('profiles')
    .select('role, organisation_id, client_organisation_id')
    .eq('id', _currentUser!.id)
    .single();
```

### The Shift Template Service Query (reads organisation_id)
```dart
// client-app/lib/services/shift_template_service.dart
final response = await _client
    .from('shift_templates')
    .select()
    .eq('organisation_id', organisationId)
    .eq('is_active', true)
    .order('name', ascending: true);
```

### The Shift Template Screen (gets org ID from auth)
```dart
// client-app/lib/ui/shifts/shift_templates_screen.dart
final auth = context.read<SupabaseAuthService>();
final orgId = auth.organisationId;
if (orgId != null && orgId.isNotEmpty) {
  final templates = await _templateService.getTemplates(orgId);
}
```

### The Trigger (writes both org columns)
```sql
INSERT INTO public.profiles (
  id, email, full_name, name, role, 
  client_organisation_id, organisation_id, is_active
)
VALUES (
  NEW.id, NEW.email, user_full_name, user_full_name,
  'client', new_org_id, new_org_id, true
)
ON CONFLICT (id) DO UPDATE SET
  role = 'client',
  client_organisation_id = EXCLUDED.client_organisation_id,
  organisation_id = EXCLUDED.organisation_id,
  full_name = COALESCE(EXCLUDED.full_name, profiles.full_name),
  name = COALESCE(EXCLUDED.name, profiles.name),
  is_active = true;
```

---

## Summary

| Issue | Cause | Fix |
|-------|-------|-----|
| 406 Not Acceptable | `client_organisation_id` column missing from `profiles` | `ALTER TABLE profiles ADD COLUMN IF NOT EXISTS client_organisation_id UUID;` |
| Organisation not found | Trigger not run OR org_id null | Re-run Step 1 SQL |
| Shift templates empty | `shift_templates` table missing OR wrong org_id | Create table + verify org_id |
| Data written vs read mismatch | Trigger writes `client_organisation_id`, service reads `organisation_id` | Ensure trigger writes BOTH columns |