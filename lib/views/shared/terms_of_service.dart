import 'package:flutter/material.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms of Service')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Last Updated: March 29, 2025\n',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              '1. Acceptance of Terms\n',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'By using this application, you agree to be bound by these terms and conditions.',
            ),
            SizedBox(height: 16),
            Text(
              '2. User Responsibilities\n',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'You agree to use the app only for lawful purposes and in a way that does not infringe the rights of others.',
            ),
            SizedBox(height: 16),
            Text(
              '3. Privacy Policy\n',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Your data will be handled according to our Privacy Policy. We collect minimal information necessary for app functionality.',
            ),
            SizedBox(height: 16),
            Text(
              '4. Limitation of Liability\n',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'We are not liable for any indirect, incidental, or consequential damages arising from your use of the app.',
            ),
          ],
        ),
      ),
    );
  }
}
