# Client-App Test Data & Live Testing Implementation Report

**Date:** 2026-07-27  
**Purpose:** Explain why the provided SQL script fails and provide a methodical path to get client-app features working for live testing

---

## Table of Contents
1. [Executive Summary](#executive-summary)
2. [Database Schema Analysis](#database-schema-analysis)
3. [Error Breakdown](#error-breakdown)
4. [Root Causes](#root-causes)
5. [Solution Options](#solution-options)
6. [Recommended Implementation Plan](#recommended-implementation-plan)
7. [Step-by-Step SQL Fixes](#step-by-step-sql-fixes)
8. [Client-App Feature Implementation](#client-app-feature-implementation)
9. [Testing Checklist](#testing-checklist)

---

## Executive Summary

The provided SQL script **will fail** when executed in the Supabase SQL Editor due to **3 critical schema violations**:

1. **Role constraint violation** - Attempting to insert `role = 'client'` when only `'admin'` and `'carer'` are allowed
2. **Missing columns** - The `profiles` table doesn't have `organisation_id`, `member_type`, or other columns referenced in the error
3. **Table structure mismatch** - The test data assumes a different schema than what exists in the database

**Bottom line:** We need to either modify the database schema OR modify the test data to match the existing schema. This report provides both options and recommends a path forward.

---

## Database Schema Analysis

### Current Schema (from `001_initial_schema.sql`)

#### `profiles` Table (Lines 5-13)
```sql
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id),
  email TEXT NOT NULL,
  full_name TEXT,
  role TEXT NOT NULL CHECK (role IN ('admin', 'carer')),  -- ⚠️ ONLY admin/carer allowed!
  phone TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**Key Constraints:**
- `role` has a CHECK constraint: `CHECK (role IN ('admin', 'carer'))`
- **NO `organisation_id` column** (added later in migration `028_add_organisation_id.sql`)
- **NO `member_type` column** (doesn't exist at all)

#### `organisations` Table (from `071_create_organisations.sql`)
```sql
CREATE TABLE IF NOT EXISTS organisations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  subscription_tier TEXT DEFAULT 'trial',
  settings JSONB DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**Key Points:**
- This is the **admin-app** organisations table
- NO `industry`, `registration_number`, `address`, `phone`, `email` columns
- NO `organisation_types`, `billing_rate_per_hour`, `shift_types` columns
- The user mentioned they have a separate `client_organisations` table (not in migrations)

#### `carers` Table (Lines 16-29)
```sql
CREATE TABLE carers (
  id UUID PRIMARY KEY REFERENCES profiles(id),  -- ⚠️ References profiles, NOT organisations
  employee_number TEXT UNIQUE,
  dbs_number TEXT,
  dbs_expiry_date DATE,
  -- ... other columns
  is_active BOOLEAN DEFAULT TRUE
);
```

**Key Constraints:**
- `id` references `profiles(id)` - carers MUST have a corresponding profile
- `employee_number` has UNIQUE constraint
- **NO `organisation_id` column** (added later in migration `072_add_organisation_id_to_all_tables.sql`)

#### `service_users` Table (Lines 32-50)
```sql
CREATE TABLE service_users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  address TEXT,
  notes TEXT,
  -- ... other columns
  is_active BOOLEAN DEFAULT TRUE
);
```

**Key Points:**
- **NO `organisation_id` column** (added later)
- **NO `date_of_birth` column** (added later in migration `070_add_carer_dob_address.sql` - but for carers, not service_users)

#### `shifts` Table (Lines 53-63)
```sql
CREATE TABLE shifts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  service_user_id UUID REFERENCES service_users(id) ON DELETE CASCADE,
  carer_id UUID REFERENCES carers(id) ON DELETE SET NULL,
  scheduled_date DATE NOT NULL,
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  status TEXT DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'in_progress', 'completed', 'cancelled')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**Key Points:**
- **NO `organisation_id` column** (added later)
- **NO `client_id` column** (the test data tries to insert this)
- Uses `scheduled_date` not `shift_date`
- Uses `start_time` and `end_time` (TIME type) not timestamps

---

## Error Breakdown

### Error 1: Role Constraint Violation
```
ERROR: 23514: new row for relation "profiles" violates check constraint "profiles_role_check"
DETAIL: Failing row contains (00000000-0000-0000-0000-000000000001, test@carehome.com, Test Client User, client, +44 7700 123456, ...)
```

**Why it fails:**
- The SQL tries to insert `role = 'client'`
- The `profiles` table only allows `'admin'` or `'carer'`
- The CHECK constraint is defined in line 9 of `001_initial_schema.sql`

**What the error shows:**
```
Failing row contains (id, email, full_name, role, phone, created_at, updated_at, organisation_id, ...)
```
This tells us the `profiles` table NOW has more columns than in the initial schema:
- `organisation_id` (added by migration `028`)
- `member_type` (added somewhere)
- Other columns not in the initial schema

### Error 2: Missing Columns in `organisations`
The test data tries to insert:
```sql
INSERT INTO public.organisations (
    id, name, address, phone, email, registration_number
)
```

But the current `organisations` table only has:
- `id`, `name`, `subscription_tier`, `settings`, `created_at`, `updated_at`

**Missing columns:** `address`, `phone`, `email`, `registration_number`

### Error 3: Missing Columns in `carers`
The test data tries to insert:
```sql
INSERT INTO public.carers (
    id, organisation_id, name, email, phone, is_active, job_role, date_of_birth, employee_number
)
```

But the current `carers` table has:
- `id` (references profiles)
- `employee_number`
- `dbs_number`, `dbs_expiry_date`, etc.
- **NO `organisation_id`** (unless migration `072` was run)
- **NO `name`** (name is in profiles.full_name)
- **NO `email`** (email is in profiles.email)
- **NO `job_role`**
- **NO `date_of_birth`** (unless migration `070` was run)

### Error 4: Missing Columns in `service_users`
The test data tries to insert:
```sql
INSERT INTO public.service_users (
    id, organisation_id, name, date_of_birth, care_plan, is_active
)
```

But the current `service_users` table has:
- `id`, `name`, `address`, `notes`, `emergency_contact_*`, `care_plan`, `is_active`
- **NO `organisation_id`** (unless migration `072` was run)
- **NO `date_of_birth`**

### Error 5: Wrong Column Names in `shifts`
The test data tries to insert:
```sql
INSERT INTO public.shifts (
    id, organisation_id, client_id, service_user_id, carer_id, start_time, end_time, ...
)
```

But the current `shifts` table has:
- `id`, `service_user_id`, `carer_id`, `scheduled_date`, `start_time`, `end_time`, `status`
- **NO `organisation_id`** (unless migration `072` was run)
- **NO `client_id`**
- Uses `scheduled_date` not `shift_date`

---

## Root Causes

### 1. **Schema Evolution**
The database schema has evolved through 114+ migrations. The test data was written for a **future/ideal schema** that doesn't exist yet.

**Migrations that add missing columns:**
- `028_add_organisation_id.sql` - Adds `organisation_id` to many tables
- `070_add_carer_dob_address.sql` - Adds `date_of_birth` to carers
- `072_add_organisation_id_to_all_tables.sql` - Adds `organisation_id` to all tables
- `029_client_and_family_tables.sql` - Adds client-specific tables

### 2. **Role System Mismatch**
The current schema only supports:
- `admin` - Organisation administrators
- `carer` - Care staff

The test data assumes a `client` role exists, which would be for:
- Care home clients who book shifts
- Family members who view service users

**This role doesn't exist yet and needs to be added.**

### 3. **Dual Organisation System**
The user mentioned:
- `public.organisations` - For admin-app users (care staff organisations)
- `client_organisations` - For client-app users (care home clients)

**This dual system doesn't exist in the current schema.**

### 4. **Test Data is Too Comprehensive**
The test data tries to insert:
- 1 organisation
- 1 profile
- 3 carers
- 3 service users
- 3 shifts
- 2 staff ratings
- 1 attendance record

**All in one SQL script.** This makes it impossible to debug which specific insert fails.

---

## Solution Options

### Option A: Modify Database Schema (Recommended for Long-Term)
**Pros:**
- Supports the full client-app feature set
- Proper separation of admin and client users
- Scalable for multi-tenant architecture

**Cons:**
- Requires creating new migrations
- More complex RLS policies needed
- Takes more time

**Steps:**
1. Add `client` role to `profiles` CHECK constraint
2. Create `client_organisations` table
3. Add `organisation_id` to all tables (if not already done)
4. Update RLS policies to support client users
5. Create client-specific views

### Option B: Modify Test Data (Recommended for Quick Testing)
**Pros:**
- Quick to implement
- Works with existing schema
- No database changes needed

**Cons:**
- Limited to admin/carer roles
- Can't test client-specific features
- Workaround, not a real solution

**Steps:**
1. Change `role = 'client'` to `role = 'carer'` or `role = 'admin'`
2. Remove columns that don't exist yet
3. Test only admin/carer features

### Option C: Hybrid Approach (RECOMMENDED)
**Pros:**
- Get client-app running quickly with Option B
- Implement Option A schema changes incrementally
- Test features as they're built

**Cons:**
- Requires coordination between schema and app changes

**Steps:**
1. Use Option B to get basic app running
2. Create migration to add `client` role
3. Create migration to add `client_organisations` table
4. Update app to support both admin and client users
5. Test incrementally

---

## Recommended Implementation Plan

### Phase 1: Get Client-App Running (Week 1)
**Goal:** Launch the client-app and log in

1. **Fix test data** (Option B)
   - Change role to `'carer'` temporarily
   - Remove non-existent columns
   - Insert minimal test data

2. **Create auth user in Supabase Dashboard**
   - Email: `test@carehome.com`
   - Password: `Test123!`
   - Copy the User ID

3. **Update test data with real User ID**
   - Replace `'00000000-0000-0000-0000-000000000001'` with actual UUID

4. **Run client-app**
   ```bash
   cd apps/client-app
   flutter run -d edge
   ```

5. **Verify login works**
   - Enter credentials
   - See dashboard

### Phase 2: Implement Client Role (Week 2)
**Goal:** Support client users in the database

1. **Create migration:** `115_add_client_role.sql`
   ```sql
   -- Update profiles role constraint to include 'client'
   ALTER TABLE profiles DROP CONSTRAINT profiles_role_check;
   ALTER TABLE profiles ADD CONSTRAINT profiles_role_check 
     CHECK (role IN ('admin', 'carer', 'client'));
   ```

2. **Create migration:** `116_create_client_organisations.sql`
   ```sql
   CREATE TABLE IF NOT EXISTS client_organisations (
     id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
     name TEXT NOT NULL,
     industry TEXT,
     registration_number TEXT,
     address TEXT,
     phone TEXT,
     email TEXT,
     created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
     updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
   );
   ```

3. **Update test data** to use `role = 'client'`

4. **Test client login**

### Phase 3: Implement Client-App Features (Week 3-4)
**Goal:** Test all client-app features

1. **View available shifts**
   - Create test shifts
   - Verify shift list displays

2. **Book a shift**
   - Test shift booking flow
   - Verify data saves to database

3. **View booking history**
   - Test booking history screen
   - Verify data displays correctly

4. **Rate staff**
   - Test staff rating feature
   - Verify ratings save

5. **2FA attendance**
   - Test shift register screen
   - Verify QR code scanning (if implemented)

---

## Step-by-Step SQL Fixes

### Step 1: Minimal Test Data (Get App Running NOW)

```sql
-- ==========================================
-- MINIMAL TEST DATA - WORKS WITH CURRENT SCHEMA
-- ==========================================

-- 1. Insert test organisation (minimal columns)
INSERT INTO public.organisations (
    id, 
    name
) VALUES (
    '11111111-1111-1111-1111-111111111111',
    'Sunrise Care Home'
) ON CONFLICT (id) DO NOTHING;

-- 2. Insert test profile with 'carer' role (NOT 'client'!)
-- ⚠️ REPLACE THE UUID BELOW WITH YOUR ACTUAL AUTH USER ID FROM SUPABASE DASHBOARD
INSERT INTO public.profiles (
    id,
    email,
    full_name,
    role,  -- Must be 'carer' or 'admin' (current constraint)
    phone
) VALUES (
    '00000000-0000-0000-0000-000000000001',  -- ← REPLACE THIS!
    'test@carehome.com',
    'Test User',
    'carer',  -- ← Using 'carer' for now
    '+44 7700 123456'
) ON CONFLICT (id) DO NOTHING;

-- 3. Insert carers (minimal columns that exist)
INSERT INTO public.carers (
    id,
    employee_number,
    is_active
) VALUES 
    (
        '55555555-5555-5555-5555-555555555555',
        'EMP-001',
        true
    ),
    (
        '66666666-6666-6666-6666-666666666666',
        'EMP-002',
        true
    ),
    (
        '77777777-7777-7777-7777-777777777777',
        'EMP-003',
        true
    )
ON CONFLICT (id) DO NOTHING;

-- 4. Insert service users (minimal columns)
INSERT INTO public.service_users (
    id,
    name,
    is_active
) VALUES 
    (
        '22222222-2222-2222-2222-222222222222',
        'Margaret Wilson',
        true
    ),
    (
        '33333333-3333-3333-3333-333333333333',
        'Robert Thompson',
        true
    ),
    (
        '44444444-4444-4444-4444-444444444444',
        'Patricia O''Brien',
        true
    )
ON CONFLICT (id) DO NOTHING;

-- 5. Insert shifts (using current schema column names)
INSERT INTO public.shifts (
    id,
    service_user_id,
    carer_id,
    scheduled_date,
    start_time,
    end_time,
    status
) VALUES 
    (
        '88888888-8888-8888-8888-888888888888',
        '22222222-2222-2222-2222-222222222222',
        '55555555-5555-5555-5555-555555555555',
        CURRENT_DATE + INTERVAL '1 day',
        '08:00:00',
        '16:00:00',
        'scheduled'
    ),
    (
        '99999999-9999-9999-9999-999999999999',
        '33333333-3333-3333-3333-333333333333',
        '66666666-6666-6666-6666-666666666666',
        CURRENT_DATE + INTERVAL '2 days',
        '14:00:00',
        '22:00:00',
        'scheduled'
    ),
    (
        'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        '44444444-4444-4444-4444-444444444444',
        '77777777-7777-7777-7777-777777777777',
        CURRENT_DATE + INTERVAL '3 days',
        '10:00:00',
        '18:00:00',
        'scheduled'
    )
ON CONFLICT (id) DO NOTHING;

-- 6. Verify data
SELECT 'organisations' as table_name, COUNT(*) as count FROM organisations
UNION ALL
SELECT 'profiles', COUNT(*) FROM profiles
UNION ALL
SELECT 'carers', COUNT(*) FROM carers
UNION ALL
SELECT 'service_users', COUNT(*) FROM service_users
UNION ALL
SELECT 'shifts', COUNT(*) FROM shifts;
```

### Step 2: How to Get Your Auth User ID

1. Go to Supabase Dashboard: https://supabase.com/dashboard
2. Select your project
3. Go to **Authentication** → **Users**
4. Click **"Add User"**
5. Fill in:
   - Email: `test@carehome.com`
   - Password: `Test123!`
   - Check **"Auto-confirm user"**
6. Click **"Create User"**
7. Copy the **User UUID** (looks like: `123e4567-e89b-12d3-a456-426614174000`)
8. Replace `'00000000-0000-0000-0000-000000000001'` in the SQL above with this UUID

### Step 3: Run the SQL

1. Go to Supabase Dashboard → **SQL Editor**
2. Click **"New Query"**
3. Paste the SQL from Step 1
4. Replace the placeholder UUID with your actual User ID
5. Click **"Run"**
6. Verify the final SELECT shows counts > 0

---

## Client-App Feature Implementation

### Current State Analysis

#### What EXISTS:
✅ `apps/client-app/lib/main.dart` - App entry point with Supabase initialization  
✅ `apps/client-app/lib/config/routes.dart` - GoRouter configuration  
✅ `apps/client-app/lib/screens/dashboard/client_dashboard.dart` - Dashboard screen  
✅ `client-app/lib/ui/shifts/shift_list_screen.dart` - Lists available shifts  
✅ `client-app/lib/ui/shifts/book_shift_screen.dart` - Book shift form  
✅ `client-app/lib/ui/shifts/shift_register_screen.dart` - Timesheet confirmation  
✅ `client-app/lib/ui/bookings/booking_history_screen.dart` - Past bookings  
✅ `client-app/lib/services/auth_service.dart` - Auth service  
✅ `client-app/lib/utils/supabase_client.dart` - SupabaseManager singleton  

#### What's MISSING:
❌ `apps/client-app/lib/ui/auth/auth_wrapper.dart` - Auth state wrapper  
❌ `apps/client-app/lib/ui/auth/login_screen.dart` - Login UI  
❌ `client-app/lib/models/shift.dart` - Shift model  
❌ `client-app/lib/models/booking.dart` - Booking model  
❌ `client-app/lib/services/booking_service.dart` - Booking CRUD  
❌ `client-app/lib/services/timesheet_service.dart` - Timesheet service  
❌ `.env` file with Supabase credentials  

### Implementation Plan

#### 1. Create Auth Wrapper

**File:** `apps/client-app/lib/ui/auth/auth_wrapper.dart`

```dart
import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthWrapper extends StatelessWidget {
  final Widget authenticatedChild;
  
  const AuthWrapper({
    super.key,
    required this.authenticatedChild,
  });

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    
    if (user != null) {
      return authenticatedChild;
    } else {
      return const LoginScreen();
    }
  }
}
```

#### 2. Create Login Screen

**File:** `apps/client-app/lib/ui/auth/login_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.business_center,
                  size: 50,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'CareQA Client',
                style: AppTypography.headlineLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Book shifts • Manage staff • Track attendance',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 48),
              // Email Field
              AppTextField(
                controller: _emailController,
                hintText: 'Email address',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              // Password Field
              AppTextField(
                controller: _passwordController,
                hintText: 'Password',
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    size: 20,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Login Button
              PrimaryButton(
                onPressed: _isLoading
                    ? null
                    : () async {
                        setState(() => _isLoading = true);
                        try {
                          await Supabase.instance.client.auth.signInWithPassword(
                            email: _emailController.text.trim(),
                            password: _passwordController.text,
                          );
                          if (mounted) {
                            // Auth state will trigger rebuild
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Login failed: ${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                        if (mounted) {
                          setState(() => _isLoading = false);
                        }
                      },
                text: 'Sign In',
              ),
              const SizedBox(height: 16),
              // Create Account Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Don\'t have an account?',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Navigate to registration
                    },
                    child: Text(
                      'Contact your admin',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

#### 3. Update main.dart

**File:** `apps/client-app/lib/main.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:client_app/ui/auth/auth_wrapper.dart';
import 'config/routes.dart';

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
    return MaterialApp.router(
      title: 'CareQA Client',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: appRouter,
    );
  }
}
```

#### 4. Create .env File

**File:** `apps/client-app/.env`

```env
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
```

**How to get these values:**
1. Go to Supabase Dashboard
2. Click **Settings** → **API**
3. Copy **URL** and **anon key**

#### 5. Update pubspec.yaml

**File:** `apps/client-app/pubspec.yaml`

Add these dependencies:

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  core:
    path: ../../packages/core
  api_client:
    path: ../../packages/api_client
  ui_kit:
    path: ../../packages/ui_kit
  
  flutter_riverpod: ^2.3.6
  go_router: ^10.0.0
  google_fonts: ^6.1.0
  flutter_svg: ^2.0.5
  cached_network_image: ^3.2.3
  shimmer: ^3.0.0
  qr_code_scanner: ^1.0.1
  camera: ^0.10.5
  geolocator: ^10.1.0
  permission_handler: ^11.0.1
  shared_preferences: ^2.2.0
  flutter_secure_storage: ^9.0.0
  intl: ^0.19.0
  package_info_plus: ^4.0.0
  connectivity_plus: ^4.0.0
  flutter_local_notifications: ^15.1.1
  
  # ADD THESE:
  supabase_flutter: ^2.12.0
  flutter_dotenv: ^5.2.1
  provider: ^6.1.0
```

#### 6. Create Missing Models

**File:** `client-app/lib/models/shift.dart`

```dart
class Shift {
  final String id;
  final String serviceUserId;
  final String? carerId;
  final DateTime scheduledDate;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String status;
  final String? notes;
  final DateTime createdAt;

  Shift({
    required this.id,
    required this.serviceUserId,
    this.carerId,
    required this.scheduledDate,
    required this.startTime,
    required this.endTime,
    this.status = 'scheduled',
    this.notes,
    required this.createdAt,
  });

  factory Shift.fromJson(Map<String, dynamic> json) {
    return Shift(
      id: json['id'] as String,
      serviceUserId: json['service_user_id'] as String,
      carerId: json['carer_id'] as String?,
      scheduledDate: DateTime.parse(json['scheduled_date'] as String),
      startTime: TimeOfDay(
        hour: int.parse((json['start_time'] as String).split(':')[0]),
        minute: int.parse((json['start_time'] as String).split(':')[1]),
      ),
      endTime: TimeOfDay(
        hour: int.parse((json['end_time'] as String).split(':')[0]),
        minute: int.parse((json['end_time'] as String).split(':')[1]),
      ),
      status: json['status'] as String,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'service_user_id': serviceUserId,
      'carer_id': carerId,
      'scheduled_date': scheduledDate.toIso8601String().split('T')[0],
      'start_time': '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}:00',
      'end_time': '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}:00',
      'status': status,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
```

**File:** `client-app/lib/models/booking.dart`

```dart
class Booking {
  final String id;
  final String shiftId;
  final String userId;
  final String status;
  final DateTime createdAt;

  Booking({
    required this.id,
    required this.shiftId,
    required this.userId,
    this.status = 'confirmed',
    required this.createdAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as String,
      shiftId: json['shift_id'] as String,
      userId: json['user_id'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shift_id': shiftId,
      'user_id': userId,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
```

#### 7. Create Missing Services

**File:** `client-app/lib/services/booking_service.dart`

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/booking.dart';

class BookingService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Booking>> getBookings(String organisationId) async {
    try {
      final response = await _client
          .from('shifts')
          .select()
          .eq('organisation_id', organisationId)
          .order('scheduled_date', ascending: false);

      return (response as List)
          .map((json) => Booking.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load bookings: $e');
    }
  }

  Future<Booking> createBooking(Booking booking) async {
    try {
      final response = await _client
          .from('bookings')
          .insert(booking.toJson())
          .select()
          .single();

      return Booking.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create booking: $e');
    }
  }
}
```

**File:** `client-app/lib/services/timesheet_service.dart`

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/timesheet_entry.dart';

class TimesheetService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<TimesheetEntry>> getTimesheetEntries(String organisationId) async {
    try {
      final response = await _client
          .from('visits')
          .select()
          .eq('organisation_id', organisationId)
          .order('check_in_time', ascending: false);

      return (response as List)
          .map((json) => TimesheetEntry.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load timesheets: $e');
    }
  }

  Future<void> confirmTimesheet(String entryId, String method) async {
    try {
      await _client
          .from('visits')
          .update({'verification_method': method})
          .eq('id', entryId);
    } catch (e) {
      throw Exception('Failed to confirm timesheet: $e');
    }
  }
}
```

**File:** `client-app/lib/models/timesheet_entry.dart`

```dart
class TimesheetEntry {
  final String id;
  final String shiftId;
  final String carerId;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final String status;

  TimesheetEntry({
    required this.id,
    required this.shiftId,
    required this.carerId,
    this.checkInTime,
    this.checkOutTime,
    this.status = 'pending',
  });

  factory TimesheetEntry.fromJson(Map<String, dynamic> json) {
    return TimesheetEntry(
      id: json['id'] as String,
      shiftId: json['shift_id'] as String,
      carerId: json['carer_id'] as String,
      checkInTime: json['check_in_time'] != null 
        ? DateTime.parse(json['check_in_time'] as String) 
        : null,
      checkOutTime: json['check_out_time'] != null 
        ? DateTime.parse(json['check_out_time'] as String) 
        : null,
      status: json['status'] as String? ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shift_id': shiftId,
      'carer_id': carerId,
      'check_in_time': checkInTime?.toIso8601String(),
      'check_out_time': checkOutTime?.toIso8601String(),
      'status': status,
    };
  }
}
```

---

## Testing Checklist

### Pre-Testing Setup
- [ ] Create Supabase auth user (`test@carehome.com` / `Test123!`)
- [ ] Copy User ID from Supabase Dashboard
- [ ] Run minimal test data SQL (Step 1 above)
- [ ] Update `.env` file with Supabase credentials
- [ ] Run `flutter pub get` in `apps/client-app/`

### Feature Testing

#### 1. Authentication
- [ ] App launches without errors
- [ ] Login screen displays
- [ ] Can enter email and password
- [ ] Login succeeds with correct credentials
- [ ] Login fails with incorrect credentials
- [ ] Redirects to dashboard after login

#### 2. Dashboard
- [ ] Dashboard loads
- [ ] Shows 4 navigation tiles (Shifts, Bookings, Timesheet, Profile)
- [ ] User info displays correctly
- [ ] Logout button works

#### 3. View Shifts
- [ ] Shift list screen loads
- [ ] Shows available shifts from database
- [ ] Shift details display (date, time, service user)
- [ ] Empty state shows when no shifts available
- [ ] Error handling works

#### 4. Book a Shift
- [ ] Can navigate to book shift screen
- [ ] Date picker works
- [ ] Time picker works
- [ ] Can select staff type
- [ ] Can adjust staff required count
- [ ] Can add notes
- [ ] Booking submits successfully
- [ ] Success message displays
- [ ] Redirects back to shift list

#### 5. Booking History
- [ ] Booking history screen loads
- [ ] Shows past bookings
- [ ] Empty state shows when no bookings
- [ ] Dates and status display correctly

#### 6. Timesheet/Attendance
- [ ] Shift register screen loads
- [ ] Shows pending timesheets
- [ ] Can confirm timesheet
- [ ] Success message displays
- [ ] Confirmed timesheets show as "Confirmed"

---

## Migration Files Reference

### Key Migrations to Review

| Migration | Purpose | Status |
|-----------|---------|--------|
| `001_initial_schema.sql` | Base tables (profiles, carers, service_users, shifts) | ✅ Applied |
| `028_add_organisation_id.sql` | Adds organisation_id to profiles | ✅ Applied |
| `070_add_carer_dob_address.sql` | Adds date_of_birth to carers | ✅ Applied |
| `071_create_organisations.sql` | Creates organisations table | ✅ Applied |
| `072_add_organisation_id_to_all_tables.sql` | Adds organisation_id everywhere | ✅ Applied |
| `029_client_and_family_tables.sql` | Client-specific tables | ❓ Unknown |

### Migrations to CREATE

| Migration | Purpose | Priority |
|-----------|---------|----------|
| `115_add_client_role.sql` | Add 'client' to profiles.role CHECK | 🔴 HIGH |
| `116_create_client_organisations.sql` | Create client_organisations table | 🔴 HIGH |
| `117_add_missing_columns.sql` | Add any missing columns to match test data | 🟡 MEDIUM |
| `118_client_rls_policies.sql` | RLS policies for client users | 🟡 MEDIUM |

---

## Next Steps

### Immediate (Today)
1. ✅ Run minimal test data SQL (Step 1 above)
2. ✅ Create auth user in Supabase Dashboard
3. ✅ Update `.env` with credentials
4. ✅ Create missing UI files (auth_wrapper.dart, login_screen.dart)
5. ✅ Test login flow

### This Week
1. Create migration `115_add_client_role.sql`
2. Create migration `116_create_client_organisations.sql`
3. Update test data to use `role = 'client'`
4. Test client-specific features

### Next Week
1. Implement shift booking feature
2. Implement booking history
3. Implement timesheet confirmation
4. Full integration testing

---

## Questions for You

Before proceeding, I need clarification on:

1. **Client Organisations Table**: You mentioned `client_organisations` exists but has no members. Can you show me the schema for this table?

2. **Dual Organisation System**: 
   - `public.organisations` = admin-app (care staff)
   - `client_organisations` = client-app (care homes)
   - Is this correct? How do they link?

3. **Profile Roles**: 
   - Current: `admin`, `carer`
   - Needed: `client` (for care home users)
   - Are there any other roles needed?

4. **Migration Status**: 
   - Have all 114+ migrations been run in your Supabase database?
   - Or are you on an earlier migration?

5. **Test Data Priority**:
   - Do you want to test with `carer` role first (quick)?
   - Or implement `client` role first (proper)?

Let me know and I'll proceed with the implementation!