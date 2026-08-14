# Client-App Authentication & Signup Flow - Comprehensive Technical Report

**Date:** 2026-08-03  
**Audience:** Developers with NO prior access to the codebase  
**Purpose:** Explain exactly how the client-app signup/auth works, what API requests are made, what Supabase endpoints are hit, how data is formatted, and why signup may fail.

---

## Table of Contents
1. [Executive Summary](#1-executive-summary)
2. [The Big Question: 1 or 3 API Requests?](#2-the-big-question-1-or-3-api-requests)
3. [Architecture Overview](#3-architecture-overview)
4. [File-by-File Breakdown](#4-file-by-file-breakdown)
5. [The Signup Request - Endpoint & Format](#5-the-signup-request---endpoint--format)
6. [What Supabase Does Server-Side](#6-what-supabase-does-server-side)
7. [The Login Flow](#7-the-login-flow)
8. [The Auth Guard](#8-the-auth-guard)
9. [Possible Reasons Signup Fails](#9-possible-reasons-signup-fails)
10. [Current Standing Errors & Known Issues](#10-current-standing-errors--known-issues)
11. [Code Reference Appendix](#11-code-reference-appendix)

---

## 1. Executive Summary

The client-app signup flow sends **exactly ONE API request** to Supabase. This single request carries all the user's personal details AND organisation details inside a `data` metadata object. Supabase then uses a **database trigger** to automatically create the organisation and profile records server-side.

**The one request:**
```
POST https://aucflsskbhaloutsdlwc.supabase.co/auth/v1/signup
```

**What happens after:**
1. Supabase creates the auth user
2. A database trigger fires and reads the metadata
3. The trigger creates a `client_organisations` record
4. The trigger creates a `profiles` record with `role = 'client'`
5. Supabase sends a verification email

---

## 2. The Big Question: 1 or 3 API Requests?

### Answer: ONE (1) API request

The signup flow makes **exactly one** HTTP request to Supabase. It does NOT make 3 separate requests.

### Why this design?

The original design considered 3 separate requests:
1. Create auth user
2. Create organisation
3. Create profile

This was **rejected** because:
- **Race conditions** - If request 2 fails after request 1 succeeds, you have an orphaned user
- **Partial failures** - No way to roll back cleanly
- **Complexity** - The Flutter app would need to handle 3 different error states

### The solution: Single request + Database Trigger

Instead of 3 requests, the app sends **1 request** with all data embedded in the `data` metadata field. A **database trigger** on `auth.users` handles the rest atomically server-side.

```
┌─────────────────────────────────────────────────────────┐
│  Flutter App                                            │
│                                                         │
│  POST /auth/v1/signup                                   │
│  {                                                      │
│    "email": "...",                                      │
│    "password": "...",                                   │
│    "data": {                                            │
│      "role": "client",                                  │
│      "full_name": "...",                                │
│      "org_name": "...",                                 │
│      "org_type": "...",                                 │
│      "org_address": "...",                              │
│      "org_phone": "..."                                 │
│    }                                                    │
│  }                                                      │
└────────────────────────┬────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────┐
│  Supabase Auth Server                                   │
│                                                         │
│  1. Creates user in auth.users                          │
│  2. Stores "data" as raw_user_meta_data                 │
│  3. Sends verification email                            │
└────────────────────────┬────────────────────────────────┘
                         │
                         ▼  (trigger fires)
┌─────────────────────────────────────────────────────────┐
│  Database Trigger (on auth.users)                       │
│                                                         │
│  1. Reads raw_user_meta_data                            │
│  2. Creates client_organisations record                 │
│  3. Creates profiles record with role='client'          │
│  4. Links them via client_organisation_id               │
└─────────────────────────────────────────────────────────┘
```

---

## 3. Architecture Overview

### The Two Key Files

| File | Role |
|------|------|
| `client-app/lib/ui/auth/signup_screen.dart` | The UI - collects form data |
| `client-app/lib/services/supabase_auth_service.dart` | The logic - formats & sends the request |

### The Call Chain

```
SignupScreen (UI)
    │
    │  User taps "Create Account"
    │
    ▼
_signUp() method
    │
    │  Validates form fields
    │  Calls authService.signUpAsClient(...)
    │
    ▼
SupabaseAuthService.signUpAsClient()
    │
    │  Formats the data map
    │  Calls _supabase.auth.signUp(...)
    │
    ▼
Supabase Flutter SDK
    │
    │  Constructs POST request
    │  Sends to /auth/v1/signup
    │
    ▼
Supabase Server
```

---

## 4. File-by-File Breakdown

### 4.1 `signup_screen.dart` - The UI Layer

**Purpose:** Collect user input and trigger the signup.

**Key components:**
- `TextEditingController` for each text field
- `GlobalKey<FormState>` for form validation
- `_orgType` string for the dropdown selection
- `_isLoading` boolean for the loading state

**The form fields:**
| Field | Controller | Validation |
|-------|-----------|------------|
| Full Name | `_nameController` | Required |
| Email | `_emailController` | Required + must contain `@` |
| Password | `_passwordController` | Required + min 6 chars |
| Organisation Name | `_orgNameController` | Required |
| Organisation Type | `_orgType` (dropdown) | Defaults to 'Care Home' |
| Address | `_orgAddressController` | Optional |
| Phone | `_orgPhoneController` | Optional |

**The submit method:**

```dart
Future<void> _signUp() async {
  if (!_formKey.currentState!.validate()) return;  // Stop if validation fails
  setState(() => _isLoading = true);               // Show spinner

  final authService = context.read<SupabaseAuthService>();
  final result = await authService.signUpAsClient(
    fullName: _nameController.text.trim(),
    email: _emailController.text.trim(),
    password: _passwordController.text,
    orgName: _orgNameController.text.trim(),
    orgType: _orgType,
    orgAddress: _orgAddressController.text.trim(),
    orgPhone: _orgPhoneController.text.trim(),
  );

  setState(() => _isLoading = false);              // Hide spinner

  if (result.success) {
    // Green SnackBar: "Account created! Please check your email..."
    Navigator.pop(context);                        // Back to login
  } else {
    // Red SnackBar with error message
  }
}
```

### 4.2 `supabase_auth_service.dart` - The Logic Layer

**Purpose:** Format the request and send it to Supabase.

**The `signUpAsClient` method:**

```dart
Future<AuthResult> signUpAsClient({
  required String fullName,
  required String email,
  required String password,
  required String orgName,
  required String orgType,
  String? orgAddress,
  String? orgPhone,
}) async {
  _isLoading = true;
  notifyListeners();

  try {
    final response = await _supabase.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'role': 'client', // CRITICAL: Triggers the database automation
        'full_name': fullName,
        'org_name': orgName,
        'org_type': orgType,
        'org_address': orgAddress ?? '',
        'org_phone': orgPhone ?? '',
      },
    );

    if (response.user != null) {
      return AuthResult.success(response.user, message: 'Signup successful. Please verify your email.');
    } else {
      return AuthResult.failure('Signup failed. Please try again.');
    }
  } catch (e) {
    return AuthResult.failure(e.toString());
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}
```

---

## 5. The Signup Request - Endpoint & Format

### The Endpoint

```
POST https://aucflsskbhaloutsdlwc.supabase.co/auth/v1/signup
```

This is the standard Supabase GoTrue auth endpoint. The URL is constructed from:
- `SUPABASE_URL` from the `.env` file: `https://aucflsskbhaloutsdlwc.supabase.co`
- The auth path: `/auth/v1/signup`

### The Request Headers (set by the SDK)

```
Content-Type: application/json
apikey: sb_publishable_ruC1mXCXtyHHsNX7KckTfA_YGrN-2hy
Authorization: Bearer sb_publishable_ruC1mXCXtyHHsNX7KckTfA_YGrN-2hy
```

### The Request Body (JSON)

```json
{
  "email": "manager@sunshinecarehome.co.uk",
  "password": "secret123",
  "data": {
    "role": "client",
    "full_name": "Jane Smith",
    "org_name": "Sunshine Care Home",
    "org_type": "Care Home",
    "org_address": "123 High Street, London",
    "org_phone": "020 1234 5678"
  }
}
```

### The Response (on success)

```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "token_type": "bearer",
  "expires_in": 3600,
  "refresh_token": "abc123...",
  "user": {
    "id": "uuid-here",
    "email": "manager@sunshinecarehome.co.uk",
    "role": "authenticated",
    "user_metadata": {
      "role": "client",
      "full_name": "Jane Smith",
      "org_name": "Sunshine Care Home",
      "org_type": "Care Home",
      "org_address": "123 High Street, London",
      "org_phone": "020 1234 5678"
    }
  }
}
```

---

## 6. What Supabase Does Server-Side

### Step 1: Create Auth User

Supabase creates a user in the `auth.users` table with:
- The email and password (hashed)
- The `data` object stored as `raw_user_meta_data`

### Step 2: Database Trigger Fires

A **trigger** on `auth.users` (created via SQL migration) fires `AFTER INSERT`. It reads `raw_user_meta_data` and:

1. **Creates a `client_organisations` record:**
```sql
INSERT INTO client_organisations (name, organisation_types, address, phone, email)
VALUES (
  meta->>'org_name',
  jsonb_build_array(meta->>'org_type'),
  meta->>'org_address',
  meta->>'org_phone',
  meta->>'email'
)
RETURNING id;
```

2. **Creates a `profiles` record:**
```sql
INSERT INTO profiles (id, email, full_name, role, organisation_id, client_organisation_id)
VALUES (
  NEW.id,
  NEW.email,
  meta->>'full_name',
  'client',
  org_id,
  org_id
);
```

### Step 3: Send Verification Email

Because the signup does NOT set `email_confirm: true`, Supabase sends a verification email. The user must click the link before they can log in.

---

## 7. The Login Flow

After the user verifies their email, they log in via `signInWithEmailPassword`:

```dart
Future<AuthResult> signInWithEmailPassword({
  required String email,
  required String password,
}) async {
  final response = await _supabase.auth.signInWithPassword(
    email: email.trim(),
    password: password,
  );

  if (response.user == null) {
    return AuthResult.failure('Sign in failed. Please check your credentials.');
  }

  await _loadUserProfile();   // ← Fetches role + org from profiles table
  await _cacheSessionFlag(true);
  return AuthResult.success(response.user!);
}
```

### The Login Endpoint

```
POST https://aucflsskbhaloutsdlwc.supabase.co/auth/v1/token?grant_type=password
```

### Profile Loading

After login, `_loadUserProfile()` queries the `profiles` table:

```dart
final profile = await _supabase
    .from('profiles')
    .select('role, organisation_id, client_organisation_id')
    .eq('id', _currentUser!.id)
    .single();
```

This is a **second API request** (but only happens AFTER login, not during signup):
```
GET https://aucflsskbhaloutsdlwc.supabase.co/rest/v1/profiles?select=role,organisation_id,client_organisation_id&id=eq.<user_id>
```

---

## 8. The Auth Guard

After login, the app enforces strict rules:

```dart
// STRICT AUTH GUARD: Only 'client' role with a valid client_organisation_id is allowed
if (_userRole != 'client') {
  await signOut();
  _authGuardError = 'This app is exclusively for registered Care Homes, Warehouses, and Factories. Please contact support.';
  notifyListeners();
  return;
}

if (_clientOrganisationId == null || _clientOrganisationId!.isEmpty) {
  await signOut();
  _authGuardError = 'Your account is not fully set up. Please contact support or sign up again.';
  notifyListeners();
  return;
}
```

### What the Guard Checks

| Check | If Fails |
|-------|----------|
| `role == 'client'` | Signs out + "Access Restricted" message |
| `client_organisation_id` is not null/empty | Signs out + "Account not fully set up" message |
| Profile query succeeds | Signs out + "Unable to verify your account" message |

---

## 9. Possible Reasons Signup Fails

### 9.1 Database Trigger Not Created

**Symptom:** User is created but no `client_organisations` or `profiles` record exists.

**Cause:** The SQL trigger on `auth.users` was never run in Supabase.

**Fix:** Run the trigger migration SQL in the Supabase SQL Editor.

### 9.2 `client_organisation_id` Column Missing

**Symptom:** Auth guard signs the user out with "Account not fully set up".

**Cause:** The `profiles` table doesn't have a `client_organisation_id` column.

**Fix:**
```sql
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS client_organisation_id UUID;
```

### 9.3 Email Already Registered

**Symptom:** Error: "User already registered" or similar.

**Cause:** The email already exists in `auth.users`.

**Fix:** Use a different email, or delete the existing user from Supabase Auth.

### 9.4 Password Too Weak

**Symptom:** Error from Supabase about password requirements.

**Cause:** Supabase's minimum password length setting (default 6).

**Fix:** The Flutter form already validates min 6 chars, but Supabase may have a higher minimum configured.

### 9.5 Email Verification Required

**Symptom:** User can't log in after signup.

**Cause:** Supabase requires email confirmation. The user hasn't clicked the verification link.

**Fix:** Check the email inbox (including spam) for the verification email.

### 9.6 `.env` File Not Loaded

**Symptom:** "No API Key found" or initialization failure.

**Cause:** The `.env` file isn't bundled as an asset.

**Fix:** Ensure `pubspec.yaml` has:
```yaml
flutter:
  uses-material-design: true
  assets:
    - .env
```

### 9.7 RLS Policies Blocking the Trigger

**Symptom:** Trigger fails silently or errors.

**Cause:** Row Level Security policies prevent the trigger from inserting into `client_organisations` or `profiles`.

**Fix:** Ensure the trigger uses `SECURITY DEFINER` or the service role.

### 9.8 Network/CORS Issues (Web)

**Symptom:** Request fails with network error.

**Cause:** The Supabase project doesn't have the app's URL in the allowed CORS origins.

**Fix:** Add the app URL to Supabase Dashboard → Authentication → URL Configuration.

---

## 10. Current Standing Errors & Known Issues

### Issue 1: "Library not defined: package:careqa_client/ui/auth/signup_screen.dart"

**Status:** RESOLVED (requires full app restart)

**Cause:** The Flutter dev server was started before `signup_screen.dart` was created. Hot reload doesn't pick up new files.

**Fix:** Press `R` (capital) in the terminal, or stop and re-run:
```bash
cd client-app
flutter clean
flutter pub get
flutter run -d edge
```

### Issue 2: "No API Key found in request"

**Status:** RESOLVED

**Cause:** The `.env` file wasn't being loaded correctly. The `??` operator didn't catch empty strings.

**Fix:** Added an `env()` helper that checks for both null AND empty strings, with hardcoded fallbacks.

### Issue 3: White Rectangles with X (missing icons)

**Status:** RESOLVED

**Cause:** `pubspec.yaml` was missing `uses-material-design: true`.

**Fix:** Added the line to `client-app/pubspec.yaml`.

### Issue 4: "Organisation not found" errors

**Status:** ADDRESSED via auth guard + signup flow

**Cause:** Users could log in without a valid `client_organisation_id`.

**Fix:** 
- New signup flow passes `role: 'client'` + org details in metadata
- Database trigger creates the org + profile atomically
- Auth guard signs out users without a valid `client_organisation_id`

---

## 11. Code Reference Appendix

### Full `signUpAsClient` Method

```dart
Future<AuthResult> signUpAsClient({
  required String fullName,
  required String email,
  required String password,
  required String orgName,
  required String orgType,
  String? orgAddress,
  String? orgPhone,
}) async {
  _isLoading = true;
  notifyListeners();

  try {
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

    if (response.user != null) {
      return AuthResult.success(response.user, message: 'Signup successful. Please verify your email.');
    } else {
      return AuthResult.failure('Signup failed. Please try again.');
    }
  } catch (e) {
    return AuthResult.failure(e.toString());
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}
```

### Full `_loadUserProfile` Method (with Auth Guard)

```dart
Future<void> _loadUserProfile() async {
  if (_currentUser == null) return;

  try {
    final profile = await _supabase
        .from('profiles')
        .select('role, organisation_id, client_organisation_id')
        .eq('id', _currentUser!.id)
        .single();

    _userRole = profile['role'] as String?;
    _organisationId = profile['organisation_id'] as String?;
    _clientOrganisationId = profile['client_organisation_id'] as String?;

    // STRICT AUTH GUARD
    if (_userRole != 'client') {
      await signOut();
      _authGuardError = 'This app is exclusively for registered Care Homes, Warehouses, and Factories. Please contact support.';
      notifyListeners();
      return;
    }

    if (_clientOrganisationId == null || _clientOrganisationId!.isEmpty) {
      await signOut();
      _authGuardError = 'Your account is not fully set up. Please contact support or sign up again.';
      notifyListeners();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userRoleKey, _userRole ?? '');
    await prefs.setString(_userOrgKey, _organisationId ?? '');

    notifyListeners();
  } catch (e) {
    debugPrint('Error loading user profile: $e');
    await signOut();
    _authGuardError = 'Unable to verify your account. Please contact support.';
    notifyListeners();
  }
}
```

### The `AuthResult` Class

```dart
class AuthResult {
  final bool success;
  final String? errorMessage;
  final String? message;
  final User? user;

  AuthResult._({
    required this.success,
    this.errorMessage,
    this.message,
    this.user,
  });

  factory AuthResult.success(User? user, {String? message}) =>
      AuthResult._(success: true, user: user, message: message);

  factory AuthResult.failure(String error) =>
      AuthResult._(success: false, errorMessage: error);
}
```

---

## Summary Table

| Question | Answer |
|----------|--------|
| How many API requests? | **1** (signup) + 1 (profile load after login) |
| What endpoint? | `POST /auth/v1/signup` |
| How is data formatted? | JSON with `data` metadata object |
| What triggers org creation? | Database trigger on `auth.users` |
| What role is assigned? | `'client'` (from metadata) |
| Email verification? | Yes, required |
| Auth guard? | Yes, checks role + client_organisation_id |
| Main failure points? | Missing trigger, missing column, email exists, weak password, RLS blocking |