// lib/features/location/location_permission_helper.dart

import 'package:permission_handler/permission_handler.dart';

class LocationPermissionHelper {
  static bool _isRequesting = false;

  static Future<PermissionStatus> requestLocationPermission() async {
    // Prevent multiple simultaneous requests
    if (_isRequesting) {
      print('⏳ Location permission request already in progress');
      throw PermissionRequestInProgressException();
    }

    try {
      _isRequesting = true;
      print('📍 Requesting location permission...');

      // Check current status
      final status = await Permission.location.status;
      print('📍 Current location status: $status');

      // Check if already granted
      if (status == PermissionStatus.granted ||
          status == PermissionStatus.limited) {
        print('✅ Location permission already granted');
        return status;
      }

      // Check if denied
      if (status == PermissionStatus.denied) {
        print('📍 Permission denied, requesting...');
        final result = await Permission.location.request();
        print(
            '📍 Permission result: ${result.isGranted ? "GRANTED" : "DENIED"}');
        return result;
      }

      // Check if permanently denied
      if (status == PermissionStatus.permanentlyDenied) {
        print('❌ Location permission permanently denied');
        return status;
      }

      return status;
    } catch (e) {
      print('❌ Error requesting location permission: $e');
      rethrow;
    } finally {
      _isRequesting = false;
    }
  }

  static Future<bool> hasLocationPermission() async {
    try {
      final status = await Permission.location.status;
      return status == PermissionStatus.granted ||
          status == PermissionStatus.limited;
    } catch (e) {
      print('❌ Error checking location permission: $e');
      return false;
    }
  }

  static Future<bool> isPermissionDenied() async {
    try {
      final status = await Permission.location.status;
      return status == PermissionStatus.denied;
    } catch (e) {
      print('❌ Error checking permission denied status: $e');
      return false;
    }
  }

  static Future<bool> isPermissionPermanentlyDenied() async {
    try {
      final status = await Permission.location.status;
      return status == PermissionStatus.permanentlyDenied;
    } catch (e) {
      print('❌ Error checking permanently denied status: $e');
      return false;
    }
  }

  static void resetPermissionState() {
    _isRequesting = false;
  }
}

class PermissionRequestInProgressException implements Exception {
  @override
  String toString() => 'A request for location permissions is already running';
}
