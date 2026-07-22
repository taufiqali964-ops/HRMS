# Implementation Plan: Ali HR Capital Management System — Leave Module

## Overview

This plan breaks the Leave Module into incremental coding tasks — from project scaffolding and database setup through to authentication, core leave workflows, notifications, reporting, and security hardening. Each task builds directly on its predecessors so no code is left orphaned or unwired. The stack is Next.js 15 App Router, React 19, JavaScript (no TypeScript), Bootstrap 5, MySQL 8, and related libraries.

---

## Tasks

- [x] 1. Project Scaffolding and Database Foundation
  - [x] 1.1 Initialise Next.js 15 project with Bootstrap 5 and base folder structure
    - Bootstrap a new Next.js 15 app with App Router enabled
    - Install dependencies: `bootstrap`, `bootstrap-icons`, `axios`, `mysql2`, `jsonwebtoken`, `bcrypt`, `multer`, `exceljs`, `pdfkit`, `web-push`, `chart.js`, `react-chartjs-2`
    - Create all folders from the design: `app/`, `api/`, `components/`, `hooks/`, `lib/`, `middleware/`, `utils/`, `context/`, `services/`, `database/`, `public/uploads/attachments/`
    - Add `styles/globals.css` with Bootstrap import and CSS custom property tokens (primary `#0F4C81`, secondary `#20B2AA`, etc.)
    - _Requirements: 10.1, 10.2, 10.3, 15.1_

  - [x] 1.2 Create database schema and seed file
    - Write `database/schema.sql` with all 19 CREATE TABLE statements from the design (roles, permissions, users, departments, branches, designations, employees, leave_types, leave_requests, leave_approvals, leave_balances, leave_ledgers, leave_quotas, holidays, compensation_leaves, notifications, audit_logs, attachments, settings)
    - Write `database/seeds.sql` with the 4 roles and a default Super Admin user (bcrypt-hashed password)
    - _Requirements: 1.1, 2.1, 5.1, 6.1, 7.1, 8.1, 13.1_

  - [x] 1.3 Implement `lib/db.js` MySQL connection pool
    - Create a `mysql2/promise` pool exported as a singleton
    - Read credentials from environment variables (`DB_HOST`, `DB_USER`, `DB_PASSWORD`, `DB_NAME`, `DB_PORT`)
    - _Requirements: all data-layer requirements_

- [x] 2. Authentication and RBAC Middleware
  - [x] 2.1 Implement `lib/jwt.js` sign/verify helpers
    - Implement `signToken(payload)` using HS256 with 8-hour expiry from `JWT_SECRET` env variable
    - Implement `verifyToken(token)` that throws on invalid or expired tokens
    - _Requirements: 14.1_

  - [x] 2.2 Implement `middleware/auth.js` and `middleware/rbac.js`
    - Write `withAuth(handler)` that extracts the Bearer token, calls `verifyToken`, attaches `req.user`, and returns 401 on failure
    - Write `withPermission(resource, action)(handler)` that calls `withAuth` and then queries the `permissions` table for the role; returns 403 if denied
    - _Requirements: 14.1, 14.2_

  - [x] 2.3 Build `api/auth/route.js` login endpoint
    - POST handler: accept `{ email, password }`, verify against `users` table with bcrypt comparison, return signed JWT on success, 401 on failure
    - _Requirements: 14.1_

  - [x] 2.4 Create `context/AuthContext.js` and `hooks/useAuth.js`
    - AuthContext stores JWT payload and exposes `login`, `logout`, `user` values
    - `useAuth` hook wraps `useContext(AuthContext)`
    - On logout, clear JWT from localStorage and redirect to `/login`
    - _Requirements: 14.1, 14.2_

  - [ ]* 2.5 Write property test for RBAC enforcement (Property 16)
    - **Property 16: RBAC Enforces 403 for Unauthorised Roles**
    - For every resource/action combination, verify that a role without permission receives HTTP 403 and no data operation is executed
    - **Validates: Requirements 14.1, 14.2**

  - [ ]* 2.6 Write property test for employee data isolation (Property 17)
    - **Property 17: Employee Data Isolation**
    - Verify that an employee-role JWT can only read/modify their own leave records; any cross-employee access returns HTTP 403
    - **Validates: Requirements 14.3**

  - [ ]* 2.7 Write property test for approval actor restriction (Property 18)
    - **Property 18: Approval Actor Restriction**
    - Verify that only the designated `approver_id` for a pending approval row can action it; all others receive HTTP 403
    - **Validates: Requirements 14.4**

- [~] 3. Checkpoint — Auth and RBAC
  - Ensure login works end-to-end, JWT is verified on protected routes, and all RBAC property tests pass. Ask the user if questions arise.

- [x] 4. Core Utilities
  - [x] 4.1 Implement `utils/workingDays.js`
    - Implement `calculateWorkingDays(startDate, endDate, holidayDates)` as designed: iterate day-by-day, skip Saturday/Sunday and dates present in the `holidayDates` Set
    - _Requirements: 3.2, 7.2_

  - [ ]* 4.2 Write property test for working days calculation (Property 5)
    - **Property 5: Working Days Calculation Excludes Holidays and Weekends**
    - Generate random date ranges and holiday sets; assert the result equals the manual count of non-weekend, non-holiday days in the range
    - **Validates: Requirements 3.2, 7.2**

  - [x] 4.3 Implement `utils/fileValidator.js`
    - Implement `validateFile(file)` returning an array of error strings; enforce allowed MIME types and 5 MB max size as designed
    - _Requirements: 3.4, 3.5, 16.2_

  - [ ]* 4.4 Write property test for file validation (Property 7)
    - **Property 7: File Validation Rejects Invalid Uploads**
    - Generate files with random MIME types and sizes; verify only allowed-type and under-5MB files pass, and all others return error messages
    - **Validates: Requirements 3.4, 3.5, 16.2**

  - [x] 4.5 Implement `utils/auditLogger.js`
    - Implement `writeAuditLog(conn, { actorId, action, entity, entityId, oldState, newState })` executing the parameterised INSERT as designed
    - _Requirements: 1.4, 4.2, 6.3, 7.3, 8.4, 13.1, 13.2_

  - [ ]* 4.6 Write property test for audit log completeness (Property 15)
    - **Property 15: Audit Log Entry Completeness**
    - For each audited entity, perform a create/update/delete and assert exactly one audit log row is written with all required fields non-null
    - **Validates: Requirements 1.4, 4.2, 6.3, 7.3, 8.4, 13.1, 13.2**

- [x] 5. Leave Type Management
  - [x] 5.1 Implement `services/leaveTypeService.js` and `api/leave-types/route.js`
    - Service: `createLeaveType`, `updateLeaveType`, `deactivateLeaveType`, `listLeaveTypes` — all writing audit logs via `auditLogger`
    - API: GET (list, supports `?page&pageSize&filter`), POST (create), PUT/[id] (update), PATCH/[id]/deactivate — protected by `withPermission('leave_types', action)`
    - _Requirements: 1.1, 1.2, 1.3, 1.4_

  - [ ]* 5.2 Write property test for leave type deactivation (Property 1)
    - **Property 1: Leave Type Deactivation Preserves Historical Records**
    - Deactivate a leave type that has existing requests; assert new submissions are rejected (422) and all historical requests remain intact in the DB
    - **Validates: Requirements 1.3**

  - [x] 5.3 Build `app/settings/leave-types/page.js` UI
    - Table of leave types with create/edit modal (React Hook Form) and deactivate toggle
    - Inline validation errors for missing name, unit, or accrual rule
    - _Requirements: 1.1, 1.2, 1.3_

- [x] 6. Leave Request Submission (Employee)
  - [x] 6.1 Implement `services/leaveRequestService.js` — create request
    - `createLeaveRequest(conn, { employeeId, leaveTypeId, startDate, endDate, reason })`:
      1. Load holiday dates from DB
      2. Call `calculateWorkingDays` to get duration
      3. Call `balanceService.getBalance` — reject (422) if duration > balance
      4. INSERT into `leave_requests` with status `pending`
      5. Call `approvalService.initApprovalChain`
      6. Call `notificationService.sendNotification` to level-1 approvers
      7. Write audit log
    - _Requirements: 3.1, 3.2, 3.3, 3.6, 3.7_

  - [ ]* 6.2 Write property test for insufficient balance blocking submission (Property 6)
    - **Property 6: Insufficient Balance Blocks Submission**
    - Submit a leave request with duration greater than balance; assert HTTP 422, no row in `leave_requests`, and balance unchanged
    - **Validates: Requirements 3.3**

  - [x] 6.3 Implement file attachment upload in `api/attachments/route.js`
    - Use multer for multipart parsing; call `validateFile`; store file with UUID filename under `/public/uploads/attachments/`; INSERT into `attachments` table
    - Return 422 with error array if validation fails; no file is saved on validation failure
    - _Requirements: 3.4, 3.5, 16.1, 16.2_

  - [x] 6.4 Build `components/leave/LeaveRequestForm.js` and `app/leave/request/page.js`
    - Form fields: Leave Type selector, start/end date pickers, reason textarea, file upload input
    - On date change: call `/api/leave-types` to get holidays, compute and display working days count
    - Show balance-insufficient warning banner if duration > balance (from `hooks/useLeaveBalance.js`)
    - On submit: POST to `/api/leave-requests`; show success toast or inline errors from React Hook Form
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

  - [x] 6.5 Implement `hooks/useLeaveBalance.js`
    - Fetches current balance for a given `(employeeId, leaveTypeId)` from `/api/leave-balances`
    - _Requirements: 3.3, 5.1_

- [x] 7. Approval Workflow Service
  - [x] 7.1 Implement `services/approvalService.js`
    - `initApprovalChain(conn, requestId, leaveTypeId)`: read `approval_levels` from `leave_types`; INSERT N rows into `leave_approvals` with `status='pending'`, level 1..N
    - `approveLevel(conn, requestId, approverId, level)`: verify requesting user is designated actor; verify previous level is approved; UPDATE current row to `approved`; if last level → call `balanceService.deductBalance` + set leave request `approved` + notify employee; else notify next-level approver
    - `rejectLevel(conn, requestId, approverId, level, reason)`: UPDATE current row to `rejected`; UPDATE all subsequent rows to `cancelled`; set leave request `rejected`; notify employee
    - Write audit log in every state transition
    - _Requirements: 2.2, 2.3, 2.4, 2.5, 2.6, 4.2, 4.3_

  - [ ]* 7.2 Write property test for approval chain initialisation (Property 2)
    - **Property 2: Approval Chain Initialisation Count**
    - For leave types configured with N ∈ {1,2,3} approval levels, submit a request and assert exactly N `leave_approvals` rows exist with status `pending`
    - **Validates: Requirements 2.3**

  - [ ]* 7.3 Write property test for sequential approval enforcement (Property 3)
    - **Property 3: Sequential Approval Enforcement**
    - Attempt to approve level N+1 before level N is approved; assert the attempt is rejected with an error
    - **Validates: Requirements 2.4**

  - [ ]* 7.4 Write property test for rejection cascade (Property 4)
    - **Property 4: Rejection Cascade**
    - Reject at level N; assert all rows at levels N+1..max are `cancelled` and leave request status is `rejected`
    - **Validates: Requirements 2.5**

  - [x] 7.5 Build `api/leave-approvals/route.js`
    - POST: call `approvalService.approveLevel` or `rejectLevel` based on `action` field; require `rejection_reason` when action is `reject`
    - GET: list approvals for the authenticated approver using `withPermission('leave_approvals', 'read')`
    - _Requirements: 4.1, 4.2, 4.3_

  - [x] 7.6 Build `components/leave/ApprovalCard.js` and `app/leave/approvals/page.js`
    - List only actionable requests (from `GET /api/leave-approvals`) with approve/reject buttons
    - Rejection requires a reason input (validated required)
    - Supports filter controls: employee name, department, Leave Type, date range, status
    - Pagination: 10 / 25 / 50 with `usePagination` hook
    - _Requirements: 4.1, 4.3, 4.4, 4.5_

  - [ ]* 7.7 Write property test for approvals list showing only actionable requests (Property 24)
    - **Property 24: Approvals List Shows Only Actionable Requests**
    - Assert the GET /api/leave-approvals response contains only requests where the authenticated user is `approver_id` at the currently pending level; no other requests appear
    - **Validates: Requirements 4.1**

- [~] 8. Checkpoint — Leave Submission and Approvals
  - Ensure leave request submission, working-days calculation, balance blocking, approval state machine, and all related property tests pass. Ask the user if questions arise.

- [x] 9. Leave Balance and Ledger
  - [x] 9.1 Implement `services/balanceService.js`
    - `deductBalance(conn, employeeId, leaveTypeId, duration, requestId)`: UPDATE `leave_balances`, INSERT debit row into `leave_ledgers`
    - `creditBalance(conn, employeeId, leaveTypeId, duration, description)`: UPDATE `leave_balances`, INSERT credit row into `leave_ledgers`
    - `getBalance(conn, employeeId, leaveTypeId)`: SELECT balance from `leave_balances` for the active (non-expired) quota period
    - _Requirements: 5.1, 5.2, 5.3_

  - [ ]* 9.2 Write property test for balance deduction on approval (Property 8)
    - **Property 8: Leave Approval Triggers Balance Deduction and Ledger Entry**
    - Fully approve a leave request; assert balance decreased by exact duration and a debit ledger entry exists with correct running balance
    - **Validates: Requirements 2.6, 5.2**

  - [ ]* 9.3 Write property test for cancellation balance restoration (Property 9)
    - **Property 9: Cancellation After Approval Restores Balance (Round-Trip)**
    - Approve then cancel a request; assert balance returns to pre-approval value and a credit ledger entry exists
    - **Validates: Requirements 5.3**

  - [x] 9.4 Build `api/leave-balances/route.js` and `api/leave-ledger/route.js`
    - GET `/api/leave-balances`: return balances for authenticated employee (or a specific employee for HR/Manager)
    - GET `/api/leave-ledger`: return ledger entries in reverse-chronological order; support `?page&pageSize&employeeId&leaveTypeId`
    - _Requirements: 5.1, 5.4, 5.5_

  - [x] 9.5 Build `components/leave/BalanceCard.js`, `components/leave/LedgerTable.js`, `app/leave/balances/page.js`, and `app/leave/ledger/page.js`
    - Balance page: grid of BalanceCard components per leave type
    - Ledger page: LedgerTable with date, type, transaction type, amount, running balance columns; pagination 10/25/50
    - _Requirements: 5.4, 5.5_

- [ ] 10. Leave Quota Management
  - [~] 10.1 Implement quota service and `api/leave-quotas/route.js`
    - `createQuota(conn, data)`: INSERT into `leave_quotas`, set `leave_balances` to entitlement amount, write audit log
    - `updateQuota(conn, id, newEntitlement)`: compute delta (newEntitlement − old), apply `creditBalance` or `deductBalance` for delta, UPDATE quota row, write audit log
    - `expireQuotas(conn)`: UPDATE `leave_quotas` SET status='expired' WHERE period_end < CURDATE()
    - API routes: GET, POST, PUT/[id] — protected by `withPermission('leave_quotas', action)`
    - _Requirements: 6.1, 6.2, 6.3, 6.4_

  - [ ]* 10.2 Write property test for quota update delta (Property 10)
    - **Property 10: Quota Update Recalculates Balance by Delta**
    - Change quota entitlement from A to B; assert balance changes by exactly (B − A) and audit log entry is written
    - **Validates: Requirements 6.3**

  - [ ]* 10.3 Write property test for expired quota exclusion (Property 11)
    - **Property 11: Expired Quota Excluded from Balance Calculations**
    - Create a quota with past period_end, run expiry job, submit a leave request; assert the expired quota balance is not counted
    - **Validates: Requirements 6.4**

  - [~] 10.4 Build `app/leave/balances/page.js` quota section and quota management UI for HR
    - HR-visible section: table of quotas with create/edit actions
    - Quota form fields: employee, leave type, entitlement, period start/end
    - _Requirements: 6.1, 6.2_

- [ ] 11. Holiday Calendar
  - [~] 11.1 Implement `api/holidays/route.js`
    - GET: list all holidays; POST: create (HR/SuperAdmin); PUT/[id]: update; DELETE/[id]: delete — each mutating operation writes audit log
    - _Requirements: 7.1, 7.3_

  - [~] 11.2 Build `components/calendar/HolidayCalendar.js` and `app/holidays/page.js`
    - Monthly grid calendar; navigation controls for previous/next months
    - Holiday markers with name and type; add/edit/delete form accessible to HR
    - _Requirements: 7.1, 7.4_

- [ ] 12. Compensation Leave
  - [~] 12.1 Implement compensation leave service and `api/compensation-leaves/route.js`
    - `createCompensationLeave(conn, { employeeId, workedDate, compensation, reason, actorId })`:
      1. INSERT into `compensation_leaves`
      2. Call `balanceService.creditBalance` for the Compensation Leave type
      3. Write audit log
    - API: POST (HR only), GET with pagination
    - _Requirements: 8.1, 8.2, 8.3, 8.4_

  - [ ]* 12.2 Write property test for compensation leave balance credit (Property 22)
    - **Property 22: Compensation Leave Credits Balance and Ledger**
    - Create a compensation leave record; assert employee's Compensation Leave balance increases by exact amount and a credit ledger entry exists with correct running balance
    - **Validates: Requirements 8.2, 8.3**

- [ ] 13. Notifications
  - [~] 13.1 Implement `services/notificationService.js`
    - `sendNotification(conn, { userIds, title, message })`: INSERT into `notifications`; attempt browser push via `lib/pushNotify.js` using stored subscriptions
    - `getUnreadNotifications(conn, userId)`: SELECT unread notifications for user, sorted reverse-chronologically
    - `markAsRead(conn, notificationId, userId)`: UPDATE `is_read=true`, verify ownership
    - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5_

  - [~] 13.2 Implement `lib/pushNotify.js` Web Push wrapper
    - Configure `web-push` with VAPID keys from env variables
    - `pushToUser(subscriptions, payload)`: `Promise.allSettled` over all subscriptions as designed
    - _Requirements: 9.3_

  - [~] 13.3 Build `api/notifications/route.js`
    - GET: `getUnreadNotifications` for authenticated user
    - PATCH/[id]/read: `markAsRead`
    - _Requirements: 9.4, 9.5_

  - [~] 13.4 Build `components/layout/NotificationBell.js` and notification panel
    - Bell icon in Navbar with unread count badge
    - Dropdown panel showing unread notifications with read/unread indicator
    - Mark-as-read on click updates UI without full page reload
    - Register service worker for browser push subscription
    - _Requirements: 9.4, 9.5, 9.6_

  - [ ]* 13.5 Write property test for notification recipients on submission (Property 20)
    - **Property 20: Notification Recipients Match Approval Level**
    - Submit a leave request; assert notification rows exist for every level-1 approver and for no unrelated users
    - **Validates: Requirements 9.1**

  - [ ]* 13.6 Write property test for approval action notification targets (Property 21)
    - **Property 21: Approval Action Notification Targets**
    - Approve at level 1 (with level 2 remaining); assert notifications created for employee and level-2 approver only
    - Reject at any level; assert notification created for employee only
    - **Validates: Requirements 9.2**

- [~] 14. Checkpoint — Balance, Quotas, Notifications
  - Ensure balance deduction/restoration, ledger entries, quota delta updates, compensation leave credits, and notification delivery all pass tests. Ask the user if questions arise.

- [ ] 15. Dashboard
  - [~] 15.1 Build Employee Dashboard page (`app/dashboard/page.js` — employee view)
    - Leave balance summary cards per leave type (from `GET /api/leave-balances`)
    - Upcoming approved leave list
    - Recent leave request status list
    - _Requirements: 10.1_

  - [~] 15.2 Build Manager/HR Dashboard view
    - Pending approvals count and quick-link
    - Team leave calendar (mini calendar with team overlaps)
    - Key leave statistics panel
    - _Requirements: 10.2_

  - [~] 15.3 Build Super Admin Dashboard view
    - System-wide stats: total pending requests, leave type utilisation, user activity metrics
    - _Requirements: 10.3_

  - [~] 15.4 Integrate Chart.js utilisation chart (`components/charts/UtilisationChart.js`)
    - Client component using `react-chartjs-2` Bar chart
    - Fetch data from `GET /api/reports/utilisation?year=YYYY`
    - _Requirements: 10.4_

  - [~] 15.5 Build `api/reports/utilisation` route
    - Return monthly leave utilisation data for the current calendar year, broken down by leave type
    - _Requirements: 10.4, 10.5_

- [ ] 16. Advanced Search, Filters, and Pagination
  - [~] 16.1 Build `components/common/FilterBar.js`, `DataTable.js`, and `Pagination.js`
    - FilterBar: text input (employee name), selects for department, branch, leave type, status, date range pickers
    - DataTable: generic table wrapper with sortable columns
    - Pagination: page-size selector (10/25/50), previous/next buttons, "Showing X–Y of Z" indicator
    - _Requirements: 11.1, 11.2, 11.3, 11.4, 4.4, 4.5_

  - [~] 16.2 Implement `hooks/usePagination.js`
    - Manage `page`, `pageSize`, `total` state; exposes handlers for page change and page size change
    - _Requirements: 4.5, 5.5, 13.4_

  - [ ]* 16.3 Write property test for filter application (Property 12)
    - **Property 12: Filter Application Returns Correct Subset**
    - Apply combinations of filters; assert every returned record satisfies all predicates and no qualifying record is omitted
    - **Validates: Requirements 4.4, 11.2, 11.3**

  - [ ]* 16.4 Write property test for filter-clear round-trip (Property 13)
    - **Property 13: Filter-Clear Restores Unfiltered Result Set (Round-Trip)**
    - Apply filters then clear; assert result set equals the unfiltered set
    - **Validates: Requirements 11.4**

  - [~] 16.5 Wire FilterBar and Pagination into approvals, balances, ledger, and quota list pages
    - Each page fetches data with combined `?page&pageSize&...filters` query params
    - Filter changes re-query without full page reload
    - _Requirements: 11.1, 11.2, 11.4_

- [ ] 17. Reports and Export
  - [~] 17.1 Implement `services/reportService.js` — Excel export
    - `generateExcel(reportData, columns)` using `exceljs` as designed: creates workbook, adds worksheet, maps columns, adds rows, returns buffer
    - _Requirements: 12.1, 12.2_

  - [~] 17.2 Implement PDF export in `services/reportService.js`
    - `generatePDF(reportData, columns)` using `pdfkit` as designed: create PDFDocument, draw table header and data rows, resolve with buffer
    - _Requirements: 12.1, 12.3_

  - [~] 17.3 Build `api/reports/route.js` report endpoints
    - GET `/api/reports?type=leave-summary|leave-balance|leave-ledger|approval-history&format=xlsx|pdf&...filters`
    - Apply active filters from query params; delegate to `reportService.generateExcel` or `generatePDF`; set appropriate Content-Type and Content-Disposition headers
    - _Requirements: 12.1, 12.2, 12.3, 12.4_

  - [ ]* 17.4 Write property test for export matching display filter state (Property 14)
    - **Property 14: Export Matches Displayed Filter State**
    - Apply filters on reports page, export to Excel; assert every row in the workbook matches the displayed filter predicates and counts are equal
    - **Validates: Requirements 12.2, 12.3, 12.4**

  - [~] 17.5 Build `components/common/ExportButtons.js` and `app/reports/page.js`
    - Report type selector, date range and filter inputs
    - Export to Excel / Export to PDF buttons triggering browser download
    - Accessible to HR and Super Admin roles only
    - _Requirements: 12.1, 12.2, 12.3, 12.4_

- [ ] 18. Audit Log Screen
  - [~] 18.1 Build `api/audit-logs/route.js`
    - GET: return paginated audit entries; support filters for actor, action, entity, date range
    - Super Admin only via `withPermission('audit_logs', 'read')`
    - _Requirements: 13.1, 13.2, 13.3, 13.4_

  - [~] 18.2 Build `app/settings/roles/page.js` and Audit Logs screen
    - Audit log table with actor, action, entity, entity ID, timestamp columns; advanced filter bar
    - Pagination 10/25/50
    - _Requirements: 13.3, 13.4_

- [ ] 19. Employee Management and User Administration
  - [~] 19.1 Build `api/employees`, `api/users`, department, branch, designation routes
    - CRUD for employees, users, departments, branches, designations — protected by appropriate role permissions
    - Each mutating operation writes audit log
    - _Requirements: 14.1, 14.2_

  - [~] 19.2 Build `app/employees/page.js` and `app/users/page.js`
    - Employee list with department/designation/branch/manager assignment
    - User management (Super Admin): activate/deactivate accounts, role assignment
    - _Requirements: 14.1, 14.5_

  - [~] 19.3 Build `app/settings/approval-chains/page.js`
    - UI for Super Admin to configure approval levels per leave type and assign role/user actors per level
    - Persists configuration to `settings` table
    - _Requirements: 2.1, 2.2, 14.5_

- [ ] 20. Theme and Layout
  - [~] 20.1 Implement `context/ThemeContext.js` and `components/layout/ThemeToggle.js`
    - ThemeContext reads from `localStorage['ali-hr-theme']` on mount; applies `data-bs-theme` attribute to `<html>` before first render to avoid flash
    - ThemeToggle writes selected theme to localStorage and updates context state
    - _Requirements: 15.1, 15.2, 15.3_

  - [ ]* 20.2 Write property test for theme persistence round-trip (Property 19)
    - **Property 19: Theme Preference Persistence (Round-Trip)**
    - Toggle theme, reload page; assert the same theme is applied without a flash of the opposite theme
    - **Validates: Requirements 15.2, 15.3**

  - [~] 20.3 Build `components/layout/Sidebar.js` and `components/layout/Navbar.js`
    - Role-aware sidebar navigation: render links based on JWT role claim as described in the design
    - Navbar: NotificationBell, ThemeToggle, user avatar/logout
    - _Requirements: 10.1, 10.2, 10.3, 14.2_

- [ ] 21. Attachment Cascade Delete
  - [~] 21.1 Implement cascade delete for attachments in the leave request delete handler
    - On DELETE `/api/leave-requests/[id]`: fetch attachment rows, delete each file from `/public/uploads/attachments/` using `fs.unlink`, then DELETE rows from `attachments` table, then DELETE the request row — all within a transaction
    - _Requirements: 16.4_

  - [ ]* 21.2 Write property test for attachment cascade delete (Property 23)
    - **Property 23: Attachment Deletion Cascades on Leave Request Delete**
    - Create a request with attachments, delete the request; assert all files are removed from disk and no orphaned rows remain in `attachments`
    - **Validates: Requirements 16.4**

- [ ] 22. Login Page and App Wiring
  - [~] 22.1 Build `app/(auth)/login/page.js`
    - Login form with email and password fields; POST to `/api/auth`; store JWT in localStorage; redirect to `/dashboard`
    - Next.js middleware redirects unauthenticated users to `/login`
    - _Requirements: 14.1_

  - [~] 22.2 Wire App Router root layout with AuthContext, ThemeContext, and Sidebar/Navbar
    - Root `layout.js` wraps children with both context providers
    - Conditionally render Sidebar/Navbar only for authenticated sessions
    - _Requirements: 10.1, 10.2, 10.3, 14.1, 15.1_

- [~] 23. Final Checkpoint — Full Integration
  - Ensure all pages are accessible via correct roles, all API routes are protected, exports work, notifications fire, and the complete test suite passes. Ask the user if questions arise.

---

## Notes

- Tasks marked with `*` are optional and can be skipped for a faster MVP delivery
- Each task references specific requirements for full traceability
- Checkpoints at tasks 3, 8, 14, and 23 ensure incremental validation throughout development
- Property tests validate universal correctness properties (listed in design document)
- Unit tests validate specific examples and edge cases
- All SQL queries must use parameterised placeholders — never string concatenation
- Files uploaded must use server-generated UUID filenames to prevent path traversal
- JWT secret and VAPID keys must be stored as environment variables, never hardcoded

---

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1", "1.2"] },
    { "id": 1, "tasks": ["1.3", "4.1", "4.3", "4.5"] },
    { "id": 2, "tasks": ["2.1", "4.2", "4.4", "4.6"] },
    { "id": 3, "tasks": ["2.2", "2.3", "2.4"] },
    { "id": 4, "tasks": ["2.5", "2.6", "2.7", "5.1"] },
    { "id": 5, "tasks": ["5.2", "5.3", "6.1", "6.3", "6.5"] },
    { "id": 6, "tasks": ["6.2", "6.4", "7.1", "9.1", "10.1", "11.1", "11.2"] },
    { "id": 7, "tasks": ["7.2", "7.3", "7.4", "7.5", "9.2", "9.3", "9.4", "10.2", "10.3", "12.1"] },
    { "id": 8, "tasks": ["7.6", "7.7", "9.5", "10.4", "12.2", "13.1", "13.2"] },
    { "id": 9, "tasks": ["13.3", "13.4", "15.1", "15.2", "15.3", "15.4", "15.5", "16.1", "16.2"] },
    { "id": 10, "tasks": ["13.5", "13.6", "16.3", "16.4", "16.5", "17.1", "17.2", "18.1", "19.1"] },
    { "id": 11, "tasks": ["17.3", "17.5", "18.2", "19.2", "19.3", "20.1", "21.1"] },
    { "id": 12, "tasks": ["17.4", "20.2", "20.3", "21.2"] },
    { "id": 13, "tasks": ["22.1"] },
    { "id": 14, "tasks": ["22.2"] }
  ]
}
```
