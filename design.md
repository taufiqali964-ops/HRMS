# Design Document — Ali HR Capital Management System (Leave Module)

## Overview

The Leave Module is a full-stack web application built on **Next.js 15 App Router**, **React 19**, **JavaScript (no TypeScript)**, **Bootstrap 5**, and **MySQL 8**. It exposes a REST API through Next.js API Routes and enforces JWT-based RBAC with four roles: Super Admin, HR, Manager, and Employee.

---

## Architecture

### High-Level Architecture

```
Browser (React 19 + Bootstrap 5)
        |
        | HTTPS / fetch (Axios)
        v
Next.js 15 App Router
  ├── app/         — Page components (RSC + Client Components)
  ├── api/         — REST API Route Handlers (Node.js)
  └── middleware/  — JWT auth + RBAC guard
        |
        | mysql2 / promise pool
        v
MySQL 8 Database (19 tables)
        |
        | /public/uploads/
        v
Local filesystem (attachments)
```

### Request Lifecycle

1. Client sends request with `Authorization: Bearer <JWT>` header.
2. `middleware/auth.js` validates the JWT and extracts `{ userId, role }`.
3. `middleware/rbac.js` checks the role against a permission map; returns 403 if denied.
4. API Route Handler executes business logic via a Service layer.
5. Service calls Repository functions that run parameterised MySQL queries.
6. Response is returned as JSON; side-effects (notifications, audit logs) are written in the same transaction or via a post-commit hook.

---

## Folder Structure

```
leave-management-system/
├── app/
│   ├── (auth)/login/page.js
│   ├── dashboard/page.js
│   ├── employees/page.js
│   ├── leave/
│   │   ├── request/page.js
│   │   ├── approvals/page.js
│   │   ├── balances/page.js
│   │   └── ledger/page.js
│   ├── settings/
│   │   ├── leave-types/page.js
│   │   ├── approval-chains/page.js
│   │   └── roles/page.js
│   ├── holidays/page.js
│   ├── users/page.js
│   └── reports/page.js
├── api/
│   ├── auth/route.js
│   ├── leave-types/route.js
│   ├── leave-requests/route.js
│   ├── leave-approvals/route.js
│   ├── leave-balances/route.js
│   ├── leave-ledger/route.js
│   ├── leave-quotas/route.js
│   ├── holidays/route.js
│   ├── compensation-leaves/route.js
│   ├── notifications/route.js
│   ├── reports/route.js
│   ├── audit-logs/route.js
│   └── attachments/route.js
├── components/
│   ├── layout/ (Sidebar, Navbar, ThemeToggle, NotificationBell)
│   ├── leave/ (LeaveRequestForm, ApprovalCard, BalanceCard, LedgerTable)
│   ├── charts/ (UtilisationChart, LeaveTypeChart)
│   ├── common/ (DataTable, Pagination, FilterBar, ExportButtons)
│   └── calendar/ (HolidayCalendar)
├── hooks/
│   ├── useAuth.js
│   ├── useNotifications.js
│   ├── useLeaveBalance.js
│   └── usePagination.js
├── lib/
│   ├── db.js            (mysql2 connection pool)
│   ├── jwt.js           (sign / verify helpers)
│   └── pushNotify.js    (Web Push API wrapper)
├── middleware/
│   ├── auth.js
│   └── rbac.js
├── utils/
│   ├── workingDays.js
│   ├── fileValidator.js
│   └── auditLogger.js
├── context/
│   ├── AuthContext.js
│   └── ThemeContext.js
├── services/
│   ├── leaveTypeService.js
│   ├── leaveRequestService.js
│   ├── approvalService.js
│   ├── balanceService.js
│   ├── notificationService.js
│   └── reportService.js
├── public/
│   └── uploads/attachments/
├── styles/
│   └── globals.css
└── database/
    ├── schema.sql
    └── seeds.sql
```

---

## Database Schema

### Core Tables (19 tables)

```sql
-- 1. roles
CREATE TABLE roles (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  name       ENUM('super_admin','hr','manager','employee') NOT NULL UNIQUE,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 2. permissions
CREATE TABLE permissions (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  role_id    INT NOT NULL REFERENCES roles(id),
  resource   VARCHAR(100) NOT NULL,
  actions    JSON NOT NULL,          -- e.g. ["read","create","update"]
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 3. users
CREATE TABLE users (
  id           INT AUTO_INCREMENT PRIMARY KEY,
  email        VARCHAR(255) NOT NULL UNIQUE,
  password     VARCHAR(255) NOT NULL,  -- bcrypt hash
  role_id      INT NOT NULL REFERENCES roles(id),
  is_active    BOOLEAN DEFAULT TRUE,
  theme        ENUM('light','dark') DEFAULT 'light',
  created_at   DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at   DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- 4. departments
CREATE TABLE departments (
  id   INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(150) NOT NULL UNIQUE
);

-- 5. branches
CREATE TABLE branches (
  id   INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(150) NOT NULL UNIQUE
);

-- 6. designations
CREATE TABLE designations (
  id   INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(150) NOT NULL UNIQUE
);

-- 7. employees
CREATE TABLE employees (
  id             INT AUTO_INCREMENT PRIMARY KEY,
  user_id        INT NOT NULL UNIQUE REFERENCES users(id),
  department_id  INT REFERENCES departments(id),
  designation_id INT REFERENCES designations(id),
  branch_id      INT REFERENCES branches(id),
  manager_id     INT REFERENCES employees(id),
  hire_date      DATE,
  created_at     DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 8. leave_types
CREATE TABLE leave_types (
  id               INT AUTO_INCREMENT PRIMARY KEY,
  name             VARCHAR(100) NOT NULL UNIQUE,
  unit             ENUM('days','hours') NOT NULL,
  accrual_rule     JSON NOT NULL,
  approval_levels  TINYINT NOT NULL DEFAULT 1 CHECK (approval_levels BETWEEN 1 AND 3),
  is_active        BOOLEAN DEFAULT TRUE,
  created_at       DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at       DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- 9. leave_requests
CREATE TABLE leave_requests (
  id              INT AUTO_INCREMENT PRIMARY KEY,
  employee_id     INT NOT NULL REFERENCES employees(id),
  leave_type_id   INT NOT NULL REFERENCES leave_types(id),
  start_date      DATE NOT NULL,
  end_date        DATE NOT NULL,
  duration        DECIMAL(6,2) NOT NULL,   -- working days or hours
  reason          TEXT,
  status          ENUM('pending','approved','rejected','cancelled') DEFAULT 'pending',
  created_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at      DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- 10. leave_approvals
CREATE TABLE leave_approvals (
  id              INT AUTO_INCREMENT PRIMARY KEY,
  request_id      INT NOT NULL REFERENCES leave_requests(id),
  level           TINYINT NOT NULL,
  approver_id     INT REFERENCES users(id),
  status          ENUM('pending','approved','rejected','cancelled') DEFAULT 'pending',
  rejection_reason TEXT,
  approved_by     INT REFERENCES users(id),
  approved_at     DATETIME,
  created_at      DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 11. leave_balances
CREATE TABLE leave_balances (
  id              INT AUTO_INCREMENT PRIMARY KEY,
  employee_id     INT NOT NULL REFERENCES employees(id),
  leave_type_id   INT NOT NULL REFERENCES leave_types(id),
  balance         DECIMAL(8,2) NOT NULL DEFAULT 0,
  period_start    DATE NOT NULL,
  period_end      DATE NOT NULL,
  UNIQUE KEY uq_emp_type_period (employee_id, leave_type_id, period_start)
);

-- 12. leave_ledgers
CREATE TABLE leave_ledgers (
  id              INT AUTO_INCREMENT PRIMARY KEY,
  employee_id     INT NOT NULL REFERENCES employees(id),
  leave_type_id   INT NOT NULL REFERENCES leave_types(id),
  request_id      INT REFERENCES leave_requests(id),
  transaction_type ENUM('credit','debit') NOT NULL,
  amount          DECIMAL(6,2) NOT NULL,
  running_balance DECIMAL(8,2) NOT NULL,
  description     VARCHAR(255),
  created_at      DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 13. leave_quotas
CREATE TABLE leave_quotas (
  id              INT AUTO_INCREMENT PRIMARY KEY,
  employee_id     INT NOT NULL REFERENCES employees(id),
  leave_type_id   INT NOT NULL REFERENCES leave_types(id),
  entitlement     DECIMAL(6,2) NOT NULL,
  period_start    DATE NOT NULL,
  period_end      DATE NOT NULL,
  status          ENUM('active','expired') DEFAULT 'active',
  created_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at      DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- 14. holidays
CREATE TABLE holidays (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  date       DATE NOT NULL UNIQUE,
  name       VARCHAR(150) NOT NULL,
  type       ENUM('public','company') NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 15. compensation_leaves
CREATE TABLE compensation_leaves (
  id              INT AUTO_INCREMENT PRIMARY KEY,
  employee_id     INT NOT NULL REFERENCES employees(id),
  worked_date     DATE NOT NULL,
  compensation    DECIMAL(6,2) NOT NULL,
  reason          TEXT,
  created_at      DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 16. notifications
CREATE TABLE notifications (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  user_id    INT NOT NULL REFERENCES users(id),
  title      VARCHAR(255) NOT NULL,
  message    TEXT NOT NULL,
  is_read    BOOLEAN DEFAULT FALSE,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 17. audit_logs
CREATE TABLE audit_logs (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  actor_id    INT REFERENCES users(id),
  action      ENUM('create','update','delete') NOT NULL,
  entity      VARCHAR(100) NOT NULL,
  entity_id   INT NOT NULL,
  old_state   JSON,
  new_state   JSON,
  created_at  DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 18. attachments
CREATE TABLE attachments (
  id              INT AUTO_INCREMENT PRIMARY KEY,
  request_id      INT NOT NULL REFERENCES leave_requests(id),
  original_name   VARCHAR(255) NOT NULL,
  stored_name     VARCHAR(255) NOT NULL,
  mime_type       VARCHAR(100) NOT NULL,
  size_bytes      INT NOT NULL,
  created_at      DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 19. settings
CREATE TABLE settings (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  key_name   VARCHAR(100) NOT NULL UNIQUE,
  value      JSON NOT NULL,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

---

## Component Interfaces

### API Route Conventions

All API routes follow the pattern:
- `GET /api/{resource}` — list with optional `?page=&pageSize=&filter=...`
- `POST /api/{resource}` — create
- `PUT /api/{resource}/[id]` — update
- `DELETE /api/{resource}/[id]` — delete

All routes return `{ success: true, data: {...}, meta: { page, pageSize, total } }` or `{ success: false, error: "message" }`.

### Authentication

```js
// lib/jwt.js
export function signToken(payload) { /* signs with HS256, 8h expiry */ }
export function verifyToken(token) { /* returns payload or throws */ }

// middleware/auth.js
export function withAuth(handler) {
  return async (req, res) => {
    const token = req.headers.authorization?.split(' ')[1]
    const payload = verifyToken(token)           // throws 401 on invalid
    req.user = payload
    return handler(req, res)
  }
}

// middleware/rbac.js
export function withPermission(resource, action) {
  return (handler) => withAuth(async (req, res) => {
    const allowed = await checkPermission(req.user.role, resource, action)
    if (!allowed) return res.status(403).json({ success: false, error: 'Forbidden' })
    return handler(req, res)
  })
}
```

### Working Days Calculator

```js
// utils/workingDays.js
/**
 * Calculate working days between two dates (inclusive),
 * excluding weekends and holiday dates from the provided set.
 *
 * @param {Date} startDate
 * @param {Date} endDate
 * @param {Set<string>} holidayDates  — ISO date strings ('YYYY-MM-DD')
 * @returns {number}
 */
export function calculateWorkingDays(startDate, endDate, holidayDates) {
  let count = 0
  const current = new Date(startDate)
  while (current <= endDate) {
    const dayOfWeek = current.getDay()
    const iso = current.toISOString().slice(0, 10)
    if (dayOfWeek !== 0 && dayOfWeek !== 6 && !holidayDates.has(iso)) {
      count++
    }
    current.setDate(current.getDate() + 1)
  }
  return count
}
```

### File Validator

```js
// utils/fileValidator.js
const ALLOWED_MIME = new Set([
  'application/pdf',
  'image/jpeg',
  'image/png',
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
])
const MAX_BYTES = 5 * 1024 * 1024  // 5 MB

export function validateFile(file) {
  const errors = []
  if (!ALLOWED_MIME.has(file.mimetype)) errors.push('Invalid file type')
  if (file.size > MAX_BYTES) errors.push('File exceeds 5 MB limit')
  return errors
}
```

### Audit Logger

```js
// utils/auditLogger.js
export async function writeAuditLog(conn, { actorId, action, entity, entityId, oldState, newState }) {
  await conn.execute(
    `INSERT INTO audit_logs (actor_id, action, entity, entity_id, old_state, new_state)
     VALUES (?, ?, ?, ?, ?, ?)`,
    [actorId, action, entity, entityId, JSON.stringify(oldState), JSON.stringify(newState)]
  )
}
```

### Approval Service (State Machine)

```js
// services/approvalService.js

/**
 * Create pending approval rows for a new leave request.
 * One row per approval level (1..leave_type.approval_levels).
 */
export async function initApprovalChain(conn, requestId, leaveTypeId) { ... }

/**
 * Approve the current pending level. If it is the last level,
 * mark the leave request as 'approved' and trigger balance deduction.
 */
export async function approveLevel(conn, requestId, approverId, level) { ... }

/**
 * Reject at the given level. Cancel all subsequent levels and
 * set leave request status to 'rejected'.
 */
export async function rejectLevel(conn, requestId, approverId, level, reason) { ... }
```

### Balance Service

```js
// services/balanceService.js

/** Deduct duration from balance and write a debit ledger entry. */
export async function deductBalance(conn, employeeId, leaveTypeId, duration, requestId) { ... }

/** Credit duration to balance (reversal) and write a credit ledger entry. */
export async function creditBalance(conn, employeeId, leaveTypeId, duration, description) { ... }

/** Return current balance for employee+leaveType within active quota period. */
export async function getBalance(conn, employeeId, leaveTypeId) { ... }
```

### Notification Service

```js
// services/notificationService.js

/** Create in-app notification record(s) and attempt browser push delivery. */
export async function sendNotification(conn, { userIds, title, message }) { ... }

/** Fetch unread notifications for a user, sorted reverse-chronologically. */
export async function getUnreadNotifications(conn, userId) { ... }

/** Mark a notification as read and return updated record. */
export async function markAsRead(conn, notificationId, userId) { ... }
```

---

## UI Design System

### Theme and Colours

| Token         | Value     | Usage                        |
|---------------|-----------|------------------------------|
| Primary       | `#0F4C81` | Buttons, links, active states |
| Secondary     | `#20B2AA` | Badges, highlights            |
| Accent        | `#FFC107` | Warnings, pending indicators  |
| Sidebar BG    | `#0a2d4a` | Dark navy sidebar             |
| BS Icons      | Bootstrap Icons 1.x |                    |

Dark/light theme is toggled via a `data-bs-theme` attribute on `<html>`. The active theme is stored in `localStorage` under the key `ali-hr-theme`.

### Sidebar Navigation

Role-aware navigation links rendered server-side based on JWT role claim:
- All roles: Dashboard, Leave Requests, Notifications
- Employee: Leave Balances, Leave Ledger
- Manager / HR: Approvals, Team Calendar, Reports
- HR / Super Admin: Employees, Holidays, Leave Quotas, Compensation Leaves, Reports
- Super Admin: Leave Types, Users, Settings, Audit Logs

### Chart.js Integration

```js
// components/charts/UtilisationChart.js
'use client'
import { Bar } from 'react-chartjs-2'

export default function UtilisationChart({ data }) {
  // data: { labels: ['Jan',...,'Dec'], datasets: [{ label, data: [numbers] }] }
  return <Bar data={data} options={{ responsive: true, plugins: { legend: { position: 'top' } } }} />
}
```

Charts are rendered on the client; data is fetched via a dedicated API route `/api/reports/utilisation?year=YYYY`.

---

## Multi-Level Approval State Machine

```
Leave Request created
        |
        v
   [level 1: pending]
        |
   approver acts
      /     \
 approved   rejected
    |            |
[level 2     All subsequent levels → cancelled
 pending]    Leave Request → rejected
    |
 ... (up to level 3)
    |
 All levels approved
    |
Leave Request → approved
    + balance deduction
    + ledger debit entry
    + employee notification
```

Key invariant: A level N+1 row has `status = 'pending'` only when level N has `status = 'approved'`. Enforcement is in `approvalService.approveLevel()`, which checks the previous level before unlocking the next.

---

## Report Export Design

### Excel (.xlsx)

Uses the `exceljs` library:

```js
// services/reportService.js
import ExcelJS from 'exceljs'

export async function generateExcel(reportData, columns) {
  const workbook = new ExcelJS.Workbook()
  const sheet = workbook.addWorksheet('Report')
  sheet.columns = columns.map(c => ({ header: c.label, key: c.key, width: 20 }))
  reportData.forEach(row => sheet.addRow(row))
  const buffer = await workbook.xlsx.writeBuffer()
  return buffer
}
```

### PDF

Uses the `pdfkit` library:

```js
import PDFDocument from 'pdfkit'

export function generatePDF(reportData, columns) {
  return new Promise((resolve) => {
    const doc = new PDFDocument({ margin: 40 })
    const chunks = []
    doc.on('data', chunk => chunks.push(chunk))
    doc.on('end', () => resolve(Buffer.concat(chunks)))
    // Draw table header and rows
    doc.end()
  })
}
```

---

## Error Handling

| Scenario | HTTP Status | UI Behaviour |
|---|---|---|
| JWT missing / expired | 401 | Redirect to `/login` |
| Insufficient role permission | 403 | Show `AccessDenied` component |
| Validation failure | 422 | Inline field errors via React Hook Form |
| Insufficient leave balance | 422 | Balance-warning banner, submission blocked |
| Invalid file upload | 422 | File input error message, no file saved |
| Database constraint violation | 500 | Toast: "Something went wrong, please retry" |
| Record not found | 404 | Show `NotFound` component |

All API errors log to `console.error` in development and are captured by the global error boundary in production.

---

## Pagination Design

Shared `DataTable` component wraps any list with:
- `pageSize` selector: 10 / 25 / 50
- Previous / Next page controls
- "Showing X–Y of Z records" indicator

API receives `?page=1&pageSize=25` query params. Repository uses `LIMIT ? OFFSET ?` in SQL.

---

## Browser Push Notifications

```js
// lib/pushNotify.js
import webpush from 'web-push'

webpush.setVapidDetails(
  'mailto:admin@ali-hr.com',
  process.env.VAPID_PUBLIC_KEY,
  process.env.VAPID_PRIVATE_KEY
)

export async function pushToUser(subscriptions, payload) {
  return Promise.allSettled(
    subscriptions.map(sub => webpush.sendNotification(sub, JSON.stringify(payload)))
  )
}
```

Subscriptions are stored in memory (or a `push_subscriptions` auxiliary table) and linked to user sessions via the service worker registration flow in the browser.

---

## Security Considerations

- Passwords hashed with `bcrypt` (cost factor 12).
- JWT signed with `HS256`; secret stored in `JWT_SECRET` env variable; 8-hour expiry.
- All SQL queries use parameterised placeholders (never string concatenation).
- File uploads use a server-generated UUID filename to prevent path traversal.
- MIME type is validated on the server (not trusting client-provided `Content-Type`).
- RBAC checks happen in middleware before any business logic runs.
- Audit logs are insert-only; no UPDATE or DELETE is allowed on `audit_logs`.

---

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system — essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property Reflection

Before listing properties, the following redundancies were resolved:
- Properties 5 (balance deduction on approval) and 7 (balance restoration on cancellation) share the same balance consistency concern. They are kept separate because they test opposite directions of the same invariant (debit vs. credit round-trip).
- Properties 2 (approval chain creation) and 3 (sequential approval progression) are related but test different aspects: row count vs. state transition ordering.
- Properties 9 (Excel export) and 10 (PDF export) are separate because they exercise different code paths and libraries.
- Properties 15, 16, and 17 (RBAC enforcement) cover overlapping authorization concerns but at distinct layers: API-level 403, data isolation, and approval actor restriction. All three are kept.
- Properties 11, 12, and 13 (filter/search) could be collapsed, but 13 (filter-clear round-trip) is an idempotence property distinct from correctness of filtering.

---

### Property 1: Leave Type Deactivation Preserves Historical Records

*For any* leave type that is deactivated, new leave requests of that type shall be rejected, while all previously submitted leave requests of that type shall remain fully accessible in the database with their original data.

**Validates: Requirements 1.3**

---

### Property 2: Approval Chain Initialisation Count

*For any* leave request submitted for a leave type configured with N approval levels (where N ∈ {1, 2, 3}), exactly N rows shall be created in `leave_approvals` with `status = 'pending'`, one for each level.

**Validates: Requirements 2.3**

---

### Property 3: Sequential Approval Enforcement

*For any* leave request with multiple approval levels, level N+1 shall only become actionable (i.e., only the designated actor may take action on it) after level N has been set to `approved`. Attempting to approve or reject level N+1 before level N is approved shall be rejected with an error.

**Validates: Requirements 2.4**

---

### Property 4: Rejection Cascade

*For any* leave request rejected at approval level N, all approval rows at levels N+1 through the configured maximum shall be set to `cancelled`, and the leave request's `status` field shall be set to `rejected`.

**Validates: Requirements 2.5**

---

### Property 5: Working Days Calculation Excludes Holidays and Weekends

*For any* date range [start, end] and any set of holiday dates H, the calculated working-day count shall equal the number of days in [start, end] that are neither Saturday nor Sunday nor present in H.

**Validates: Requirements 3.2, 7.2**

---

### Property 6: Insufficient Balance Blocks Submission

*For any* leave request where the calculated duration exceeds the employee's current leave balance for the selected leave type, the submission shall be rejected, the leave request shall not be persisted, and the employee's balance shall remain unchanged.

**Validates: Requirements 3.3**

---

### Property 7: File Validation Rejects Invalid Uploads

*For any* uploaded file whose MIME type is not in {`application/pdf`, `image/jpeg`, `image/png`, `application/vnd.openxmlformats-officedocument.wordprocessingml.document`} or whose size exceeds 5 MB, the system shall reject the upload, return a descriptive error message, and persist no file to the filesystem or the `attachments` table.

**Validates: Requirements 3.4, 3.5, 16.2**

---

### Property 8: Leave Approval Triggers Balance Deduction and Ledger Entry

*For any* leave request that reaches fully approved status (all levels approved), the employee's leave balance for the corresponding leave type shall decrease by exactly the approved duration, and a debit entry shall be written to `leave_ledgers` with the correct amount and running balance.

**Validates: Requirements 2.6, 5.2**

---

### Property 9: Cancellation After Approval Restores Balance (Round-Trip)

*For any* leave request that is approved and subsequently cancelled, the employee's leave balance shall be credited back by exactly the previously deducted duration, returning the balance to the pre-approval value, and a credit entry shall be written to `leave_ledgers`.

**Validates: Requirements 5.3**

---

### Property 10: Quota Update Recalculates Balance by Delta

*For any* leave quota updated from entitlement amount A to entitlement amount B, the employee's leave balance for that quota's leave type and period shall change by exactly (B − A), and an audit log entry shall be written recording the old and new states.

**Validates: Requirements 6.3**

---

### Property 11: Expired Quota Excluded from Balance Calculations

*For any* leave quota whose `period_end` is before the current date, the quota shall be flagged as `expired` and shall not contribute to the available leave balance used to validate new leave request submissions.

**Validates: Requirements 6.4**

---

### Property 12: Filter Application Returns Correct Subset

*For any* combination of active filters (employee name, department, branch, leave type, date range, status) applied to a leave list, the returned records shall each satisfy all filter predicates simultaneously, and no record satisfying all predicates shall be omitted.

**Validates: Requirements 4.4, 11.2, 11.3**

---

### Property 13: Filter-Clear Restores Unfiltered Result Set (Round-Trip)

*For any* sequence of filter applications followed by a "clear all filters" action, the resulting record set shall be identical to the record set that would be returned with no filters applied.

**Validates: Requirements 11.4**

---

### Property 14: Export Matches Displayed Filter State

*For any* report screen state with an active filter configuration, the rows in the generated Excel or PDF export shall be identical in content and count to the rows displayed on screen at the moment of export.

**Validates: Requirements 12.2, 12.3, 12.4**

---

### Property 15: Audit Log Entry Completeness

*For any* create, update, or delete operation performed on the entities: Leave Types, Leave Requests, Leave Approvals, Leave Quotas, Leave Balances, Compensation Leaves, Holidays, Users, or Settings — exactly one audit log entry shall be written to `audit_logs` containing a non-null actor user ID, action type, affected table name, affected row ID, previous state (JSON), new state (JSON), and timestamp.

**Validates: Requirements 1.4, 4.2, 6.3, 7.3, 8.4, 13.1, 13.2**

---

### Property 16: RBAC Enforces 403 for Unauthorised Roles

*For any* API request where the JWT role claim does not grant permission for the requested resource and action, the API shall return HTTP 403 with an error message, and no data operation shall be executed.

**Validates: Requirements 14.1, 14.2**

---

### Property 17: Employee Data Isolation

*For any* API request made by a user with the `employee` role, the system shall return or modify only records belonging to that employee's own identity. Any attempt to read or modify another employee's leave records shall be rejected with HTTP 403.

**Validates: Requirements 14.3**

---

### Property 18: Approval Actor Restriction

*For any* approval action (approve or reject) on a leave request at level N, the system shall only permit the action if the requesting user is the designated actor (`approver_id`) for that leave approval row. Requests from any other user shall be rejected with HTTP 403.

**Validates: Requirements 14.4**

---

### Property 19: Theme Preference Persistence (Round-Trip)

*For any* theme selection (light or dark) made by a user, the chosen theme shall be written to `localStorage`, and on the next page load, the same theme shall be applied to the UI before the first render without a flash of the opposite theme.

**Validates: Requirements 15.2, 15.3**

---

### Property 20: Notification Recipients Match Approval Level

*For any* leave request submission, in-app notification records shall be created in the `notifications` table for every user designated as a level-1 approver for that leave type, and for no other users.

**Validates: Requirements 9.1**

---

### Property 21: Approval Action Notification Targets

*For any* approval level action (approve or reject) on a leave request, the system shall create a notification for the submitting employee, and — if the action is an approval and a next level exists — also for the next level's designated approver, and for no other unrelated users.

**Validates: Requirements 9.2**

---

### Property 22: Compensation Leave Credits Balance and Ledger

*For any* compensation leave record created for an employee, the employee's Compensation Leave balance shall increase by exactly the specified compensation amount, and a credit entry shall be written to `leave_ledgers` with the correct amount and running balance.

**Validates: Requirements 8.2, 8.3**

---

### Property 23: Attachment Deletion Cascades on Leave Request Delete

*For any* leave request that is deleted, all files associated with that request shall be removed from the `/public/uploads/attachments/` directory, and all corresponding rows in the `attachments` table shall be deleted, leaving no orphaned records or files.

**Validates: Requirements 16.4**

---

### Property 24: Approvals List Shows Only Actionable Requests

*For any* HR user or Manager, the approvals list shall display only leave requests for which that user is the designated actor at the currently pending approval level, sorted by `created_at` ascending, and shall exclude all requests at levels they are not currently responsible for.

**Validates: Requirements 4.1**
