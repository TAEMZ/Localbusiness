import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseNotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Request Notification Permissions (iOS)
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print("✅ Push notifications permission granted.");
    } else {
      print("❌ Push notifications permission denied.");
    }

    // Get FCM Token
    String? token = await messaging.getToken();
    print("📲 FCM Token: $token");

    // Handle Foreground Notifications (Only show if not the creator)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print(
          "📩 Received foreground notification: ${message.notification?.title}");

      bool shouldNotify = await _shouldReceiveNotification(message.data);
      if (shouldNotify) {
        _showLocalNotification(message.notification);
      }
    });

    // Handle Notification Click
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      print("📩 User clicked on notification.");

      bool shouldNavigate = await _shouldReceiveNotification(message.data);
      if (shouldNavigate) {
        _handleNotificationClick(message.data);
      }
    });

    // Initialize Local Notifications
    const AndroidInitializationSettings androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings =
        InitializationSettings(android: androidInitSettings);
    await _localNotifications.initialize(initSettings);
  }

  /// ✅ **Checks if the current user should receive the notification**
  static Future<bool> _shouldReceiveNotification(
      Map<String, dynamic> data) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return false; // No user logged in

    final String? businessId = data['businessId'];
    if (businessId == null) return true; // No business ID, allow notification

    try {
      final businessDoc = await FirebaseFirestore.instance
          .collection('businesses')
          .doc(businessId)
          .get();
      final String? creatorId = businessDoc.data()?['creatorId'];

      if (creatorId == user.uid) {
        print("🚫 Notification blocked for creator.");
        return false; // Creator should not receive the notification
      }
    } catch (e) {
      print("❌ Error checking business creator: $e");
    }

    return true; // Allow notification for other users
  }

  /// ✅ **Shows a local notification**
  static Future<void> _showLocalNotification(
      RemoteNotification? notification) async {
    if (notification == null) return;

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'default_channel',
      'General Notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      0,
      notification.title,
      notification.body,
      platformDetails,
    );
  }

  /// ✅ **Handles notification clicks (Navigation)**
  static void _handleNotificationClick(Map<String, dynamic> data) {
    print("Navigating to: ${data['businessId']}");
    // TODO: Implement navigation to business details page
  }

  /// ✅ **Subscribes to an FCM topic**
  static void subscribeToTopic(String topic) async {
    await FirebaseMessaging.instance.subscribeToTopic(topic);
    print("✅ Subscribed to topic: $topic");
  }
}
