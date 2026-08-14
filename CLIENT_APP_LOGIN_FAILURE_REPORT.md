# Client-App Login Failure - Root Cause Analysis Report

**Date:** 2026-07-28  
**Author:** Cline  
**Purpose:** Diagnose why login fails in the client-app  
**Status:** Multiple root causes identified

---

## Table of Contents
1. [Executive Summary](#1-executive-summary)
2. [Architecture Overview](#2-architecture-overview)
3. [Root Cause 1: Routes File Points to Non-Existent Screens](#3-root-cause-1-routes-file-points-to-non-existent-screens)
4. [Root Cause 2: Missing Auth Wrapper Integration](#4-root-cause-2-missing-auth-wrapper-integration)
5. [Root Cause 3: No Post-Login Navigation Logic](#5-root-cause-3-no-post-login-navigation-logic)
6. [Root Cause 4: Missing Database Service for Role-Based Access](#6-root-cause-4-missing-database-service-for-role-based-access)
7. [Root Cause 5: No Auth State Listener](#7-root-cause-5-no-auth-state-listener)
8. [Root Cause 6: Missing .env Asset Bundling After Clean](#8-root-cause-6-missing-env-asset-bundling-after-clean)
9. [Root Cause 7: Pubspec.yaml Has Orphaned Lines](#9-root-cause-7-pubspecyaml-has-orphaned-lines)
10. [Root Cause 8: Missing Supabase Dependencies in core Package](#10-root-cause-8-missing-supabase-dependencies-in-core-package)
11. [Root Cause 9: Wrong Env Variable Names in .env](#11-root-cause-9-wrong-env-variable-names-in-env)
12. [Fix Implementation - Complete Solution](#12-fix-implementation---complete-solution)
13. [Testing Verification Steps](#13-testing-verification-steps)
14. [Files That Need Changes](#14-files-that-need-changes)
15. [Appendix: Admin-App Reference Implementation](#15-appendix-admin-app-reference-implementation)

---

## 1. Executive Summary

The client-app cannot log in because of **a critical mismatch between the routes configuration and the actual file structure**. The GoRouter in `routes.dart` imports screens from `../screens/auth/login_screen.dart`, but this file does not exist. The login screen was created at `../ui/auth/login_screen.dart`, which the router never looks at.

Additionally, there is **no auth state management** in `main.dart`. Unlike the admin-app (which uses `AuthWrapper` with `Provider` and `SupabaseAuthService`), the client-app's `main.dart` has no auth provider, no auth state listener, and no logic to redirect users to the dashboard after login.

**Total issues found: 9** across 4 layers (frontend, backend, configuration, dependencies).

---

## 2. Architecture Overview

### How the admin-app successfully handles auth (reference implementation)

**File:** `admin-app/lib/main.dart`
```dart
return MultiProvider(
  providers: [
    ChangeNotifierProvider<SupabaseAuthService>(
      create: (_) => SupabaseAuthService(supabase),
    ),
    // ...
  ],
  child: MaterialApp(
    home: const AuthWrapper(
      authenticatedChild: AdminDashboard(),
    ),
  ),
);
```

**Flow:**
1. `main.dart` initializes Supabase
2. Creates `SupabaseAuthService` as a Provider
3. Renders `AuthWrapper` which checks `Supabase.instance.client.auth.currentUser`
4. If logged in → shows `AdminDashboard`
5. If not logged in → shows `LoginScreen`

### How the client-app currently works (broken)

**File:** `apps/client-app/lib/main.dart`
```dart
return MaterialApp.router(
  title: 'CareQA Client',
  routerConfig: appRouter,  // ← GoRouter with fixed routes
);
```

**Flow:**
1. `main.dart` initializes Supabase
2. Renders `MaterialApp.router` with GoRouter
3. GoRouter has initial location `/login`
4. `/login` route tries to load `LoginScreen` from `../screens/auth/login_screen.dart`
5. **File doesn't exist** → **CRASH**

---

## 3. Root Cause 1: Routes File Points to Non-Existent Screens

### The Problem

**File:** `apps/client-app/lib/config/routes.dart` (lines 1-3)
```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/auth/login_screen.dart';          // ← FILE DOES NOT EXIST
import '../screens/auth/register_screen.dart';        // ← FILE DOES NOT EXIST
import '../screens/auth/forgot_password_screen.dart'; // ← FILE DOES NOT EXIST
import '../screens/onboarding/industry_selection_screen.dart';  // ← DOES NOT EXIST
import '../screens/onboarding/organisation_join_screen.dart';   // ← DOES NOT EXIST
import '../screens/onboarding/profile_setup_screen.dart';       // ← DOES NOT EXIST
import '../screens/shifts/shift_booking_screen.dart';  // ← DOES NOT EXIST
import '../screens/shifts/shift_diary_screen.dart';    // ← DOES NOT EXIST
import '../screens/shifts/shift_detail_screen.dart';   // ← DOES NOT EXIST
import '../screens/staff/staff_rating_screen.dart';    // ← DOES NOT EXIST
import '../screens/staff/staff_directory_screen.dart'; // ← DOES NOT EXIST
import '../screens/staff/staff_profile_screen.dart';   // ← DOES NOT EXIST
import '../screens/invoices/invoice_list_screen.dart'; // ← DOES NOT EXIST
import '../screens/invoices/invoice_detail_screen.dart'; // ← DOES NOT EXIST
import '../screens/profile/preferences_screen.dart';   // ← DOES NOT EXIST
import '../screens/profile/settings_screen.dart';      // ← DOES NOT EXIST
import '../screens/notifications/notification_screen.dart'; // ← DOES NOT EXIST
```

**Every single screen import points to a non-existent file.** The directory structure shows:
```
apps/client-app/lib/screens/
├── auth/          ← EMPTY (no files)
├── dashboard/
│   └── client_dashboard.dart
├── invoices/      ← EMPTY
├── notifications/ ← EMPTY
├── onboarding/    ← EMPTY
├── profile/       ← EMPTY
├── shifts/        ← EMPTY
└── staff/         ← EMPTY
```

Only `client_dashboard.dart` exists in this directory structure.

### Where the actual login screen is

**Exists at:** `apps/client-app/lib/ui/auth/login_screen.dart` ✅

But the router is importing from `../screens/auth/login_screen.dart` which is at `apps/client-app/lib/screens/auth/login_screen.dart` ❌

### Impact

When the app starts, GoRouter tries to resolve `/login`:
1. Finds the route configuration
2. Tries to import `LoginScreen` from the wrong path
3. Gets a compile-time error OR runtime error
4. The login screen is never rendered

### Directory Structure Visualization

```
apps/client-app/lib/
├── config/
│   └── routes.dart              # Imports from ../screens/auth/ ← WRONG
├── screens/
│   ├── auth/                    # EMPTY - no files here
│   └── dashboard/
│       └── client_dashboard.dart
└── ui/
    └── auth/
        ├── login_screen.dart    # ACTUAL login screen ← HERE
        └── auth_wrapper.dart    # ACTUAL auth wrapper ← HERE
```

The `screens/` and `ui/` directories are **sibling directories**. The router lives in `config/` and tries to reach `../screens/auth/`, but the actual login screen is at `../ui/auth/`.

---

## 4. Root Cause 2: Missing Auth Wrapper Integration

### The Problem

The `main.dart` does NOT use the `AuthWrapper` component. Compare:

**Admin-app (working):**
```dart
// admin-app/lib/main.dart
return MaterialApp(
  home: const AuthWrapper(
    authenticatedChild: AdminDashboard(),
  ),
);
```

**Client-app (broken):**
```dart
// apps/client-app/lib/main.dart
return MaterialApp.router(
  routerConfig: appRouter,  // GoRouter with no auth check
);
```

### Impact

The GoRouter always starts at `/login`, even if the user is already logged in. There is no auth state check before deciding which screen to show. This means:
1. No session persistence - closing and reopening the app always shows login
2. No automatic redirect to dashboard after successful login
3. The login screen has no way to navigate to dashboard after auth

### Code Snippet of the Missing Auth Logic

```dart
// What should be in main.dart:
return ChangeNotifierProvider<SupabaseAuthService>(
  create: (_) => SupabaseAuthService(Supabase.instance.client),
  child: MaterialApp(
    home: const AuthWrapper(
      authenticatedChild: ClientDashboard(),
    ),
  ),
);
```

---

## 5. Root Cause 3: No Post-Login Navigation Logic

### The Problem

**File:** `apps/client-app/lib/ui/auth/login_screen.dart` (lines 99-108)
```dart
try {
  await Supabase.instance.client.auth.signInWithPassword(
    email: _emailController.text.trim(),
    password: _passwordController.text,
  );
  if (mounted) {
    // Auth state will trigger rebuild  ← THIS IS A LIE!
  }
} catch (e) {
  // ...
}
```

After a successful login, the code does **nothing** except check `if (mounted)`. There is no:
- Navigation to dashboard (`Navigator.pushReplacementNamed('/dashboard')`)
- Change in widget state to show the authenticated view
- Provider update to trigger AuthWrapper rebuild

### Impact

Even if `Supabase.instance.client.auth.signInWithPassword()` succeeds:
1. The `AuthWrapper` is NOT being used
2. The GoRouter does NOT check auth state
3. There's no navigation logic
4. The user stays on the login screen with a spinner
5. Eventually the spinner stops, but nothing changes

### How the admin-app handles this (correct)

The admin-app uses `AuthWrapper` which watches `Supabase.instance.client.auth.onAuthStateChange`. When auth state changes (like after login), the widget rebuilds automatically and shows the authenticated view.

---

## 6. Root Cause 4: Missing Database Service for Role-Based Access

### The Problem

Even if login succeeds, the client-app needs to check the user's `role` from the `profiles` table to:
1. Verify the user has role = 'client'
2. Load organisation data
3. Determine which features to show

The client-app has **no database service** to fetch the user's profile after login.

### What's Missing

**File that needs to exist:** `apps/client-app/lib/services/profile_service.dart`
```dart
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  final SupabaseClient _client;

  ProfileService(this._client);

  Future<Map<String, dynamic>?> getProfile(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      return response as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }
}
```

### Impact

After login, there's no way to:
1. Verify the user's role
2. Load user preferences
3. Load organisation-specific data
4. Show a personalized dashboard

---

## 7. Root Cause 5: No Auth State Listener

### The Problem

The app needs to listen for auth state changes (login, logout, token refresh) and react accordingly. Neither `main.dart` nor any widget sets up `onAuthStateChange` listener.

### What's Missing

```dart
// This should be in main.dart or AuthWrapper
Supabase.instance.client.auth.onAuthStateChange.listen((data) {
  if (data.session != null) {
    // User is logged in - redirect to dashboard
  } else {
    // User is logged out - redirect to login
  }
});
```

### Impact

- No automatic redirect on login
- No session persistence check
- No logout detection
- No token refresh handling

---

## 8. Root Cause 6: Missing .env Asset Bundling After Clean

### The Problem

The `.env` file is declared as an asset in `pubspec.yaml`, but if `flutter clean` is run, the app needs `flutter pub get` to re-bundle assets. If the user runs `flutter clean` without `flutter pub get`, the `.env` file won't be bundled.

### Verification

Check if assets are bundled:
```bash
# After running the app, check for this in the debug console:
flutter: Loaded .env file  # ← Should appear if dotenv.load succeeded
```

If you see:
```
"Error: Supabase initialization failed"
```

Then `.env` isn't being loaded.

### The .env File Itself

**File:** `apps/client-app/.env`
```env
# Supabase Database Connection
DATABASE_URL=postgresql://postgres.aucflsskbhaloutsdlwc:SBV8U4GggNECuA2g@aws-1-eu-west-1.pooler.supabase.com:5432/postgres

# Supabase Project Configuration
SUPABASE_URL=https://aucflsskbhaloutsdlwc.supabase.co

# Supabase Anon Key (for client-side access)
SUPABASE_ANON_KEY=sb_publishable_ruC1mXCXtyHHsNX7KckTfA_YGrN-2hy

# Supabase Service Role Key (for server-side access)
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF1Y2Zsc3NrYmhhbG91dHNkbHdjIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MzE0MDE0MywiZXhwIjoyMDg4NzE2MTQzfQ.TDutC0zroQ0Ye7BgQkv-oawgxdVOZxRNT-b_-eSk9lQ
```

This file is correct and the credentials match the admin-app's `.env`.

---

## 9. Root Cause 7: Pubspec.yaml Has Orphaned Lines

### The Problem

**File:** `apps/client-app/pubspec.yaml` (line 54)
```yaml
flutter:
  uses-material-design: true
  assets:
    - .env
</arg_value>
<task_progress>
```

Lines 54-62 are NOT valid YAML. These leftover lines from a previous tool call (containing `</arg_value>`, `<task_progress>`, etc.) will cause the Flutter build to fail.

### Impact

The pubspec.yaml is malformed. When Flutter tries to parse it:
```bash
Error on line 54: Expected 'while scanning for the next token', found '<'
```

This prevents the app from building at all.

---

## 10. Root Cause 8: Missing Supabase Dependencies in core Package

### The Problem

The `packages/core/lib/` directory has many services (like `auth_service.dart`, `supabase_auth_service.dart`, etc.) that import from `package:supabase_flutter/supabase_flutter.dart`, but the `packages/core/pubspec.yaml` does NOT list `supabase_flutter` as a dependency.

### Impact

If any file in `packages/core` is imported (e.g., by the client-app's authentication logic), the build will fail with:
```dart
Error: Target of URI doesn't exist: 'package:supabase_flutter/supabase_flutter.dart'
```

This is why the code has hundreds of errors in the VS Code problems panel.

---

## 11. Root Cause 9: Wrong Env Variable Names in .env

### The Problem

The `.env` file uses these variable names:
```
SUPABASE_URL
SUPABASE_ANON_KEY
```

But the admin-app's `.env` uses the exact same names and works fine. **This is actually correct.** However, the `main.dart` code accesses them as:
```dart
dotenv.env['SUPABASE_URL']!
dotenv.env['SUPABASE_ANON_KEY']!
```

**Potential issue:** The `flutter_dotenv` package version `^5.2.1` may require the `.env` file to be at the project root. Since the client-app is in a subdirectory (`apps/client-app/`), the path might need to be adjusted.

### The Fix

In `main.dart`, try:
```dart
await dotenv.load(fileName: '.env');  // Relative to project root
```

Or use the full path:
```dart
await dotenv.load(fileName: 'apps/client-app/.env');
```

---

## 12. Fix Implementation - Complete Solution

### Fix 1: Fix pubspec.yaml (MOST URGENT)

Remove orphaned lines at the end of `apps/client-app/pubspec.yaml`:

```yaml
flutter:
  uses-material-design: true
  assets:
    - .env
```

### Fix 2: Create Missing Screen Files

Create a minimal `login_screen.dart` at the location the router expects:

**File:** `apps/client-app/lib/screens/auth/login_screen.dart`
```dart
// Redirect to the actual login screen implementation
export '../../ui/auth/login_screen.dart';
```

OR update the router to point to the correct path:

**File:** `apps/client-app/lib/config/routes.dart`
```dart
import '../../ui/auth/login_screen.dart';
// Remove ALL other imports that don't exist yet
```

### Fix 3: Rewrite main.dart with Auth Wrapper

**File:** `apps/client-app/lib/main.dart`
```dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'ui/auth/auth_wrapper.dart';
import 'screens/dashboard/client_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  runApp(const ClientApp());
}

class ClientApp extends StatelessWidget {
  const ClientApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CareQA Client',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00BF6D),
          primary: const Color(0xFF00BF6D),
        ),
        useMaterial3: true,
      ),
      home: const AuthWrapper(
        authenticatedChild: ClientDashboard(),
      ),
    );
  }
}
```

### Fix 4: Update AuthWrapper to Handle Auth State Changes

**File:** `apps/client-app/lib/ui/auth/auth_wrapper.dart`
```dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';

class AuthWrapper extends StatefulWidget {
  final Widget authenticatedChild;

  const AuthWrapper({
    super.key,
    required this.authenticatedChild,
  });

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  late StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();
    // Listen for auth state changes
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen(
      (data) {
        if (mounted) {
          setState(() {});  // Trigger rebuild on auth change
        }
      },
    );
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    
    if (user != null) {
      return widget.authenticatedChild;
    } else {
      return const LoginScreen();
    }
  }
}
```

### Fix 5: Add Post-Login Navigation to LoginScreen

**File:** `apps/client-app/lib/ui/auth/login_screen.dart` (update the login handler)
```dart
try {
  await Supabase.instance.client.auth.signInWithPassword(
    email: _emailController.text.trim(),
    password: _passwordController.text,
  );
  // AuthWrapper will automatically rebuild due to auth state change
  // No manual navigation needed
} catch (e) {
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Login failed: ${e.toString()}')),
    );
  }
}
```

### Fix 6: Remove Unused Dependencies or Fix core/pubspec.yaml

**File:** `packages/core/pubspec.yaml` (add `supabase_flutter`)
```yaml
dependencies:
  supabase_flutter: ^2.12.0
```

Then run:
```bash
cd packages/core
flutter pub get
```

---

## 13. Testing Verification Steps

### Pre-Test Checklist

- [ ] Run `flutter clean` in `apps/client-app/`
- [ ] Run `flutter pub get` in `apps/client-app/`
- [ ] Verify pubspec.yaml has no orphaned lines
- [ ] Verify .env file exists in `apps/client-app/.env`
- [ ] Run `flutter pub get` in `packages/core/`
- [ ] Run migration 115 in Supabase SQL Editor
- [ ] Create auth user in Supabase Dashboard
- [ ] Run test data SQL with actual User UUID

### Launch & Test

```bash
cd apps/client-app
flutter run -d edge
```

### Expected Behavior

| Step | Action | Expected Result |
|------|--------|----------------|
| 1 | App starts | Login screen displays |
| 2 | Enter `test@carehome.com` / `Test123!` | No errors |
| 3 | Click Sign In | Loading spinner shows |
| 4 | Login succeeds | Automatically navigates to Dashboard |
| 5 | Dashboard loads | Shows navigation tiles |
| 6 | Close browser, reopen app | App remembers login (session persistence) |

### Error Diagnosis

| Symptom | Most Likely Cause | Fix |
|---------|------------------|-----|
| Blank white screen immediately | pubspec.yaml orphaned lines OR missing import | Fix pubspec.yaml, check imports |
| "No API Key found" | .env not bundled | Run `flutter pub get` |
| "target of URI doesn't exist" | Wrong import path in routes.dart | Fix routes.dart to use correct paths |
| Login button does nothing | No auth state listener | Implement AuthWrapper with onAuthStateChange |
| Login succeeds but stays on login screen | No post-login navigation | AuthWrapper handles this automatically |
| Build fails with YAML error | Orphaned lines in pubspec.yaml | Remove lines 54-62 |
| "Role 'client' check violation" | Migration 115 not run | Run migration in Supabase SQL Editor |
| "Foreign key violation" on profiles insert | Wrong UUID in test data | Use actual auth user UUID |
| "Invalid login credentials" | User not created in Supabase Auth | Create user in Supabase Dashboard |

---

## 14. Summary of All Root Causes

| # | Root Cause | Layer | Severity | Fix |
|---|-----------|-------|----------|-----|
| 1 | Routes file imports non-existent screens | Frontend | 🔴 CRITICAL | Fix import paths or create screen files |
| 2 | Missing AuthWrapper in main.dart | Frontend | 🔴 CRITICAL | Rewrite main.dart with Provider + AuthWrapper |
| 3 | No post-login navigation logic | Frontend | 🔴 CRITICAL | AuthWrapper handles this automatically |
| 4 | No database service for role-based access | Frontend | 🟡 HIGH | Create ProfileService |
| 5 | No auth state listener | Frontend | 🟡 HIGH | Add onAuthStateChange to AuthWrapper |
| 6 | .env not bundled after clean | Build | 🟡 MEDIUM | Run `flutter pub get` |
| 7 | Orphaned lines in pubspec.yaml | Build | 🔴 CRITICAL | Remove lines 54-62 |
| 8 | Missing supabase_flutter in core package | Dependencies | 🟡 MEDIUM | Add to core/pubspec.yaml |
| 9 | .env path resolution | Build | 🟢 LOW | Verify `dotenv.load()` path |

**Priority order for fixes:**
1. Fix pubspec.yaml (remove orphaned lines) → solves build failure
2. Rewrite main.dart with AuthWrapper → solves auth flow
3. Fix routes.dart or create screen files → solves login screen loading
4. Add auth state listener to AuthWrapper → solves post-login redirect
5. Add ProfileService → solves role-based access
6. Add supabase_flutter to core package → solves dependency issues

---

## 15. Files That Need Changes

| File | Change Required | Priority |
|------|----------------|----------|
| `apps/client-app/pubspec.yaml` | Remove orphaned lines 54-62 | 🔴 NOW |
| `apps/client-app/lib/main.dart` | Add Provider + AuthWrapper | 🔴 NOW |
| `apps/client-app/lib/config/routes.dart` | Fix import paths or simplify | 🔴 NOW |
| `apps/client-app/lib/ui/auth/auth_wrapper.dart` | Add onAuthStateChange listener | 🔴 NOW |
| `apps/client-app/lib/screens/auth/login_screen.dart` | Create this file (export from ui/auth) | 🔴 NOW |
| `packages/core/pubspec.yaml` | Add supabase_flutter dependency | 🟡 ASAP |
| `apps/client-app/lib/services/profile_service.dart` | Create this new file | 🟡 NEXT |

---

## 16. Appendix: Admin-App Reference Implementation

### How admin-app successfully handles auth

1. **main.dart** initializes Supabase and wraps app in `MultiProvider` with `SupabaseAuthService`
2. **SupabaseAuthService** manages auth state and notifies listeners
3. **AuthWrapper** checks `currentUser` and shows appropriate screen
4. **LoginScreen** calls `SupabaseAuthService.signInWithEmailAndPassword()`
5. **Auth state listener** detects login and triggers rebuild of AuthWrapper
6. **AuthWrapper** rebuilds, sees `currentUser != null`, shows dashboard

### Key difference that makes it work

The admin-app uses `home: AuthWrapper(authenticatedChild: AdminDashboard())` which watches auth state in real-time. The client-app uses `routerConfig: appRouter` which has fixed routes with no auth awareness.

**The fix is to replace GoRouter with AuthWrapper, or integrate auth state into GoRouter using redirects.**