# Expenze Application Changelog

## Version 1.4.4+15 - 2026-02-24

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
