import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hop_eir/features/rides/presentation/controllers/ride_ws_controller.dart';

class DriverLiveLocationService {
  DriverLiveLocationService({
    required this.onLocation,
  });

  final void Function(Position position) onLocation;

  StreamSubscription<Position>? _sub;
  Position? _lastSent;

  // ✅ config (good balance)
  static const int minMetersToSend = 8; // don’t spam if not moved
  static const int minSecondsToSend = 2;

  DateTime _lastSentAt = DateTime.fromMillisecondsSinceEpoch(0);

  Future<void> start() async {
    // 1) permission
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      perm = await Geolocator.requestPermission();
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
    );
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    _lastSent = null;
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

  Future<void> startForRide(int rideId) async {
    if (state == true && _rideId == rideId) return;

    await stop();

    _rideId = rideId;

    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      perm = await Geolocator.requestPermission();
    }

    const settings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 8,
    );

    _sub = Geolocator.getPositionStream(locationSettings: settings).listen(
      (pos) {
        if (_rideId == null) return;

        // ✅ make sure socket connected
        ref.read(rideWSControllerProvider(_rideId!).notifier).connect();

        // ✅ send location
        ref
            .read(rideWSControllerProvider(_rideId!).notifier)
            .sendDriverLocation(
              lat: pos.latitude,
              lng: pos.longitude,
              bearing: pos.heading,
            );
      },
    );

    state = true;
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    _rideId = null;
    state = false;
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
