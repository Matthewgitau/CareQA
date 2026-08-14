# Client-App Architectural Breakdown & Sub-User System

## Table of Contents
1. [High-Level Architecture](#1-high-level-architecture)
2. [Supabase Connection Setup](#2-supabase-connection-setup)
3. [Authentication & Session Flow](#3-authentication--session-flow)
4. [The Profile & Sub-User System](#4-the-profile--sub-user-system)
5. [Service Layer — What the App Calls & Writes](#5-service-layer--what-the-app-calls--writes)
6. [Database Schema & RLS Policies](#6-database-schema--rls-policies)
7. [Data Flow Diagrams](#7-data-flow-diagrams)
8. [Security Model](#8-security-model)
9. [Key Code Examples](#9-key-code-examples)
10. [Potential Issues & Recommendations](#10-potential-issues--recommendations)

---

## 1. High-Level Architecture

The client-app is a **Flutter** application that communicates exclusively with **Supabase** (Postgres + Auth + Realtime). It does **not** use a custom backend API — all reads and writes go directly through the Supabase client with **Row Level Security (RLS)** enforcing permissions.

```
┌─────────────────────────────────────────────────────────────┐
│                    Flutter Client-App                       │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  UI Layer (screens)                                   │  │
│  │  - AuthWrapper / Login / Signup                       │  │
│  │  - DashboardScreen                                    │  │
│  │  - BookShiftScreen                                    │  │
│  │  - PreferredCarersScreen ("My Profile & Sub-Users")   │  │
│  │  - ShiftsScreen / ShiftRegisterScreen                 │  │
│  └──────────────────────────┬────────────────────────────┘  │
│                             │                               │
│  ┌──────────────────────────▼────────────────────────────┐  │
│  │  Service Layer (state-less data access)               │  │
│  │  - SupabaseAuthService (auth state)                   │  │
│  │  - ShiftService (shifts CRUD)                         │  │
│  │  - ShiftTemplateService (templates)                   │  │
│  │  - StaffService (carers, ratings, sub-users)          │  │
│  └──────────────────────────┬────────────────────────────┘  │
│                             │                               │
│  ┌──────────────────────────▼────────────────────────────┐  │
│  │  SupabaseManager (singleton client wrapper)           │  │
│  └──────────────────────────┬────────────────────────────┘  │
└─────────────────────────────┼───────────────────────────────┘
                              │  HTTPS (REST/PostgREST)
┌─────────────────────────────▼───────────────────────────────┐
│                      Supabase Project                        │
│  ┌──────────────┐  ┌──────────────┐  ┌───────────────────┐  │
│  │ Auth (GoTrue)│  │  Postgres DB │  │ RLS Policies      │  │
│  │  - users     │  │  - profiles  │  │  - profiles RLS   │  │
│  │  - sessions  │  │  - shifts    │  │  - shifts RLS     │  │
│  └──────────────┘  │  - shift_    │  └───────────────────┘  │
│                    │    templates │                          │
│                    │  - visits    │                          │
│                    │  - carers    │                          │
│                    └──────────────┘                          │
└──────────────────────────────────────────────────────────────┘
```

### Key Characteristics
- **State management**: `provider` (`ChangeNotifierProvider`)
- **Models**: A mix of local models (`client-app/lib/models/`) and shared models (`packages/core/lib/`)
- **No server-side logic in the app**: all access control is delegated to Postgres RLS
- **Auth**: Supabase GoTrue (email/password, magic link, biometric)
- **UUID generation**: Client-side via `uuid` package for shift IDs

---

## 2. Supabase Connection Setup

### 2.1 `main.dart` — App Bootstrap

The app initializes Supabase in `main()` before `runApp()`:

```dart
// client-app/lib/main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env for credentials (with hardcoded fallbacks)
  final supabaseUrl = env('SUPABASE_URL', 'https://aucflsskbhaloutsdlwc.supabase.co');
  final supabaseAnonKey = env('SUPABASE_ANON_KEY', 'sb_publishable_ruC1mXCXtyHHsNX7KckTfA_YGrN-2hy');

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(const CareQAClientApp());
}
```

### 2.2 `CareQAClientApp` — Provider Wiring

```dart
class CareQAClientApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SupabaseAuthService>(
          create: (_) => SupabaseAuthService(supabase),
        ),
      ],
      child: MaterialApp(
        title: 'CareQA Client',
        home: const AuthWrapper(),
      ),
    );
  }
}
```

The `SupabaseAuthService` is provided app-wide so any screen can access the current auth state.

### 2.3 `SupabaseManager` — Singleton Client Wrapper

```dart
// client-app/lib/utils/supabase_client.dart
class SupabaseManager {
  static final SupabaseManager _instance = SupabaseManager._internal();
  late final SupabaseClient client;

  SupabaseManager._internal() {
    client = Supabase.instance.client;
  }

  static SupabaseManager get instance => _instance;
}
```

Every service obtains the client via `SupabaseManager.instance.client`. This provides a single access point to the global Supabase client.

---

## 3. Authentication & Session Flow

### 3.1 `SupabaseAuthService`

This is a `ChangeNotifier` that wraps all authentication. It is constructed with the Supabase client and listens for auth state changes:

```dart
SupabaseAuthService(this._supabase) {
  _supabase.auth.onAuthStateChange.listen((data) {
    _currentUser = data.session?.user;
    if (_currentUser != null) {
      _loadUserProfile();
    } else {
      _userRole = null;
      _organisationId = null;
      _clientOrganisationId = null;
    }
    notifyListeners();
  });
}
```

### 3.2 Login (`signInWithEmailPassword`)

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
    return AuthResult.failure('Sign in failed.');
  }
  await _loadUserProfile();
  await _cacheSessionFlag(true);
  return AuthResult.success(response.user!);
}
```

### 3.3 Profile Loading & AUTH GUARD

On authentication, the service loads the user's profile to determine their role and organisation. There is a **strict auth guard**:

```dart
Future<void> _loadUserProfile() async {
  final profile = await _supabase
      .from('profiles')
      .select('role, organisation_id, client_organisation_id')
      .eq('id', _currentUser!.id)
      .single();

  _userRole = profile['role'];
  _organisationId = profile['organisation_id'];
  _clientOrganisationId = profile['client_organisation_id'];

  // STRICT AUTH GUARD: Only 'client' role OR a valid organisation is allowed
  if (_userRole != 'client') {
    await signOut();
    _authGuardError = 'This app is exclusively for registered Care Homes.';
    return;
  }
  if (_organisationId == null || _organisationId!.isEmpty) {
    await signOut();
    _authGuardError = 'Your account is not fully set up.';
    return;
  }
}
```

> ⚠️ **Key detail for sub-users:** Because the auth guard requires `role == 'client'`, every sub-user must ALSO have `role = 'client'` in their profile (they are "client" users of the same care home, differentiated by `overseer_id`).

### 3.4 Exposed Getters

```dart
User? get currentUser => _currentUser;
String? get userRole => _userRole;
String? get organisationId => _organisationId;
String? get clientOrganisationId => _clientOrganisationId;
bool get isClientUser => _userRole == 'client';
```

---

## 4. The Profile & Sub-User System

### 4.1 Overview

The "My Profile & Sub-Users" screen (`preferred_carers_screen.dart`) replaced the old "Preferred Carers" screen. It:
1. Displays the **logged-in user's profile** (name, email, org ID, role, phone)
2. Lists **sub-users** they have created
3. Lets them **create new sub-users** who can log in and book shifts under the same care home
4. Lets them **remove** (soft-delete) sub-users

### 4.2 User Profile Loading

```dart
// client-app/lib/ui/staff/preferred_carers_screen.dart
Future<void> _loadUserProfile() async {
  final userId = _authService.currentUser?.id;
  if (userId == null) return;

  final response = await _staffService.client
      .from('profiles')
      .select('role, organisation_id, client_organisation_id, full_name, email, phone')
      .eq('id', userId)
      .single();

  setState(() {
    _userProfile = {
      'full_name': response['full_name'],
      'email': response['email'],
      'client_organisation_id': response['client_organisation_id'],
      'role': response['role'],
      'phone': response['phone'],
      'organisation_id': response['organisation_id'],
    };
    _isLoading = false;
  });
}
```

### 4.3 Listing Sub-Users

Sub-users are profiles where `overseer_id = currentUser.id`:

```dart
Future<void> _loadSubUsers() async {
  final userId = _authService.currentUser?.id;
  if (userId == null) return;

  final response = await _staffService.client
      .from('profiles')
      .select('id, email, full_name, role, organisation_id')
      .eq('overseer_id', userId)
      .eq('is_active', true);

  setState(() {
    _subUsers = (response as List)
        .map((e) => Carer.fromJson(e as Map<String, dynamic>))
        .toList();
    _isLoading = false;
  });
}
```

### 4.4 Creating a Sub-User (CRITICAL)

The sub-user creation calls `Supabase.auth.signUp()` **with metadata** that the DB trigger uses:

```dart
final authResult = await _authService.supabase.auth.signUp(
  email: _emailController.text.trim(),
  password: _passwordController.text,
  data: {
    'role': 'client',
    'full_name': _nameController.text.trim(),
    'is_sub_user': 'true',
    'overseer_id': _authService.currentUser?.id,
    'client_organisation_id': _userProfile?['client_organisation_id'],
    'organisation_id': _userProfile?['organisation_id'],
  },
);
```

> **How it works:** The app passes `is_sub_user: 'true'` plus the parent's org IDs and their own user ID as `overseer_id`. A **database trigger** (`handle_new_client_signup`) reads these metadata values and creates the profile row automatically. The app does **not** manually insert into `profiles` anymore (previously it did, which caused conflicts with the trigger).

### 4.5 Removing a Sub-User (Soft Delete)

```dart
await _staffService.client
    .from('profiles')
    .update({'is_active': false})
    .eq('id', subUser.id);
```

---

## 5. Service Layer — What the App Calls & Writes

### 5.1 `StaffService` — Carers, Ratings, and Sub-User Support

**Public getter for Supabase client:**
```dart
class StaffService {
  final SupabaseClient _client = SupabaseManager.instance.client;
  SupabaseClient get client => _client;
  // ...
}
```

**Get available carers** (queries `client_organisation_spl` → `carers`):
```dart
Future<List<Carer>> getAvailableCarers(String clientOrganisationId) async {
  final splResponse = await _client
      .from('client_organisation_spl')
      .select('service_provider_id')
      .eq('client_org_id', clientOrganisationId)
      .eq('status', 'active');

  final agencyIds = (splResponse as List)
      .map((e) => e['service_provider_id'] as String)
      .toList();

  final response = await _client
      .from('carers')
      .select()
      .or('organisation_id.in.(${agencyIds.join(',')}),organisation_id.is.null')
      .eq('is_active', true)
      .order('name');

  return (response as List)
      .map((json) => Carer.fromJson(json as Map<String, dynamic>))
      .toList();
}
```

**Get carer rating ranking** (queries `visits`):
```dart
Future<CarerRatingRanking> getCarerRatingsRanking(String clientOrganisationId) async {
  final visitsResponse = await _client
      .from('visits')
      .select('carer_id, staff_rating')
      .eq('client_organisation_id', clientOrganisationId)
      .not('staff_rating', 'is', null);

  // aggregate per carer, exclude any with rating < 3, sort by avg desc
  // ...
  return CarerRatingRanking(ranked: ranked, disqualifiedCarerIds: disqualified);
}
```

### 5.2 `ShiftService` — Shift CRUD & Sub-User Shift Attribution

This is the key service for shift creation. Notice how `created_by` is set to the **current logged-in user's ID** — meaning a sub-user who books a shift is attributed as the creator:

```dart
Future<Shift> createShift({...}) async {
  final shiftId = _uuid.v4();
  final auth = SupabaseManager.instance.client.auth.currentUser;
  final userId = auth?.id ?? '';   // <-- current user (parent OR sub-user)

  final shiftData = {
    'id': shiftId,
    'client_organisation_id': clientOrganisationId,
    'organisation_id': organisationId,
    'scheduled_date': scheduledDate.toIso8601String().split('T')[0],
    'start_time': 'HH:MM:00',
    'end_time': 'HH:MM:00',
    'status': 'scheduled',
    'shift_type': 'care',
    'location': location,
    'staff_required': staffRequired ?? 1,
    'staff_type': staffType,
    'notes': notes,
    'broadcast_type': broadcastType.name,
    'created_by': userId,          // <-- attribution to the scheduling user
  };

  final response = await _client
      .from('shifts')
      .insert(shiftData)
      .select()
      .single();

  return Shift.fromJson(response as Map<String, dynamic>);
}
```

Other shift operations:
- `getShifts(clientOrganisationId)` → SELECT from `shifts`
- `broadcastShift` / `broadcastToAll` → INSERT multiple shifts
- `assignCarer(shiftId, carerId)` → UPDATE `shifts`
- `updateShiftStatus` → UPDATE
- `checkCarerAvailability` → SELECT + overlap logic

### 5.3 `ShiftTemplateService` — Shift Templates

```dart
Future<List<ShiftTemplate>> getTemplates(String clientOrganisationId) async {
  final response = await _client
      .from('shift_templates')
      .select()
      .eq('client_organisation_id', clientOrganisationId)
      .eq('is_active', true)
      .order('name', ascending: true);

  return (response as List)
      .map((json) => ShiftTemplate.fromJson(json as Map<String, dynamic>))
      .toList();
}
```

---

## 6. Database Schema & RLS Policies

### 6.1 `profiles` Table (used by sub-user system)

| Column | Type | Purpose |
|--------|------|---------|
| `id` | uuid | PK, matches `auth.users.id` |
| `email` | text | User email |
| `full_name` / `name` | text | Display name |
| `role` | text | `client`, `carer`, `admin`, etc. |
| `client_organisation_id` | uuid | The care home (key for sub-users) |
| `organisation_id` | uuid | Parent organisation (FK) |
| `overseer_id` | uuid | **The parent who created this sub-user** |
| `is_active` | boolean | Soft-delete flag |

### 6.2 RLS Policies on `profiles` (after migrations 128–130)

```
Users can view own profile          (SELECT: id = auth.uid())
Users can view their sub-users      (SELECT: overseer_id = auth.uid())
Users can create sub-users under themselves (INSERT: overseer_id = auth.uid())
Users can update own profile        (UPDATE: id = auth.uid())
Overseers can update their sub-users (UPDATE: overseer_id = auth.uid())
Overseers can soft-delete their sub-users (UPDATE: overseer_id = auth.uid())
```

> **Note on recursion fix:** Migration 130 removed the policy `Users can view profiles in same care home` because its subquery on `profiles` caused **infinite recursion** (500 error → auto logout). The remaining policies are non-recursive (they compare against `auth.uid()` directly).

### 6.3 The Sub-User Creation Trigger

The trigger `on_auth_user_created_client` fires on `auth.users` INSERT and calls `handle_new_client_signup()`. The modified function (migrations 129/130) detects `is_sub_user`:

```sql
IF meta->>'is_sub_user' = 'true' THEN
  -- Reuse the parent's care home; do NOT create a new organisation
  v_client_org_id := (meta->>'client_organisation_id')::UUID;
  v_overseer_id   := (meta->>'overseer_id')::UUID;

  INSERT INTO public.profiles (
    id, email, full_name, name, role,
    client_organisation_id, organisation_id,
    overseer_id, is_active
  ) VALUES (
    NEW.id, NEW.email, v_full_name, v_full_name, 'client',
    v_client_org_id, v_parent_org_id, v_overseer_id, true
  )
  ON CONFLICT (id) DO UPDATE SET ...;
END IF;
```

This ensures:
- A sub-user shares the **same** `client_organisation_id` as the parent (same care home)
- `overseer_id` links back to the parent
- No accidental new organisation is created

---

## 7. Data Flow Diagrams

### 7.1 Sub-User Creation Flow

```
Parent (logged in as client)
  │
  │ 1. Navigates to "My Profile & Sub-Users"
  │ 2. Clicks "Create Sub-User"
  │ 3. Enters name / email / password
  ▼
preferred_carers_screen.dart
  │
  │ supabase.auth.signUp(email, password, data: { role, is_sub_user,
  │     overseer_id, client_organisation_id, organisation_id })
  ▼
Supabase Auth (GoTrue)
  │
  │ INSERT INTO auth.users (via trigger)
  ▼
handle_new_client_signup() trigger
  │
  │ Detects is_sub_user='true'
  ▼
INSERT INTO profiles (id, role='client', client_organisation_id=<parent's>,
                      overseer_id=<parent's id>, is_active=true)
  │
  ▼
Sub-user can now log in with their own email/password
```

### 7.2 Sub-User Booking a Shift

```
Sub-user (logged in, role='client', same client_organisation_id)
  │
  │ Navigates to "Book a Shift"
  ▼
book_shift_screen.dart
  │
  ▼
ShiftService.createShift()
  │
  │ created_by = <sub-user's auth.uid()>
  │ client_organisation_id = <same care home as parent>
  ▼
INSERT INTO shifts (created_by=<sub-user id>, client_organisation_id=<care home>)
  │
  ▼
RLS "Clients can create shifts for their own care home" (WITH CHECK passes:
  client_organisation_id = parent's org = sub-user's org)
```

---

## 8. Security Model

| Concern | Mechanism |
|---------|-----------|
| Authentication | Supabase GoTrue (email/password) |
| Authorization | Postgres RLS policies on each table |
| Sub-user isolation | `overseer_id` + same `client_organisation_id` |
| Role gating | Auth guard in `SupabaseAuthService` (requires `role='client'`) |
| Soft delete | `is_active = false` on `profiles` |
| Shift ownership | `created_by` field set to current user's `auth.uid()` |

> **Important:** Because the auth guard requires `role == 'client'`, sub-users are created with `role = 'client'` — they are "client users" of the same care home, distinguished only by `overseer_id`.

---

## 9. Key Code Examples

### 9.1 Signing up a sub-user (Flutter)

```dart
final authResult = await _authService.supabase.auth.signUp(
  email: email,
  password: password,
  data: {
    'role': 'client',
    'full_name': name,
    'is_sub_user': 'true',
    'overseer_id': parentUserId,
    'client_organisation_id': parentOrgId,
    'organisation_id': parentOrganisationId,
  },
);
```

### 9.2 Reading sub-users (Flutter)

```dart
final response = await _staffService.client
    .from('profiles')
    .select('id, email, full_name, role, organisation_id')
    .eq('overseer_id', currentUserId)
    .eq('is_active', true);
```

### 9.3 Creating a shift with sub-user attribution (Flutter)

```dart
final shiftData = {
  'id': uuid.v4(),
  'created_by': SupabaseManager.instance.client.auth.currentUser!.id,
  'client_organisation_id': clientOrgId,
  'scheduled_date': dateStr,
  'start_time': '08:00:00',
  'end_time': '16:00:00',
  'status': 'scheduled',
  // ...
};
await _client.from('shifts').insert(shiftData).select().single();
```

### 9.4 The trigger creating a sub-user profile (SQL)

```sql
CREATE OR REPLACE FUNCTION public.handle_new_client_signup()
 RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER AS $function$
BEGIN
  meta := NEW.raw_user_meta_data;
  v_role := COALESCE(meta->>'role', 'client');

  IF v_role = 'client' AND meta->>'is_sub_user' = 'true' THEN
    -- Reuse parent's org, set overseer_id
    INSERT INTO public.profiles (
      id, email, full_name, name, role,
      client_organisation_id, organisation_id,
      overseer_id, is_active
    ) VALUES (
      NEW.id, NEW.email,
      COALESCE(meta->>'full_name', NEW.email),
      COALESCE(meta->>'full_name', NEW.email),
      'client',
      (meta->>'client_organisation_id')::UUID,
      (meta->>'organisation_id')::UUID,
      (meta->>'overseer_id')::UUID,
      true
    );
  END IF;
  RETURN NEW;
END;
$function$;
```

---

## 10. Potential Issues & Recommendations

### 10.1 Auth Guard Conflict with Future Roles
The auth guard requires `role == 'client'`. If you later want sub-users with different roles (e.g., `carer`), the guard will sign them out. Recommend adding an explicit check for `overseer_id IS NOT NULL` as an allowed case.

### 10.2 Mixed Model Usage
The app uses local models (`client-app/lib/models/`) alongside shared core models (`packages/core/lib/`). For example, `StaffService` uses the local `Carer`, while `ShiftService` uses the core `Shift`. This duplication should be consolidated.

### 10.3 `profiles` RLS Recursion (FIXED)
Migration 130 fixed an infinite-recursion issue in the `profiles` RLS policy. Be careful when adding any new policy that subqueries `profiles` itself — prefer `auth.uid()` comparisons or a `SECURITY DEFINER` function.

### 10.4 Shift Attribution
Sub-user shift attribution works via `created_by = auth.uid()`. To display "which user scheduled this shift" in the admin-app, you must join `shifts.created_by` to `profiles`. Ensure that column is selected in admin queries.

### 10.5 Client-Side UUID for Shifts
Shifts use client-generated UUIDs (`uuid.v4()`). This is fine for inserts but requires the client and DB to agree on the PK. If any server-side logic generates IDs, this could conflict.

---

## Appendix: All Supabase Tables Referenced

| Table | Read/Write | Purpose |
|-------|-----------|---------|
| `profiles` | R/W | User profiles, roles, sub-user linkage (`overseer_id`) |
| `shifts` | R/W | Shift records; `created_by` = scheduling user |
| `shift_templates` | R/W | Reusable shift templates per care home |
| `carers` | R | Available carers (for preferred carer list) |
| `visits` | R | Carer rating data (via `staff_rating`) |
| `client_organisation_spl` | R | Service Provider List (agencies) |
| `client_organisations` | R | Care home / client organisation records |
| `routes` | R | Route schedule (secondary view) |

---

*Report generated based on the current state of `client-app/`, `packages/core/`, and `supabase/migrations/128-130`.*