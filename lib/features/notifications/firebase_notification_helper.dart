import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class FirebaseNotificationHelper {
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // Android settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS settings
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    // Final init settings
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Initialize local notification plugin
    await _localNotificationsPlugin.initialize(initSettings);

    // Foreground notification listener
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleMessage(message);
    });
  }

  static void _handleMessage(RemoteMessage message) {
    if (message.notification != null) {
      final title = message.notification!.title ?? '📢 Notification';
      final body = message.notification!.body ?? 'You have a new update.';

      final androidDetails = AndroidNotificationDetails(
        'default_channel',
        'General Notifications',
        channelDescription: 'This channel is used for general notifications.',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
      );

      const iosDetails = DarwinNotificationDetails();

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      _localNotificationsPlugin.show(
        message.hashCode,
        title,
        body,
        notificationDetails,
      );
    }
  }

  /// Call this to get and print FCM token
  static Future<void> printFcmToken() async {
    final token = await FirebaseMessaging.instance.getToken();
    debugPrint('📲 FCM Token: $token');
  }
}
