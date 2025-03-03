import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class EmailAction extends StatelessWidget {
  final String fetchedEmail;

  const EmailAction({required this.fetchedEmail});

  static void launchEmail({
    required String toEmail,
    required String subject,
    required String body,
  }) async {
    // Encode the subject and body to handle special characters
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: toEmail, // Business email goes here
      queryParameters: {
        'subject': Uri.encodeComponent(subject), // Encode subject
        'body': Uri.encodeComponent(body), // Encode body
      },
    );

    // Launch the email client
    if (await canLaunch(emailUri.toString())) {
      await launch(emailUri.toString());
    } else {
      throw 'Could not launch email';
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.email, color: Colors.blue),
      onPressed: () {
        launchEmail(
          toEmail: fetchedEmail, // Business email (creator email)
          subject: 'Regarding Your Business',
          body: 'Hello, I would like to inquire about...',
        );
      },
    );
  }
}
