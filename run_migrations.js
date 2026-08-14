require('dotenv').config();
const { Client } = require('pg');
const fs = require('fs');
const path = require('path');

const DATABASE_URL = process.env.DATABASE_URL;

if (!DATABASE_URL) {
  console.error('❌ DATABASE_URL is not set in your .env file.');
  console.error('   Add: DATABASE_URL=postgresql://postgres:[PASSWORD]@db.xxxx.supabase.co:5432/postgres');
  process.exit(1);
}

async function testConnection(client) {
  try {
    const result = await client.query('SELECT version()');
    console.log('✅ Connected to:', result.rows[0].version);
    return true;
  } catch (err) {
    console.error('❌ Connection test failed:', err.message);
    return false;
  }
}

async function runMigrations() {
  const client = new Client({
    connectionString: DATABASE_URL,
    ssl: {
      rejectUnauthorized: false,
      checkServerIdentity: () => undefined
    }
  });

  try {
    await client.connect();
    console.log('✅ PostgreSQL connection established\n');

    const connected = await testConnection(client);
    if (!connected) {
      console.error('❌ Aborting — could not verify database connection.');
      process.exit(1);
    }

    const migrationsDir = './supabase/migrations';

    if (!fs.existsSync(migrationsDir)) {
      console.error(`❌ Migrations directory not found: ${migrationsDir}`);
      process.exit(1);
    }

    const files = fs.readdirSync(migrationsDir)
      .filter(f => f.endsWith('.sql'))
      .sort();

    console.log(`\nFound ${files.length} migration files to run:\n`);
    files.forEach(f => console.log(`  - ${f}`));
    console.log('\n--- Starting migrations ---\n');

    // Check if tables already exist
    const tableCheck = await client.query(`
      SELECT table_name FROM information_schema.tables 
      WHERE table_schema = 'public' 
      AND table_name IN ('profiles', 'service_users', 'compliance_rules', 'compliance_flags', 'compliance_scores')
    `);

    let filesToRun;
    if (tableCheck.rows.length > 0) {
      console.log('⚠️  Some tables already exist. Skipping initial schema migration.');
      console.log('   Continuing with remaining migrations...');
      // Filter out the initial schema migration if tables exist
      const initialSchemaFiles = ['001_initial_schema.sql', '002_compliance_engine.sql', '003_compliance_settings.sql'];
      filesToRun = files.filter(f => !initialSchemaFiles.includes(f));
      console.log(`\nSkipping: ${initialSchemaFiles.join(', ')}`);
      console.log(`Running remaining ${filesToRun.length} migrations...\n`);
    } else {
      console.log('✅ No existing tables found. Starting fresh migration...');
      filesToRun = files;
    }

    let successCount = 0;
    let failedFile = null;

    for (const file of filesToRun) {
      const filePath = path.join(migrationsDir, file);
      const sql = fs.readFileSync(filePath, 'utf8');

      console.log(`Running ${file}...`);

      try {
        await client.query(sql);
        console.log(`✅ ${file} — success\n`);
        successCount++;
      } catch (err) {
        console.error(`❌ ${file} — FAILED`);
        console.error(`   Error: ${err.message}`);
        console.error(`   Position: ${err.position || 'unknown'}`);
        console.error(`\n⚠️  Stopping after ${successCount} successful migrations.`);
        console.error(`   Fix ${file} then run again.\n`);
        failedFile = file;
        break;
      }
    }

    if (!failedFile) {
      console.log(`\n🎉 All ${successCount} migrations completed successfully!`);
    }

  } catch (err) {
    console.error('❌ Fatal error:', err.message);
    if (err.message.includes('password authentication failed')) {
      console.error('   → Check your DATABASE_URL password in .env');
    }
    if (err.message.includes('ENOTFOUND') || err.message.includes('ECONNREFUSED')) {
      console.error('   → Check your DATABASE_URL hostname in .env');
    }
  } finally {
    await client.end();
    console.log('Database connection closed.');
  }
}

runMigrations();