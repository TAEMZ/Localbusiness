import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

//not finfished the too part is not filled

class EmailAction extends StatelessWidget {
  final String fetchedEmail;

  const EmailAction({super.key, required this.fetchedEmail});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.email, color: Colors.red),
      onPressed: () async {
        // Construct the mailto URI with the fetched email in the "To" section
        final Uri emailUri = Uri(
          scheme: 'mailto',
          path: fetchedEmail, // Use fetched email for the "To" field
          queryParameters: {
            'subject': 'Your Subject', // Optional, specify if needed
            'body': 'Your email body content goes here.', // Optional
          },
        );

        // Check if the email client can be launched
        if (await canLaunchUrl(emailUri)) {
          await launchUrl(
              emailUri); // Open the email client with the "To" field filled
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cannot send email')),
          );
        }
      },
      tooltip: 'Email',
    );
  }
}
