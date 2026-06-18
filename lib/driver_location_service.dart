import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hop_eir/features/rides/presentation/controllers/ride_ws_controller.dart';

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
  int _retryCount = 0;
  static const int maxRetries = 3;
  bool _isLocationServiceEnabled = false;

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
      _retryCount = 0;

      print('📍 Starting location tracking for ride #$rideId');

      // Check if location services are enabled
      _isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
      print('📍 Service Enabled => $_isLocationServiceEnabled');

      if (!_isLocationServiceEnabled) {
        print('❌ Location services are disabled');
        _isStarting = false;
        // Notify UI to show dialog
        state = false;
        return;
      }

      // Check and request permission
      final permission = await Geolocator.checkPermission();
      print('📍 Current Permission => $permission');

      // Handle permission states
      final hasPermission = await _handlePermission(permission);
      if (!hasPermission) {
        _isStarting = false;
        state = false;
        return;
      }

      // Start tracking
      await _startLocationTracking(rideId);
    } catch (e) {
      print('❌ Error starting location tracking for ride #$rideId: $e');
      state = false;
      _handleError(e);
    } finally {
      _isStarting = false;
    }
  }

  Future<bool> _handlePermission(LocationPermission permission) async {
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      return true;
    }

    if (permission == LocationPermission.denied) {
      print('📍 Permission denied, requesting...');
      final requested = await Geolocator.requestPermission();
      print('📍 Requested Permission => $requested');

      if (requested == LocationPermission.whileInUse ||
          requested == LocationPermission.always) {
        return true;
      }

      if (requested == LocationPermission.denied) {
        print('❌ Location permission denied by user');
        // Show permission dialog
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('❌ Location permission permanently denied');
      // Show permission dialog to open settings
      return false;
    }

    return false;
  }

  Future<void> _startLocationTracking(int rideId) async {
    const settings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 8,
      timeLimit: Duration(seconds: 5),
    );

    _sub = Geolocator.getPositionStream(locationSettings: settings).listen(
      (pos) {
        if (_rideId == null) return;

        try {
          final wsController =
              ref.read(rideWSControllerProvider(_rideId!).notifier);
          wsController.connect();
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
      cancelOnError: false,
    );

    state = true;
    print('✅ Location tracking started for ride #$rideId');
  }

  void _handleLocationError(dynamic error) {
    if (error is PermissionRequestInProgressException) {
      print('⏳ Permission request in progress, retrying...');
      if (_retryCount < maxRetries && _rideId != null) {
        _retryCount++;
        Future.delayed(const Duration(seconds: 1), () {
          startForRide(_rideId!);
        });
      } else {
        print('❌ Max retries reached for location permission');
        _retryCount = 0;
      }
    } else if (error is LocationServiceDisabledException) {
      print('📍 Location services are disabled');
      _isLocationServiceEnabled = false;
      state = false;
    } else {
      print('❌ Unhandled location error: $error');
      _handleError(error);
    }
  }

  void _handleError(dynamic error) {
    print('❌ Location error: $error');
    state = false;
    _isStarting = false;
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    _rideId = null;
    state = false;
    _isStarting = false;
    _retryCount = 0;
    print('🛑 Location tracking stopped');
  }

  Future<bool> checkLocationServices() async {
    _isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
    return _isLocationServiceEnabled;
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
