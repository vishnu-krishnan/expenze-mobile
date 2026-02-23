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

    // 1. STRICTURE FILTERING: Exclude Non-Transaction Messages

    // Explicitly exclude Reminders and Bill Alerts
    final isReminder = lowerBody.contains('due date') ||
        lowerBody.contains('bill generated') ||
        lowerBody.contains('overdue') ||
        lowerBody.contains('pay by') ||
        lowerBody.contains('payment requested') ||
        lowerBody.contains('statement for') ||
        lowerBody.contains('upcoming') ||
        lowerBody.contains('min due') ||
        lowerBody.contains('minimum due') ||
        lowerBody.contains('total due') ||
        lowerBody.contains('outstanding') ||
        lowerBody.contains('reminder') ||
        lowerBody.contains('self transfer') ||
        lowerBody.contains('transfer to own') ||
        lowerBody.contains('transfer to self') ||
        lowerBody.contains('between own accounts') ||
        lowerBody.contains('to your own account');

    if (isReminder) return null;

    // Explicitly exclude Notifications (Login, OTP, Balance Inquiry)
    final isNotification = lowerBody.contains('otp is') ||
        lowerBody.contains('verification code') ||
        lowerBody.contains('logged in') ||
        lowerBody.contains('login') ||
        lowerBody.contains('successful login') ||
        lowerBody.contains('balance is') ||
        lowerBody.contains('available balance') ||
        lowerBody.contains('bal:') ||
        lowerBody.contains('avl bal') ||
        lowerBody.contains('blocked') ||
        lowerBody.contains('your account has been');

    // Also exclude common credit/income patterns (Income is not an Expense)
    final isCredit = lowerBody.contains('credited') ||
        lowerBody.contains('refund') ||
        lowerBody.contains('received') ||
        lowerBody.contains('reward') ||
        lowerBody.contains('cashback') ||
        lowerBody.contains('cr to');

    // 2. IDENTIFY DEBIT TRANSACTIONS
    // Must contain specific debit/payment markers
    final isDebit = lowerBody.contains('debited') ||
        lowerBody.contains('debit') ||
        lowerBody.contains('paid') ||
        lowerBody.contains('spent') ||
        lowerBody.contains('payment') ||
        lowerBody.contains('withdrawn') ||
        lowerBody.contains('dr to') ||
        lowerBody.contains('towards') ||
        lowerBody.contains('transfer to') ||
        lowerBody.contains('purc on') ||
        lowerBody.contains('purchased') ||
        lowerBody.contains('txn') ||
        lowerBody.contains('using upi') ||
        lowerBody.contains('sent to') ||
        lowerBody.contains('sent rs') ||
        lowerBody.contains('recharge') ||
        lowerBody.contains('recharged');

    // Logic: If it's a notification/credit but NOT a debit, ignore.
    // If it's a notification/credit AND a debit, we need to be very careful.
    // Usually, "credited" messages don't contain "debited".
    if (!isDebit ||
        isCredit ||
        (isNotification &&
            !(lowerBody.contains('debited') || lowerBody.contains('debit')))) {
      return null;
    }

    // Amount Extraction Patterns - Enhanced
    final amountPatterns = [
      // Standard formats: Rs 500.00, Rs. 500, Rs.500, INR 100, ₹100
      RegExp(r'(?:rs\.?|inr|₹|amt:?)\s*?([\d,]+\.?\d{0,2})',
          caseSensitive: false),
      // Specific debit phrases: "debited for Rs 100"
      RegExp(r'debited\s*(?:for|of)?\s*(?:rs\.?|inr|₹)?\s*?([\d,]+\.?\d{0,2})',
          caseSensitive: false),
      // Payment phrases: "Paid Rs 100"
      RegExp(r'paid\s*(?:rs\.?|inr|₹)?\s*?([\d,]+\.?\d{0,2})',
          caseSensitive: false),
      // Transaction phrases: "Txn of Rs 100"
      RegExp(
          r'txn\s*(?:of|for|amount)?\s*(?:rs\.?|inr|₹)?\s*?([\d,]+\.?\d{0,2})',
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
      // UPI VPA: "to [VPA]"
      RegExp(r'(?:to|at)\s+([a-zA-Z0-9.\-_]{3,25}@[a-zA-Z0-9.\-_]{3,25})',
          caseSensitive: false),
      // "Spent ... at/on [Merchant]"
      RegExp(
          r'(?:at|on|to)\s+([A-Za-z0-9\s&*_\-.]{3,40}?)(?:\s+on\s+card|\s+on\s+account|\s+ending|\s+via|\s+date|\s+ref|\s+txn|\.|\d)',
          caseSensitive: false),
      // "Debited for [Merchant]"
      RegExp(
          r'(?:for|info:)\s+([A-Za-z0-9\s&*_\-.]{3,40}?)(?:\s+on|\s+ref|\s+txn|\.|\d)',
          caseSensitive: false),
      // "Payment to [Merchant]"
      RegExp(
          r'payment\s+to\s+([A-Za-z0-9\s&*_\-.]{3,40}?)(?:\s+on|\s+ref|\s+txn|\.|\d)',
          caseSensitive: false),
      // Card usage: "Purchase of ... at [Merchant]"
      RegExp(
          r'purchase\s+of\s+.*?\s+at\s+([A-Za-z0-9\s&*_\-.]{3,40}?)(?:\s+on|\.|\d)',
          caseSensitive: false),
    ];

    String merchant = '';

    // 1. Look for VPA first (High confidence)
    final vpaMatch =
        RegExp(r'([a-zA-Z0-9.\-_]+@[a-zA-Z0-9.\-_]+)').firstMatch(body);
    if (vpaMatch != null) {
      merchant = vpaMatch.group(1)!;
    }

    if (merchant.isEmpty) {
      for (var pattern in merchantPatterns) {
        final match = pattern.firstMatch(body);
        if (match != null) {
          String val = match.group(1)!.trim();

          // Cleanup values
          val = val
              .replaceAll(
                  RegExp(r'\s+(on|at|for|ref|from|to|with|by|via|date)$',
                      caseSensitive: false),
                  '')
              .trim();

          // Filter out generic banking noise
          final lowerVal = val.toLowerCase();
          if (val.isNotEmpty &&
              val.length > 2 &&
              !lowerVal.contains('account') &&
              !lowerVal.contains('bank') &&
              !lowerVal.contains('xxxx') &&
              !lowerVal.contains('ending') &&
              !lowerVal.contains('balance') &&
              !lowerVal.contains('limit') &&
              !lowerVal.contains('wallet') &&
              !lowerVal.contains('card') &&
              !lowerVal.contains('debit') &&
              !lowerVal.contains('credit') &&
              !lowerVal.contains('your ac') &&
              !lowerVal.contains('reference') &&
              !lowerVal.contains('txn')) {
            // If looks like a VPA, keep it
            if (val.contains('@')) {
              merchant = val;
              break;
            }

            // If just text, verify it's not generic 'transaction'
            if (!lowerVal.contains('transaction') &&
                !lowerVal.contains('transfer')) {
              merchant = val;
              break;
            }
          }
        }
      }
    }

    if (merchant.isEmpty) {
      merchant = 'Transaction';
    }

    // Post-processing cleanup
    merchant = merchant.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (merchant.length > 35) merchant = merchant.substring(0, 35).trim();

    // Payment Mode Extraction
    String paymentMode = 'Other';
    if (lowerBody.contains('upi')) {
      paymentMode = 'UPI';
    } else if (lowerBody.contains('card') ||
        lowerBody.contains('pos txn') ||
        lowerBody.contains('ending in') ||
        lowerBody.contains('spent on')) {
      paymentMode = 'Card';
    } else if (lowerBody.contains('wallet') ||
        lowerBody.contains('paytm') ||
        lowerBody.contains('amazon pay')) {
      paymentMode = 'Wallet';
    } else if (lowerBody.contains('netbanking') ||
        lowerBody.contains('online banking') ||
        lowerBody.contains('imps') ||
        lowerBody.contains('neft')) {
      paymentMode = 'Net Banking';
    }

    return {
      'amount': amount,
      'merchant': merchant,
      'payment_mode': paymentMode,
      'raw': body,
    };
  }
}
