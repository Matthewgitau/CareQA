# Client-App Signup 500 Error - Root Cause & Correct Sequence Report

**Date:** 2026-08-05  
**Audience:** Developer with NO prior access to the codebase  
**Purpose:** Diagnose the `500 Internal Server Error` on signup, explain the correct three-layer organisation flow, and document what needs to change.

---

## Table of Contents
1. [The Error - What You Saw](#1-the-error---what-you-saw)
2. [Root Cause: The Database Trigger is Broken](#2-root-cause-the-database-trigger-is-broken)
3. [The Correct Three-Layer Organisation Architecture](#3-the-correct-three-layer-organisation-architecture)
4. [What You Were Doing Wrong vs What Needs to Happen](#4-what-you-were-doing-wrong-vs-what-needs-to-happen)
5. [The SQL Trigger That Must Be Removed/Fixed](#5-the-sql-trigger-that-must-be-removed-fixed)
6. [The Correct Signup Sequence](#6-the-correct-signup-sequence)
7. [The Fix - Step by Step](#7-the-fix---step-by-step)
8. [Code Reference - Current vs Correct](#8-code-reference---current-vs-correct)
9. [How to Test the Fix](#9-how-to-test-the-fix)

---

## 1. The Error - What You Saw

### Flutter Error
```
AuthRetryableFetchException(
  message: ("code": "Unexpected_failure", "message": "database error saving new user"),
  statusCode: 500
)
```

### DevTools Console
```
POST https://aucflsskbhaloutsdlwc.supabase.co/auth/v1/signup? 500 (Internal Server Error)
```

### What This Means
Supabase received the signup request, created the user in `auth.users`, but then the **database trigger** fired and **threw an error**. Because a trigger error is considered fatal, Supabase rolled back the entire signup and returned 500.

**The user is created by Supabase, but the trigger fails, so the whole transaction is rolled back.**

---

## 2. Root Cause: The Database Trigger is Broken

### The Trigger That's Causing It
The SQL trigger `handle_new_client_signup()` was created earlier. It fires `AFTER INSERT ON auth.users` and tries to insert into `profiles`.

### The Problem
**The trigger's INSERT statement references a column called `client_organisation_id` in the `profiles` table — but that column has been DELETED from the database.**

```sql
-- THIS IS THE BROKEN TRIGGER (references deleted column)
INSERT INTO public.profiles (
  id, email, full_name, name, role, 
  client_organisation_id,   -- ← ❌ THIS COLUMN WAS DELETED
  organisation_id, 
  is_active
)
VALUES (
  NEW.id, NEW.email, user_full_name, user_full_name,
  'client', new_org_id, new_org_id, true
);
```

When the trigger fires:
1. Supabase creates the auth user successfully
2. The trigger tries to insert into `profiles` with `client_organisation_id`
3. Postgres throws: `column "client_organisation_id" of relation "profiles" does not exist`
4. The trigger error propagates up → Supabase returns 500 → signup fails

### The Chain of Events That Led Here

| Step | What Happened | Result |
|------|--------------|--------|
| 1 | `client_organisation_id` column was deleted from `profiles` | Column gone |
| 2 | Flutter code was updated to stop querying it | Code updated ✅ |
| 3 | **But the SQL trigger still references it** | **❌ Trigger still broken** |
| 4 | New user signs up → trigger fires → column missing error | **500 error** |

---

## 3. The Correct Three-Layer Organisation Architecture

Your schema defines a **three-layer hierarchy** that every query must respect:

```
┌─────────────────────────────────────────────┐
│  organisations (PARENT - the agency/head)   │
│  id = 11111111-1111-1111-1111-111111111111  │
└──────────────┬──────────────────────────────┘
               │
      ┌────────┴────────┐
      │                 │
      ▼                 ▼
┌──────────────────┐  ┌──────────────────────┐
│ profiles         │  │ client_organisations │
│ organisation_id  │  │ organisation_id      │
│ = parent org id  │  │ = parent org id      │
│ role = 'client'  │  │ = care home record   │
└──────────────────┘  └──────────────────────┘
```

### The Critical Rule
**`profiles.organisation_id` MUST point to the PARENT `organisations` table.**
**`client_organisations.organisation_id` MUST ALSO point to the PARENT `organisations` table.**

They share the same parent ID, but they are DIFFERENT tables.

### The ID Confusion
- `11111111-1111-1111-1111-111111111111` → a row in `organisations` (parent) ✅
- `de434c42-d5a6-45a1-8ada-959123584da3` → a row in `client_organisations` (care home) ❌ (wrong table for profiles FK)

You correctly fixed this by pointing the profile to the parent org ID.

---

## 4. What You Were Doing Wrong vs What Needs to Happen

### ❌ What You Were Trying (Broken Sequence)
```
Sign up user
    ↓
Create care home (client_organisations)
    ↓
Assign care home ID to profile.organisation_id   ← WRONG - FK violation
```

### ✅ What Needs to Happen (Correct Sequence)
```
Sign up user
    ↓
Create profile with PARENT organisation ID       ← Step 3 - was being skipped
    ↓
Create care home (client_organisations) linked to PARENT org
    ↓
Insert shift templates using PARENT organisation ID
```

**You were skipping step 3** - creating the profile with the parent organisation ID. Instead, you were trying to use the care home ID, which violates the foreign key constraint.

---

## 5. The SQL Trigger That Must Be Removed/Fixed

### The Broken Trigger (Currently in Database)

```sql
-- ❌ CURRENT TRIGGER - BROKEN because client_organisation_id was deleted
CREATE OR REPLACE FUNCTION public.handle_new_client_signup()
RETURNS TRIGGER AS $$
DECLARE
  new_org_id UUID;
  ...
BEGIN
  ...
  INSERT INTO public.profiles (
    id, email, full_name, name, role, 
    client_organisation_id,   -- ← COLUMN DOES NOT EXIST ANYMORE → ERROR
    organisation_id, 
    is_active
  )
  VALUES (
    NEW.id, NEW.email, user_full_name, user_full_name,
    'client', new_org_id, new_org_id, true
  );
  ...
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created_client
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_new_client_signup();
```

### Why It Causes the 500

1. New user signs up via `POST /auth/v1/signup`
2. Supabase inserts into `auth.users` ✅
3. Trigger fires `AFTER INSERT` 🔥
4. Trigger tries `INSERT INTO profiles (... client_organisation_id ...)`
5. Postgres error: `column "client_organisation_id" does not exist`
6. The trigger function throws
7. Supabase treats trigger failure as fatal → rolls back the user creation
8. Returns `500 Internal Server Error` with `"database error saving new user"`

---

## 6. The Correct Signup Sequence

### When Data is Written by the Trigger

| Table | What Gets Written | Source |
|-------|-------------------|--------|
| `auth.users` | User account | Supabase (automatic) |
| `profiles` | Role + organisation_id | Trigger should write |
| `client_organisations` | Care home record | Trigger should write |

### What the Trigger SHOULD Do (After Removing client_organisation_id)

```sql
-- ✅ FIXED TRIGGER - only writes to columns that exist
CREATE OR REPLACE FUNCTION public.handle_new_client_signup()
RETURNS TRIGGER AS $$
DECLARE
  new_org_id UUID;
  user_role TEXT;
  org_name TEXT;
  org_type TEXT;
  org_address TEXT;
  org_phone TEXT;
  user_full_name TEXT;
BEGIN
  user_role := COALESCE(NEW.raw_user_meta_data->>'role', 'client');

  IF user_role = 'client' THEN
    org_name := COALESCE(NEW.raw_user_meta_data->>'org_name', 'New Client Organisation');
    org_type := COALESCE(NEW.raw_user_meta_data->>'org_type', 'Care Home');
    org_address := COALESCE(NEW.raw_user_meta_data->>'org_address', '');
    org_phone := COALESCE(NEW.raw_user_meta_data->>'org_phone', '');
    user_full_name := COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email);

    -- A. Create the Client Organisation
    INSERT INTO public.client_organisations (
      name,
      organisation_types,
      address,
      phone,
      email,
      is_active
    )
    VALUES (
      org_name,
      jsonb_build_array(org_type),
      org_address,
      org_phone,
      NEW.email,
      true
    )
    RETURNING id INTO new_org_id;

    -- B. Create or Update the User Profile
    -- NOTE: client_organisation_id removed - only organisation_id is written
    INSERT INTO public.profiles (
      id,
      email,
      full_name,
      name,
      role,
      organisation_id,
      is_active
    )
    VALUES (
      NEW.id,
      NEW.email,
      user_full_name,
      user_full_name,
      'client',
      new_org_id,
      true
    )
    ON CONFLICT (id) DO UPDATE SET
      role = 'client',
      organisation_id = EXCLUDED.organisation_id,
      full_name = COALESCE(EXCLUDED.full_name, profiles.full_name),
      name = COALESCE(EXCLUDED.name, profiles.name),
      is_active = true;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

**Note:** `organisation_id` already accepts the care home ID in this trigger's design (there's no separate FK to parent `organisations` in the trigger — it uses the newly-created `client_organisations` ID). This is a design decision that must match your actual FK constraints. **If `profiles.organisation_id` has a FK to `organisations` (parent) only, the trigger must instead look up the parent org via a `client_organisation.organisation_id` and use that.**

---

## 7. The Fix - Step by Step

### Step 1: Drop the broken trigger & function
```sql
DROP TRIGGER IF EXISTS on_auth_user_created_client ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_client_signup();
```

### Step 2: Verify the profiles table columns
```sql
SELECT column_name FROM information_schema.columns
WHERE table_name = 'profiles'
ORDER BY ordinal_position;
```
Confirm there is **no** `client_organisation_id`.

### Step 3: Check the FK constraint on profiles.organisation_id
```sql
SELECT
  tc.constraint_name,
  kcu.column_name,
  ccu.table_name AS foreign_table,
  ccu.column_name AS foreign_column
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
  ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage ccu
  ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_name = 'profiles';
```

**This tells you if `profiles.organisation_id` must point to `organisations(id)` (parent) or if it can point to `client_organisations(id)` (care home).** This determines which ID the trigger must write.

### Step 4: Re-create the trigger with the corrected INSERT (from Section 6)

### Step 5: Re-test signup with a NEW email address

---

## 8. Code Reference - Current vs Correct

### Current Flutter Code (Client-App) - Already Correct ✅
The Flutter app now correctly:
- Takes org details from the form
- Packs them into `data` metadata
- Sends ONE signup request

```dart
// client-app/lib/services/supabase_auth_service.dart (correct)
final response = await _supabase.auth.signUp(
  email: email.trim(),
  password: password,
  data: {
    'role': 'client',
    'full_name': fullName,
    'org_name': orgName,
    'org_type': orgType,
    'org_address': orgAddress ?? '',
    'org_phone': orgPhone ?? '',
  },
);
```

### Current Flutter Code - Profile Loading (Correct ✅)
```dart
// client-app/lib/services/supabase_auth_service.dart (correct)
final profile = await _supabase
    .from('profiles')
    .select('role, organisation_id')
    .eq('id', _currentUser!.id)
    .maybeSingle();
```

### Current Database Trigger (BROKEN ❌ - Causes the 500)
The trigger references `client_organisation_id` which was deleted from `profiles`.

### The Fix (in the DATABASE, not Flutter)
The trigger must be updated to remove `client_organisation_id` references.

---

## 9. How to Test the Fix

### Test 1: Sign up a new user
- Use a **brand new email** (e.g., `test-500@carehome.com`)
- **Expected:** Green success SnackBar, NO 500 error

### Test 2: Check auth.users
- Supabase Dashboard → Authentication → Users
- The new user should exist

### Test 3: Check profiles
```sql
SELECT id, email, role, organisation_id FROM profiles;
```
- The profile should have `role = 'client'` and a non-null `organisation_id`

### Test 4: Check client_organisations
```sql
SELECT id, name, organisation_types FROM client_organisations;
```
- A new care home row should exist

### Test 5: Log in with the new user
- The app should pass the auth guard (role = 'client', organisation_id present)
- Dashboard loads

---

## Summary

| Question | Answer |
|----------|--------|
| Why the 500 error? | The SQL trigger references `client_organisation_id`, a column deleted from `profiles` |
| Does Flutter cause it? | **NO** - the Flutter code is already correct |
| What must be fixed? | The **SQL trigger** in Supabase |
| Correct sequence? | Create profile with parent org ID → create care home linked to parent → insert templates with parent ID |
| What was implemented in its place? | A trigger that writes to a deleted column |
| The fix | Drop & recreate the trigger without `client_organisation_id` |