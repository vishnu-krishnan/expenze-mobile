# Technical Specification - Bill Status & Quick Actions

System Overview
Enhancement of the existing financial tracking system to support status tracking and streamlined data entry.

Architecture Diagram
[Dashboard Screen] --> (ExpenseProvider) --> [Quick Add Modal]
[Regular Payments Screen] --> (RegularPaymentProvider) --> [Edit Dialog] --> [SQLite v8]

Component Breakdown
1.  Model Upgrade: Added 'status' and 'statusDescription' to RegularPayment.
2.  Database: Migrated to v8 with ALTER TABLE commands.
3.  UI: ModalBottomSheet integration in Dashboard and RegularPayments screens.

Data Flow
1.  User inputs data in modal.
2.  Provider processes event and calls static DatabaseHelper methods.
3.  NotifyListeners() triggers UI rebuild.

API Contracts
Local SQLite only.

Validation Rules
-   Subscription/Expense Name: Required.
-   Category: Required.
-   Amount: Must be numeric.

Error Handling
-   Empty fields: User is prompted (non-fatal).
-   DB Migration: Try-Catch blocks ensure robustness for existing installations.

Schema Changes
-   Table: regular_payments
    -   ADD status TEXT
    -   ADD status_description TEXT

Security Model
-   Local-only processing.
-   No external data transmission.

Performance Analysis
-   Minimal O(1) impact on SQLite operations.

Scalability Plan
-   Status field allows for future automated status updates (e.g., via SMS detection).

Deployment Plan
-   Standard Flutter build/run.

Rollback Plan
-   Revert database to version 7 (removes status columns).

Date: 2026-02-16
