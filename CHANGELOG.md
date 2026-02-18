# Changelog

All notable changes to this project will be documented in this file.

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
