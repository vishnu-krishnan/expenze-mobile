# Technical Specification - Analytics Period Fixes

## System Overview
Refactors the data retrieval and state processing logic for the Analytics module to ensure strict alignment with the selected calendar period.

## Component Breakdown

### 1. ExpenseRepository Logic Shift
- **Rolling Window Calculation**: Created a logic to determine the `startMonthKey` (e.g., `2025-09`) by subtracting N months from the current date.
- **Query Optimization**: Updated `getTrends` and `getAnalyticsSummary` to use `WHERE month_key >= ?` filters.
- **Averaging Fix**: Replaced the SQL `AVG()` (which only considers months with data) with a custom calculation: `SUM(total) / periodMonths`.

### 2. ExpenseProvider State Synchronization
- **Filling Logic**: Refined `loadTrends` to generate a continuous sequence of `yyyy-MM` keys for the selected period, ensuring the chart x-axis is always proportional and chronological.
- **Stats Integration**: Ensured `avgMonthlySpent` and `maxMonthlySpent` reflect the exact subset of data displayed in the chart.

### 3. AnalyticsScreen UI Alignment
- Verified that the `_selectedPeriod` state correctly informs the provider during re-fetches.
- Standardized the x-axis interval logic to handle 5-year views (60 points) gracefully by showing labels every 6 months.

## Data Flow
1. User selects "1Y".
2. `AnalyticsScreen` calls `provider.loadTrends(12)`.
3. `ExpenseRepository` calculates `startMonth = now - 12` and executes filtered GPS.
4. `ExpenseProvider` fills gaps in the result set to ensure 12 data points.
5. `fl_chart` renders the 12-point trend.

## Security Model
- No changes to security. Data access remains local-only.

## Performance Analysis
- SQL filtering via `month_key` is highly efficient on the `expenses` table.
- Grouping logic remains unchanged in complexity but operates on a smaller, more relevant dataset for most periods.

Date: 2026-02-17
