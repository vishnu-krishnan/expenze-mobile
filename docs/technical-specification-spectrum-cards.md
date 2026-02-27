# Technical Specification - Dynamic Spectrum Cards

## System Overview
Expansion of the presentation layer's reactive UI to support multi-stage conditional gradients for the `DashboardScreen` and `MonthPlanScreen` cards.

## Component Breakdown
1.  **Spectrum Logic Engine**: 
    -   Located within UI private methods (`_buildWalletCard` and `_buildPremiumSummary`).
    -   Evaluates `pctUsed` (Spent / Planned) against 5 threshold brackets.
    -   Selects a `List<Color>` gradient and a `Color` shadow base.

2.  **Theme Extensions**:
    -   Added `warningDark` and `dangerDark` to `AppTheme` for expanded shadow and gradient depth.

3.  **Visual Alignment**:
    -   Neutralized progress bar colors within cards to `Colors.white.withOpacity` to prevent color clashing.
    -   Implemented `isStrained` boolean flags to switch legend/label contrast when cards enter warning/danger zones.

## Logic Mapping
| usage % | State | Gradient Start | Gradient End |
|---|---|---|---|
| < 50% | Healthy | Primary (Teal) | PrimaryDark |
| 50-70% | Caution | Lime-600 | Lime-700 |
| 70-85% | Warning | Warning (Amber) | WarningDark |
| 85-110%| Danger | Danger (Red) | DangerDark |
| > 110% | Critical | Red-800 | Red-900 |

## Performance Impact
- Negligible. Color selection happens during build phase based on existing provider state variables. No extra SQL queries.

Date: 2026-02-24
