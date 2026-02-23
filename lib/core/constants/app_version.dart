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
  static const String current = '1.3.0';
  static const String buildNumber = '10';
  static const String releaseName = 'AI-Powered SMS Import';

  static const List<ReleaseInfo> history = [
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
