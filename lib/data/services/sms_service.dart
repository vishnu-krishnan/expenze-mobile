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

  Future<List<SmsMessage>> getRecentSms({int limit = 100}) async {
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
    if (body.isEmpty) return null;

    final lowerBody = body.toLowerCase();

    // Check if it's a debit/payment message
    final isDebit = lowerBody.contains('debited') ||
        lowerBody.contains('paid') ||
        lowerBody.contains('spent') ||
        lowerBody.contains('payment') ||
        lowerBody.contains('withdrawn') ||
        lowerBody.contains('dr to') ||
        lowerBody.contains('transfer to');

    if (!isDebit) return null;

    // Amount Extraction Patterns
    final amountPatterns = [
      RegExp(
          r'(?:rs\.?|inr|₹|debited for rs|spent rs|amt:)\s*?([\d,]+(?:\.\d{1,2})?)',
          caseSensitive: false),
      RegExp(r'vpa.*?\s([\d,]+(?:\.\d{1,2})?)', caseSensitive: false),
      RegExp(r'debited.*?([\d,]+(?:\.\d{1,2})?)', caseSensitive: false),
    ];

    double? amount;
    for (var pattern in amountPatterns) {
      final match = pattern.firstMatch(body);
      if (match != null) {
        try {
          amount = double.parse(match.group(1)!.replaceAll(',', ''));
          break;
        } catch (_) {}
      }
    }

    if (amount == null || amount <= 0) return null;

    // Merchant Extraction Patterns
    final merchantPatterns = [
      RegExp(
          r'(?:to|at|for|from|merchant:?|vpa|info:)\s+([A-Za-z0-9\s&*_\-.]{3,30})',
          caseSensitive: false),
      RegExp(r'(?:debited to)\s+([A-Za-z0-9\s&*]{3,30})', caseSensitive: false),
      RegExp(r'([A-Za-z0-9\s&*]{3,20})\s+ref', caseSensitive: false),
    ];

    String merchant = 'Unknown Merchant';
    for (var pattern in merchantPatterns) {
      final match = pattern.firstMatch(body);
      if (match != null) {
        final val = match.group(1)!.trim();
        if (val.isNotEmpty &&
            !val.toLowerCase().contains('debit') &&
            !val.toLowerCase().contains('credit')) {
          merchant = val;
          break;
        }
      }
    }

    // Clean merchant name
    merchant = merchant.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (merchant.length > 25) merchant = merchant.substring(0, 25).trim();

    return {
      'amount': amount,
      'merchant': merchant,
      'raw': body,
    };
  }
}
