# Changelog

All notable changes to this project will be documented in this file.

## [1.7.3+23] - 2026-03-12
### Added
- **Content-Area Refresh**: Refactored the Dashboard to keep the header (greeting/user name) static during pull-to-refresh, isolating the refresh animation to the scrollable content area.
- **Header Synchronization**: Unified `SliverAppBar` properties (110px height, pinned state) and text hierarchy (Main title on top) across all screens including Monthly Planner, Regular Payments, and Settings.
- **Enhanced Iconography**: Replaced the sparkles refresh icon with a specialized `rotateCw` icon for a more professional feel.
- **Typography Deep-Sync**: Standardized header weights (`w900`) and Category card label styles (`w800`) across the platform.

### Fixed
- **Build Integrity**: Resolved `SystemUiOverlayStyle` undefined name error and cleaned up unused `GoogleFonts` imports and variables across multiple files.
- **Clean Navigation**: Removed redundant back buttons on the Categories screen to align with the core navigation architecture.

## [1.7.2+22] - 2026-03-11
### Added
- **Global Typography**: Implemented **Outfit** as the global application font.
- **Header Synchronization**: Unified header layouts (size, weight, spacing) across Dashboard, Analytics, Settings, Notes, Wishlist, and Categories.
- **UX Flow**: Removed redundant back buttons on main screens (Notes, Wishlist) for a cleaner UX.
- **Standardized FAB**: Fixed the position of the plus button (+) to be perfectly identical on every screen.
- **Edge-to-Edge**: Finalized transparent system navigation bar integration.

## [1.7.1+21] - 2026-03-03
### Fixed
- **UI Polish**: Final refinement of dashboard action cards and layout consistency.
- **Font Reversion**: Completed full reversion to original typography across all application screens.

## [1.7.0+20] - 2026-03-03
### Added
- **Wish List Module**: New dedicated tracker for future purchase goals (Electronics, Shopping).
- **UX Safety**: Implemented confirmation dialogs before deleting Notes or Wish List entries.
- **Database Resilience**: Fixed SQLite initialization for the `wishes` table.

## [1.6.1+19] - 2026-03-02
### Added
- **Animated Actions**: Introduced micro-animations (scale on tap) to the Dashboard Quick Actions.

### Fixed
- **Code Health**: Replaced all deprecated `withOpacity` calls with `withValues`.

## [1.6.0+18] - 2026-03-02
### Added
- **Local Backup & Restore**: Added ability to export expenses database to a local `.db` file, and import it back to restore all previous data across reinstalls.

## [1.5.1+17] - 2026-02-27
### Fixed
- **UI Responsiveness**: Fixed keyboard overlap issues across various text input screens (like Notes) by dynamically adjusting bottom padding for improved typing experience.
- **Regular Expenses Data**: Fixed an issue where the `endDate` field was displaying the `nextDueDate`. Re-labeled it correctly as "End Date".
- **Notes UI Improvements**: Enhanced Notes screen with rich typography, shadow effects, and automatic list formatting features.

## [1.5.0+16] - 2026-02-27
### Added
- **Account Verification**: Major enhancements to the email verification flow, including a polished OTP input experience and fixed resend mechanisms.

## [1.4.4+15] - 2026-02-24
### Added
- **Dynamic Spectrum Cards**: Main wallet and summary cards now change color through a "Spectrum" (Green -> Yellow -> Red -> Dark Red) based on budget consumption.
- **Visual Feedback**: Synchronized card shadows and layout elements to the new spectrum logic.

### Changed
- **Cleaner UI**: Standardized progress bars to use white semantic shades for better legibility on colored cards.
- **Theme Updates**: Enhanced `AppTheme` with darker variants for warning and danger states.

## [1.4.3+14] - 2026-02-24
### Added
- **Entrance Animations**: Implemented smooth Fade + Slide entrance animations for the Landing, Login, Register, and Profile Setup screens.
- **Visual Polish**: Refined bottom sheet transitions in the Profile Screen for a more premium experience.

### Changed
- **Branding & Tone**: Rebranded app copy with a professional and friendly voice across all screens (Dashboard, Analytics, SMS Import, etc.).
- **AI Performance**: Switched default SMS parsing provider to **Groq** for significantly faster transaction processing.
- **Improved UX**: New engaging empty states and field hints to guide users more effectively.

### Fixed
- **Profile Updates**: Fixed an issue where updating your email could lead to logout or synchronization errors.
- **System Stability**: Resolved various UI lints and logic edge cases.

## [1.0.5] - 2026-02-18
### Added
- **Payment Mode Tracking**: Automatically detects UPI, Card, Wallet, and Net Banking from SMS messages.
- **Manual Entry**: Added payment mode selector to manual expense creation and editing.
- **Bulk Import**: Refactored SMS import to use bulk insertion for improved stability and performance.

### Changed
- **Planner Polish**: Imported SMS transactions now have their planned amount set to the actual amount, preventing them from showing up with "zero planned amount" in the Monthly Planner.
- **Analytics UI**: Pie chart segments now show the category name and percentage when selected for better readability.

### Fixed
- **Database Schema**: Fixed a critical issue where the `payment_mode` column was occasionally missing during migrations (Database v13).
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
