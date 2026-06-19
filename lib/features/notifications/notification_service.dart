// ignore_for_file: avoid_print

import 'dart:io' show Platform;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class LocalNotificationHelper {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;
  static bool _permissionRequested = false;
  static bool _permissionGranted = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      requestProvisionalPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse res) {
        print('🔔 Notification tapped: ${res.payload}');
        if (res.payload != null) {
          _handleNotificationTap(res.payload!);
        }
      },
    );

    _isInitialized = true;
    print('✅ LocalNotificationHelper initialized');
  }

  static void _handleNotificationTap(String payload) {
    print('📱 Notification payload: $payload');
    // Navigate to ride details or appropriate screen
  }

  // Request permissions - called at app start
  static Future<bool> requestPermissions() async {
    // If already requested, return cached result
    if (_permissionRequested) {
      print('🔔 Permission already requested: $_permissionGranted');
      return _permissionGranted;
    }

    try {
      _permissionRequested = true;
      print('🔔 Requesting notification permissions...');

      // For iOS - use FlutterLocalNotificationsPlugin
      if (Platform.isIOS) {
        final plugin =
            _notificationsPlugin.resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>();

        if (plugin != null) {
          // Request permissions through the plugin
          final bool? result = await plugin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
            provisional: true,
          );

          _permissionGranted = result ?? false;
          print(
              '🔔 iOS permission result: ${_permissionGranted ? "GRANTED" : "DENIED"}');

          // Also request through Firebase Messaging for remote notifications
          await FirebaseMessaging.instance.requestPermission(
            alert: true,
            badge: true,
            sound: true,
            provisional: true,
          );

          return _permissionGranted;
        }
        return false;
      }

      // For Android
      if (Platform.isAndroid) {
        final status = await Permission.notification.status;
        print('🔔 Android permission status: $status');

        if (status == PermissionStatus.granted) {
          _permissionGranted = true;
          return true;
        }

        if (status == PermissionStatus.denied) {
          final result = await Permission.notification.request();
          _permissionGranted = result == PermissionStatus.granted;
          print(
              '🔔 Android permission result: ${_permissionGranted ? "GRANTED" : "DENIED"}');
          return _permissionGranted;
        }

        if (status == PermissionStatus.permanentlyDenied) {
          _permissionGranted = false;
          print('❌ Android permission permanently denied');
          return false;
        }

        _permissionGranted = false;
        return false;
      }

      // Fallback for other platforms
      return false;
    } catch (e) {
      print('❌ Error requesting notification permissions: $e');
      _permissionGranted = false;
      return false;
    }
  }

  // Check if permissions are granted without requesting
  static Future<bool> hasPermission() async {
    try {
      // For iOS - Use Firebase Messaging to check
      if (Platform.isIOS) {
        final settings =
            await FirebaseMessaging.instance.getNotificationSettings();
        print('🔔 iOS permission status: ${settings.authorizationStatus}');

        final bool hasPermission =
            settings.authorizationStatus == AuthorizationStatus.authorized ||
                settings.authorizationStatus == AuthorizationStatus.provisional;

        print('🔔 iOS has permission: $hasPermission');
        return hasPermission;
      }

      // For Android
      if (Platform.isAndroid) {
        final status = await Permission.notification.status;
        print('🔔 Android permission status: $status');
        return status == PermissionStatus.granted;
      }

      return false;
    } catch (e) {
      print('❌ Error checking permission: $e');
      return false;
    }
  }

  // Show notification
  static Future<bool> showNotification(
    String title,
    String body, {
    String? payload,
    int? id,
  }) async {
    // Check permission before showing
    final bool hasNotificationPermission = await hasPermission();
    if (!hasNotificationPermission) {
      print('❌ Notification permission not granted. Cannot show: $title');
      // Try to request permission again
      await requestPermissions();
      // Check again
      final bool retryPermission = await hasPermission();
      if (!retryPermission) {
        print('❌ Still no permission after retry. Cannot show: $title');
        return false;
      }
    }

    try {
      print('🔔 Showing notification: $title');

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'ride_requests_channel',
        'Ride Requests',
        channelDescription: 'Notifications for ride request updates',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        channelShowBadge: true,
        visibility: NotificationVisibility.public,
        icon: '@mipmap/ic_launcher',
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.active,
        threadIdentifier: 'ride_requests',
        categoryIdentifier: 'ride_request_category',
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final notificationId =
          id ?? DateTime.now().millisecondsSinceEpoch ~/ 1000;

      await _notificationsPlugin.show(
        notificationId,
        title,
        body,
        platformDetails,
        payload: payload,
      );

      print('✅ Notification shown successfully: $title');
      return true;
    } catch (e) {
      print('❌ Error showing notification: $e');
      return false;
    }
  }

  // Show dialog to enable notifications in settings
  static Future<void> showEnableNotificationDialog(BuildContext context) async {
    final bool hasNotificationPermission = await hasPermission();

    if (hasNotificationPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Notifications already enabled!'),
          backgroundColor: Colors.green,
        ),
      );
      return;
    }

    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.notifications_off, color: Colors.orange),
            SizedBox(width: 10),
            Text('Enable Notifications'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notifications help you stay updated about:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8),
            Text('• 🚘 Ride status updates'),
            Text('• 📍 Driver location tracking'),
            Text('• 💬 Ride request messages'),
            Text('• ⏰ Important ride alerts'),
            SizedBox(height: 12),
            Text(
              'Please enable notifications in your device settings.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Not Now'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await openAppSettings();
              // Check if permission was granted after returning
              final bool hasPermissionAfterSettings = await hasPermission();
              if (hasPermissionAfterSettings && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Notifications enabled!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            icon: const Icon(Icons.settings),
            label: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  // Cancel notifications
  static Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }
}
