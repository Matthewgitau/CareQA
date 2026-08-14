const { createClient } = require('@supabase/supabase-js');
require('dotenv').config({ path: '.env' });

// Initialize Supabase client
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseKey) {
  console.error('Error: SUPABASE_URL and SUPABASE_ANON_KEY must be set in .env file');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseKey);

async function checkDriversTable() {
  console.log('🔍 Checking drivers table...\n');
  
  try {
    // Check if table exists by trying to query it
    const { data, error } = await supabase
      .from('drivers')
      .select('id, staff_name', { count: 'exact', head: true });
    
    if (error) {
      if (error.code === '42P01') {
        console.error('❌ Drivers table does not exist!');
        console.log('   Run migrations first: npm run migrate');
        return;
      }
      console.error('❌ Error checking table:', error.message);
      return;
    }
    
    console.log('✅ Drivers table exists!');
    
    // Get actual count and data
    const { data: drivers, error: fetchError } = await supabase
      .from('drivers')
      .select('*')
      .order('created_at', { ascending: false });
    
    if (fetchError) {
      console.error('❌ Error fetching drivers:', fetchError.message);
      return;
    }
    
    console.log(`📊 Total drivers: ${drivers.length}\n`);
    
    if (drivers.length === 0) {
      console.log('⚠️  No drivers found in the database.');
      console.log('   Would you like to add a test driver? (y/n)');
      
      // For automated testing, we'll add one automatically
      console.log('\n📝 Adding test driver...');
      const { data: newDriver, error: insertError } = await supabase
        .from('drivers')
        .insert([{
          staff_name: 'Test Driver',
          employee_id: 'EMP001',
          job_role: 'Senior Carer',
          contact_phone: '07123 456789',
          is_active: true,
          is_exclusive_driver: false,
          license_number: 'SMITH123456789',
          license_categories: 'B, B+E',
          created_at: new Date().toISOString()
        }])
        .select()
        .single();
      
      if (insertError) {
        console.error('❌ Error adding test driver:', insertError.message);
      } else {
        console.log('✅ Test driver added successfully!');
        console.log(`   ID: ${newDriver.id}`);
        console.log(`   Name: ${newDriver.staff_name}`);
      }
    } else {
      console.log('📋 Recent drivers:');
      drivers.slice(0, 5).forEach(driver => {
        console.log(`   - ${driver.staff_name} (${driver.employee_id || 'No emp ID'})`);
      });
      if (drivers.length > 5) {
        console.log(`   ... and ${drivers.length - 5} more`);
      }
    }
    
  } catch (err) {
    console.error('❌ Unexpected error:', err.message);
  }
}

// Run the check
checkDriversTable();