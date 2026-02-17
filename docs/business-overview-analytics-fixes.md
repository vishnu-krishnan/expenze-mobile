# Business Overview - Analytics Period Fixes

## Problem
The Analytics screen currently exhibits several data inconsistencies:
1. **Trend Disconnect**: The spending trend chart doesn't always align with the selected time period (6 months, 1 year, 5 years) because it relies on "last active months" instead of "last calendar months."
2. **Inaccurate Insights**: The "Average" and "Highest" spending calculations are based only on months that have data, rather than the entire selected time period. This leads to inflated averages (e.g., if you spent ₹10,000 in one month out of a 6-month period, the average shows as ₹10,000 instead of ₹1,666).
3. **X-Axis Irregularity**: X-axis labels can appear inconsistent if the data source contains gaps or older records that fall outside the intended view.

## Objective
To synchronize the entire Analytics suite with the user-selected time period, ensuring that charts and stats reflect a true calendar-based history.

## Feature Summary
- **Calendar-Based Filtering**: All analytics queries now use a rolling date window based on the current date and the selected period.
- **Improved Averaging**: "Average Monthly Spent" now calculates the average over the entire selected period (e.g., Total / 12 for a 1-year view), providing a more realistic financial outlook.
- **Accurate Peaks**: "Highest Expense" is now strictly limited to the selected period, preventing old spikes from skewing current insights.
- **Chronological Consistency**: The trend chart is guaranteed to show exactly N months of history, filling gaps with zero values where necessary.

## Business Value
- **Predictability**: Users can better understand their long-term spending habits.
- **Accuracy**: Financial insights are now mathematically correct relative to the selected time window.
- **UX Clarity**: The chart and stats now always move in sync when switching between 6M, 1Y, and 5Y views.

## Timeline
- Implementation and Verification: 1-2 hours.

Date: 2026-02-17
