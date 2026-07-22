# Ali HR Capital Management System — Leave Module

A full-featured leave management system built with **Next.js 15** (App Router), **React 19**, **Bootstrap 5**, and **MySQL 8**.

---

## Prerequisites

- Node.js 18 or later
- MySQL 8.0 or later

---

## Setup

### 1. Install dependencies

```bash
npm install
```

### 2. Configure environment variables

Copy the example file and fill in your values:

```bash
cp .env.local.example .env.local
```

Edit `.env.local`:

| Variable | Description |
|---|---|
| `DB_HOST` | MySQL host (e.g. `localhost`) |
| `DB_USER` | MySQL username |
| `DB_PASSWORD` | MySQL password |
| `DB_NAME` | Database name (e.g. `ali_hr_leave`) |
| `DB_PORT` | MySQL port (default `3306`) |
| `JWT_SECRET` | Random secret for JWT signing — run `openssl rand -base64 64` |
| `VAPID_PUBLIC_KEY` | Web Push VAPID public key |
| `VAPID_PRIVATE_KEY` | Web Push VAPID private key |

To generate VAPID keys:

```bash
npx web-push generate-vapid-keys
```

### 3. Initialise the database

Create the database in MySQL, then run the schema:

```bash
mysql -u root -p ali_hr_leave < database/schema.sql
```

Optionally load seed data:

```bash
mysql -u root -p ali_hr_leave < database/seeds.sql
```

### 4. Run the development server

```bash
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) in your browser.

---

## Build for production

```bash
npm run build
npm start
```

---

## Project Structure

```
leave-management-system/
├── app/               Next.js App Router pages
├── api/               REST API route handlers
├── components/        React components
│   ├── layout/        Sidebar, Navbar, etc.
│   ├── leave/         Leave-related components
│   ├── charts/        Chart.js wrappers
│   ├── common/        Shared UI (DataTable, Pagination, etc.)
│   └── calendar/      Holiday calendar
├── hooks/             Custom React hooks
├── lib/               DB pool, JWT helpers, push notify
├── middleware/        Auth and RBAC middleware
├── utils/             Working days, file validator, audit logger
├── context/           React context providers
├── services/          Business logic services
├── database/          SQL schema and seeds
├── public/            Static assets
│   └── uploads/attachments/  Uploaded files
└── styles/            Global CSS
```

---

## Roles

| Role | Permissions |
|---|---|
| Super Admin | Full access, configure leave types, users, settings |
| HR | Manage employees, quotas, holidays, reports |
| Manager | Approve/reject team leave requests, view reports |
| Employee | Submit leave requests, view own balances and ledger |

---

## Tech Stack

- **Framework**: Next.js 15 (App Router)
- **UI**: React 19 + Bootstrap 5 + Bootstrap Icons
- **Database**: MySQL 8 via `mysql2`
- **Auth**: JWT (`jsonwebtoken`) + bcrypt (`bcryptjs`)
- **Charts**: Chart.js + react-chartjs-2
- **Forms**: react-hook-form
- **Export**: exceljs (Excel) + pdfkit (PDF)
- **Notifications**: web-push (browser push) + in-app
- **File uploads**: multer
