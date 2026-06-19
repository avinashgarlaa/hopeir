import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hop_eir/features/notifications/notification_service.dart';
import 'package:hop_eir/splash_screen.dart';
import 'firebase_options.dart';

void main() async {
  // 1. Ensure widgets binding
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Get FCM token

  // 3. Initialize notifications
  await LocalNotificationHelper.initialize();

  // 4. Request and store permission result
  final hasPermission = await LocalNotificationHelper.requestPermissions();
  print('🔔 Notification permission at start: $hasPermission');

  // 5. Setup background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 6. Run the app
  runApp(const ProviderScope(child: MyApp()));
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase in background
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize notifications in background
  await LocalNotificationHelper.initialize();

  // Show notification
  await LocalNotificationHelper.showNotification(
    message.notification?.title ?? 'HopEir',
    message.notification?.body ?? 'You have a new notification',
    payload: message.data['rideId']?.toString(),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupForegroundNotifications();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissionOnResume();
    }
  }

  Future<void> _checkPermissionOnResume() async {
    final hasPermission = await LocalNotificationHelper.hasPermission();
    if (hasPermission) {
      print('✅ Notification permission granted!');
    }
  }

  void _setupForegroundNotifications() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      LocalNotificationHelper.showNotification(
        message.notification?.title ?? 'HopEir',
        message.notification?.body ?? 'You have a new notification',
        payload: message.data['rideId']?.toString(),
      );
    });

    // Handle when app is opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final rideId = message.data['rideId'];
      if (rideId != null) {
        print('📱 Opened from notification with rideId: $rideId');
        // Navigate to ride details
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HopEir',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Poppins',
      ),
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}
