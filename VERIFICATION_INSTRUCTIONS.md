# How to Verify the Drivers Table

## The PGRST205 Error

The error "PGRST205: relation 'public.drivers' does not exist" means the `drivers` table hasn't been created in your Supabase database yet, or the migration hasn't been run.

## Verification Steps

### Option 1: Using Supabase Dashboard (Recommended)

1. **Open your Supabase project** at https://supabase.com
2. **Go to SQL Editor** (left sidebar)
3. **Copy and paste** the contents of `supabase/verify_drivers_table.sql`
4. **Click "Run"** to execute the queries
5. **Review the results** in the output panel

### Option 2: Using Node.js Script

If you have Node.js installed:

```bash
# Make sure you have a .env file with your Supabase credentials
# SUPABASE_URL=https://your-project.supabase.co
# SUPABASE_ANON_KEY=your-anon-key

node scripts/check_drivers.js
```

This script will:
- Check if the table exists
- Show driver count
- Add a test driver if empty

### Option 3: Using psql (if installed)

```bash
psql -h db.your-project-ref.supabase.co -U postgres -d postgres -f supabase/verify_drivers_table.sql
```

## What the Verification Queries Do

### Query 1: Check if table exists
Returns `true` if the `drivers` table exists, `false` otherwise.

### Query 2: Show table structure
Lists all columns with their data types, nullability, and default values.

Expected columns:
- `id` (uuid, not null)
- `carer_id` (uuid, nullable)
- `is_exclusive_driver` (bool, nullable, default: false)
- `staff_name` (text, not null)
- `employee_id` (text, nullable)
- `job_role` (text, nullable)
- `contact_phone` (text, nullable)
- `date_of_birth` (date, nullable)
- `license_number` (text, nullable)
- `license_expiry` (date, nullable)
- `license_categories` (text, nullable)
- `license_issue_date` (date, nullable)
- `license_checked` (bool, nullable, default: false)
- `has_endorsements` (bool, nullable, default: false)
- `endorsement_details` (text, nullable)
- `license_copy_url` (text, nullable)
- `is_active` (bool, nullable, default: true)
- `created_at` (timestamp, nullable, default: now())

### Query 3: Count drivers
Shows how many drivers are in the table.

### Query 4: Show sample data
Displays up to 5 most recent drivers.

## If the Table Doesn't Exist

If Query 1 returns `false`, you need to run the migration:

### Method A: Run the full migration file
```bash
# In Supabase SQL Editor, paste the entire content of:
# supabase/migrations/068_drivers_and_vehicles.sql
# Then click "Run"
```

### Method B: Create just the drivers table
Uncomment and run the CREATE TABLE statement in `supabase/verify_drivers_table.sql` (STEP 5).

### Method C: Use the migration runner
```bash
# If you have the Supabase CLI installed
cd supabase
supabase db reset  # This will run all migrations
```

## If the Table Exists but is Empty

If Query 3 shows 0 drivers:

1. **Add a test driver** - Uncomment STEP 6 in `supabase/verify_drivers_table.sql` and run it
2. **Or use the Node.js script** - `node scripts/check_drivers.js` will auto-add a test driver

## Expected Results After Fix

After running the migration:

✅ Query 1 should return: `drivers_table_exists = true`

✅ Query 2 should show 18 columns matching the schema above

✅ Query 3 should show: `driver_count = 0` (or more if you added test data)

✅ The Drivers page in your app should now load without the PGRST205 error

## Troubleshooting

### Still getting PGRST205 after migration?

1. **Check you're using the right database** - Make sure your app's SUPABASE_URL matches the project where you ran the migration
2. **Verify migration ran successfully** - Check the Supabase logs or run Query 1 again
3. **Check RLS policies** - The migration includes RLS policies that allow access

### Table exists but app can't see it?

1. **Check your Supabase URL** - Make sure it's correct in your .env file
2. **Check your anon key** - Make sure it's the correct key for your project
3. **Restart your app** - Sometimes the app needs to be restarted to pick up changes

### Need to reset everything?

```sql
-- Drop and recreate the table (CAUTION: This deletes all data!)
DROP TABLE IF EXISTS drivers CASCADE;

-- Then run the CREATE TABLE statement from the migration
```

## Next Steps

Once the table exists and has data:

1. **Test the Drivers page** in your Flutter app
2. **Try adding a new driver** using the "Add Driver" button
3. **Try editing a driver** by tapping the edit icon
4. **Try deleting a driver** by tapping the delete icon
5. **Test the Vehicle Sign-Out** tab

All CRUD operations should now work correctly!