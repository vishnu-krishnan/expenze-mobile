# Expenze Application Changelog

## Version 1.8.11+35 - 2026-03-13
### Fixed
- **Wallet Card Color Purity**: Finalized the removal of all dark/desaturated shades, replacing legacy Red 700 with high-vibrancy Rose Red for over-budget states.
- **Simplified Color Logic**: Streamlined the status engine to use single vibrant primary colors paired exclusively with white for maximum clarity and vibrancy.

## Version 1.8.10+34 - 2026-03-13
### Changed
- **Dashboard Hierarchy**: Expanded the Wallet Card vertical presence with 38px internal padding and 16px top clearance for a more professional visual tier.
- **Elite Mini-Grid**: Redesigned the Quick Actions hub into a high-density "mini-tile" grid with optimized 1.5 aspect ratios and trimmed icon padding.
- **Layout Compression**: Tightened vertical gaps between all main dashboard sections to maximize glanceable information.

## Version 1.8.9+33 - 2026-03-13
### Added
- **Enhanced Time Context**: Updated the header date pill to include the current weekday for better glanceability (e.g., "Fri, 13 Mar").

### Changed
- **Pristine Wallet Card**: Refined the "Total Spent" card with a high-vibrancy "usage color + pure white" aesthetic, removing muddy desaturated tones and dark shades.
- **Standardized Navigation**: Modernized month picker arrows with circular tap targets and professional Lucide iconography for perfect alignment.

### Fixed
- **Visual Polish**: Optimized backdrop filter transparency and removed inconsistent shadows in the main wallet container.

## Version 1.8.8+32 - 2026-03-13
### Added
- **Analytics Revamp**: Implemented a "Liquid Glass" aesthetic for summary cards (Total Spent, Daily Avg, Peak Day) with high-quality backdrop blurring.
- **Enhanced Period Selection**: Redesigned the period chooser (1W, 1M, 3M) with a premium glassy finish and improved active state visibility.

### Fixed
- **Scroll Position Bug**: Resolved an issue where expanding the history list would incorrectly scroll the screen back to the top.
- **Chart Precision**: Optimized Y-axis label spacing to prevent clipping of large currency values and refined X-axis intervals for better readability.
- **Stability Fix**: Resolved a missing framework import that caused rendering issues on some devices.

## Version 1.8.7+31 - 2026-03-13
### Added
- **Quick Actions Hub**: Replaced the horizontal-scroll Action Hub with a clean, professional 2×3 fixed grid — all shortcuts visible at a glance, no swiping required.
- **EMI Calculator**: Brand-new built-in loan calculator with real-time calculations and Indian notation formatting.

### Changed
- **Professional Card Design**: Action cards now use a solid color-tinted background instead of Liquid Glass blur for better contrast and performance.

## Version 1.8.6+30 - 2026-03-13
### Added
- **Category Modal**: Add New Category is now a lightweight bottom sheet popup.
- **Compact Category Grid**: Revamped the category list to a 3-column grid with staggered fade animations.

### Changed
- **Header Unification**: Category screens now use the premium Large Title gradient header.
- **Text Clarity**: Replaced playful labels with clear, professional financial terminology.

## Version 1.8.1+25 - 2026-03-13
### Added
- **Frosted Glass Cards**: Overhauled the Dashboard design with a modern "frosted glass" effect for a sleek, contemporary look.
- **Unified Status Bar**: Synchronized the phone's top status bar with the application's header colors across all screens for a seamless transition.
- **Immersive Display**: Enabled full edge-to-edge display support for a more modern mobile design.

### Fixed
- **Navigation Polish**: Corrected the alignment of the quote author and cleaned up the visual layout of the Quote card.
- **Stability Fixes**: Fixed several layout and rendering issues to ensure a smoother experience.

## Version 1.6.0+18 - 2026-03-02

### Added
- **Local Backup & Restore**: Added ability to export expenses database to a local `.db` file, and import it back to restore all previous data across reinstalls.

## Version 1.5.1+17 - 2026-02-27

### Fixed
- **UI Responsiveness**: Fixed keyboard overlap issues across various text input screens (like Notes) by dynamically adjusting bottom padding for improved typing experience.
- **Regular Expenses Data**: Fixed an issue where the `endDate` field was displaying the `nextDueDate`. Re-labeled it correctly as "End Date".
- **Notes UI Improvements**: Enhanced Notes screen with rich typography, shadow effects, and automatic list formatting features.

## Version 1.5.0+16 - 2026-02-27

### Added
- **Account Verification**: Major enhancements to the email verification flow, including a polished OTP input experience and fixed resend mechanisms.

### Added
- **Dynamic Spectrum Cards**: Implemented a color-shifting background system for main financial cards (Dashboard & Planner). Card colors now transition from Teal (Healthy) to Lime (Attention), Amber (Warning), Red (Danger), and Dark Red (Critical) based on real-time budget usage.
- **Spectrum Shadows**: Added color-matched shadows that shift with card state for a "glow" feedback effect.

### Changed
- **Progress Bar Refresh**: Unified progress bars to use white semantic shades for a cleaner, high-contrast look on top of dynamic card backgrounds.
- **Theme Palette Expansion**: Added `warningDark` and `dangerDark` constants to `AppTheme` for expanded visual feedback.

## Version 1.4.3+14 - 2026-02-24

### Added
- **Entrance Animations**: Implemented smooth Fade + Slide entrance animations for Landing, Login, Register, and Profile Setup screens.
- **Visual Polish**: Added TweenAnimationBuilder for refined bottom sheet transitions in the Profile Screen.

### Changed
- **App Voice & Tone**: Rebranded all user-facing copy to a professional and friendly tone across all major screens (Dashboard, Analytics, SMS Import, Notes, and Categories).
- **AI Infrastructure**: Switched default SMS parsing engine to **Groq (Llama 3.1)** for sub-second latency and improved cost profile.
- **Empty States**: Redesigned empty state messaging in Notes and Regular Payments with engaging, helpful copy.

### Fixed
- **Auth Persistence**: Resolved a critical bug in `AuthProvider.updateProfile` where email updates caused session instability; now correctly synchronizes with SharedPreferences and SQLite.
- **Lint Corrections**: Fixed missing curly braces in flow control and resolved duplicated imports in the Note module.

## Version 1.4.2+13 - 2026-02-24

### Changed
- Refined UI/UX in Analytics Screen with a new TransactionsDialog to view daily expenses on tap.
- Updated `sms_import_screen` to clearly display "Plan Match" on tracked UI elements when recognizing an expense.
- Tweaked `ExpenseProvider.processImportedExpenses` to perform updates on existing matched transactions from SMS.
- Altered SMS scan behavior to unconditionally show the AI use limit notice on refresh.
- Fixed duplicated package imports in `notes_screen.dart` causing lint errors.

## Version 1.0.0 - 2025-12-08

### Added
- **Dashboard Features**
  - Month navigation with Previous/Next buttons and month picker
  - 4 summary cards: Current Month, Total Expenses, Upcoming Payments, Savings Goal
  - Line chart showing last 6 months trend (Planned vs Actual)
  - Pie chart showing category-wise expense breakdown for current month
  - Real-time data updates when changing months
  - Formatted month display (MMM-YY format)

- **Categories Management**
  - Add new categories with sort order
  - Edit existing categories
  - Delete categories with usage warning
  - Duplicate prevention (case-insensitive)
  - Enhanced delete confirmation showing template usage
  - Sort order explanation tooltip

- **Payment Templates**
  - Create templates with start/end dates
  - View templates with months remaining calculation
  - Edit and delete templates
  - Active/Inactive status display
  - Category assignment

- **Monthly Plan**
  - Generate month from templates
  - Add manual payment items
  - Edit planned/actual amounts inline
  - Mark items as paid
  - Add notes to items
  - Delete items
  - Category-grouped display
  - Real-time totals calculation

- **API Endpoints**
  - GET /api/categories - List all categories
  - POST /api/categories - Create category
  - PUT /api/categories/:id - Update category
  - DELETE /api/categories/:id - Delete category
  - GET /api/templates - List all templates
  - POST /api/templates - Create template
  - PUT /api/templates/:id - Update template
  - DELETE /api/templates/:id - Delete template
  - GET /api/month/:key - Get month plan and items
  - POST /api/month/generate - Generate month from templates
  - PUT /api/items/:id - Update payment item
  - POST /api/items - Create manual item
  - DELETE /api/items/:id - Delete item
  - GET /api/summary/last6 - Get last 6 months summary
  - GET /api/category-expenses/:monthKey - Get category expenses for pie chart

### Design
- Professional teal color scheme (#0d9488)
- Inter font family for modern typography
- Responsive layout (mobile, tablet, desktop)
- Smooth animations and transitions
- Card-based UI with hover effects
- Gradient header
- Breadcrumb navigation

### Calculations
- Total Planned: Sum of all planned amounts
- Total Actual: Sum of all actual amounts
- Difference: Planned - Actual (remaining budget)
  - Positive (green) = Under budget
  - Negative (red) = Over budget
- Savings %: (Difference / Planned) × 100

### Known Issues
- Month picker display issue in some browsers (showing text instead of control)
- Need to verify data persistence across page reloads

### Technical Stack
- Backend: Node.js + Express
- Database: SQLite3
- Frontend: Vanilla JavaScript
- Charts: Chart.js
- Styling: Custom CSS with CSS variables

---

## Future Enhanations Planned
- Export data to CSV/PDF
- Budget alerts and notifications
- Recurring payment automation
- Multi-currency support
- Dark mode toggle
- Data backup/restore
- Mobile app version
