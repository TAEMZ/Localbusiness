import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:logger/logger.dart';

final Logger _logger = Logger();

class ShareService {
  static Future<void> shareBusiness({
    required String name,
    required String description,
    required String phone,
    required String category,
    required BuildContext context,
  }) async {
    try {
      await Share.share(
        _buildShareMessage(
          name: name,
          description: description,
          phone: phone,
          category: category,
        ),
        subject: 'Check out $name',
      );
    } catch (e, stackTrace) {
      _logger.e('Error sharing business', error: e, stackTrace: stackTrace);
      _showErrorSnackbar(context, 'Failed to share business');
    }
  }

  static String _buildShareMessage({
    required String name,
    required String description,
    required String phone,
    required String category,
  }) {
    return '''
🌟 ${_sanitizeText(name)} 🌟

📌 Category: ${_sanitizeText(category)}
📞 Phone: ${_sanitizePhone(phone)}

📝 About: 
${_sanitizeText(description).length > 150 ? '${_sanitizeText(description).substring(0, 150)}...' : _sanitizeText(description)}

📍 Find more businesses on our app:
👉 https://play.google.com/store/apps/
''';
  }

  static String _sanitizeText(String text) =>
      text.replaceAll(RegExp(r'[\n\r\t]'), ' ').trim();

  static String _sanitizePhone(String phone) =>
      phone.replaceAll(RegExp(r'[^0-9+]'), '').trim();

  static void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
