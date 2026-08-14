-- ==========================================
-- CLIENT-APP TEST DATA
-- ==========================================
-- This script creates test data for the client-app
-- Run this AFTER running migration 115_add_client_role.sql

-- ==========================================
-- STEP 1: Create test organisation
-- ==========================================
INSERT INTO public.organisations (
    id, 
    name
) VALUES (
    '11111111-1111-1111-1111-111111111111',
    'Sunrise Care Home'
) ON CONFLICT (id) DO NOTHING;

-- ==========================================
-- STEP 2: Create test client user
-- ==========================================
-- ⚠️ CRITICAL: You MUST replace the UUID below with your ACTUAL auth user ID
-- 
-- WHY: The profiles table has a foreign key to auth.users(id)
-- This means the user MUST exist in Supabase Auth BEFORE you can insert into profiles
--
-- HOW TO GET THE UUID:
-- 1. Go to Supabase Dashboard → Authentication → Users
-- 2. Find user: test@carehome.com
-- 3. Click "Copy" next to the User UUID
-- 4. Replace '00000000-0000-0000-0000-000000000001' with the actual UUID
--
-- EXAMPLE: If your user UUID is '123e4567-e89b-12d3-a456-426614174000', use:
--     '123e4567-e89b-12d3-a456-426614174000'
--
-- ❌ WRONG: Using the placeholder UUID will fail with foreign key constraint error
-- ✅ CORRECT: Use the actual UUID from Supabase Auth
INSERT INTO public.profiles (
    id,
    email,
    full_name,
    role,
    phone
) VALUES (
    'a8f0d00e-e25a-447a-8a87-903890d22537',  -- ← REPLACE THIS WITH YOUR ACTUAL AUTH USER ID!
    'test@carehome.com',
    'Test Client User',
    'client',  -- ← Now allowed after migration 115
    '+44 7700 123456'
) ON CONFLICT (id) DO NOTHING;

-- ==========================================
-- STEP 3: Create test carers (staff)
-- ==========================================
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

-- ==========================================
-- STEP 4: Create test service users (residents)
-- ==========================================
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

-- ==========================================
-- STEP 5: Create test shifts
-- ==========================================
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

-- ==========================================
-- STEP 6: Verify data was inserted
-- ==========================================
SELECT 'organisations' as table_name, COUNT(*) as count FROM organisations
UNION ALL
SELECT 'profiles', COUNT(*) FROM profiles
UNION ALL
SELECT 'carers', COUNT(*) FROM carers
UNION ALL
SELECT 'service_users', COUNT(*) FROM service_users
UNION ALL
SELECT 'shifts', COUNT(*) FROM shifts;

-- ==========================================
-- STEP 7: View test data
-- ==========================================
SELECT 
    'Profiles' as type,
    id,
    email,
    full_name,
    role,
    phone
FROM profiles
WHERE email = 'test@carehome.com';

SELECT 
    'Carers' as type,
    id,
    employee_number,
    is_active
FROM carers
WHERE employee_number IN ('EMP-001', 'EMP-002', 'EMP-003');

SELECT 
    'Service Users' as type,
    id,
    name,
    is_active
FROM service_users
WHERE name IN ('Margaret Wilson', 'Robert Thompson', 'Patricia O''Brien');

SELECT 
    'Shifts' as type,
    id,
    scheduled_date,
    start_time,
    end_time,
    status,
    service_user_id,
    carer_id
FROM shifts
WHERE scheduled_date >= CURRENT_DATE
ORDER BY scheduled_date;