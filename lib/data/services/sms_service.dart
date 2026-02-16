import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';

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

  Future<List<SmsMessage>> getRecentSms({int limit = 50}) async {
    bool granted = await Permission.sms.isGranted;
    if (!granted) {
      granted = await requestPermissions();
    }

    if (!granted) return [];

    try {
      return await _query.querySms(
        count: limit,
        kinds: [SmsQueryKind.inbox],
      );
    } catch (e) {
      logger.e('Error fetching SMS: $e');
      return [];
    }
  }

  Map<String, dynamic>? parseExpenseFromSms(String body) {
    // Regex for Amount (₹, Rs, INR)
    final amountRegex = RegExp(
        r'(?:Rs\.?|INR|₹|debited for Rs|spent Rs)\s*?([\d,]+(?:\.\d{2})?)',
        caseSensitive: false);
    final amountMatch = amountRegex.firstMatch(body);

    if (amountMatch == null) return null;

    final amount = double.parse(amountMatch.group(1)!.replaceAll(',', ''));

    // Regex for Merchant
    final merchantRegex = RegExp(
        r'(?:at|to|for|from|merchant:?|vpa)\s+([A-Z0-9\s&]{3,24})',
        caseSensitive: false);
    final merchantMatch = merchantRegex.firstMatch(body);
    final merchant = merchantMatch != null
        ? merchantMatch.group(1)!.trim()
        : 'Unknown Merchant';

    // Filter out messages that don't look like debits/spends
    final isExpense =
        RegExp(r'(debited|spent|paid|payment|withdrawn)', caseSensitive: false)
            .hasMatch(body);

    if (!isExpense) return null;

    return {
      'amount': amount,
      'merchant': merchant,
      'raw': body,
    };
  }
}
