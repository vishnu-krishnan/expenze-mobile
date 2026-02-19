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
  static const String current = '1.0.6';
  static const String buildNumber = '7';
  static const String releaseName = 'Stability & UI Polish';

  static const List<ReleaseInfo> history = [
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
