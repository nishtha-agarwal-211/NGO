import 'package:url_launcher/url_launcher.dart';

/// Utility methods for WhatsApp quick messaging, calls, and SMS.
class CommunicationUtils {
  CommunicationUtils._();

  /// Clean phone number to standard format (defaulting to +91 if 10 digits without country code).
  static String formatPhoneForWhatsApp(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length == 10) {
      return '91$cleaned';
    }
    return cleaned;
  }

  /// Launch WhatsApp with an optional pre-filled message.
  static Future<bool> openWhatsApp({
    required String phone,
    String? message,
  }) async {
    final formattedPhone = formatPhoneForWhatsApp(phone);
    final encodedMessage = message != null ? Uri.encodeComponent(message) : '';
    final uri = Uri.parse('https://wa.me/$formattedPhone?text=$encodedMessage');

    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  /// Send personalized birthday wish to member.
  static Future<bool> sendBirthdayWish({
    required String name,
    required String phone,
  }) {
    final message = '''
🎉 Happy Birthday $name! 🎂✨

On behalf of श्री श्याम सेवा समिति, we wish you a joyful birthday filled with health, happiness, and prosperity! Thank you for your support and dedication to our cause. 🙏

Regards,
Shree Shyam Seva Samiti
''';
    return openWhatsApp(phone: phone, message: message);
  }

  /// Send personalized wedding anniversary wish to member.
  static Future<bool> sendAnniversaryWish({
    required String name,
    required String phone,
  }) {
    final message = '''
💐 Happy Wedding Anniversary $name! ✨

Wishing you and your spouse a lifetime of togetherness, peace, and joy. Thank you for being a cherished part of श्री श्याम सेवा समिति! 🙏

Warm Regards,
Shree Shyam Seva Samiti
''';
    return openWhatsApp(phone: phone, message: message);
  }

  /// Send donation receipt/acknowledgment to donor.
  static Future<bool> sendDonationReceipt({
    required String donorName,
    required String phone,
    required String amountOrItem,
    String? projectName,
    String? dateStr,
  }) {
    final projectInfo = projectName != null && projectName.isNotEmpty ? ' towards "$projectName"' : '';
    final dateInfo = dateStr != null && dateStr.isNotEmpty ? ' on $dateStr' : '';

    final message = '''
🙏 Thank You $donorName!

श्री श्याम सेवा समिति gratefully acknowledges your contribution of $amountOrItem$projectInfo$dateInfo.

Your generosity directly helps us serve those in need. May Lord Shyam bless you and your family! 🌺

Warm Regards,
Shree Shyam Seva Samiti
''';
    return openWhatsApp(phone: phone, message: message);
  }

  /// Direct phone call shortcut.
  static Future<bool> makePhoneCall(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone.trim());
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri);
    }
    return false;
  }

  /// Direct SMS shortcut.
  static Future<bool> sendSms(String phone, {String? body}) async {
    final uri = Uri(
      scheme: 'sms',
      path: phone.trim(),
      queryParameters: body != null ? {'body': body} : null,
    );
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri);
    }
    return false;
  }
}
