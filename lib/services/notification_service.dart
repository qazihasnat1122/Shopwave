import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> initialize() async {
    // Request permission
    await _messaging.requestPermission(
      alert: true, badge: true, sound: true,
    );

    // Get and save FCM token
    final token = await _messaging.getToken();
    if (token != null) await _saveToken(token);

    // Listen for token refresh
    _messaging.onTokenRefresh.listen(_saveToken);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background tap
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);
  }

  Future<void> _saveToken(String token) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    await _db.collection('users').doc(userId).update({
      'fcmTokens': FieldValue.arrayUnion([token]),
      'lastTokenUpdate': FieldValue.serverTimestamp(),
    });
  }

  void _handleForegroundMessage(RemoteMessage message) {
    // Show local notification using flutter_local_notifications
    // (integrate as needed)
    debugPrint('Foreground notification: ${message.notification?.title}');
  }

  void _handleMessageTap(RemoteMessage message) {
    final data = message.data;
    // Navigate based on notification type
    // e.g., if (data['type'] == 'order') navigate to order detail
    debugPrint('Notification tapped: $data');
  }

  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }
}
