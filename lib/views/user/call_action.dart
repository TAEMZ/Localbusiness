import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CallAction extends StatelessWidget {
  final String phone;

  const CallAction({super.key, required this.phone});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.phone, color: Colors.green),
      onPressed: () async {
        final Uri callUri = Uri(scheme: 'tel', path: phone);
        if (await canLaunchUrl(callUri)) {
          await launchUrl(callUri);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cannot place call')),
          );
        }
      },
      tooltip: 'Call',
    );
  }
}
