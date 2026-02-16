# Business Overview - Data Connectivity & Business Logic

Date: 2026-02-16

Objective
Connect the Expenze Mobile application's UI to the real SQLite backend, replacing all hardcoded dummy values with dynamic data and implementing full CRUD operations for expenses and categories.

Feature summary
- Real-time Dashboard: Spending summaries are now calculated directly from the SQLite `expenses` table.
- Advanced Analytics: Spending trends (6M, 1Y, 3Y) are derived from historical transaction data.
- Insights Module: Average monthly spending and highest spending metrics are calculated dynamically.
- Interactive Navigation: Proper routing between Dashboard actions and management screens.
- Category Breakdown: Visual representation of spending per category using actual user data.

High-level workflow
1. User adds/imports an expense.
2. SQLite database is updated via Repository.
3. Providers (ChangeNotifier) trigger a rebuild across all screens.
4. Calculations (totals, averages, trends) are recalculated on-demand.

Business value
Transforms the app from a static mockup into a functional financial management tool, providing users with accurate data to make informed budgeting decisions.

Risks
- Data integrity issues if imports are duplicated (mitigated via deduplication logic).
- Performance lag on extremely large datasets (mitigated via indexed database queries).
