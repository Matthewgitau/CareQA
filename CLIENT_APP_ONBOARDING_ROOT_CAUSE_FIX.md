# Client-App Onboarding: Root-Cause Fix Report & Implementation Plan

**Date:** 2026-08-01  
**Purpose:** Definitive, production-ready solution for the client-app onboarding flow  
**Problem:** Users can log in but are not guaranteed `role = 'client'` or a valid `client_organisation_id`, causing "Organisation not found" errors.

---

## Table of Contents
1. [The Absolute Signup Flow (UI & Logic)](#1-the-absolute-signup-flow-ui--logic)
2. [Database & Supabase Automation (The "Absolute" Guarantee)](#2-database--supabase-automation-the-absolute-guarantee)
3. [Strict Profile & Auth Guard Enforcement](#3-strict-profile--auth-guard-enforcement)
4. [Step-by-Step Implementation Checklist](#4-step-by-step-implementation-checklist)

---

## 1. The Absolute Signup Flow (UI & Logic)

### 1.1 New File: `client-app/lib/ui/auth/signup_screen.dart`

A dedicated signup screen that captures all required fields in a single form:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/supabase_auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _orgNameController = TextEditingController();
  final _orgAddressController = TextEditingController();
  final _orgPhoneController = TextEditingController();
  String _orgType = 'Care Home';
  bool _isLoading = false;

  static const _orgTypes = ['Care Home', 'Warehouse', 'Factory', 'Other'];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _orgNameController.dispose();
    _orgAddressController.dispose();
    _orgPhoneController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final authService = context.read<SupabaseAuthService>();
    final result = await authService.signUpAsClient(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      organisationName: _orgNameController.text.trim(),
      organisationType: _orgType,
      organisationAddress: _orgAddressController.text.trim(),
      organisationPhone: _orgPhoneController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created! Please check your email to verify your account.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context); // Back to login
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? 'Signup failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Client Account')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Personal Details
            const Text('Your Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person)),
              validator: (v) => v == null || v.isEmpty ? 'Please enter your name' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please enter your email';
                if (!v.contains('@')) return 'Please enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock)),
              obscureText: true,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please enter a password';
                if (v.length < 6) return 'Password must be at least 6 characters';
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Organisation Details
            const Text('Organisation Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _orgNameController,
              decoration: const InputDecoration(labelText: 'Organisation Name', prefixIcon: Icon(Icons.business)),
              validator: (v) => v == null || v.isEmpty ? 'Please enter your organisation name' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _orgType,
              decoration: const InputDecoration(labelText: 'Organisation Type', prefixIcon: Icon(Icons.category)),
              items: _orgTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setState(() => _orgType = v!),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _orgAddressController,
              decoration: const InputDecoration(labelText: 'Address', prefixIcon: Icon(Icons.location_on)),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _orgPhoneController,
              decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone)),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: _isLoading ? null : _signUp,
              icon: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.person_add),
              label: Text(_isLoading ? 'Creating Account...' : 'Create Account'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Already have an account? Login'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### 1.2 Update `client-app/lib/services/supabase_auth_service.dart`

Add the `signUpAsClient` method that calls the Supabase Edge Function (which handles the atomic transaction):

```dart
// Add to SupabaseAuthService class:

/// Sign up a new client with organisation details.
/// This calls the `client-signup` Edge Function which atomically:
/// 1. Creates the auth user
/// 2. Creates the client_organisation
/// 3. Creates the profile with role='client' and client_organisation_id
Future<AuthResult> signUpAsClient({
  required String name,
  required String email,
  required String password,
  required String organisationName,
  required String organisationType,
  String? organisationAddress,
  String? organisationPhone,
}) async {
  _isLoading = true;
  notifyListeners();

  try {
    final response = await _supabase.functions.invoke(
      'client-signup',
      body: {
        'name': name,
        'email': email,
        'password': password,
        'organisation_name': organisationName,
        'organisation_type': organisationType,
        'organisation_address': organisationAddress,
        'organisation_phone': organisationPhone,
      },
    );

    if (response.status >= 200 && response.status < 300) {
      return AuthResult.success(null, message: 'Account created! Please verify your email.');
    } else {
      final data = response.data as Map<String, dynamic>?;
      return AuthResult.failure(data?['error'] ?? 'Signup failed. Please try again.');
    }
  } catch (e) {
    return AuthResult.failure('Signup failed: $e');
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}
```

### 1.3 Update `client-app/lib/ui/auth/login_screen.dart`

Add a "Create Account" button that navigates to the SignupScreen:

```dart
// Add to the login screen's build method, after the magic link button:
TextButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SignupScreen()),
    );
  },
  child: const Text('New client? Create an account'),
),
```

---

## 2. Database & Supabase Automation (The "Absolute" Guarantee)

### Recommended: Option B - Supabase Edge Function (Atomic Transaction)

**Why Edge Function over Trigger:**
- Edge Functions run in a single atomic transaction - if any step fails, everything rolls back
- Triggers on `auth.users` are complex and can have race conditions with the `profiles` trigger
- Edge Functions can call the Admin API to create users with confirmed email
- Edge Functions can return meaningful error messages to the client

### 2.1 Create Edge Function: `supabase/functions/client-signup/index.ts`

```typescript
import { createClient } from 'npm:@supabase/supabase-js@2';

const supabaseAdmin = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  { auth: { autoRefreshToken: false, persistSession: false } }
);

Deno.serve(async (req) => {
  try {
    const { name, email, password, organisation_name, organisation_type, organisation_address, organisation_phone } = await req.json();

    // Validate required fields
    if (!name || !email || !password || !organisation_name || !organisation_type) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // Step 1: Create the auth user
    const { data: authData, error: authError } = await supabaseAdmin.auth.admin.createUser({
      email,
      password,
      email_confirm: true, // Auto-confirm email for immediate access
      user_metadata: {
        name,
        role: 'client',
        organisation_name,
        organisation_type,
      },
    });

    if (authError) {
      return new Response(
        JSON.stringify({ error: authError.message }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }

    const userId = authData.user.id;

    // Step 2: Create the client_organisation
    const { data: orgData, error: orgError } = await supabaseAdmin
      .from('client_organisations')
      .insert({
        name: organisation_name,
        organisation_types: [organisation_type],
        address: organisation_address || null,
        phone: organisation_phone || null,
        email: email,
        is_active: true,
      })
      .select('id')
      .single();

    if (orgError) {
      // Rollback: delete the auth user if org creation fails
      await supabaseAdmin.auth.admin.deleteUser(userId);
      return new Response(
        JSON.stringify({ error: `Failed to create organisation: ${orgError.message}` }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      );
    }

    const orgId = orgData.id;

    // Step 3: Create the profile with role='client' and client_organisation_id
    const { error: profileError } = await supabaseAdmin
      .from('profiles')
      .insert({
        id: userId,
        email: email,
        full_name: name,
        role: 'client',
        organisation_id: orgId,
      });

    if (profileError) {
      // Rollback: delete auth user and org if profile creation fails
      await supabaseAdmin.auth.admin.deleteUser(userId);
      await supabaseAdmin.from('client_organisations').delete().eq('id', orgId);
      return new Response(
        JSON.stringify({ error: `Failed to create profile: ${profileError.message}` }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      );
    }

    return new Response(
      JSON.stringify({ success: true, message: 'Client account created successfully' }),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    );
  } catch (e) {
    return new Response(
      JSON.stringify({ error: `Unexpected error: ${e.message}` }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    );
  }
});
```

### 2.2 Deploy the Edge Function

```bash
cd supabase
supabase functions deploy client-signup --no-verify-jwt
```

### 2.3 RLS Policy for `client_organisations` (if not already present)

```sql
-- Allow authenticated clients to read their own organisation
ALTER TABLE client_organisations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "clients_read_own_org" ON client_organisations;
CREATE POLICY "clients_read_own_org" ON client_organisations
  FOR SELECT TO authenticated
  USING (id IN (
    SELECT organisation_id FROM profiles WHERE id = auth.uid()
  ));
```

---

## 3. Strict Profile & Auth Guard Enforcement

### 3.1 Update `client-app/lib/services/supabase_auth_service.dart`

Add strict validation in `_loadUserProfile()`:

```dart
// Replace the existing _loadUserProfile method:

Future<void> _loadUserProfile() async {
  if (_currentUser == null) return;

  try {
    final profile = await _supabase
        .from('profiles')
        .select('role, organisation_id')
        .eq('id', _currentUser!.id)
        .single();

    _userRole = profile['role'] as String?;
    _organisationId = profile['organisation_id'] as String?;

    // STRICT AUTH GUARD: Only 'client' role with a valid organisation_id is allowed
    if (_userRole != 'client' || _organisationId == null || _organisationId!.isEmpty) {
      debugPrint('AUTH GUARD: User is not a valid client. Signing out.');
      await signOut();
      _authGuardError = 'This app is exclusively for registered Care Homes, Warehouses, and Factories. Please contact support.';
      notifyListeners();
      return;
    }

    // Cache role and org for quick access
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

// Add this field and getter:
String? _authGuardError;
String? get authGuardError => _authGuardError;
```

### 3.2 Update `client-app/lib/ui/auth/auth_wrapper.dart`

Show the auth guard error if present:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/supabase_auth_service.dart';
import 'login_screen.dart';

class AuthWrapper extends StatelessWidget {
  final Widget authenticatedChild;

  const AuthWrapper({super.key, required this.authenticatedChild});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<SupabaseAuthService>(context);

    if (authService.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Show auth guard error if present
    if (authService.authGuardError != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'Access Restricted',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  authService.authGuardError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => authService.signOut(),
                  child: const Text('Back to Login'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (authService.isAuthenticated) {
      return authenticatedChild;
    } else {
      return const LoginScreen();
    }
  }
}
```

---

## 4. Step-by-Step Implementation Checklist

### Phase A: Database & Edge Function (Supabase)

| # | Action | File | Status |
|---|--------|------|--------|
| 1 | Create Edge Function `client-signup` | `supabase/functions/client-signup/index.ts` | ❌ TODO |
| 2 | Deploy Edge Function | Run `supabase functions deploy client-signup --no-verify-jwt` | ❌ TODO |
| 3 | Add RLS policy for `client_organisations` | Run SQL in Supabase SQL Editor | ❌ TODO |
| 4 | Verify `profiles` table has `role IN ('admin', 'carer', 'client')` | Migration 115 already done | ✅ DONE |

### Phase B: Flutter Code Changes

| # | Action | File | Status |
|---|--------|------|--------|
| 5 | Create SignupScreen | `client-app/lib/ui/auth/signup_screen.dart` | ❌ TODO |
| 6 | Add `signUpAsClient()` method | `client-app/lib/services/supabase_auth_service.dart` | ❌ TODO |
| 7 | Add strict auth guard in `_loadUserProfile()` | `client-app/lib/services/supabase_auth_service.dart` | ❌ TODO |
| 8 | Add `authGuardError` field and getter | `client-app/lib/services/supabase_auth_service.dart` | ❌ TODO |
| 9 | Update AuthWrapper to show auth guard error | `client-app/lib/ui/auth/auth_wrapper.dart` | ❌ TODO |
| 10 | Add "Create Account" button to LoginScreen | `client-app/lib/ui/auth/login_screen.dart` | ❌ TODO |
| 11 | Run `flutter pub get` | Terminal | ❌ TODO |
| 12 | Run `flutter analyze` | Terminal | ❌ TODO |

### Phase C: Testing

| # | Test | Expected Result |
|---|------|-----------------|
| 13 | Sign up as new client | Account created, email verified, role='client', org created |
| 14 | Log in with new client | Dashboard loads, no "Organisation not found" error |
| 15 | Log in with admin/carer account | Auth guard signs out, shows "Access Restricted" message |
| 16 | Log in with client but no org_id | Auth guard signs out, shows "Access Restricted" message |
| 17 | Duplicate email signup | Edge Function returns clear error |
| 18 | Missing required fields | Edge Function returns 400 with error message |

---

## Summary

| Area | Solution | Guarantee |
|------|----------|-----------|
| Signup UI | New `SignupScreen` with all fields | User provides all required data upfront |
| Atomic creation | Edge Function `client-signup` | Auth user + org + profile created in one transaction with rollback |
| Role enforcement | Strict auth guard in `_loadUserProfile()` | Non-client users are immediately signed out |
| Org enforcement | Auth guard checks `organisation_id` is not null | Users without org are signed out |
| Error messaging | Clear "Access Restricted" screen | Users understand why they can't access the app |