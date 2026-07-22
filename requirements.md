# Requirements Document

## Introduction

The Ali HR Capital Management System — Leave Module is a full-featured, end-to-end leave management system built on Next.js 15, React 19, and a MySQL 8 backend exposed through Node.js API Routes. The module covers employee self-service leave requests, configurable multi-level approval workflows (1–3 levels per leave type), leave balance tracking, quota management, holiday calendars, compensation leave, reporting, and in-app / browser push notifications. Access is controlled through a JWT-based RBAC system with four roles: Super Admin, HR, Manager, and Employee.

---

## Glossary

- **System**: The Ali HR Capital Management System (Leave Module) as a whole.
- **Leave Request**: A formal employee submission asking for time off against a specific leave type.
- **Leave Type**: One of the 14 configurable categories of leave (e.g., Annual, Sick, Maternity, Unpaid, etc.).
- **Leave Balance**: The remaining entitlement units available to an employee for a given leave type in a given period.
- **Leave Ledger**: The chronological transaction log that records every credit and debit to an employee's leave balance.
- **Leave Quota**: The total entitlement assigned to an employee for a leave type within a defined period.
- **Approval Level**: A single stage in the multi-level approval chain; each stage is assigned to a role or specific approver.
- **Approval Chain**: The ordered sequence of Approval Levels that a Leave Request must pass through before it is considered approved.
- **Compensation Leave**: Additional leave credit granted to an employee in exchange for working on a holiday or rest day.
- **Holiday Calendar**: The repository of public and company-defined non-working days.
- **Notification**: An in-app message or browser push alert delivered to a user about a leave-related event.
- **Audit Log**: An immutable record of every create, update, or delete action performed in the System.
- **Attachment**: A file uploaded by an employee to support a Leave Request, stored under `/public/uploads/attachments/`.
- **RBAC**: Role-Based Access Control; the permission model governing what each role may read, write, or administer.
- **Super Admin**: The highest-privilege role; may configure all system settings including leave types and approval levels.
- **HR**: The Human Resources role; manages employee records, leave quotas, holiday calendars, and reports.
- **Manager**: A supervisory role that acts as an Approval Level actor for subordinates' Leave Requests.
- **Employee**: The end-user role that submits Leave Requests and views personal leave information.
- **Dashboard**: The role-specific landing page displaying summaries, pending actions, and recent notifications.
- **Settings**: The administration panel where Super Admins configure system-wide parameters.
- **Export**: Generation of a downloadable Excel (.xlsx) or PDF report from tabular data.

---

## Requirements

### Requirement 1 — Leave Type Configuration

**User Story:** As a Super Admin, I want to define and manage leave types, so that the organisation's leave policy is accurately reflected in the system.

#### Acceptance Criteria

1. THE System SHALL support the creation, editing, and deactivation of up to 14 distinct Leave Types.
2. WHEN a Super Admin creates a Leave Type, THE System SHALL require a unique name, a unit (days or hours), and an accrual/entitlement rule.
3. WHEN a Super Admin deactivates a Leave Type, THE System SHALL prevent new Leave Requests of that type while retaining all historical records.
4. THE System SHALL persist Leave Type configuration changes to the `leave_types` table and write an entry to the `audit_logs` table.

---

### Requirement 2 — Configurable Multi-Level Approval Workflow

**User Story:** As a Super Admin, I want to configure the number of approval levels (1–3) per leave type, so that each leave category follows the correct authorisation chain.

#### Acceptance Criteria

1. WHEN a Super Admin configures a Leave Type, THE System SHALL allow the Super Admin to set the number of required Approval Levels to an integer between 1 and 3, inclusive.
2. THE System SHALL store the Approval Chain configuration in the `settings` table and link it to the corresponding Leave Type in `leave_types`.
3. WHEN a Leave Request is submitted, THE System SHALL create one row per Approval Level in the `leave_approvals` table with status `pending`.
4. WHILE a Leave Request has at least one `pending` Approval Level, THE System SHALL enforce sequential progression: Level N+1 becomes actionable only after Level N is approved.
5. IF an Approval Level actor rejects a Leave Request, THEN THE System SHALL mark all subsequent Approval Levels as `cancelled` and set the Leave Request status to `rejected`.
6. WHEN all Approval Levels for a Leave Request reach `approved` status, THE System SHALL set the Leave Request status to `approved` and trigger balance deduction.

---

### Requirement 3 — Employee Leave Request Submission

**User Story:** As an Employee, I want to submit a leave request through a self-service form, so that I can formally request time off without contacting HR directly.

#### Acceptance Criteria

1. WHEN an Employee accesses the leave request form, THE System SHALL present a form with fields for Leave Type, start date, end date, reason, and optional file attachment.
2. WHEN an Employee selects a date range, THE System SHALL calculate and display the number of working days (excluding weekends and holidays from the Holiday Calendar) in that range.
3. IF the calculated leave duration exceeds the Employee's current Leave Balance for the selected Leave Type, THEN THE System SHALL display a balance-insufficient warning and prevent submission.
4. WHEN an Employee attaches a file, THE System SHALL validate that the file is a PDF, JPG, PNG, or DOCX and does not exceed 5 MB, then store the file under `/public/uploads/attachments/` and record the path in the `attachments` table.
5. IF the file fails validation, THEN THE System SHALL display an error message specifying the violation and reject the upload without saving any file.
6. WHEN the Employee submits a valid Leave Request, THE System SHALL persist the record to the `leave_requests` table with status `pending` and initiate the Approval Chain.
7. WHEN a Leave Request is created, THE System SHALL send a Notification to each Level-1 Approval Level actor.

---

### Requirement 4 — Leave Request Management (HR and Manager)

**User Story:** As an HR user or Manager, I want to review, approve, or reject pending leave requests assigned to my approval level, so that I can fulfil my role in the Approval Chain.

#### Acceptance Criteria

1. WHEN an HR user or Manager accesses the approvals screen, THE System SHALL display only the Leave Requests for which that user is the current actionable Approval Level actor, sorted by submission date ascending.
2. WHEN an approver approves a Leave Request at their level, THE System SHALL update the corresponding `leave_approvals` row to `approved`, set the `approved_by` and `approved_at` fields, and write an Audit Log entry.
3. WHEN an approver rejects a Leave Request, THE System SHALL require the approver to enter a rejection reason, update the `leave_approvals` row to `rejected`, and propagate the cancellation per Requirement 2, Criterion 5.
4. THE System SHALL provide advanced search and filter controls on the approvals list, allowing filtering by employee name, department, Leave Type, date range, and status.
5. THE System SHALL support pagination on the approvals list with a configurable page size of 10, 25, or 50 records per page.

---

### Requirement 5 — Leave Balance and Ledger

**User Story:** As an Employee, I want to view my leave balances and transaction history, so that I can track my entitlements and plan my time off.

#### Acceptance Criteria

1. THE System SHALL maintain a real-time Leave Balance for each Employee–Leave Type pair in the `leave_balances` table.
2. WHEN a Leave Request reaches `approved` status, THE System SHALL deduct the approved duration from the Employee's Leave Balance and record a debit entry in the `leave_ledgers` table.
3. WHEN a Leave Request is cancelled after approval, THE System SHALL credit the reversed duration back to the Employee's Leave Balance and record a credit entry in the `leave_ledgers` table.
4. WHEN an Employee views the leave ledger screen, THE System SHALL display all ledger entries for that Employee in reverse-chronological order with columns for date, Leave Type, transaction type (credit/debit), amount, and running balance.
5. THE System SHALL provide pagination on the ledger view with a configurable page size of 10, 25, or 50 records per page.

---

### Requirement 6 — Leave Quota Management

**User Story:** As an HR user, I want to define and adjust leave quotas per employee and leave type, so that entitlements reflect individual contracts and company policies.

#### Acceptance Criteria

1. WHEN an HR user creates a Leave Quota, THE System SHALL require the employee identifier, Leave Type, entitlement amount, and validity period (start date and end date).
2. THE System SHALL store Leave Quota records in the `leave_quotas` table and initialise the corresponding Leave Balance in `leave_balances` to the entitlement amount.
3. WHEN an HR user updates a Leave Quota, THE System SHALL recalculate the Employee's Leave Balance by applying the difference between the old and new entitlement, and write an Audit Log entry.
4. IF a Leave Quota's validity period has expired, THEN THE System SHALL flag the quota as `expired` and exclude it from balance calculations for new Leave Requests.

---

### Requirement 7 — Holiday Calendar

**User Story:** As an HR user, I want to maintain a holiday calendar, so that the system accurately excludes non-working days from leave calculations.

#### Acceptance Criteria

1. THE System SHALL allow HR users to add, edit, and delete holiday entries in the `holidays` table, each with a date, name, and type (public or company).
2. WHEN calculating working days for a Leave Request, THE System SHALL exclude all dates present in the `holidays` table that fall within the requested date range.
3. WHEN a holiday is added or modified, THE System SHALL write an Audit Log entry.
4. THE System SHALL display the holiday calendar in a monthly grid view with navigation controls for previous and next months.

---

### Requirement 8 — Compensation Leave

**User Story:** As an HR user, I want to grant compensation leave credits to employees who work on holidays or rest days, so that the organisation meets its legal and policy obligations.

#### Acceptance Criteria

1. WHEN an HR user creates a Compensation Leave record, THE System SHALL require the employee identifier, the worked date, the compensation amount, and an optional reason.
2. THE System SHALL persist Compensation Leave records to the `compensation_leaves` table and credit the corresponding amount to the Employee's Compensation Leave balance in `leave_balances`.
3. THE System SHALL credit the Compensation Leave amount to the `leave_ledgers` table as a credit entry.
4. WHEN a Compensation Leave record is created, THE System SHALL write an Audit Log entry.

---

### Requirement 9 — Notifications

**User Story:** As any user, I want to receive timely notifications about leave-related events, so that I can act on pending requests or stay informed without checking the system manually.

#### Acceptance Criteria

1. WHEN a Leave Request is submitted, THE System SHALL create in-app Notification records in the `notifications` table for all Approval Level actors at Level 1.
2. WHEN an Approval Level is actioned (approved or rejected), THE System SHALL create in-app Notification records for the submitting Employee and, where applicable, the next Approval Level actor.
3. WHEN a Notification record is created, THE System SHALL attempt to deliver a browser push notification to all active sessions of the target user.
4. WHEN a user views the notifications panel, THE System SHALL display all unread Notification records for that user in reverse-chronological order with a read/unread indicator.
5. WHEN a user marks a Notification as read, THE System SHALL update the `notifications` row and reflect the change immediately in the UI without a full page reload.
6. THE System SHALL display a notification badge on the Dashboard navigation item showing the count of unread Notifications for the authenticated user.

---

### Requirement 10 — Dashboard

**User Story:** As any authenticated user, I want a role-specific dashboard, so that I can see the information and actions most relevant to my role at a glance.

#### Acceptance Criteria

1. WHEN an Employee logs in, THE System SHALL display the Employee Dashboard showing leave balance summaries per Leave Type, upcoming approved leave, and recent Leave Request status.
2. WHEN a Manager or HR user logs in, THE System SHALL display a summary of pending Leave Requests awaiting their approval action, team leave calendar, and key leave statistics.
3. WHEN a Super Admin logs in, THE System SHALL display system-wide statistics including total pending requests, leave type utilisation, and user activity metrics.
4. THE System SHALL render dashboard charts using Chart.js displaying leave utilisation trends by month for the current calendar year.
5. THE System SHALL update dashboard statistics on page load without requiring a manual refresh.

---

### Requirement 11 — Advanced Search and Filters

**User Story:** As an HR user or Manager, I want to search and filter leave records across all modules, so that I can quickly locate specific records for review or audit.

#### Acceptance Criteria

1. THE System SHALL provide a search input and filter controls on all leave list screens (requests, balances, ledger, quotas).
2. WHEN a user applies a filter, THE System SHALL re-query the database with the combined filter parameters and display the filtered result set within the same page without a full page reload.
3. THE System SHALL support filtering by at minimum: employee name, department, branch, Leave Type, date range, and status.
4. WHEN a user clears all filters, THE System SHALL restore the unfiltered result set.

---

### Requirement 12 — Reports and Export

**User Story:** As an HR user or Super Admin, I want to export leave reports in Excel and PDF formats, so that I can share data with stakeholders or satisfy audit requirements.

#### Acceptance Criteria

1. THE System SHALL provide a Reports screen accessible to HR and Super Admin roles with predefined report types: Leave Summary, Leave Balance, Leave Ledger, and Approval History.
2. WHEN a user requests an Excel export, THE System SHALL generate a `.xlsx` file containing the filtered report data and trigger a browser download.
3. WHEN a user requests a PDF export, THE System SHALL generate a PDF document containing the report data formatted in a tabular layout and trigger a browser download.
4. THE System SHALL apply the same active search and filter parameters to the exported report as are visible on screen at the time of export.

---

### Requirement 13 — Audit Logs

**User Story:** As a Super Admin, I want a complete audit trail of all system actions, so that I can investigate discrepancies and demonstrate compliance.

#### Acceptance Criteria

1. THE System SHALL write an Audit Log entry to the `audit_logs` table for every create, update, and delete operation on the following entities: Leave Types, Leave Requests, Leave Approvals, Leave Quotas, Leave Balances, Compensation Leaves, Holidays, Users, and Settings.
2. WHEN an Audit Log entry is written, THE System SHALL record the actor user ID, action type, affected table, affected row ID, previous state (JSON), new state (JSON), and timestamp.
3. WHEN a Super Admin accesses the Audit Log screen, THE System SHALL display all audit entries with advanced search and filter controls for actor, action type, entity, and date range.
4. THE System SHALL support pagination on the Audit Log screen with a configurable page size of 10, 25, or 50 records per page.

---

### Requirement 14 — Role-Based Access Control

**User Story:** As a Super Admin, I want access to all features to be governed by RBAC, so that users can only perform actions appropriate to their role.

#### Acceptance Criteria

1. THE System SHALL enforce permission checks on every API route using the JWT token's role claim before executing any data operation.
2. IF a user's role does not include permission for the requested action, THEN THE System SHALL return HTTP 403 and display an access-denied message in the UI.
3. THE System SHALL restrict Leave Request submission and personal leave viewing to the Employee's own records; an Employee SHALL NOT be able to view or modify another Employee's leave records.
4. THE System SHALL restrict Approval actions to the user designated as the actor for the current Approval Level of a Leave Request.
5. WHEN a Super Admin modifies role permissions in Settings, THE System SHALL apply the new permissions to all subsequent requests without requiring a server restart.

---

### Requirement 15 — Dark/Light Theme

**User Story:** As any user, I want to toggle between dark and light themes, so that I can use the application comfortably in different lighting conditions.

#### Acceptance Criteria

1. THE System SHALL provide a theme toggle control accessible from the main navigation bar.
2. WHEN a user activates the theme toggle, THE System SHALL switch all UI components between the dark and light Bootstrap 5 theme variants without a full page reload.
3. THE System SHALL persist the user's theme preference in `localStorage` and apply the stored preference on the next page load.

---

### Requirement 16 — File Attachments

**User Story:** As an Employee, I want to attach supporting documents to a leave request, so that approvers have the evidence needed to make an informed decision.

#### Acceptance Criteria

1. WHEN an Employee uploads an attachment, THE System SHALL store the file under `/public/uploads/attachments/` using a unique server-generated filename and record the original filename, stored path, MIME type, and file size in the `attachments` table.
2. THE System SHALL enforce a maximum file size of 5 MB and restrict accepted MIME types to `application/pdf`, `image/jpeg`, `image/png`, and `application/vnd.openxmlformats-officedocument.wordprocessingml.document`.
3. WHEN an approver views a Leave Request, THE System SHALL display a link to download each attached file.
4. IF a Leave Request is deleted, THEN THE System SHALL delete the associated attachment files from the `/public/uploads/attachments/` directory and remove the corresponding rows from the `attachments` table.
