import 'dart:math';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../core/utils/logger.dart';

class EmailService {
  static final EmailService _instance = EmailService._internal();

  factory EmailService() {
    return _instance;
  }

  EmailService._internal();

  String _generateOtp() {
    final rnd = Random.secure();
    final otp = rnd.nextInt(900000) + 100000; // Generates a 6-digit number
    return otp.toString();
  }

  Future<String?> sendVerificationCode(String toEmail, String userName) async {
    final emailUser = dotenv.env['EMAIL_USER'];
    final emailPass = dotenv.env['EMAIL_PASS'];

    if (emailUser == null || emailPass == null) {
      logger.e("SMTP credentials missing from .env");
      throw Exception("Email configuration error.");
    }

    final smtpServer = gmail(emailUser, emailPass);
    final otp = _generateOtp();

    final message = Message()
      ..from = Address(emailUser, 'Expenze System')
      ..recipients.add(toEmail)
      ..subject = 'Expenze Verification OTP'
      ..text = 'Dear $userName,\n\n'
          'Your OTP for verification is: $otp\n'
          'This code expires in 5 minutes.\n\n'
          'Best Regards,\nExpenze Team'
      ..html = '<h3>Dear $userName,</h3>\n'
          '<p>Your OTP for verification is: <strong>$otp</strong></p>\n'
          '<p>This code expires in 5 minutes.</p>\n'
          '<br><p>Best Regards,<br>Expenze Team</p>';

    try {
      final sendReport = await send(message, smtpServer);
      logger.i('Message sent: $sendReport');
      return otp;
    } on MailerException catch (e) {
      logger.e('Message not sent.', error: e);
      for (var p in e.problems) {
        logger.e('Problem: ${p.code}: ${p.msg}');
      }
      throw Exception("Failed to send verification email. Please try again.");
    } catch (e) {
      logger.e('Failed to send email: ', error: e);
      throw Exception("Failed to send verification email. Please try again.");
    }
  }
}
