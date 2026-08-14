-- Check if drivers table exists
SELECT EXISTS (
  SELECT FROM information_schema.tables 
  WHERE table_name = 'drivers'
) AS drivers_table_exists;

-- Count drivers
SELECT COUNT(*) AS driver_count FROM drivers;

-- If no drivers exist, add a test driver
-- Uncomment the following lines to add a test driver:
-- INSERT INTO drivers (id, staff_name, is_active, created_at) 
-- VALUES (gen_random_uuid(), 'Test Driver', true, NOW());

-- Show all drivers
SELECT id, staff_name, employee_id, job_role, license_number, license_expiry, is_exclusive_driver, is_active, created_at
FROM drivers
ORDER BY created_at DESC;