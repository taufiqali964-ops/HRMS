// Simple database connection test
const mysql = require('mysql2/promise');
require('dotenv').config({ path: '.env.local' });

async function testDatabaseConnection() {
  console.log('=====================================');
  console.log('Database Connection Test');
  console.log('=====================================\n');

  console.log('Configuration:');
  console.log(`  Host: ${process.env.DB_HOST || 'localhost'}`);
  console.log(`  Port: ${process.env.DB_PORT || '3306'}`);
  console.log(`  User: ${process.env.DB_USER || 'root'}`);
  console.log(`  Database: ${process.env.DB_NAME || 'ali_hr_leave'}`);
  console.log(`  Password: ${process.env.DB_PASSWORD ? '***set***' : '(empty)'}\n`);

  try {
    console.log('Attempting to connect to MySQL...');
    
    const connection = await mysql.createConnection({
      host: process.env.DB_HOST || 'localhost',
      port: parseInt(process.env.DB_PORT || '3306'),
      user: process.env.DB_USER || 'root',
      password: process.env.DB_PASSWORD || '',
      database: process.env.DB_NAME || 'ali_hr_leave',
    });

    console.log('✓ Connected to MySQL successfully!\n');

    // Test query
    console.log('Checking tables...');
    const [tables] = await connection.execute('SHOW TABLES');
    
    if (tables.length === 0) {
      console.log('✗ No tables found!');
      console.log('  → Import schema: mysql -u root -p ali_hr_leave < database/schema.sql');
    } else {
      console.log(`✓ Found ${tables.length} tables:\n`);
      tables.forEach((row, idx) => {
        const tableName = row[Object.keys(row)[0]];
        console.log(`  ${idx + 1}. ${tableName}`);
      });
    }

    // Check for required tables
    console.log('\nChecking required tables...');
    const requiredTables = ['users', 'roles', 'employees', 'leave_requests', 'leave_types'];
    let allPresent = true;
    
    for (const tableName of requiredTables) {
      const found = tables.some(row => row[Object.keys(row)[0]] === tableName);
      if (found) {
        console.log(`  ✓ ${tableName}`);
      } else {
        console.log(`  ✗ ${tableName} - MISSING!`);
        allPresent = false;
      }
    }

    if (allPresent) {
      console.log('\n✓ All required tables present!');
    } else {
      console.log('\n✗ Some required tables are missing!');
      console.log('  → Import schema: mysql -u root -p ali_hr_leave < database/schema.sql');
    }

    // Test a simple query
    console.log('\nTesting query on roles table...');
    try {
      const [roles] = await connection.execute('SELECT COUNT(*) as count FROM roles');
      console.log(`✓ Found ${roles[0].count} role(s)`);
      
      if (roles[0].count === 0) {
        console.log('  → No roles found. Consider importing seeds.sql');
      }
    } catch (err) {
      console.log(`✗ Query failed: ${err.message}`);
    }

    await connection.end();
    console.log('\n✓ Database connection test PASSED!');
    console.log('\nYou can now start the server: npm run dev');
    
  } catch (error) {
    console.log('\n✗ Database connection FAILED!\n');
    console.log('Error:', error.message);
    console.log('\nCommon solutions:');
    console.log('  1. Check if MySQL is running: net start MySQL80');
    console.log('  2. Verify credentials in .env.local');
    console.log('  3. Create database: CREATE DATABASE ali_hr_leave;');
    console.log('  4. Check MySQL is on port', process.env.DB_PORT || '3306');
    console.log('\nFor detailed help, see DATABASE_SETUP.md');
    process.exit(1);
  }

  console.log('\n=====================================');
}

testDatabaseConnection();
