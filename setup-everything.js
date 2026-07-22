// Automatic Database Setup Script
const mysql = require('mysql2/promise');
const bcrypt = require('bcryptjs');
const fs = require('fs');

async function setupEverything() {
    console.log('========================================');
    console.log('AUTOMATIC DATABASE SETUP');
    console.log('========================================\n');

    let connection;
    
    try {
        // Try to connect to MySQL (without database first)
        console.log('[1/6] Connecting to MySQL...');
        connection = await mysql.createConnection({
            host: 'localhost',
            user: 'root',
            password: '', // Empty password - common for local dev
            port: 3306
        });
        console.log('✓ Connected to MySQL\n');

        // Create database
        console.log('[2/6] Creating database...');
        await connection.query('CREATE DATABASE IF NOT EXISTS ali_hr_leave');
        console.log('✓ Database created\n');

        // Switch to the database
        await connection.query('USE ali_hr_leave');

        // Read and execute schema
        console.log('[3/6] Creating tables...');
        const schema = fs.readFileSync('database/schema.sql', 'utf8');
        const statements = schema.split(';').filter(stmt => stmt.trim());
        
        for (const statement of statements) {
            if (statement.trim()) {
                try {
                    await connection.query(statement);
                } catch (err) {
                    // Ignore duplicate table errors
                    if (!err.message.includes('already exists')) {
                        console.log('Warning:', err.message);
                    }
                }
            }
        }
        console.log('✓ Tables created\n');

        // Insert default roles
        console.log('[4/6] Creating roles...');
        await connection.query(`
            INSERT IGNORE INTO roles (id, name) VALUES
            (1, 'super_admin'),
            (2, 'hr'),
            (3, 'manager'),
            (4, 'employee')
        `);
        console.log('✓ Roles created\n');

        // Create default users
        console.log('[5/6] Creating default users...');
        
        // Hash passwords
        const adminPass = await bcrypt.hash('Admin@123', 12);
        const hrPass = await bcrypt.hash('Hr@123', 12);
        const managerPass = await bcrypt.hash('Manager@123', 12);
        const empPass = await bcrypt.hash('Employee@123', 12);

        await connection.query(`
            INSERT IGNORE INTO users (email, password, role_id, first_name, last_name, is_active) VALUES
            ('admin@ali-hr.com', ?, 1, 'Super', 'Admin', TRUE),
            ('hr@ali-hr.com', ?, 2, 'HR', 'User', TRUE),
            ('manager@ali-hr.com', ?, 3, 'Manager', 'User', TRUE),
            ('employee@ali-hr.com', ?, 4, 'Employee', 'User', TRUE)
        `, [adminPass, hrPass, managerPass, empPass]);
        
        console.log('✓ Users created\n');

        // Create basic leave types
        console.log('[6/6] Creating leave types...');
        await connection.query(`
            INSERT IGNORE INTO leave_types (name, unit, accrual_rule, approval_levels, is_active) VALUES
            ('Annual Leave', 'days', '{"type":"annual","amount":21}', 2, TRUE),
            ('Sick Leave', 'days', '{"type":"annual","amount":14}', 1, TRUE),
            ('Casual Leave', 'days', '{"type":"annual","amount":10}', 1, TRUE)
        `);
        console.log('✓ Leave types created\n');

        await connection.end();

        console.log('========================================');
        console.log('✓ DATABASE SETUP COMPLETE!');
        console.log('========================================\n');
        console.log('You can now login with:\n');
        console.log('Email:    admin@ali-hr.com');
        console.log('Password: Admin@123\n');
        console.log('Or use any of these:\n');
        console.log('- hr@ali-hr.com / Hr@123');
        console.log('- manager@ali-hr.com / Manager@123');
        console.log('- employee@ali-hr.com / Employee@123\n');
        console.log('========================================');
        console.log('Open: http://localhost:3000');
        console.log('========================================\n');

    } catch (error) {
        console.error('\n✗ Setup failed!');
        console.error('Error:', error.message);
        console.error('\nPossible solutions:');
        console.error('1. Make sure MySQL is running');
        console.error('2. Check if MySQL root password is empty (or update this script)');
        console.error('3. Start MySQL: net start MySQL80');
        process.exit(1);
    }
}

setupEverything();
