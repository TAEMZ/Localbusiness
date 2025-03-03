import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CallAction {
  final String phone;

  const CallAction({required this.phone});

  static void launchCaller(String phone) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phone);

    if (await canLaunch(phoneUri.toString())) {
      await launch(phoneUri.toString());
    } else {
      throw 'Could not launch phone call';
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.call, color: Colors.green),
      onPressed: () {
        launchCaller(phone);
      },
    );
  }
}
