// ignore_for_file: avoid_print

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hop_eir/features/requests/domain/entities/ride_request.dart';
import 'package:hop_eir/features/requests/presentation/controllers/ride_request_ws_controller.dart';
import 'package:hop_eir/features/rides/domain/entities/ride.dart';
import 'package:hop_eir/features/rides/domain/usecases/create_ride_usecase.dart';
import 'package:hop_eir/features/rides/domain/usecases/created_rides_usecase.dart';
import 'package:hop_eir/features/rides/domain/usecases/get_ride_by_id_usecase.dart';
import 'package:hop_eir/features/rides/domain/usecases/get_rides_usecase.dart';
import 'package:hop_eir/features/rides/domain/usecases/request_ride_usecase.dart';
import 'package:hop_eir/features/rides/presentation/providers/ride_provider.dart';

class RideController extends AutoDisposeAsyncNotifier<List<Ride>> {
  late final GetRidesUsecase _getRidesUsecase;
  late final CreateRideUsecase _createRideUsecase;
  late final CreatedRidesUsecase _createdRidesUsecase;
  late final RequestRideUsecase _requestRideUsecase;
  late final GetRideByIdUsecase _getRideByIdUsecase;

  @override
  FutureOr<List<Ride>> build() async {
    _getRidesUsecase = ref.watch(getRidesUsecaseProvider);
    _createRideUsecase = ref.watch(creatRideUsecaseProvider);
    _createdRidesUsecase = ref.watch(createdRidesUsecaseProvider);
    _requestRideUsecase = ref.watch(requestRideUsecaseProvider);
    _getRideByIdUsecase = ref.watch(getRideByIdUsecaseProvider);
    return await _getRidesUsecase();
  }

  Future<void> refreshRides() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _getRidesUsecase());
  }

  Future<Ride?> createRide({
    required String user,
    required int vehicle,
    required int totalSeats,
    required int startLocation,
    required int endLocation,
    required double distance,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      final newRide = await _createRideUsecase(
        user: user,
        vehicle: vehicle,
        seats: totalSeats,
        startLocation: startLocation,
        endLocation: endLocation,
        distance: distance,
        startTime: startTime,
        endTime: endTime,
      );
      print(newRide);
      await refreshRides();
      return newRide;
    } catch (e, st) {
      print(e);
      state = AsyncError(e, st);
      return null;
    }
  }

  Future<Map<String, dynamic>> requestRide({
    required int ride,
    required String fromUser, // passenger user_id
    required WidgetRef ref,
  }) async {
    try {
      final response = await _requestRideUsecase(
        fromUser: fromUser,
        ride: ride,
      );

      print('✅ Ride request response: $response');

      // 🔥 DRF wraps payload inside "data"
      final data = response['data'];
      if (data == null) {
        return response;
      }

      final fromUserData = data['from_user'] as Map<String, dynamic>?;

      final newRequest = RideRequest(
        id: data['request_id']?.toString() ?? '',

        // Ride ID
        rideId: data['ride_id'],

        // Passenger
        passengerId: fromUserData?['id']?.toString() ?? fromUser,

        passengerName: fromUserData?['name']?.toString() ?? '',

        // ⚠️ Driver is NOT known yet (will come from WS later)
        driverId: '',

        status: data['request_status']?.toString() ?? 'pending',

        requestedAt: data['requested_at']?.toString(),
      );

      print('📨 Injecting RideRequest into RideRequest WS → $newRequest');

      /// 🔥 HTTP → WS bridge (request list only)
      ref
          .read(
            rideRequestWSControllerProvider(fromUser).notifier,
          )
          .addMyRequest(newRequest);

      return response;
    } on DioException catch (e) {
      print('❌ Ride request failed');
      print('STATUS: ${e.response?.statusCode}');
      print('DATA: ${e.response?.data}');
      rethrow;
    }
  }

  Future<List<Ride>> fetchCreatedRides({required String currentUserId}) async {
    try {
      final createdRides = await _createdRidesUsecase(
        currentUserId: currentUserId,
      );
      return createdRides;
    } catch (e, st) {
      state = AsyncError(e, st);
      return [];
    }
  }

  Future<Ride?> fetchRideById(int rideId) async {
    try {
      final ride = await _getRideByIdUsecase.call(rideId);
      return ride;
    } catch (e) {
      return null;
    }
  }
}
