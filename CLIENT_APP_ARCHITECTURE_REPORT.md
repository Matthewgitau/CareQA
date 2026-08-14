# Client App Architecture & Compilation Error Report

## 1. Project Overview

The `client-app` is a Flutter-based mobile application for the CareQA staffing platform. It allows clients (care homes, warehouses, cleaning companies) to book shifts, manage staff attendance via 2FA, rate staff performance, and view invoices.

**Location:** `c:\Users\matth\src\XP Software\CareQA\client-app\`

---

## 2. Complete File Structure

```
client-app/
├── pubspec.yaml                          # Dependencies (supabase_flutter, provider, intl, local_auth)
├── lib/
│   ├── main.dart                         # App entry point
│   ├── models/
│   │   ├── shift.dart                    # Shift data model
│   │   ├── booking.dart                  # Booking data model
│   │   └── timesheet_entry.dart          # Timesheet entry model
│   ├── services/
│   │   ├── auth_service.dart             # Singleton auth service (Supabase profiles query)
│   │   ├── supabase_auth_service.dart    # Full auth with biometric, magic link, role hierarchy
│   │   ├── shift_service.dart            # Shift CRUD (getShifts, createShift, etc.)
│   │   ├── booking_service.dart          # Booking CRUD
│   │   ├── timesheet_service.dart        # Timesheet confirmation
│   │   └── supabase_client.dart          # Supabase client singleton
│   ├── ui/
│   │   ├── auth/
│   │   │   └── biometric_unlock_screen.dart  # Biometric authentication screen
│   │   ├── dashboard/
│   │   │   └── dashboard_screen.dart         # Main dashboard with 4 navigation tiles
│   │   ├── shifts/
│   │   │   ├── shift_list_screen.dart        # Lists available shifts + ShiftDetailScreen
│   │   │   ├── book_shift_screen.dart        # Shift booking form (date, time, staff type)
│   │   │   └── shift_register_screen.dart    # Timesheet confirmation (2FA attendance)
│   │   └── bookings/
│   │       └── booking_history_screen.dart   # Past bookings list
│   └── utils/
│       └── supabase_client.dart              # SupabaseManager singleton
└── test/
```

---

## 3. Dependency Graph (What Imports What)

```
dashboard_screen.dart
  ├── supabase_auth_service.dart  (for signOut)
  ├── shift_list_screen.dart      (ShiftListScreen)
  ├── book_shift_screen.dart      (BookShiftScreen)
  ├── shift_register_screen.dart  (ShiftRegisterScreen)
  └── booking_history_screen.dart (BookingHistoryScreen)

shift_list_screen.dart
  ├── shift_service.dart          (ShiftService)
  ├── auth_service.dart           (AuthService)
  ├── models/shift.dart           (Shift model)
  └── book_shift_screen.dart      (BookShiftScreen - for navigation from ShiftDetailScreen)

book_shift_screen.dart
  ├── models/shift.dart           (Shift model)
  ├── shift_service.dart          (ShiftService)
  └── supabase_auth_service.dart  (SupabaseAuthService - for organisationId)

shift_register_screen.dart
  ├── timesheet_service.dart      (TimesheetService)
  ├── auth_service.dart           (AuthService)
  └── models/timesheet_entry.dart (TimesheetEntry model)

booking_history_screen.dart
  ├── booking_service.dart        (BookingService)
  ├── auth_service.dart           (AuthService)
  └── models/booking.dart         (Booking model)
```

---

## 4. Service Layer Details

### 4.1 `auth_service.dart` (Singleton)
```dart
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final SupabaseClient _client = Supabase.instance.client;

  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    final response = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();
    return response as Map<String, dynamic>;
  }
}
```
- **Purpose:** Lightweight singleton for fetching the current user's profile from the `profiles` table
- **Used by:** `ShiftListScreen`, `ShiftRegisterScreen`, `BookingHistoryScreen` (all call `getCurrentUserProfile()` to get `organisation_id`)

### 4.2 `supabase_auth_service.dart` (ChangeNotifier)
```dart
class SupabaseAuthService extends ChangeNotifier {
  final SupabaseClient _supabase;
  final LocalAuthentication _localAuth = LocalAuthentication();
  User? _currentUser;
  String? _userRole;
  String? _organisationId;

  SupabaseAuthService(this._supabase) {
    _supabase.auth.onAuthStateChange.listen((data) {
      _currentUser = data.session?.user;
      if (_currentUser != null) _loadUserProfile();
      notifyListeners();
    });
  }
```
- **Purpose:** Full auth management with email/password, magic link, biometric unlock, role hierarchy
- **Used by:** `DashboardScreen` (for `signOut()`), `BookShiftScreen` (for `organisationId`)

### 4.3 `shift_service.dart`
```dart
class ShiftService {
  final SupabaseClient _client = SupabaseManager.instance.client;

  Future<List<Shift>> getShifts(String organisationId) async { ... }
  Future<Shift> getShiftById(String id) async { ... }
  Future<Shift> createShift(Shift shift) async { ... }
  Future<Shift> updateShift(Shift shift) async { ... }
  Future<void> deleteShift(String id) async { ... }
}
```
- **Constructor takes ZERO arguments** - uses `SupabaseManager.instance.client` internally
- **Key issue:** `book_shift_screen.dart` was previously calling `ShiftService(Supabase.instance.client, auth.organisationId)` with 2 positional args, which doesn't match the no-arg constructor

---

## 5. Compilation Error Analysis

### Error 1: Duplicate `BookShiftScreen` Class Definition

**Error message:**
```
'BookShiftScreen' is imported from both
'package:careqa_client/ui/shifts/book_shift_screen.dart' and
'package:careqa_client/ui/shifts/shift_list_screen.dart'
```

**Root cause:** The file `shift_list_screen.dart` contained TWO class definitions:
1. `ShiftListScreen` (lines 7-82) - the intended class
2. `BookShiftScreen` (lines 153-224) - a DUPLICATE class that was accidentally left in the file

This meant that when `dashboard_screen.dart` imported `shift_list_screen.dart`, it also pulled in the duplicate `BookShiftScreen` class. When it also imported `book_shift_screen.dart` (which has the canonical `BookShiftScreen`), Dart saw two definitions of the same class name and threw the "imported from both" error.

**The cascade effect:** Because the compiler couldn't resolve which `BookShiftScreen` to use, it couldn't type-check the `MaterialPageRoute(builder: (_) => const BookShiftScreen())` expression. This caused the `InvalidType` error and the entire Dart compiler to crash with the `Unsupported operation: Unsupported invalid type` stack trace.

**Fix applied:**
1. Removed the duplicate `BookShiftScreen` class from `shift_list_screen.dart` (lines 153-224 deleted)
2. Added `import 'book_shift_screen.dart';` to `shift_list_screen.dart` so `ShiftDetailScreen` can still navigate to it

### Error 2: Wrong `ShiftService` Constructor Call

**Error message:**
```
lib/ui/shifts/book_shift_screen.dart:106:33: Error: Too many positional arguments: 0 allowed, but 2 found.
    final service = ShiftService(Supabase.instance.client, auth.organisationId);
```

**Root cause:** `book_shift_screen.dart` was calling `ShiftService(Supabase.instance.client, auth.organisationId)` with 2 positional arguments, but `ShiftService`'s constructor takes zero arguments (it uses `SupabaseManager.instance.client` internally).

**Fix applied:** Changed to `final service = ShiftService();`

### Error 3: Missing `const` Constructors

**Error message:**
```
Cannot invoke a non-'const' constructor where a const expression is expected.
    MaterialPageRoute(builder: (_) => const ShiftListScreen())
```

**Root cause:** `ShiftListScreen`, `ShiftRegisterScreen`, and `BookingHistoryScreen` were missing `const` constructors. When used inside `const MaterialPageRoute(builder: (_) => const X())`, the class must have a `const` constructor.

**Fix applied:** Added `const` keyword to all three constructors:
```dart
class ShiftListScreen extends StatefulWidget {
  const ShiftListScreen({super.key});  // Added const
  ...
}
```

---

## 6. Current State After Fixes

### Files Modified:

| File | Change |
|------|--------|
| `lib/ui/shifts/shift_list_screen.dart` | Added `const` constructor, removed duplicate `BookShiftScreen` class, added import for `book_shift_screen.dart` |
| `lib/ui/shifts/shift_register_screen.dart` | Added `const` constructor |
| `lib/ui/bookings/booking_history_screen.dart` | Added `const` constructor |
| `lib/ui/shifts/book_shift_screen.dart` | Fixed `ShiftService()` constructor call (removed 2 args) |
| `lib/services/auth_service.dart` | Created new file (was missing - needed by shift_list_screen, shift_register_screen, booking_history_screen) |

### Remaining Issues to Address:

1. **Missing model files** - `models/shift.dart`, `models/booking.dart`, `models/timesheet_entry.dart` are imported but may not exist or may have incompatible field definitions
2. **Missing service files** - `services/booking_service.dart`, `services/timesheet_service.dart` are imported but may not exist
3. **Missing utility file** - `utils/supabase_client.dart` (referenced by `shift_service.dart` as `SupabaseManager.instance.client`) may not exist
4. **`Shift` model compatibility** - The `Shift` model used in `shift_list_screen.dart` has fields like `.location`, `.shiftDate`, `.startTime`, `.endTime`, `.staffRequired`, `.staffType` which may not match the actual model definition

---

## 7. How to Verify the Fix

```bash
cd client-app
flutter pub get
flutter run -d edge
```

If the remaining missing files cause errors, create stub files for each:
- `models/shift.dart` - Define Shift class with fields: id, location, shiftDate, startTime, endTime, staffRequired, staffType, status, notes, organisationId
- `models/booking.dart` - Define Booking class with fields: id, status, createdAt
- `models/timesheet_entry.dart` - Define TimesheetEntry class with fields: id, startTime, status
- `services/booking_service.dart` - Define BookingService with getBookings(orgId) method
- `services/timesheet_service.dart` - Define TimesheetService with getTimesheetEntries(orgId) and confirmTimesheet(id, method) methods
- `utils/supabase_client.dart` - Define SupabaseManager with static instance.client getter