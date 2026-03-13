class ReleaseInfo {
  final String version;
  final String date;
  final List<String> changes;

  const ReleaseInfo({
    required this.version,
    required this.date,
    required this.changes,
  });
}

class AppVersion {
  static const String current = '1.8.8';
  static const String buildNumber = '32';
  static const String releaseName = 'Analytics Revamp & UX Polish';

  static const String website = 'https://expenze-elite.netlify.app/';
  static const String supportEmail = 'expenzehelp@gmail.com';

  static const List<ReleaseInfo> history = [
    ReleaseInfo(
      version: '1.8.8',
      date: '2026-03-13',
      changes: [
        'Analytics Revamp: Implemented a "Liquid Glass" aesthetic for summary cards (Total Spent, Daily Avg, Peak Day) with high-quality backdrop blurring.',
        'Scroll Fix: Resolved a bug where expanding the history list would incorrectly scroll the screen back to the top.',
        'Enhanced Period Selection: Redesigned the period chooser (1W, 1M, 3M) with a premium glassy finish and improved active state visibility.',
        'Chart Precision: Optimized Y-axis label spacing to prevent clipping of large currency values and refined X-axis intervals for better readability.',
        'Stability: Fixed a missing framework import that could cause rendering issues on certain devices.',
      ],
    ),
    ReleaseInfo(
      version: '1.8.7',
      date: '2026-03-13',
      changes: [
        'Quick Actions Hub: Replaced the horizontal-scroll Action Hub with a clean, professional 2×3 fixed grid — all shortcuts visible at a glance, no swiping required.',
        'Professional Card Design: Action cards now use a solid color-tinted background instead of Liquid Glass blur — sharper, faster to read, and consistent with premium fintech design.',
        'EMI Calculator: Brand-new built-in loan calculator — enter principal, rate, and tenure to instantly get monthly EMI, total interest, and total payment with a visual breakdown bar.',
        'Smart Number Formatting: EMI results display in Indian notation (Lakhs/Crores) for familiar readability.',
        'Tenure Toggle: Switch between Years and Months for loan tenure with a single tap.',
        'Real-Time Calculation: Results update instantly as values are typed — no "Calculate" button needed.',
      ],
    ),
    ReleaseInfo(
      version: '1.8.6',
      date: '2026-03-13',
      changes: [
        'Category Modal: Add New Category is now a lightweight bottom sheet popup — no more full-screen navigation.',
        'Compact Category Grid: Revamped the category list to a 3-column grid with smaller, cleaner tiles for better at-a-glance scanning.',
        'Fade-In Animation: Each category card now enters with a smooth staggered fade-and-slide effect.',
        'Duplicate Prevention: Creating a category with an existing name now shows an inline error — the sheet stays open for correction instead of silently failing.',
        'Header Unification: Category Add and Edit screens now use the same premium Large Title gradient header as the Dashboard.',
        'Text Clarity: Replaced playful internal slang ("New Squad Member", "The Usual Suspects") with clear, professional labels.',
      ],
    ),
    ReleaseInfo(
      version: '1.8.5',
      date: '2026-03-13',
      changes: [
        'Action Hub UX: Restored the intuitive horizontal navigation while upgrading cards to the new Liquid Glass aesthetic with luminous borders and inner glows.',
        'Pristine Light Theme: Overhauled the Wallet card and background elements for light theme—removed all murky tints for a pure, bright aesthetic.',
        'Category Management: Fixed incorrect header themes and enabled back navigation on Add/Edit screens for a seamless management experience.',
        'Glossy Progress Bar: Redesigned the budget progress bar with vibrant primary colors and a professional "glossy" finish.',
        'Chronological Accuracy: Fixed sorting logic to ensure recent "Pitstops" and "Pulse" activities always appear at the top.',
      ],
    ),
    ReleaseInfo(
      version: '1.8.4',
      date: '2026-03-13',
      changes: [
        'Speed Boost: Background aurora animations are now 75% faster and more energetic.',
        'Snappy Navigation: Removed fade-in effects to restore instant screen switching.',
      ],
    ),
    ReleaseInfo(
      version: '1.8.3',
      date: '2026-03-13',
      changes: [
        'Performance Boost: Optimized background rendering for faster screen loading.',
        'Seamless Transitions: Added professional fade transitions when navigating between screens and tabs.',
        'Enhanced Aurora: Made the color-drifting animations more visible and smooth.',
      ],
    ),
    ReleaseInfo(
      version: '1.8.2',
      date: '2026-03-13',
      changes: [
        'Dynamic Aurora Backgrounds: Smooth, drifting animations added to the Dashboard cards for a premium "alive" feel.',
        'Improved Card Depth: Enhanced the visual layering of the Wallet and Quote cards to improve focus.',
      ],
    ),
    ReleaseInfo(
      version: '1.8.1',
      date: '2026-03-13',
      changes: [
        'Frosted Glass Cards: Overhauled the Dashboard design with a modern "frosted glass" effect.',
        'Unified Status Bar: Synchronized the phone\'s status bar with the application\'s header colors across all screens.',
        'Immersive Display: Enabled full edge-to-edge support for a more modern mobile experience.',
        'Navigation Polish: Corrected Quote card alignment and visual layout.',
      ],
    ),
    ReleaseInfo(
      version: '1.8.0',
      date: '2026-03-12',
      changes: [
        'Liquid Glass Design: Redesigned the main action button with a premium new shape and inner highlights.',
        'Revamped Action Hub: Updated Dashboard action cards with vibrant new colors and modernized icons.',
        'Dashboard Date Pill: Added a subtle date indicator to the Dashboard header.',
      ],
    ),
    ReleaseInfo(
      version: '1.7.3',
      date: '2026-03-12',
      changes: [
        'Improved Refresh Experience: Dashboard header now stays fixed during pull-to-refresh.',
        'Consistent Header Design: Standardized top header layout across all major screens.',
        'Professional Iconography: Updated icons and typography for a more polished look.',
      ],
    ),
    ReleaseInfo(
      version: '1.7.2',
      date: '2026-03-11',
      changes: [
        'Modern Typography: Updated the app-wide font to \'Outfit\' for a cleaner look.',
        'Header Synchronization: Unified design and spacing across all major modules.',
        'Standardized Actions: Aligned primary action button positions for intuitive navigation.',
        'Seamless System Navigation: Improved integration with device navigation bars.',
      ],
    ),
    ReleaseInfo(
      version: '1.7.1',
      date: '2026-03-03',
      changes: [
        'Dashboard Polish: Refined animated action cards and hover effects',
        'Stability Fix: Final cleanup of font standardizations to match original theme',
        'UX Patch: Resolved various small UI layout inconsistencies found across screens',
      ],
    ),
    ReleaseInfo(
      version: '1.7.0',
      date: '2026-03-03',
      changes: [
        'Wish List: New specialized module to save and track your future desires (Electronics, Shopping, etc.)',
        'Wish List: Support for optional amounts, links/sources, and custom naming',
        'Database Stability: Added migration logic for \'wishes\' table to resolve initial load crashes',
        'Reliability: Implemented delete confirmation prompts for both Notes and Wishes',
      ],
    ),
    ReleaseInfo(
      version: '1.6.1',
      date: '2026-03-02',
      changes: [
        'Interactive Dashboard: Introduced subtle scale animations to Quick Action cards',
        'UI Cleanup: Resolved standing deprecation and linting warnings for opacity',
        'Performance: Database initialization and hot reload optimization',
      ],
    ),
    ReleaseInfo(
      version: '1.6.0',
      date: '2026-03-02',
      changes: [
        'Local Backup & Restore: Export expenses to a local .db file',
        'Restore all previous data across reinstallations via importing your .db file',
      ],
    ),
    ReleaseInfo(
      version: '1.5.1',
      date: '2026-02-27',
      changes: [
        'UI Responsiveness: Fixed keyboard overlap issues across various text input screens by dynamically adjusting bottom padding',
        'Regular Expenses Data: Re-labeled endDate field correctly to "End Date"',
        'Notes UI Improvements: Enhanced Notes screen with rich typography, shadow effects, and automatic list formatting features',
      ],
    ),
    ReleaseInfo(
      version: '1.5.0',
      date: '2026-02-27',
      changes: [
        'Account Verification: Major enhancements to the email verification flow',
        'Polished OTP input experience and fixed resend mechanisms',
      ],
    ),
    ReleaseInfo(
      version: '1.4.4',
      date: '2026-02-24',
      changes: [
        'Dynamic Spectrum Cards: Dashboard & Planner cards now shift colors (Green -> Yellow -> Red) based on budget health',
        'Visual Feedback: Card shadows now glow with matching semantic colors for instant status recognition',
        'UI Cleanup: Progress bars modernized with neutral white shades for better compatibility with dynamic backgrounds',
        'Theme Expansion: Added richer warning and danger shades for high-impact visual feedback',
      ],
    ),
    ReleaseInfo(
      version: '1.4.3',
      date: '2026-02-24',
      changes: [
        'Copy Rebrand: Updated app tone to be professional, friendly, and humorous across all modules',
        'Onboarding Flow: Enhanced landing and setup screens with personality-driven copy and animations',
        'Entrance Animations: Added smooth fade-in and slide-up transitions for a more premium app feel',
        'AI Provider: Default parse engine shifted to Groq for faster, cost-effective SMS parsing',
        'Bug Fix: Resolved profile update stability issue when updating email addresses',
        'Security Polish: Friendlier copy for App Lock and password reset screens',
      ],
    ),
    ReleaseInfo(
      version: '1.4.2',
      date: '2026-02-24',
      changes: [
        'Analytics Taps: Added TransactionsDialog to view daily expenses directly from the chart tiles',
        'Plan Match UI: SMS Import screen now displays "Plan Match" overlays for tracked expenses',
        'Data Sync: Enhanced logic to perform updates on existing matched transactions from SMS',
        'Code Quality: Resolved duplicated package imports causing lint errors in Notes module',
      ],
    ),
    ReleaseInfo(
      version: '1.4.1',
      date: '2026-02-24',
      changes: [
        'Intelligent Matching: SMS transactions now auto-link to budget plans by matching category/amount',
        'Smart Filtering: Added aggressive exclusion for promotional SMS and marketing noise',
        'Dynamic Quotes: Integrated ZenQuotes API for fresh daily inspiration on the dashboard',
        'Scan Transparency: Improved scan status visibility and simplified SMS hub headers',
      ],
    ),
    ReleaseInfo(
      version: '1.4.0',
      date: '2026-02-24',
      changes: [
        'Smart SMS Hub: Centralized exclusion system to eliminate double-counting of credit card bills',
        'AI Overhaul: Rebuilt ApiService with multi-provider failover and automatic key rotation',
        'Optimized Scanning: Capped SMS scans to 20 messages per batch for speed and cost-efficiency',
        'Batch Disclaimer: Added UI transparency regarding AI processing limits and scan groups',
      ],
    ),
    ReleaseInfo(
      version: '1.3.0',
      date: '2026-02-23',
      changes: [
        'SMS Import: Inbox scan now uses AI (Groq) for all parsing — better accuracy, proper categories',
        'SMS Import: Imported expenses now show real categories in Analytics pie chart',
        'SMS Import: AI batch capped at 20 messages per scan to save API tokens',
        'SMS Import: Self-transfers between own accounts are now excluded automatically',
        'SMS Import: Payment reminders, min-due, total-due alerts are now reliably filtered out',
        'SMS Import: Per-AI prompt is now centralised in ai_prompts.dart for easy tuning',
        'Analytics: Summary card now shows Total Spent + Active Day Avg + Peak Day for the selected period',
        'Analytics: Section labels now correctly reflect the selected time range (7d / 30d / 90d)',
        'Analytics: Uncategorised expenses show as "General" instead of "Imported"',
        'Profile: Removed redundant Monthly Budget field (manage budget via Settings)',
      ],
    ),
    ReleaseInfo(
      version: '1.2.1',
      date: '2026-02-23',
      changes: [
        'Analytics: Zero-spend periods now show "Saved!" in green instead of ₹0',
        'Analytics: Fixed 1-month chart x-axis label overlap (interval reduced to every 5 days)',
        'Monthly Planner: Added horizontal swipe gesture for month navigation',
        'Dashboard: Pull-to-refresh now also refreshes the daily motivational quote',
        'Navigation: Switching tabs always resets to the current month',
      ],
    ),
    ReleaseInfo(
      version: '1.2.0',
      date: '2026-02-23',
      changes: [
        'Fixed SMS duplicate imports — deduplication now correctly parses the SMS ID from notes',
        'Fixed AI Analysis — Groq API response was not being decoded correctly; now extracts expenses from choices[0].message.content',
        'Calculation fix — all trend and summary queries now filter by is_paid=1 (debit only)',
        'Date accuracy fix — daily trend queries now use actual paid_date, not created_at fallback',
        'Removed Lite Scan — manual SMS tab now uses a single AI Analysis button',
        'Dashboard card revamped to vertical layout — large Total Spent, two-column stats row, progress bar',
        'Motivational quote of the day on dashboard via ZenQuotes API (no account needed)',
        'Register screen updated with friendlier onboarding text and budget tip card',
        'Budget scoping — setting a budget now asks: This Month only, or This & All Future months',
        'Past month budget protection — editing a past month\'s budget never affects current or future months',
        'Navigation reset — switching tabs always reloads the current month, no stale data',
        'Pull-to-refresh always snaps back to current month',
        'Loading indicator now uses the primary app colour instead of system green',
        'Budget scope dialog redesigned — clean Lucide icon tiles, no emoji, professional layout',
      ],
    ),
    ReleaseInfo(
      version: '1.0.6',
      date: '2026-02-18',
      changes: [
        'Improved stability: Added mounted guards for BuildContext across async operations',
        'UI Refinement: Renamed "Actual" label to "Spent" for clearer terminology',
        'SMS Import Update: "Uncategorized" transactions are now labeled as "Imported"',
        'Formatting: Standardized "Amount Spent" labels in detail views'
      ],
    ),
    ReleaseInfo(
      version: '1.0.5',
      date: '2026-02-18',
      changes: [
        'Enabled Payment Mode tracking: Auto-detect UPI, Card, and Wallet from SMS',
        'Added manual Payment Mode selection when creating or editing expenses',
        'Refined Analytics: Pie Chart now shows category labels on selection',
        'Performance Fix: Implemented bulk-insertion for SMS imports',
        'Planner Polish: Imported SMS transactions now match planned amount to reduce clutter',
        'Database Fix: Resolved column missing issue during schema migrations'
      ],
    ),
    ReleaseInfo(
      version: '1.0.4',
      date: '2026-02-18',
      changes: [
        'Rebranded "Spending Limit" to "Monthly Budget" across the app',
        'Simplified Registration: Removed username requirement for faster sign-up',
        'Enhanced UI: Improved visibility of budget adjustment inputs',
        'Updated deriving logic for automatic username generation'
      ],
    ),
    ReleaseInfo(
      version: '1.0.3',
      date: '2026-02-18',
      changes: [
        'Enhanced Analytics: Pie chart now shows dynamic percentage on interaction',
        'Fixed Pie chart rendering issues (100% glitch and single category bug)',
        'Improved SQL robustness for category aggregation',
        'Refined Regular Expenses: Fixed modal navigation context checks',
        'General stability improvements and bug fixes'
      ],
    ),
    ReleaseInfo(
      version: '1.0.2',
      date: '2026-02-18',
      changes: [
        'Rebranded "Bills" to "Regular Expenses" for better clarity (EMI, Rent, etc.)',
        'Updated Dashboard quick actions with "Regular" shortcut',
        'Enhanced Monthly Planner with prioritized unconfirmed expenses',
        'Refined Planned vs Unplanned logic for better clarity',
        'Fixed issue where editing unplanned expenses converted them to planned',
        'Improved UI: Unplanned expenses are locked correctly to avoid state confusion',
        'Fixed Null safety crash in Category details view',
        'Added Confirmed & Pending breakdown to Monthly Summary card',
        'Standardized transaction status labels across the app'
      ],
    ),
    ReleaseInfo(
      version: '1.0.1',
      date: '2026-02-18',
      changes: [
        'Refined Profile Screen with motivational quotes',
        'Standardized UI headers across analytics screens',
        'Integrated automatic & manual theme mode selection',
        'Improved SMS import to preserve original message content',
        'Fixed layout overflow and deprecated opacity calls',
        'Integrated in-app versioning and changelog'
      ],
    ),
    ReleaseInfo(
      version: '1.0.0',
      date: '2026-02-12',
      changes: [
        'Initial Release',
        'Core expense tracking and category management',
        'Local-first storage with SQLite'
      ],
    ),
  ];

  static List<String> get recentChanges => history.first.changes;
}
