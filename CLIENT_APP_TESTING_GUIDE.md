# Client-App Testing Guide - Step-by-Step Instructions

**Purpose:** Get the client-app running with client role login for live testing  
**Time Required:** 15-20 minutes  
**Prerequisites:** All 114+ migrations have been run in Supabase

---

## Overview

You will:
1. Run migration 115 to add the 'client' role
2. Create a test user in Supabase Dashboard
3. Run test data SQL to populate the database
4. Configure the client-app with Supabase credentials
5. Launch and test the app

---

## Step 1: Add 'client' Role to Database (2 minutes)

### 1.1 Open Supabase Dashboard
1. Go to https://supabase.com/dashboard
2. Select your CareQA project
3. Click **SQL Editor** in the left sidebar

### 1.2 Run Migration 115
1. Click **New Query**
2. Copy and paste the contents of `supabase/migrations/115_add_client_role.sql`:

```sql
-- Add 'client' role to profiles table
ALTER TABLE profiles DROP CONSTRAINT IF EXISTS profiles_role_check;

ALTER TABLE profiles ADD CONSTRAINT profiles_role_check 
  CHECK (role IN ('admin', 'carer', 'client'));

COMMENT ON COLUMN profiles.role IS 'User role: admin (organisation admin), carer (care staff), client (care home client)';
```

3. Click **Run**
4. You should see "Success. No rows returned"

### ✅ Verification
Run this query to verify the constraint was updated:
```sql
SELECT conname, pg_get_constraintdef(oid) 
FROM pg_constraint 
WHERE conname = 'profiles_role_check';
```

You should see: `CHECK (role = ANY (ARRAY['admin'::text, 'carer'::text, 'client'::text]))`

---

## Step 2: Create Test User in Supabase Auth (3 minutes)

### 2.1 Navigate to Authentication
1. In Supabase Dashboard, click **Authentication** → **Users**
2. Click **Add User** button

### 2.2 Create User
Fill in the form:
- **Email:** `test@carehome.com`
- **Password:** `Test123!`
- **Auto-confirm user:** ✅ Check this box
- **Email confirmed:** ✅ Should be checked automatically

3. Click **Create User**

### 2.3 Copy the User ID
After creating the user, you'll see it in the users list:
- Copy the **User UUID** (it looks like: `123e4567-e89b-12d3-a456-426614174000`)
- **Save this UUID** - you'll need it in Step 3

**Example:** `00000000-0000-0000-0000-000000000001` (this is a placeholder, use your real UUID)

---

## Step 3: Insert Test Data (5 minutes)

### 3.1 Open SQL Editor
1. Go back to **SQL Editor**
2. Click **New Query**

### 3.2 Copy Test Data SQL
Open the file `supabase/seed/client_app_test_data.sql` and copy ALL the contents.

### 3.3 Replace Placeholder UUID
**CRITICAL:** Find this line in the SQL:
```sql
INSERT INTO public.profiles (
    id,
    email,
    full_name,
    role,
    phone
) VALUES (
    '00000000-0000-0000-0000-000000000001',  -- ← REPLACE THIS WITH YOUR AUTH USER ID!
```

Replace `'00000000-0000-0000-0000-000000000001'` with the **actual User UUID** you copied in Step 2.3.

**Example:**
```sql
    '123e4567-e89b-12d3-a456-426614174000',  -- ← Your actual UUID
```

### 3.3 Run the SQL
1. Paste the modified SQL into the SQL Editor
2. Click **Run**
3. You should see the verification query at the bottom showing counts:

```
organisations | 1
profiles      | 1
carers        | 3
service_users | 3
shifts        | 3
```

### ✅ Verification
Run this query to verify your test user was created:
```sql
SELECT id, email, full_name, role, phone 
FROM profiles 
WHERE email = 'test@carehome.com';
```

You should see:
```
id: 123e4567-e89b-12d3-a456-426614174000 (your actual UUID)
email: test@carehome.com
full_name: Test Client User
role: client
phone: +44 7700 123456
```

---

## Step 4: Configure Client-App (3 minutes)

### 4.1 Get Supabase Credentials
1. In Supabase Dashboard, click **Settings** → **API**
2. Copy these two values:
   - **URL** (e.g., `https://xyz123.supabase.co`)
   - **anon key** (a long string starting with `eyJ...`)

### 4.2 Create .env File
1. Navigate to `apps/client-app/` directory
2. Create a new file called `.env` (no file extension)
3. Add your credentials:

```env
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
```

**Example:**
```env
SUPABASE_URL=https://xyz123.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh5ejEyMyIsInJvbGUiOiJzZXJ2aWNlIiwiaWF0IjoxNjE2MjM5MDIyfQ.example
```

### 4.3 Update pubspec.yaml (if needed)
Check if `apps/client-app/pubspec.yaml` has these dependencies:

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  supabase_flutter: ^2.12.0
  flutter_dotenv: ^5.2.1
  provider: ^6.1.0
```

If any are missing, add them and run:
```bash
cd apps/client-app
flutter pub get
```

---

## Step 5: Launch the App (2 minutes)

### 5.1 Start the App
```bash
cd apps/client-app
flutter run -d edge
```

The app should:
1. Compile (may take 1-2 minutes on first run)
2. Launch in Edge browser
3. Show the **Login Screen**

### 5.2 Test Login
1. Enter email: `test@carehome.com`
2. Enter password: `Test123!`
3. Click **Sign In**

### ✅ Expected Result
- Login succeeds
- App redirects to Dashboard
- You see the dashboard with navigation options

---

## Step 6: Test Features (10 minutes)

### 6.1 View Shifts
1. From Dashboard, click **Shifts** or **Available Shifts**
2. You should see 3 test shifts:
   - Margaret Wilson - Tomorrow 8:00 AM - 4:00 PM
   - Robert Thompson - Day after tomorrow 2:00 PM - 10:00 PM
   - Patricia O'Brien - 3 days from now 10:00 AM - 6:00 PM

### 6.2 View Booking History
1. From Dashboard, click **Bookings** or **Booking History**
2. You should see "No bookings found" (because we haven't created any bookings yet)

### 6.3 Test Shift Booking (if implemented)
1. From shift list, tap on a shift
2. Click **Book Shift**
3. Fill in the booking form
4. Submit
5. Verify it appears in booking history

### 6.4 Logout
1. Go to Dashboard
2. Click **Logout**
3. You should return to Login Screen

---

## Troubleshooting

### Problem: "Supabase initialization error"
**Solution:** Check your `.env` file has correct URL and anon key

### Problem: "Invalid login credentials"
**Solution:** 
- Verify you created the user in Supabase Dashboard
- Verify you used the correct email/password
- Verify you checked "Auto-confirm user" when creating the user

### Problem: "Role 'client' is not allowed"
**Solution:** You didn't run migration 115. Go back to Step 1.

### Problem: "Column does not exist"
**Solution:** The test data SQL is trying to insert columns that don't exist. Make sure you're using the SQL from `supabase/seed/client_app_test_data.sql` (not the original comprehensive SQL).

### Problem: App shows blank white screen
**Solution:** Check the debug console for errors. Most likely:
- Missing `.env` file
- Wrong Supabase credentials
- Missing dependencies (run `flutter pub get`)

### Problem: "No shifts available"
**Solution:** The test data shifts have `scheduled_date` set to future dates. Verify with:
```sql
SELECT * FROM shifts WHERE scheduled_date >= CURRENT_DATE;
```

---

## What You Can Test Right Now

✅ **Authentication**
- Login with email/password
- Logout
- Session persistence (close and reopen app)

✅ **View Shifts**
- See list of available shifts
- View shift details
- See carer assignments

✅ **Dashboard**
- See navigation options
- User info display

❌ **Not Yet Implemented** (requires additional work):
- Booking shifts (no bookings table exists yet)
- Rating staff (no staff_ratings table for clients)
- Timesheet confirmation (requires visits table integration)
- Push notifications

---

## Next Steps After Testing

Once you've verified the basic login and shift viewing works:

1. **Create bookings table** (if you want to test booking shifts)
2. **Create staff_ratings table** (if you want to test rating carers)
3. **Implement booking flow** in the app
4. **Add more test data** for different scenarios

---

## Quick Reference

### Test User Credentials
- **Email:** test@carehome.com
- **Password:** Test123!
- **Role:** client

### Test Data Summary
- **1 organisation:** Sunrise Care Home
- **1 client user:** Test Client User
- **3 carers:** Sarah Johnson, James Williams, Emily Brown
- **3 service users:** Margaret Wilson, Robert Thompson, Patricia O'Brien
- **3 shifts:** Scheduled for next 3 days

### Important Files
- Migration: `supabase/migrations/115_add_client_role.sql`
- Test data: `supabase/seed/client_app_test_data.sql`
- App entry: `apps/client-app/lib/main.dart`
- Login screen: `apps/client-app/lib/ui/auth/login_screen.dart`
- Auth wrapper: `apps/client-app/lib/ui/auth/auth_wrapper.dart`

---

## Support

If you encounter issues:
1. Check the Flutter debug console for errors
2. Check Supabase Dashboard → Logs for database errors
3. Verify all steps were completed in order
4. Ensure migration 115 was run successfully
5. Ensure test data SQL was run with the correct User UUID

**Happy Testing! 🚀**