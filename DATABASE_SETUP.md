# Database Setup Guide

## Problem: "localhost refused to connect"

This error means the development server isn't running. The most common reason is a **database connection failure**.

---

## Quick Fix

### Step 1: Check if MySQL is Running

**Option A: Using Task Manager**
1. Press `Ctrl + Shift + Esc` to open Task Manager
2. Go to "Services" tab
3. Look for "MySQL" or "MySQL80" service
4. If not running, right-click and select "Start"

**Option B: Using Services**
1. Press `Win + R`, type `services.msc`, press Enter
2. Find "MySQL" or "MySQL80"
3. Right-click → Start (if not running)

**Option C: Using Command Prompt**
```cmd
net start MySQL80
```
(Replace MySQL80 with your MySQL service name)

### Step 2: Create the Database

**Using MySQL Workbench (Recommended):**
1. Open MySQL Workbench
2. Connect to your local MySQL server
3. Click "Create new schema" or run:
   ```sql
   CREATE DATABASE ali_hr_leave;
   ```

**Using Command Line:**
```cmd
mysql -u root -p
```
Then in MySQL prompt:
```sql
CREATE DATABASE ali_hr_leave;
EXIT;
```

### Step 3: Import the Schema

**Using MySQL Workbench:**
1. Select the `ali_hr_leave` database
2. Go to File → Run SQL Script
3. Browse to: `database\schema.sql`
4. Click "Run"

**Using Command Line:**
```cmd
cd /d "c:\Users\Team Lead Hopper\Downloads\leave-management-system"
mysql -u root -p ali_hr_leave < database\schema.sql
```

### Step 4: Configure Password

Edit `.env.local` and set your MySQL password:

```env
DB_PASSWORD=your_mysql_password_here
```

**If MySQL has no password (local development):**
- Leave it empty: `DB_PASSWORD=`
- This is fine for local testing

### Step 5: Start the Server

**Run the diagnostic first:**
```cmd
diagnose.bat
```

**Then start the dev server:**
```cmd
start-dev.bat
```

Or directly:
```cmd
npm run dev
```

---

## Troubleshooting

### Error: "Access denied for user 'root'@'localhost'"

**Solution:** Wrong password in `.env.local`
- Check your MySQL root password
- Update `DB_PASSWORD` in `.env.local`

### Error: "Unknown database 'ali_hr_leave'"

**Solution:** Database not created
- Create it: `CREATE DATABASE ali_hr_leave;`
- Then import the schema

### Error: "Can't connect to MySQL server"

**Solution:** MySQL not running
- Start MySQL service (see Step 1 above)
- Or install MySQL: https://dev.mysql.com/downloads/mysql/

### Error: "Table doesn't exist"

**Solution:** Schema not imported
- Import: `mysql -u root -p ali_hr_leave < database\schema.sql`
- Or use MySQL Workbench to run the schema.sql file

### Port 3000 already in use

**Solution:** Another app is using port 3000
1. Find what's using it:
   ```cmd
   netstat -ano | findstr :3000
   ```
2. Kill that process:
   ```cmd
   taskkill /PID [process_id] /F
   ```
3. Or run Next.js on different port:
   ```cmd
   npm run dev -- -p 3001
   ```

---

## Verify Database Setup

Run this query in MySQL to check tables exist:

```sql
USE ali_hr_leave;
SHOW TABLES;
```

You should see these tables:
- audit_logs
- attachments
- branches
- compensation_leaves
- departments
- designations
- employees
- holidays
- leave_approvals
- leave_balances
- leave_ledgers
- leave_quotas
- leave_requests
- leave_types
- notifications
- roles
- users

---

## Default Admin Account

After importing schema and seeds:

- **Email:** Check `database/seeds.sql` for default credentials
- **Password:** Usually `admin123` or similar

If no seeds file or want to create manually:

```sql
-- Create admin role first
INSERT INTO roles (name, permissions) VALUES 
('super_admin', '["*"]');

-- Create admin user (password: admin123)
INSERT INTO users (email, password, role_id, first_name, last_name) VALUES 
('admin@example.com', 
 '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5kuyvkMGHmhfK',
 1, 'Admin', 'User');
```

---

## Testing Database Connection

Create a test file: `test-db.js`

```javascript
const mysql = require('mysql2/promise');

async function testConnection() {
  try {
    const connection = await mysql.createConnection({
      host: 'localhost',
      user: 'root',
      password: '', // Your password
      database: 'ali_hr_leave',
      port: 3306
    });
    
    console.log('✓ Database connected successfully!');
    
    const [rows] = await connection.execute('SHOW TABLES');
    console.log(`✓ Found ${rows.length} tables`);
    
    await connection.end();
    console.log('✓ Connection closed');
  } catch (error) {
    console.error('✗ Database connection failed:');
    console.error(error.message);
  }
}

testConnection();
```

Run: `node test-db.js`

---

## Common MySQL Installation Locations

**Program Files:**
- `C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe`

**Add to PATH:**
1. Copy the bin folder path above
2. Win + X → System → Advanced system settings
3. Environment Variables → Path → Edit
4. Add new entry with MySQL bin path

---

## Still Having Issues?

1. **Run diagnostics:**
   ```cmd
   diagnose.bat
   ```

2. **Check if database is accessible:**
   - Open MySQL Workbench
   - Try connecting to localhost
   - Browse to `ali_hr_leave` database

3. **Check MySQL logs:**
   - Location: MySQL data directory
   - Usually: `C:\ProgramData\MySQL\MySQL Server 8.0\Data\`
   - Look for `*.err` files

4. **Restart MySQL:**
   ```cmd
   net stop MySQL80
   net start MySQL80
   ```

5. **Try different MySQL client:**
   - HeidiSQL: https://www.heidisql.com/
   - DBeaver: https://dbeaver.io/

---

## Need Help?

Create an issue with:
- Error message from server console
- Output of `diagnose.bat`
- MySQL version: `mysql --version`
- Node version: `node --version`
