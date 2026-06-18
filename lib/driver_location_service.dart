import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hop_eir/features/rides/presentation/controllers/ride_ws_controller.dart';
import 'package:hop_eir/location_service.dart'
    hide PermissionRequestInProgressException;
import 'package:permission_handler/permission_handler.dart';

class DriverLiveLocationService {
  DriverLiveLocationService({
    required this.onLocation,
  });

  final void Function(Position position) onLocation;

  StreamSubscription<Position>? _sub;
  Position? _lastSent;

  // ✅ config (good balance)
  static const int minMetersToSend = 8; // don't spam if not moved
  static const int minSecondsToSend = 2;

  DateTime _lastSentAt = DateTime.fromMillisecondsSinceEpoch(0);
  bool _isStarting = false;

  Future<void> start() async {
    // Prevent multiple simultaneous starts
    if (_isStarting) {
      print('⏳ Location service already starting...');
      return;
    }

    try {
      _isStarting = true;
      print('📍 Starting driver location service...');

      // 1) Check and request permission with proper handling
      final hasPermission = await _ensureLocationPermission();
      if (!hasPermission) {
        print('❌ Location permission not granted');
        _isStarting = false;
        return;
      }

      // 2) GPS settings
      const settings = LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: minMetersToSend,
      );

      _sub?.cancel();
      _sub = Geolocator.getPositionStream(locationSettings: settings).listen(
        (pos) {
          final now = DateTime.now();

          // ✅ throttle by seconds also
          if (now.difference(_lastSentAt).inSeconds < minSecondsToSend) return;

          if (_lastSent != null) {
            final moved = Geolocator.distanceBetween(
              _lastSent!.latitude,
              _lastSent!.longitude,
              pos.latitude,
              pos.longitude,
            );

            if (moved < minMetersToSend) return;
          }

          _lastSentAt = now;
          _lastSent = pos;
          onLocation(pos);
        },
        onError: (error) {
          print('❌ Location stream error: $error');
          _handleLocationError(error);
        },
      );

      print('✅ Driver location service started');
    } catch (e) {
      print('❌ Error starting location service: $e');
    } finally {
      _isStarting = false;
    }
  }

  Future<bool> _ensureLocationPermission() async {
    try {
      // Use the permission helper to avoid multiple requests
      final status = await LocationPermissionHelper.requestLocationPermission();
      return status == PermissionStatus.granted ||
          status == PermissionStatus.limited;
    } catch (e) {
      print('❌ Error checking location permission: $e');
      return false;
    }
  }

  void _handleLocationError(dynamic error) {
    if (error is PermissionRequestInProgressException) {
      print('⏳ Permission request already in progress, retrying...');
      // Retry after a delay
      Future.delayed(const Duration(seconds: 1), () {
        start();
      });
    } else {
      print('❌ Unhandled location error: $error');
    }
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    _lastSent = null;
    _isStarting = false;
    print('🛑 Driver location service stopped');
  }
}

final driverLocationControllerProvider =
    StateNotifierProvider<DriverLocationController, bool>(
  (ref) => DriverLocationController(ref),
);

class DriverLocationController extends StateNotifier<bool> {
  DriverLocationController(this.ref) : super(false);

  final Ref ref;

  StreamSubscription<Position>? _sub;
  int? _rideId;
  bool _isStarting = false;

  Future<void> startForRide(int rideId) async {
    if (state == true && _rideId == rideId) return;

    if (_isStarting) {
      print('⏳ Location controller already starting...');
      return;
    }

    await stop();

    try {
      _isStarting = true;
      _rideId = rideId;

      print('📍 Starting location tracking for ride #$rideId');

      // Check and request permission
      final hasPermission = await _ensureLocationPermission();
      if (!hasPermission) {
        print('❌ Location permission not granted for ride #$rideId');
        _isStarting = false;
        return;
      }

      const settings = LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 8,
      );

      _sub = Geolocator.getPositionStream(locationSettings: settings).listen(
        (pos) {
          if (_rideId == null) return;

          try {
            // ✅ make sure socket connected
            final wsController =
                ref.read(rideWSControllerProvider(_rideId!).notifier);
            wsController.connect();

            // ✅ send location
            wsController.sendDriverLocation(
              lat: pos.latitude,
              lng: pos.longitude,
              bearing: pos.heading,
            );
          } catch (e) {
            print('❌ Error sending location for ride #$_rideId: $e');
          }
        },
        onError: (error) {
          print('❌ Location stream error for ride #$rideId: $error');
          _handleLocationError(error);
        },
      );

      state = true;
      print('✅ Location tracking started for ride #$rideId');
    } catch (e) {
      print('❌ Error starting location tracking for ride #$rideId: $e');
      state = false;
    } finally {
      _isStarting = false;
    }
  }

  Future<bool> _ensureLocationPermission() async {
    try {
      final status = await LocationPermissionHelper.requestLocationPermission();
      return status == PermissionStatus.granted ||
          status == PermissionStatus.limited;
    } catch (e) {
      print('❌ Error ensuring location permission: $e');

      // Handle PermissionRequestInProgressException
      if (e is PermissionRequestInProgressException) {
        print('⏳ Permission request in progress, waiting...');
        // Wait and retry
        await Future.delayed(const Duration(seconds: 1));
        return await _ensureLocationPermission();
      }

      return false;
    }
  }

  void _handleLocationError(dynamic error) {
    if (error is PermissionRequestInProgressException) {
      print('⏳ Permission request in progress, retrying...');
      if (_rideId != null) {
        Future.delayed(const Duration(seconds: 1), () {
          startForRide(_rideId!);
        });
      }
    } else if (error is LocationServiceDisabledException) {
      print('📍 Location services are disabled');
      // Show dialog to enable location services
    } else {
      print('❌ Unhandled location error: $error');
    }
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    _rideId = null;
    state = false;
    _isStarting = false;
    print('🛑 Location tracking stopped');
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
