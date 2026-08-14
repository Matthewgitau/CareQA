# Client-App Final Setup - Get It Running Now

**Status:** Code is complete, needs build/run  
**Time Required:** 5 minutes  
**Issue:** "No API Key found in request" error

---

## The Problem

The `.env` file exists with correct credentials, but Flutter needs to:
1. Bundle the `.env` file as an asset (done in pubspec.yaml ✅)
2. Install dependencies (needs `flutter pub get`)
3. Rebuild the app (needs fresh `flutter run`)

---

## Solution (3 Steps)

### Step 1: Install Dependencies (1 minute)

```bash
cd "c:\Users\matth\src\XP Software\CareQA\apps\client-app"
flutter pub get
```

**Expected output:**
```
Resolving dependencies...
Got socket error trying to find package flutter_dotenv at https://pub.dev.
Got socket error trying to find package supabase_flutter at https://pub.dev.
...
Running "flutter pub get" in client_app...
```

### Step 2: Hot Restart the App (2 minutes)

If the app is already running in Edge:
1. Press **r** in the terminal where Flutter is running (hot reload)
2. OR press **R** (capital R) for hot restart
3. OR stop the app (Ctrl+C) and run again:

```bash
flutter run -d edge
```

### Step 3: Test Login (1 minute)

1. App should launch in Edge
2. You should see the **Login Screen** (not a blank white screen)
3. Enter credentials:
   - **Email:** `test@carehome.com`
   - **Password:** `Test123!`
4. Click **Sign In**

**Expected result:**
- Login succeeds
- Redirects to Dashboard
- No more "No API Key found" error

---

## If You Still Get "No API Key" Error

### Verify .env is in Assets

Check `apps/client-app/pubspec.yaml` has this section:

```yaml
flutter:
  uses-material-design: true
  assets:
    - .env
```

### Verify .env Loading in main.dart

Check `apps/client-app/lib/main.dart` has:

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');  // ← This line loads the .env file
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  runApp(const ClientApp());
}
```

### Clean and Rebuild

If still not working, do a clean rebuild:

```bash
cd "c:\Users\matth\src\XP Software\CareQA\apps\client-app"
flutter clean
flutter pub get
flutter run -d edge
```

---

## What Should Happen

### ✅ Success Flow

1. **App launches** → Shows Login Screen with "CareQA Client" title
2. **Enter credentials** → `test@carehome.com` / `Test123!`
3. **Click Sign In** → Button shows loading spinner
4. **Login succeeds** → Redirects to Dashboard
5. **Dashboard shows** → Navigation tiles for Shifts, Bookings, etc.

### ❌ Common Errors

| Error | Cause | Solution |
|-------|-------|----------|
| "No API Key found" | .env not loaded | Run `flutter pub get` and restart |
| "Invalid login credentials" | User not created in Supabase | Create user in Supabase Dashboard |
| "Role 'client' not allowed" | Migration 115 not run | Run migration 115 in Supabase SQL Editor |
| "Foreign key violation" | Profile UUID doesn't match auth user | Use actual UUID from Supabase Auth |
| Blank white screen | Missing dependencies | Run `flutter pub get` |

---

## Quick Verification Checklist

Before testing, verify:

- [ ] Migration 115 run in Supabase (adds 'client' role)
- [ ] Test user created in Supabase Auth (`test@carehome.com`)
- [ ] Test data SQL run with actual User UUID (not placeholder)
- [ ] `.env` file exists in `apps/client-app/`
- [ ] `flutter pub get` completed successfully
- [ ] App rebuilt after adding `.env` file

---

## Test Data Verification

Run this in Supabase SQL Editor to verify test data exists:

```sql
-- Check profiles
SELECT id, email, full_name, role 
FROM profiles 
WHERE email = 'test@carehome.com';

-- Check shifts
SELECT COUNT(*) as shift_count 
FROM shifts 
WHERE scheduled_date >= CURRENT_DATE;

-- Check carers
SELECT COUNT(*) as carer_count 
FROM carers;
```

Expected results:
- profiles: 1 row with role = 'client'
- shifts: 3 rows
- carers: 3 rows

---

## Next Steps After Login Works

Once you can successfully login and see the dashboard:

1. **Test shift listing** - Verify 3 test shifts appear
2. **Test navigation** - Click through different screens
3. **Test logout** - Verify you return to login screen
4. **Test session persistence** - Close and reopen app, should stay logged in

---

## Support

If you're still having issues:

1. **Check Flutter console** for errors (look for red text)
2. **Check Supabase logs** in Dashboard → Logs
3. **Verify .env file** is in the right location: `apps/client-app/.env`
4. **Verify pubspec.yaml** has `.env` in assets section
5. **Run `flutter doctor`** to check for environment issues

```bash
flutter doctor
```

---

## Summary

**What's Done:**
- ✅ Migration 115 created (adds 'client' role)
- ✅ Test data SQL created (3 shifts, 3 carers, 3 service users)
- ✅ Login UI created
- ✅ Auth wrapper created
- ✅ .env file created with credentials
- ✅ pubspec.yaml configured with dependencies and assets

**What You Need To Do:**
1. Run `flutter pub get`
2. Hot restart or rebuild app
3. Login with `test@carehome.com` / `Test123!`

**That's it!** The app should work now. 🚀