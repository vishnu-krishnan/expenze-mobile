# Changelog

All notable changes to this project will be documented in this file.
+
+## [1.0.5] - 2026-02-18
+### Added
+- **Payment Mode Tracking**: Automatically detects UPI, Card, Wallet, and Net Banking from SMS messages.
+- **Manual Entry**: Added payment mode selector to manual expense creation and editing.
+- **Bulk Import**: Refactored SMS import to use bulk insertion for improved stability and performance.
+
+### Changed
+- **Planner Polish**: Imported SMS transactions now have their planned amount set to the actual amount, preventing them from showing up with "zero planned amount" in the Monthly Planner.
+- **Analytics UI**: Pie chart segments now show the category name and percentage when selected for better readability.
+
+### Fixed
+- **Database Schema**: Fixed a critical issue where the `payment_mode` column was occasionally missing during migrations (Database v13).
+

## [1.0.4] - 2026-02-18
### Changed
- **Branding**: Rebranded "Spending Limit" to **"Monthly Budget"** across Dashboard and Settings for a clearer, more positive financial tone.
- **Registration**: Removed mandatory username field. Usernames are now automatically generated from the email or full name to simplify onboarding.
- **UI Enhancement**: Improved visibility of the budget adjustment text field with high-contrast colors and larger font size.


## [1.0.3] - 2026-02-18
### Fixed
- Analytics Pie Chart rendering issues:
  - Fixed "100% glitch" where one category dominated the chart.
  - Fixed issue where only one category was displayed.
  - Improved SQL robustness for data aggregation.
- Pie Chart interactivity:
  - Percentage labels now only appear on touch to reduce clutter.
  - Fixed decimal precision for clearer values.
- **Regular Expenses**:
  - Fixed potential crash when adding a new regular payment (context safety).


## [1.0.2] - 2026-02-18
### Added
- Prioritized unconfirmed expenses at the top of Monthly Planner.
- Standardized "Unplanned" vs "Planned" status labels.

### Changed
- Rebranded "Bills" feature to **"Regular Expenses"** to better accommodate steady costs like EMIs, Rent, Loans, and Utilities.
- Updated Dashboard quick action label to "Regular" and restored "Planner" to the bottom navigation bar.

### Fixed
- Null safety crash when viewing Uncategorized transactions.
- Improper planned amount baseline in Monthly Summary.
- Layout alignment of expense details footer.

## [1.0.1] - 2026-02-18
### Added
- Randomized motivational quotes in the Profile Screen.
- "Member Since" field in User Profile.
- In-app versioning and recent changes display.
- Automatic (System) and Manual theme mode selection.
- Improved SMS import to preserve original message content.

### Changed
- Standardized header design in Monthly Planner to match Analytics.
- Refined Profile Screen UI: Removed extra fields, conditional camera icon.
- Improved Monthly Planner progress bar reference proportions.

### Fixed
- Layout overflow on certain screen sizes.
- Replaced deprecated `.withOpacity()` with `.withValues()`.

## [1.0.0] - 2026-02-12
### Initial Release
- Core expense tracking, category management, and analytics.
- Firebase Authentication & Google Sign-In.
- Local-first storage with SQLite.
