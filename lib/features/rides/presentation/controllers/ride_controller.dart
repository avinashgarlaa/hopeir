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
    required String fromUser, // user_id (STRING)
    required WidgetRef ref,
  }) async {
    try {
      final response = await _requestRideUsecase(
        fromUser: fromUser,
        ride: ride,
      );

      print('✅ Ride request response: $response');

      /// 🔥 DRF returns the object directly (no success / data wrapper)
      if (response['id'] != null) {
        final newRequest = RideRequest(
          id: response['id'].toString(),
          rideId: response['ride'].toString(),
          passengerId: response['from_user'], // ✅ STRING user_id
          passengerName: '', // not returned here
          status: response['request_status'],
          requestedAt: response['requested_at'],
        );

        print('📨 New RideRequest: $newRequest');

        /// Inject into WS controller
        ref
            .read(
              rideRequestWSControllerProvider(fromUser).notifier,
            )
            .addMyRequest(newRequest);
      }

      return response;
    } on DioException catch (e) {
      /// 🔥 ALWAYS log backend error
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
