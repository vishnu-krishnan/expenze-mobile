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
  static const String current = '1.0.2';
  static const String buildNumber = '3';
  static const String releaseName = 'Planner & Stability Update';

  static const List<ReleaseInfo> history = [
    ReleaseInfo(
      version: '1.0.2',
      date: '2026-02-18',
      changes: [
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
