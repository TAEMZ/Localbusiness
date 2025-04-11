import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class SendNotification {
  static Future<void> sendNotificationToServer(
      Map<String, dynamic> businessData, String businessId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final Uri serverUrl =
          Uri.parse('https://localbusinesnode.vercel.app/api/send');

      final response = await http.post(
        serverUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': 'New Business Added!',
          'message':
              '${businessData['name']} is now open in ${businessData['city']}! Check it out.',
          'category': 'business_updates',
          'businessId': businessId,
          'creator_id': user?.uid,
        }),
      );

      if (response.statusCode == 200) {
        print("✅ Notification sent successfully!");
      } else {
        print("❌ Failed to send notification: ${response.body}");
      }
    } catch (e) {
      print("error notificatoin sending:$e");
    }
  }
}
