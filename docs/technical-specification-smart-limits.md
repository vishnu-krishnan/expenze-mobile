# Technical Specification: Smart Spending Limit Carry-over

System Overview:
The spending limit system manages user-defined budget caps for monthly spending. This update transitions the system from a strict month-by-month matching logic to a time-series carry-over logic.

Architecture Diagram (ASCII):

[ UI Level ] -> [ ExpenseProvider ] -> [ ExpenseRepository ] -> [ SQLite (month_plans) ]
                                            |
                                            V
                                     [ Carry-over Logic ]
                                     "Find MAX(month_key) <= target WHERE limit > 0"

Component Breakdown:
1. ExpenseRepository: Modified `getMonthlyLimit(String monthKey)`.
2. SQLite: Optimized `month_plans` table query.

Data Flow:
1. Provider requests summary for '2026-03'.
2. Repository queries `month_plans` for entries <= '2026-03' ordered by key DESC.
3. If '2026-03' exists, it is returned.
4. If not, '2026-02' (or most recent) is returned.
5. Final fallback to `users.default_budget`.

Validation Rules:
- Only positive REAL values (> 0) are considered valid limits for carry-over.

Error Handling:
- Fallback to 0.0 handled if no plans or default budget exist.

Schema Changes:
- None required (optimized existing table usage).

Security Model:
- Local database access only.

Performance Analysis:
- O(log N) lookup due to indexed `month_key` in `month_plans` table.

Rollback Plan:
- Revert query in `expense_repository.dart` from `month_key <= ?` to `month_key = ?`.
