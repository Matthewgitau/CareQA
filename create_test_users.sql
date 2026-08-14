-- CareQA Test User Accounts for Physical Device Testing
-- Run this SQL script in Supabase SQL Editor

-- Insert test profiles (run in Supabase SQL editor)
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at) VALUES
  ('11111111-1111-1111-1111-111111111111', 'admin@careqa.com', '$2a$10$dummy_hash_for_testing_purposes_only', NOW(), NOW(), NOW()),
  ('22222222-2222-2222-2222-222222222222', 'carer@careqa.com', '$2a$10$dummy_hash_for_testing_purposes_only', NOW(), NOW(), NOW());

-- Insert test profiles
INSERT INTO profiles (id, email, full_name, role, created_at, updated_at) VALUES
  ('11111111-1111-1111-1111-111111111111', 'admin@careqa.com', 'Admin User', 'admin', NOW(), NOW()),
  ('22222222-2222-2222-2222-222222222222', 'carer@careqa.com', 'Carer User', 'carer', NOW(), NOW());

-- Insert test service user for testing
INSERT INTO service_users (id, name, address, date_of_birth, medical_conditions, created_at, updated_at) VALUES
  ('33333333-3333-3333-3333-333333333333', 'Mary Jones', '123 Care Home Lane, London', '1945-03-15', 'Diabetes, Hypertension', NOW(), NOW());

-- Insert test carer for testing
INSERT INTO carers (id, name, employee_number, qualifications, created_at, updated_at) VALUES
  ('44444444-4444-4444-4444-444444444444', 'John Smith', 'EMP001', ARRAY['NVQ Level 3', 'First Aid'], NOW(), NOW());

-- Insert test shift for today
INSERT INTO shift_rotas (id, service_user_id, carer_id, shift_type, day_of_week, start_date, end_date, status, notes, created_at, updated_at) VALUES
  ('55555555-5555-5555-5555-555555555555', '33333333-3333-3333-3333-333333333333', '44444444-4444-4444-4444-444444444444', 'Morning', 'Monday', NOW(), NOW() + INTERVAL '8 hours', 'Scheduled', 'Regular morning visit', NOW(), NOW());

-- Test credentials for physical device testing:
-- Admin: admin@careqa.com / password123
-- Carer: carer@careqa.com / password123

-- Note: In a real deployment, you would need to:
-- 1. Set proper password hashes using Supabase auth functions
-- 2. Configure email confirmation
-- 3. Set up proper authentication flows
-- This script is for testing purposes only