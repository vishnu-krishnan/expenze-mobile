# Business Overview - Dynamic Spectrum Cards

## Problem
Static progress bars were easy to overlook when users were overspending. There was no high-impact visual "warning" that immediately communicated budget stress during quick glances at the Dashboard.

## Objective
Implement a "Dynamic Spectrum" system for primary financial cards that uses color as an intuitive, high-impact indicator of spending health.

## Feature Summary
1.  **Spectrum Gradients**: Wallet and Summary cards now change background color through a logic-driven spectrum:
    -   **Green/Teal**: Safe (<50% used)
    -   **Lime/Yellow**: Caution (50-70%)
    -   **Amber/Orange**: Warning (70-85%)
    -   **Red**: Danger (85-110%)
    -   **Dark Red**: Critical (>110%)
2.  **Shadow Glow**: Card shadows now glow with the same semantic color to reinforce status.
3.  **Unified Styling**: Standardized progress bars use clean, translucent white segments to look modern against varying card colors.

## High-level Workflow
1.  User enters an expense -> `pctUsed` is recalculated.
2.  Card background and logic check thresholds -> Gradient updates instantly to match status.
3.  User checks Dashboard/Planner -> Instant visual feedback on "spending intensity."

## Business Value
- Improved user financial awareness through intuitive color-coding.
- Increased "premium" feel of the app through dynamic, reactive UI.
- Lower cognitive load: Users understand their status in 1 second without reading numbers.

## Timeline
- Implemented: 2026-02-24

Date: 2026-02-24
