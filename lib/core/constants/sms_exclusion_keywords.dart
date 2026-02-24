class SmsExclusionKeywords {
  // 1. Transactional Credits (Ignore these as they are income/refunds)
  static const List<String> credits = [
    'credited',
    'added',
    'received',
    'refund',
    'cashback',
    'deposited',
    'credit',
  ];

  // 2. Reminders, Statements & Bills (Not actual completed transactions)
  static const List<String> remindersAndBills = [
    'due date',
    'outstanding',
    'min due',
    'reminder',
    'total due',
    'bill generated',
    'statement',
    'upcoming',
    'will be debited',
    'is scheduled',
    'requested',
  ];

  // 3. Repayments & Credit Card Bill Payments (Double-counting protection)
  static const List<String> repayments = [
    'payment towards credit card',
    'cc bill payment',
    'repayment',
    'bill settled',
    'card payment received',
    'thank you for paying',
  ];

  // 4. Security & Authentication (Non-financial noise)
  static const List<String> securityAlerts = [
    'otp',
    'one time password',
    'verification code',
    'login',
    'pswd',
    'password',
    'blocked',
    'limit increase',
    'balance inquiry',
    'account balance',
    'avail bal',
  ];

  // 5. Failed Transactions
  static const List<String> failed = [
    'failed',
    'declined',
    'rejected',
    'insufficient funds',
  ];

  // 6. Generic Noise
  static const List<String> noise = [
    'thank you for using',
    'bank updates',
    'rate this',
    'download app',
  ];

  // Helper method to get all exclusion keywords for AI Context
  static String getAIExclusionSummary() {
    return '''
1. Credits: ${credits.join(", ")}
2. Reminders & Bills: ${remindersAndBills.join(", ")}
3. Repayments (Double-Counting): ${repayments.join(", ")}
4. Alerts: ${securityAlerts.join(", ")}
5. Failed: ${failed.join(", ")}
6. Generic Noise: ${noise.join(", ")}
''';
  }
}
