# Leave Management System - Setup Guide

## Fixes Applied

All API route naming conflicts have been resolved. The following files were fixed:
- ✅ app/api/users/route.js
- ✅ app/api/users/[id]/route.js
- ✅ app/api/leave-quotas/route.js
- ✅ app/api/leave-quotas/[id]/route.js
- ✅ app/api/leave-approvals/route.js
- ✅ app/api/leave-balances/route.js
- ✅ app/api/leave-ledger/route.js
- ✅ app/api/notifications/route.js
- ✅ app/api/reports/route.js
- ✅ app/api/reports/utilisation/route.js

## Prerequisites

1. **Node.js** (v18 or later)
   - Check: `node --version`

2. **MySQL 8.0** or later
   - Check: `mysql --version`

## Setup Instructions

### 1. Install Dependencies

```bash
npm install
```

### 2. Configure Environment Variables

The `.env.local` file is already created. Verify these settings:

```env
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=
DB_NAME=ali_hr_leave
DB_PORT=3306

JWT_SECRET=ali-hr-super-secret-jwt-key-change-in-production

VAPID_PUBLIC_KEY=
VAPID_PRIVATE_KEY=
```

**Important:**
- Set your MySQL password in `DB_PASSWORD`
- Generate a secure JWT_SECRET for production: `openssl rand -base64 64`
- VAPID keys are optional for push notifications

### 3. Setup MySQL Database

Open MySQL command line or MySQL Workbench and run:

```sql
CREATE DATABASE IF NOT EXISTS ali_hr_leave;
```

Then import the schema:

```bash
mysql -u root -p ali_hr_leave < database/schema.sql
```

Optionally, load seed data:

```bash
mysql -u root -p ali_hr_leave < database/seeds.sql
```

### 4. Run the Development Server

**Option A: Using npm (recommended)**
```bash
npm run dev
```

**Option B: Using the batch file**
```bash
dev.bat
```

The application will be available at http://localhost:3000

### 5. Build for Production

```bash
npm run build
npm start
```

## Default Login Credentials

After loading seed data (if available), you can login with:
- Email: admin@example.com
- Password: admin123

(Check `database/seeds.sql` for actual credentials)

## Troubleshooting

### Build Errors
If you encounter "Identifier already declared" errors:
- All known issues have been fixed
- Clear the `.next` folder and rebuild: `rm -rf .next && npm run build`

### Database Connection Errors
- Ensure MySQL is running
- Check credentials in `.env.local`
- Verify database exists: `SHOW DATABASES;`
- Check user permissions: `GRANT ALL PRIVILEGES ON ali_hr_leave.* TO 'root'@'localhost';`

### PowerShell Execution Policy Error
If npm commands fail in PowerShell:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

Or use the batch files provided (`.bat` files work with cmd.exe)

## Project Structure

```
├── app/               # Next.js App Router pages & API routes
├── components/        # React components
├── hooks/             # Custom React hooks
├── lib/               # Database, JWT utilities
├── middleware/        # Auth & RBAC middleware
├── services/          # Business logic
├── utils/             # Helper functions
├── database/          # SQL schema and seeds
└── public/            # Static assets
```

## API Endpoints

All API routes are under `/api/`:
- `/api/auth` - Authentication
- `/api/users` - User management
- `/api/employees` - Employee management
- `/api/leave-types` - Leave types
- `/api/leave-requests` - Leave request submissions
- `/api/leave-approvals` - Approval workflow
- `/api/leave-balances` - Leave balance inquiry
- `/api/leave-quotas` - Quota management
- `/api/holidays` - Holiday calendar
- `/api/reports` - Reports and analytics
- `/api/notifications` - User notifications

## Next Steps

1. Start the dev server: `npm run dev`
2. Navigate to http://localhost:3000
3. Login with default credentials
4. Explore the dashboard

## Support

For issues or questions, refer to the main README.md file.
