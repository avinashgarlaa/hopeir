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

    _startAnimations();
  }

  Future<void> _startAnimations() async {
    try {
      await _logoController.forward();
      await Future.delayed(const Duration(milliseconds: 400));
      await _textController.forward();
      await Future.delayed(const Duration(seconds: 1));

      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('user_email');
      final password = prefs.getString('user_password');

      debugPrint("📧 Cached email: $email");
      debugPrint("🔑 Cached password exists: ${password != null}");

      if (email != null && password != null) {
        final container = ProviderScope.containerOf(context, listen: false);

        unawaited(() async {
          final authNotifier = container.read(authNotifierProvider.notifier);
          await authNotifier.checkLoginStatus(email, password, context);

          final user = container.read(authNotifierProvider).user;

          if (user != null && user.userId != "") {
            debugPrint("✅ Logged in as user ID: ${user.userId}");

            // ✅ Fetch vehicle
            try {
              await container
                  .read(vehicleControllerProvider.notifier)
                  .fetchVehicleByUserId(user.userId);
            } catch (e) {
              debugPrint("⚠️ Vehicle fetch failed: $e");
            }

            // =========================================================
            // ✅ Ride Requests WS (global request listener)
            // =========================================================
            final requestWSProvider = rideRequestWSControllerProvider(
              user.userId,
            );

            bool initialSyncDone = false;
            List<RideRequest> previousRequests = [];

            container.listen<RideRequestWSState>(
              requestWSProvider,
              (prev, next) {
                final currentRequests = next.incomingRequests;
                final currentIds = currentRequests.map((r) => r.id).toSet();
                final oldIds = previousRequests.map((r) => r.id).toSet();

                debugPrint("🟡 Old Request IDs: $oldIds");
                debugPrint("🟢 Current Request IDs: $currentIds");

                if (!initialSyncDone) {
                  initialSyncDone = true;
                  previousRequests = List.from(currentRequests);
                  debugPrint(
                    "🛑 Skipping notifications for first-time initial_state sync",
                  );
                  return;
                }

                // ✅ Notify new requests (driver side)
                final newRequests = currentRequests
                    .where((r) => !oldIds.contains(r.id))
                    .toList();

                for (final r in newRequests) {
                  final isDriver = r.passengerId != user.userId;
                  if (isDriver) {
                    LocalNotificationHelper.showNotification(
                      '📥 New Ride Request',
                      'From: ${r.passengerName}',
                    );
                  }
                }

                // ✅ Notify status changes
                final oldMap = {for (var r in previousRequests) r.id: r};
                for (final r in currentRequests) {
                  final old = oldMap[r.id];
                  if (old != null && old.status != r.status) {
                    final isDriver = r.passengerId != user.userId;
                    final who = isDriver
                        ? 'Request from ${r.passengerName}'
                        : 'Your request';

                    LocalNotificationHelper.showNotification(
                      isDriver
                          ? '🔁 Ride Request Updated'
                          : '📢 Request Status Updated',
                      '$who is now ${r.status.toUpperCase()}',
                    );
                  }
                }

                previousRequests = List.from(currentRequests);
              },
              fireImmediately: false,
            );

            // =========================================================
            // ✅ DRIVER: connect WS for created rides (rideWSController)
            // =========================================================
            final rideController = container.read(
              rideControllerProvider.notifier,
            );

            final createdRides = await rideController.fetchCreatedRides(
              currentUserId: user.userId,
            );
            final createdRideIds = createdRides.map((r) => r.id).toSet();

            for (final rideId in createdRideIds) {
              try {
                final ride = await container.read(getRideByIdUsecaseProvider)(
                  rideId,
                );
                final status = ride.status.toLowerCase();

                if (status == 'completed' || status == 'cancelled') {
                  debugPrint(
                      "🛑 Skipping DRIVER WS for ride #$rideId ($status)");
                  continue;
                }

                container.read(rideWSControllerProvider(rideId));
                debugPrint("🚀 Connected DRIVER WS for created ride: $rideId");
              } catch (e) {
                debugPrint("❌ Error fetching ride #$rideId for driver: $e");
              }
            }

            // =========================================================
            // ✅ PASSENGER: connect WS for joined rides (PassengerRideWS)
            // =========================================================
            await Future.delayed(const Duration(seconds: 2));

            final requests = container.read(requestWSProvider).incomingRequests;

            final joinedRideIds = requests
                .where((r) => r.passengerId == user.userId)
                .where(
                    (r) => r.status.toLowerCase() == "accepted") // ✅ IMPORTANT
                .map((r) => r.rideId)
                .whereType<int>()
                .toSet()
                .difference(createdRideIds);

            for (final rideId in joinedRideIds) {
              try {
                // ✅ cached final? skip
                if (isRideFinalCached(rideId)) {
                  debugPrint(
                      "🔒 Passenger ride #$rideId already final (cached)");
                  continue;
                }

                final ride = await container.read(getRideByIdUsecaseProvider)(
                  rideId,
                );
                final rideStatus = ride.status.toLowerCase();

                // ✅ final ride: no ws needed, but we still fetch once
                if (rideStatus == 'completed' || rideStatus == 'cancelled') {
                  container.read(passengerRideWSProvider(rideId).notifier);
                  debugPrint(
                    "🔒 Passenger ride #$rideId is final ($rideStatus). No WS.",
                  );
                  continue;
                }

                // ✅ trigger passenger ride controller (safe)
                container.read(passengerRideWSProvider(rideId).notifier);
                debugPrint(
                  "🚀 Triggered PassengerRideWSController for ride: $rideId",
                );

                // ✅ optional: listen to passenger status updates
                container.listen<String>(
                  passengerRideWSProvider(rideId),
                  (prev, next) {
                    if (prev != next && next.toLowerCase() != 'pending') {
                      LocalNotificationHelper.showNotification(
                        '🚘 Ride Status Updated',
                        'Your ride is now ${next.toUpperCase()}',
                      );
                    }
                  },
                  fireImmediately: false,
                );
              } catch (e) {
                debugPrint("❌ Error handling passenger ride #$rideId: $e");
              }
            }

            if (!mounted) return;

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const MainScreen()),
            );
            return;
          }

          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }());

        return;
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } catch (e, st) {
      debugPrint("❌ Error during startup: $e\n$st");

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
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

  Widget buildCustomLogo(double size) {
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

  Widget buildAnimatedSlogan(double width) {
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
            colors: [Color(0xffc1e899), Color(0xffc1e899)],
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
                buildCustomLogo(width * 0.28),
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
                buildAnimatedSlogan(width),
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

  _ArcPainter({required this.color, required this.thickness});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final startAngle = -0.6;
    final sweepAngle = 1.8;

    canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> setupFCM() async {
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
            'Default',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );
    }
  });

  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    print("📬 User opened app from notification: ${message.data}");
  });

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("🔕 Handling background FCM: ${message.messageId}");
}
