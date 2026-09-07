# Staff-App Architecture Report

## Executive Summary

This document provides a comprehensive analysis of the **CareQA Staff-App** (Flutter + Supabase), covering:
- All screens and their functions
- Service layer architecture
- Data models and database relationships
- **Root cause diagnosis of the 406 (Not Acceptable) error** on profile loading
- Actionable remediation steps

---

## 1. Application Structure

```
staff-app/
├── lib/
│   ├── main.dart                          # App entry point, providers, Supabase init
│   ├── models/                            # 20+ data models
│   ├── services/                          # 15+ service classes
│   ├── ui/
│   │   ├── auth/                          # Login, biometric unlock, auth wrapper
│   │   ├── dashboard/                     # Main dashboard, shifts, shift detail, check-in
│   │   ├── competency/                    # Competency assessments
│   │   ├── compliance/                    # Compliance dashboard
│   │   ├── daily/                         # Daily notes, logs
│   │   ├── medication/                    # Medication management
│   │   ├── notifications/                 # Notification bell, inbox
│   │   ├── risk/                          # Risk assessments (10+ types)
│   │   └── common/                        # Shared UI components
│   ├── utils/                             # Date, dialog, snackbar helpers
│   └── widgets/                           # Reusable widgets (ShiftCard)
```

---

## 2. Core Services

### 2.1 SupabaseAuthService (`services/supabase_auth_service.dart`)

**Purpose**: Central authentication state management.

**Key Responsibilities**:
- Email/password sign-in
- Magic link (OTP) sign-in
- Biometric unlock (fingerprint/FaceID + PIN fallback)
- Session persistence via `SharedPreferences`
- **Profile loading** — **THIS IS WHERE THE 406 ERROR OCCURS**

**Critical Code Path** (lines 172-194):
```dart
Future<void> _loadUserProfile() async {
  if (_currentUser == null) return;

  try {
    final profile = await _supabase
        .from('profiles')
        .select('role, organisation_id')
        .eq('id', _currentUser!.id)
        .single();  // ← FAILS HERE WHEN PROFILE DOESN'T EXIST

    _userRole = profile['role'] as String?;
    _organisationId = profile['organisation_id'] as String?;
    // ... caching ...
    notifyListeners();
  } catch (e) {
    debugPrint('Error loading user profile: $e');
  }
}
```

**Auth State Listener** (lines 25-36):
```dart
_supabase.auth.onAuthStateChange.listen((data) {
  _currentUser = data.session?.user;
  if (_currentUser != null) {
    _loadUserProfile();  // Called on EVERY auth state change
  } else {
    _userRole = null;
    _organisationId = null;
  }
  notifyListeners();
});
```

### 2.2 ShiftService (`services/shift_service.dart`)

**Purpose**: Shift queries scoped to the logged-in carer.

```dart
Future<List<Shift>> getShiftsForCurrentCarer() async {
  final user = _client.auth.currentUser;
  if (user == null) return [];

  final response = await _client
      .from('shifts')
      .select('*, service_users(name), carers(name)')
      .eq('carer_id', user.id)  // Scoped to auth.uid()
      .order('scheduled_date', ascending: true)
      .order('start_time', ascending: true);

  return (response as List)
      .map((json) => Shift.fromMap(json as Map<String, dynamic>))
      .toList();
}
```

### 2.3 FirestoreService (`services/firestore_service.dart`)

**Purpose**: Legacy Firestore-backed visits (check-in/out).

```dart
Future<List<Shift>> getShiftsForCurrentUser(String carerId) async {
  final response = await _supabase
      .from('shifts')
      .select()
      .eq('carer_id', carerId);
  return (response as List<dynamic>)
      .map((item) => Shift.fromMap(item as Map<String, dynamic>))
      .toList();
}
```

### 2.4 Risk/Assessment Services (10+ services)

Each follows the same pattern:
- `getAssessmentsForUser(userId)`
- `createAssessment(data)`
- `updateAssessment(id, data)`
- `deleteAssessment(id)`

Examples: `ActivityRiskService`, `AnaphylaxisService`, `SepsisService`, `DiabetesService`, etc.

---

## 3. Screens & User Flows

### 3.1 Authentication Flow

| Screen | File | Purpose |
|--------|------|---------|
| **AuthWrapper** | `ui/auth/auth_wrapper.dart` | Gatekeeper: checks session → biometric → login |
| **LoginScreen** | `ui/auth/login_screen.dart` | Email/password + magic link |
| **BiometricUnlockScreen** | `ui/auth/biometric_unlock_screen.dart` | Fingerprint/FaceID unlock |

**Flow**:
```
App Start
    ↓
AuthWrapper.initState() → _checkSessionOnStartup()
    ↓
hasSessionCached() + isBiometricAvailable()
    ↓
├─ Valid session + biometric → BiometricUnlockScreen
├─ Valid session only → _loadUserProfile() → StaffDashboard
└─ No session → LoginScreen
```

### 3.2 Main Dashboard (`ui/dashboard/staff_dashboard.dart`)

**Structure**:
- AppBar: Title + NotificationBell + Logout
- Body: Welcome text + **ShiftsScreen** (embedded)

### 3.3 Shifts Screen (`ui/dashboard/shifts_screen.dart`)

**Features**:
- **Date navigation**: Prev/Next day + "Today" button
- **Status filter chips**: All / Scheduled / Confirmed / Completed / Declined
- **Pull-to-refresh** + refresh button
- **ShiftCard** list (time, status chip, service user, location)
- Tap → **ShiftDetailScreen**

**Data Source**: `ShiftService.getShiftsForCurrentCarer()`

### 3.4 Shift Detail Screen (`ui/dashboard/shift_detail_screen.dart`)

**Displays**:
- Status chip (color-coded)
- Service user, time, location, notes
- **Action buttons** (only for `scheduled`/`pending`):
  - **Accept** → `ShiftService.acceptShift()` → status = `confirmed`
  - **Decline** (with confirmation) → `ShiftService.declineShift()` → status = `declined`

### 3.5 Check-In Screen (`ui/dashboard/check_in_screen.dart`)

**Purpose**: Visit check-in/out with notes (uses FirestoreService for visits).

### 3.6 Risk Assessment Screens (10+)

Each risk type has a dedicated form screen:
- `AnaphylaxisRiskForm`, `SepsisRiskScreen`, `FallsRiskScreen`, `MedicationRiskScreen`, etc.
- All follow: Form → Validation → Service.createAssessment() → Navigate back

### 3.7 Competency & Compliance

- `CompetencyDashboardScreen` + individual competency forms
- `ComplianceDashboard` with scoring

---

## 4. Data Models

### 4.1 Shift (`models/shift.dart`)

```dart
class Shift {
  final String id;
  final String? serviceUserId;
  final String? serviceUserName;    // From joined service_users
  final String? carerId;
  final String? carerName;          // From joined carers
  final String? scheduledDate;      // YYYY-MM-DD (date type)
  final String startTime;           // HH:MM:SS (time type)
  final String endTime;
  final String status;              // scheduled/pending/confirmed/completed/declined
  final String? location;
  final int? staffRequired;
  final String? staffType;
  final String? notes;
  final String? clientOrganisationId;
  final String? organisationId;
}
```

### 4.2 Visit (`models/visit.dart`)

```dart
class Visit {
  final String id;
  final String shiftId;
  final String carerId;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final String notes;
}
```

### 4.3 Assessment Models (10+)

Each has: `id`, `userId`, `date`, risk-specific fields, `createdAt`, `updatedAt`.

---

## 5. Database Schema (Relevant Tables)

### 5.1 `auth.users` (Supabase Auth)
- `id` (UUID, PK) — **Same UUID used in profiles & carers**
- `email`, `encrypted_password`, `email_confirmed_at`, etc.

### 5.2 `public.profiles`
| Column | Type | Notes |
|--------|------|-------|
| `id` | UUID | PK, FK → auth.users.id |
| `email` | text | |
| `full_name` | text | |
| `name` | text | Duplicate of full_name |
| `role` | text | carer/senior_carer/team_leader/manager/admin/super_admin |
| `organisation_id` | UUID | FK → organisations |
| `overseer_id` | UUID | FK → profiles.id (self-ref) |
| `is_active` | boolean | |

**RLS Policies**:
- `Users can view own profile` — `SELECT` WHERE `id = auth.uid()`
- `Users can view their sub-users` — `SELECT` WHERE `overseer_id = auth.uid()`

### 5.3 `public.carers`
| Column | Type | Notes |
|--------|------|-------|
| `id` | UUID | PK, FK → auth.users.id |
| `name`, `email`, `phone` | text | |
| `job_role`, `staff_type` | text | |
| `organisation_id` | UUID | FK → organisations |
| `invite_status` | text | invited/active/inactive |
| `invited_at`, `invited_by` | timestamptz/UUID | |
| `is_active` | boolean | |

### 5.4 `public.shifts`
| Column | Type | Notes |
|--------|------|-------|
| `id` | UUID | PK |
| `carer_id` | UUID | FK → carers.id ( = auth.uid() ) |
| `service_user_id` | UUID | FK → service_users.id |
| `scheduled_date` | date | |
| `start_time`, `end_time` | time | |
| `status` | text | scheduled/pending/confirmed/completed/declined |
| `location`, `notes` | text | |

---

## 6. 406 (Not Acceptable) Error — Root Cause Diagnosis

### 6.1 Error Details

```
GET https://...supabase.co/rest/v1/profiles?select=role%2Corganisation_id&id=eq.5db831cf-a895-487f-b8fc-2fa4293b4554 406 (Not Acceptable)

PostgrestException(message: Cannot coerce the result to a single JSON object, code: PGRST116, details: The result contains 0 rows)
```

### 6.2 What Happened

1. User `5db831cf-a895-487f-b8fc-2fa4293b4554` exists in **`auth.users`** (email: `matthewgitau25@gmail.com`)
2. **NO record exists in `public.profiles`** for this user ID
3. **NO record exists in `public.carers`** for this user ID
4. `SupabaseAuthService._loadUserProfile()` calls:
   ```dart
   .from('profiles')
   .select('role, organisation_id')
   .eq('id', _currentUser!.id)
   .single()  // ← PostgREST .single() requires EXACTLY 1 row
   ```
5. PostgREST returns **0 rows** → throws **PGRST116** (406 Not Acceptable)

### 6.3 Why the Profile is Missing

The user was likely created **before** the carer invite system (Phase 4) was implemented, or:
- Created via Supabase Dashboard / direct SQL
- Created via a different sign-up flow that didn't create the profile
- The `create_carer_with_auth` RPC was not used for this user

**The RPC `create_carer_with_auth` (Phase 4) atomically creates all three:**
1. `auth.users` (GoTrue)
2. `public.profiles` (with `role = p_staff_type`, `overseer_id = p_invited_by`)
3. `public.carers` (with `invite_status = 'invited'`)

But this user bypassed that flow.

### 6.4 Code Location

**File**: `staff-app/lib/services/supabase_auth_service.dart`
**Method**: `_loadUserProfile()` (lines 172-194)
**Called from**: 
- `AuthWrapper._buildRoleGate()` → blocks dashboard if `userRole == null`
- `onAuthStateChange` listener → runs on every auth event

---

## 7. Remediation Plan

### 7.1 Immediate Fix (Defensive Code)

**File**: `staff-app/lib/services/supabase_auth_service.dart`

Replace `.single()` with `.maybeSingle()` and handle missing profile gracefully:

```dart
Future<void> _loadUserProfile() async {
  if (_currentUser == null) return;

  try {
    final profile = await _supabase
        .from('profiles')
        .select('role, organisation_id')
        .eq('id', _currentUser!.id)
        .maybeSingle();  // Returns null if 0 rows, throws if >1

    if (profile == null) {
      // Profile doesn't exist — set defaults, don't crash
      _userRole = 'carer';  // Default role
      _organisationId = null;
      debugPrint('Profile not found for user ${_currentUser!.id}, using defaults');
    } else {
      _userRole = profile['role'] as String?;
      _organisationId = profile['organisation_id'] as String?;
    }

    // Cache role and org for quick access
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userRoleKey, _userRole ?? '');
    await prefs.setString(_userOrgKey, _organisationId ?? '');

    notifyListeners();
  } catch (e) {
    debugPrint('Error loading user profile: $e');
    // Don't rethrow — allow app to continue with defaults
  }
}
```

**Also update `AuthWrapper._buildRoleGate()`** to not block on null role:
```dart
Widget _buildRoleGate(SupabaseAuthService authService) {
  // Allow access even if profile hasn't loaded yet
  // Role will be loaded asynchronously
  return widget.authenticatedChild;
}
```

### 7.2 Data Fix (Create Missing Profile)

Run this SQL to create the missing profile for the affected user:

```sql
-- Get the user's email from auth.users
SELECT id, email FROM auth.users WHERE id = '5db831cf-a895-487f-b8fc-2fa4293b4554';

-- Insert profile (adjust role/organisation_id as needed)
INSERT INTO public.profiles (id, email, full_name, name, role, organisation_id, is_active)
VALUES (
  '5db831cf-a895-487f-b8fc-2fa4293b4554',
  'matthewgitau25@gmail.com',
  'Matthew Gitau',
  'Matthew Gitau',
  'carer',  -- or appropriate role
  (SELECT id FROM organisations LIMIT 1),  -- or specific org ID
  true
);

-- Optionally create carer record if they should be a carer
INSERT INTO public.carers (id, name, email, job_role, staff_type, organisation_id, invite_status, is_active)
VALUES (
  '5db831cf-a895-487f-b8fc-2fa4293b4554',
  'Matthew Gitau',
  'matthewgitau25@gmail.com',
  'carer',
  'carer',
  (SELECT id FROM organisations LIMIT 1),
  'active',
  true
);
```

### 7.3 Prevention (Future-Proofing)

1. **Enforce profile creation at sign-up**: Ensure ALL auth user creation paths call the RPC or create the profile
2. **Add a database trigger** on `auth.users` to auto-create profile:
   ```sql
   CREATE OR REPLACE FUNCTION public.handle_new_user()
   RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
   BEGIN
     INSERT INTO public.profiles (id, email, full_name, name, role, is_active)
     VALUES (NEW.id, NEW.email, NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'full_name', 'carer', true)
     ON CONFLICT (id) DO NOTHING;
     RETURN NEW;
   END;
   $$;
   
   CREATE TRIGGER on_auth_user_created
     AFTER INSERT ON auth.users
     FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
   ```
3. **Add health check endpoint** to detect users without profiles

---

## 8. Development Guidelines for Continuing Work

### 8.1 Adding New Screens

1. Create model in `models/`
2. Create service in `services/` (follow existing pattern)
3. Create screen in `ui/<feature>/`
4. Add route/navigation in `StaffDashboard` or relevant parent
5. Run `flutter analyze` — fix all errors/warnings

### 8.2 Database Changes

1. Create migration in `supabase/migrations/`
2. Apply locally: `supabase db reset` or run SQL directly
3. Update models to match new schema
4. Update services to use new columns

### 8.3 Authentication-Related Changes

**Always test these scenarios**:
- Fresh login (no cached session)
- Cached session + biometric unlock
- Cached session + biometric unavailable (fallback)
- Sign out → sign in as different user
- Profile missing (simulate by deleting from `profiles` table)

### 8.4 Key Files to Know

| File | Purpose |
|------|---------|
| `main.dart` | Providers, Supabase init |
| `services/supabase_auth_service.dart` | **Auth state, profile loading (406 fix here)** |
| `ui/auth/auth_wrapper.dart` | Auth gatekeeper |
| `ui/dashboard/staff_dashboard.dart` | Main shell |
| `ui/dashboard/shifts_screen.dart` | Shift list + filters |
| `ui/dashboard/shift_detail_screen.dart` | Accept/decline actions |
| `models/shift.dart` | Shift data model |
| `services/shift_service.dart` | Shift queries |

---

## 9. Testing Checklist

- [ ] Login with email/password
- [ ] Login with magic link
- [ ] Biometric unlock (device with biometrics)
- [ ] Biometric fallback (device without / disabled)
- [ ] Sign out → sign in as different user
- [ ] User with **missing profile** (simulate: `DELETE FROM profiles WHERE id = '...'`)
- [ ] Shift list loads for assigned carer
- [ ] Shift detail shows accept/decline for `scheduled` status
- [ ] Accept → status changes to `confirmed`
- [ ] Decline → status changes to `declined`
- [ ] Date navigation works
- [ ] Status filter works
- [ ] Pull-to-refresh works
- [ ] Check-in/out creates visit record
- [ ] Risk assessment forms submit correctly

---

## 10. Summary

The **staff-app is functionally complete** for Phases 1-5 (auth, shifts, check-in, risk assessments, competency). The **only blocker** is the 406 error when a user exists in `auth.users` but lacks a `public.profiles` record.

**Fix priority**: 
1. **Immediate**: Apply defensive code fix in `supabase_auth_service.dart` (`.maybeSingle()` + defaults)
2. **Data**: Create missing profile for affected user(s)
3. **Prevention**: Add database trigger for auto-profile creation

Once the 406 fix is deployed, the app will gracefully handle missing profiles and allow carers to access their shifts immediately.

---

*Report generated: 2026-08-15*  
*For: CareQA Staff-App Development Team*