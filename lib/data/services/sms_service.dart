import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';
import '../../core/constants/sms_exclusion_keywords.dart';

class SmsService {
  final SmsQuery _query = SmsQuery();
  final logger = Logger();

  static final SmsService _instance = SmsService._internal();
  factory SmsService() => _instance;
  SmsService._internal();

  Future<bool> requestPermissions() async {
    final status = await Permission.sms.request();
    return status.isGranted;
  }

  Future<List<SmsMessage>> getRecentSms({int months = 6}) async {
    bool granted = await Permission.sms.isGranted;
    if (!granted) {
      granted = await requestPermissions();
    }

    if (!granted) return [];

    try {
      final messages = await _query.querySms(
        count: 10000,
        kinds: [SmsQueryKind.inbox],
      );

      final cutoffDate = DateTime.now().subtract(Duration(days: months * 30));
      final filtered = messages.where((m) {
        if (m.date == null) return false;
        return m.date!.isAfter(cutoffDate);
      }).toList();

      filtered.sort(
          (a, b) => (b.date ?? DateTime(0)).compareTo(a.date ?? DateTime(0)));
      return filtered;
    } catch (e) {
      logger.e('Error fetching SMS: $e');
      return [];
    }
  }

  Map<String, dynamic>? parseExpenseFromSms(String body) {
    if (body.isEmpty) return null;
    final lowerBody = body.toLowerCase();

    // 1. Mandatory Security/OTP Filter (Earliest escape)
    for (final word in SmsExclusionKeywords.securityAlerts) {
      if (lowerBody.contains(word)) return null;
    }
    if (RegExp(r'\b\d{4,6}\s+is\s+your\b').hasMatch(lowerBody)) return null;

    // 2. Credits & Repayments Filter (Avoid Income/Double Counting)
    for (final word in SmsExclusionKeywords.credits) {
      if (lowerBody.contains(word)) return null;
    }
    for (final word in SmsExclusionKeywords.repayments) {
      if (lowerBody.contains(word)) return null;
    }

    // 3. Reminders & Statement Filter
    for (final word in SmsExclusionKeywords.remindersAndBills) {
      if (lowerBody.contains(word)) return null;
    }

    // 4. Failed Transactions
    for (final word in SmsExclusionKeywords.failed) {
      if (lowerBody.contains(word)) return null;
    }

    // 5. Broad Intent Detection (Is it actually a financial activity?)
    final isDebit = lowerBody.contains('spent') ||
        lowerBody.contains('debited') ||
        lowerBody.contains('paid') ||
        lowerBody.contains('txn') ||
        lowerBody.contains('transaction') ||
        lowerBody.contains('payment') ||
        lowerBody.contains('transfer') ||
        lowerBody.contains('sent to');

    final hasCurrency = lowerBody.contains('rs') ||
        lowerBody.contains('inr') ||
        lowerBody.contains('₹') ||
        RegExp(r'(?:rs|inr|₹)\s*\d+').hasMatch(lowerBody);

    // If it passed all filters AND looks like a transaction, send to AI
    if (isDebit || hasCurrency) {
      return {'body': body};
    }
    return null;
  }
}
