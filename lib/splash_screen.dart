// ignore_for_file: avoid_print

import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hop_eir/features/auth/presentation/pages/login_screen.dart';
import 'package:hop_eir/features/auth/presentation/providers/auth_provider.dart';
import 'package:hop_eir/features/notifications/notification_service.dart';
import 'package:hop_eir/features/requests/domain/entities/ride_request.dart';
import 'package:hop_eir/features/requests/presentation/controllers/passanger_ride_ws_controller.dart';
import 'package:hop_eir/features/requests/presentation/controllers/ride_request_ws_controller.dart';
import 'package:hop_eir/features/rides/presentation/controllers/ride_ws_controller.dart';
import 'package:hop_eir/features/rides/presentation/providers/ride_provider.dart';
import 'package:hop_eir/features/vehicles/presentation/provider/vehicle_providers.dart';
import 'package:hop_eir/main_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final AnimationController _textController;
  late final AnimationController _shimmerController;
  late final Animation<double> _logoScaleAnimation;
  late final Animation<double> _textFadeInAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _logoScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.6, end: 1.1)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 70,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.1, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 30,
      ),
    ]).animate(_logoController);

    _textFadeInAnimation = CurvedAnimation(
      parent: _textController,
      curve: Curves.easeIn,
    );
  }

  Future<void> _startAnimations() async {
    try {
      await _logoController.forward();
      await Future.delayed(const Duration(milliseconds: 400));
      await _textController.forward();
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;
      await _handleAuthenticationAndSetup();
    } catch (e) {
      debugPrint("❌ Animation error: $e");
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  Future<void> _handleAuthenticationAndSetup() async {
    try {
      final container = ProviderScope.containerOf(context, listen: false);
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('user_email');
      final password = prefs.getString('user_password');

      debugPrint("📧 Cached email: $email");

      if (email == null || password == null) {
        _navigateToLogin();
        return;
      }

      // Attempt login
      final authNotifier = container.read(authNotifierProvider.notifier);
      await authNotifier.checkLoginStatus(email, password, context);

      final user = container.read(authNotifierProvider).user;

      if (user == null || user.userId.isEmpty) {
        _navigateToLogin();
        return;
      }

      debugPrint("✅ Logged in as user ID: ${user.userId}");

      // Setup user data
      await _setupUserData(container, user);

      // Setup WebSocket connections
      await _setupWebSocketConnections(container, user);

      if (!mounted) return;
      _navigateToMainScreen();
    } catch (e, st) {
      debugPrint("❌ Error during authentication: $e\n$st");
      if (mounted) {
        _navigateToLogin();
      }
    }
  }

  Future<void> _setupUserData(ProviderContainer container, dynamic user) async {
    try {
      await container
          .read(vehicleControllerProvider.notifier)
          .fetchVehicleByUserId(user.userId);
      debugPrint("✅ Vehicle data loaded");
    } catch (e) {
      debugPrint("⚠️ Vehicle fetch failed: $e");
    }
  }

  Future<void> _setupWebSocketConnections(
      ProviderContainer container, dynamic user) async {
    // Setup ride requests WebSocket listener
    await _setupRideRequestsListener(container, user);

    // Setup driver rides
    await _setupDriverRides(container, user);

    // Setup passenger accepted rides
    await _setupPassengerRides(container, user);
  }

  Future<void> _setupRideRequestsListener(
      ProviderContainer container, dynamic user) async {
    final requestWSProvider = rideRequestWSControllerProvider(user.userId);
    bool initialSyncDone = false;
    List<RideRequest> previousRequests = [];
    final Set<int> passengerWSConnectedRideIds = {};

    Future<void> triggerPassengerRideWS(int rideId) async {
      if (passengerWSConnectedRideIds.contains(rideId)) return;

      if (isRideFinalCached(rideId)) {
        debugPrint("🔒 Passenger ride #$rideId already final (cached)");
        passengerWSConnectedRideIds.add(rideId);
        return;
      }

      passengerWSConnectedRideIds.add(rideId);

      try {
        container.read(passengerRideWSProvider(rideId).notifier);
        debugPrint("🚀 Triggered PassengerRideWSController for ride: $rideId");
        container.read(rideWSControllerProvider(rideId).notifier).connect();
      } catch (e) {
        debugPrint("❌ Error triggering passenger ride #$rideId: $e");
      }
    }

    container.listen<RideRequestWSState>(
      requestWSProvider,
      (prev, next) async {
        final currentRequests = next.incomingRequests;

        if (!initialSyncDone) {
          initialSyncDone = true;
          previousRequests = List.from(currentRequests);
          debugPrint("🛑 Skip notifications for initial_state sync");
          return;
        }

        final oldMap = {for (var r in previousRequests) r.id: r};

        for (final r in currentRequests) {
          final old = oldMap[r.id];
          if (old == null) continue;

          final oldStatus = old.status.toLowerCase();
          final newStatus = r.status.toLowerCase();

          if (oldStatus != newStatus) {
            final isDriver = r.passengerId != user.userId;

            LocalNotificationHelper.showNotification(
              isDriver
                  ? '🔁 Ride Request Updated'
                  : '📢 Request Status Updated',
              '${isDriver ? "Request from ${r.passengerName}" : "Your request"} is now ${r.status.toUpperCase()}',
            );

            if (!isDriver && newStatus == "accepted") {
              LocalNotificationHelper.showNotification(
                '✅ Ride Accepted',
                'Driver accepted your request. Ride tracking started.',
              );
              await triggerPassengerRideWS(r.rideId);
            }
          }
        }

        previousRequests = List.from(currentRequests);
      },
      fireImmediately: false,
    );
  }

  Future<void> _setupDriverRides(
      ProviderContainer container, dynamic user) async {
    try {
      final rideController = container.read(rideControllerProvider.notifier);
      final createdRides = await rideController.fetchCreatedRides(
        currentUserId: user.userId,
      );

      final createdRideIds = createdRides.map((r) => r.id).toSet();

      for (final rideId in createdRideIds) {
        try {
          final ride = await container.read(getRideByIdUsecaseProvider)(rideId);
          final status = ride.status.toLowerCase();

          if (status == 'completed' || status == 'cancelled') {
            debugPrint("🛑 Skipping DRIVER WS for ride #$rideId ($status)");
            continue;
          }

          final ws = container.read(rideWSControllerProvider(rideId).notifier);
          ws.connect();

          debugPrint("🚀 Connected DRIVER WS for ride: $rideId status=$status");
        } catch (e) {
          debugPrint("❌ Error fetching ride #$rideId for driver: $e");
        }
      }
    } catch (e) {
      debugPrint("❌ Error setting up driver rides: $e");
    }
  }

  Future<void> _setupPassengerRides(
      ProviderContainer container, dynamic user) async {
    try {
      await Future.delayed(const Duration(seconds: 2));

      final requestWSProvider = rideRequestWSControllerProvider(user.userId);
      final requests = container.read(requestWSProvider).incomingRequests;

      final rideController = container.read(rideControllerProvider.notifier);
      final createdRides = await rideController.fetchCreatedRides(
        currentUserId: user.userId,
      );
      final createdRideIds = createdRides.map((r) => r.id).toSet();

      final joinedRideIds = requests
          .where((r) => r.passengerId == user.userId)
          .where((r) => r.status.toLowerCase() == "accepted")
          .map((r) => r.rideId)
          .whereType<int>()
          .toSet()
          .difference(createdRideIds);

      final Set<int> passengerWSConnectedRideIds = {};

      Future<void> triggerPassengerRideWS(int rideId) async {
        if (passengerWSConnectedRideIds.contains(rideId)) return;

        if (isRideFinalCached(rideId)) {
          passengerWSConnectedRideIds.add(rideId);
          return;
        }

        passengerWSConnectedRideIds.add(rideId);

        try {
          container.read(passengerRideWSProvider(rideId).notifier);
          container.read(rideWSControllerProvider(rideId).notifier).connect();
          debugPrint("🚀 Connected PASSENGER WS for ride: $rideId");
        } catch (e) {
          debugPrint("❌ Error connecting passenger ride #$rideId: $e");
        }
      }

      for (final rideId in joinedRideIds) {
        await triggerPassengerRideWS(rideId);
      }
    } catch (e) {
      debugPrint("❌ Error setting up passenger rides: $e");
    }
  }

  void _navigateToLogin() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  void _navigateToMainScreen() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  Widget _buildCustomLogo(double size) {
    return ScaleTransition(
      scale: _logoScaleAnimation,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: size * 0.85,
              height: size * 0.85,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: Center(child: Image.asset("assets/images/logo.png")),
            ),
            Positioned(
              left: size * 0.12,
              top: size * 0.3,
              child: _ArcWidget(
                size: size * 0.25,
                color: Colors.white54,
                thickness: 4,
              ),
            ),
            Positioned(
              right: size * 0.12,
              top: size * 0.45,
              child: _ArcWidget(
                size: size * 0.18,
                color: Colors.white38,
                thickness: 3,
              ),
            ),
            Positioned(
              bottom: size * 0.25,
              child: _ArcWidget(
                size: size * 0.3,
                color: Colors.white30,
                thickness: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedSlogan(double width) {
    return AnimatedBuilder(
      animation: Listenable.merge([_textFadeInAnimation, _shimmerController]),
      builder: (_, __) {
        final shimmerPercent = _shimmerController.value;
        final gradient = LinearGradient(
          begin: Alignment(-1 + shimmerPercent * 2, 0),
          end: Alignment(1 + shimmerPercent * 2, 0),
          colors: const [Colors.white, Color(0xffc1e899), Colors.white],
          stops: const [0.1, 0.5, 0.9],
        );

        return Opacity(
          opacity: _textFadeInAnimation.value,
          child: ShaderMask(
            shaderCallback: (bounds) => gradient.createShader(
              Rect.fromLTWH(0, 0, bounds.width, bounds.height),
            ),
            blendMode: BlendMode.srcIn,
            child: Text(
              'Everyday car pooling solution',
              style: GoogleFonts.righteous(
                fontSize: width * 0.045,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        width: width,
        height: height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xffc1e899), Color(0xffa8d47d)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Column(
              children: [
                const Spacer(flex: 3),
                _buildCustomLogo(width * 0.28),
                const SizedBox(height: 18),
                FadeTransition(
                  opacity: _textFadeInAnimation,
                  child: Text(
                    'hopeir',
                    style: GoogleFonts.righteous(
                      fontSize: width * 0.18,
                      letterSpacing: 3,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Spacer(flex: 2),
                _buildAnimatedSlogan(width),
                const Spacer(flex: 3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ArcWidget extends StatelessWidget {
  final double size;
  final Color color;
  final double thickness;

  const _ArcWidget({
    required this.size,
    required this.color,
    required this.thickness,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _ArcPainter(color: color, thickness: thickness),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final Color color;
  final double thickness;

  const _ArcPainter({required this.color, required this.thickness});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    const startAngle = -0.6;
    const sweepAngle = 1.8;

    canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Global notification plugin instance
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Setup FCM notifications
Future<void> setupFCM() async {
  try {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();

    final token = await messaging.getToken();
    print("📱 FCM Token: $token");

    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
    );

    await flutterLocalNotificationsPlugin.initialize(initSettings);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        final notification = message.notification!;
        flutterLocalNotificationsPlugin.show(
          message.notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'default_channel',
              'Default Notifications',
              channelDescription: 'General notifications',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );
      }
    });

    // Handle app opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print("📬 User opened app from notification: ${message.data}");
    });

    // Background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    print("✅ FCM setup completed");
  } catch (e) {
    print("❌ FCM setup error: $e");
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("🔕 Handling background FCM: ${message.messageId}");
}
