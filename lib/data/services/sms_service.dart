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

  Future<List<SmsMessage>> getRecentSms({int months = 6}) async {
    bool granted = await Permission.sms.isGranted;
    if (!granted) {
      granted = await requestPermissions();
    }

    if (!granted) return [];

    try {
      // Fetch a large enough sample. 6 months could be a lot.
      // We take a higher count and filter by date.
      final messages = await _query.querySms(
        count: 1000, // Adjusted to a larger sample
        kinds: [SmsQueryKind.inbox],
      );

      final cutoffDate = DateTime.now().subtract(Duration(days: months * 30));
      return messages.where((m) {
        if (m.date == null) return false;
        return m.date!.isAfter(cutoffDate);
      }).toList();
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
        lowerBody.contains('transfer to') ||
        lowerBody.contains('txn') ||
        lowerBody.contains('purchased') ||
        lowerBody.contains('upi') ||
        lowerBody.contains('bank ac');

    // Also exclude common credit/refund patterns
    final isCredit = lowerBody.contains('credited') ||
        lowerBody.contains('refund') ||
        lowerBody.contains('received') ||
        lowerBody.contains('cashback');

    if (!isDebit || isCredit) return null;

    // Amount Extraction Patterns - Enhanced
    final amountPatterns = [
      // Standard formats: Rs 500.00, Rs. 500, Rs.500
      RegExp(r'(?:rs\.?|inr|₹|amt:?)\s*?([\d,]+\.?\d{0,2})',
          caseSensitive: false),
      // Specific debit phrases
      RegExp(r'debited\s*(?:for|of)?\s*(?:rs\.?|inr|₹)?\s*?([\d,]+\.?\d{0,2})',
          caseSensitive: false),
      // Payment phrases
      RegExp(r'paid\s*(?:rs\.?|inr|₹)?\s*?([\d,]+\.?\d{0,2})',
          caseSensitive: false),
      // UPI and VPA patterns
      RegExp(r'transferred\s*(?:rs\.?|inr|₹)?\s*?([\d,]+\.?\d{0,2})',
          caseSensitive: false),
    ];

    double? amount;
    for (var pattern in amountPatterns) {
      final match = pattern.firstMatch(body);
      if (match != null) {
        try {
          final rawAmount = match.group(1)!.replaceAll(',', '');
          amount = double.parse(rawAmount);
          if (amount > 0) break;
        } catch (_) {}
      }
    }

    if (amount == null || amount <= 0) return null;

    // Merchant Extraction Patterns - Enhanced
    final merchantPatterns = [
      // To [Merchant]
      RegExp(
          r'(?:to|paid to|spent on|at|info:|at:)\s+([A-Za-z0-9\s&*_\-.]{3,40}?)(?:\s+on|\s+ref|\s+from|\s+dated|\s+at|\s+using|\.|\d)',
          caseSensitive: false),
      // Merchant: [Name]
      RegExp(r'(?:merchant:?|vpa:?)\s*([A-Za-z0-9\s&*_\-.]{3,40})',
          caseSensitive: false),
      // Text between debited to and [date/ref]
      RegExp(
          r'debited\s+to\s+([A-Za-z0-9\s&*]{3,40})(?:\s+on|\s+ref|\s+dated|\s+at)',
          caseSensitive: false),
      // Start of message mentions
      RegExp(r'([A-Za-z0-9\s&*]{3,25})\s+(?:ref|txn|id)', caseSensitive: false),
    ];

    String merchant = '';
    for (var pattern in merchantPatterns) {
      final match = pattern.firstMatch(body);
      if (match != null) {
        String val = match.group(1)!.trim();

        // Remove trailing prepositions/filler words
        val = val
            .replaceAll(
                RegExp(r'\s+(on|at|for|ref|from|to)$', caseSensitive: false),
                '')
            .trim();

        if (val.isNotEmpty &&
            val.length > 2 &&
            !val.toLowerCase().contains('account') &&
            !val.toLowerCase().contains('bank') &&
            !val.toLowerCase().contains('debit') &&
            !val.toLowerCase().contains('credit') &&
            !val.toLowerCase().contains('balance')) {
          merchant = val;
          break;
        }
      }
    }

    if (merchant.isEmpty) {
      // Fallback: look for VPA or common identifiers
      final vpaMatch =
          RegExp(r'([a-zA-Z0-9.\-_]+@[a-zA-Z0-9.\-_]+)').firstMatch(body);
      if (vpaMatch != null) {
        merchant = vpaMatch.group(1)!;
      } else {
        merchant = 'Transaction';
      }
    }

    // Post-processing cleanup
    merchant = merchant.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (merchant.length > 30) merchant = merchant.substring(0, 30).trim();

    return {
      'amount': amount,
      'merchant': merchant,
      'raw': body,
    };
  }
}
