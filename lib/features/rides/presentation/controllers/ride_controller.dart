// ignore_for_file: avoid_print

import 'dart:async';
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
    required String fromUser,
    required WidgetRef ref, // 👈 pass ref here
  }) async {
    try {
      final response = await _requestRideUsecase(
        fromUser: fromUser,
        ride: ride,
      );
      print(response);
      print("ride sent successfully");

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];

        // Convert response to RideRequest entity
        final newRequest = RideRequest(
          id: data['request_id'].toString(),
          rideId: data['ride_id'].toString(),
          passengerId: data['from_user']['id'].toString(),
          passengerName: data['from_user']['name'],
          status: data['request_status'],
          requestedAt: data['requested_at'],
        );

        // Inject into WebSocket controller so it appears instantly
        ref
            .read(rideRequestWSControllerProvider(fromUser.toString()).notifier)
            .addMyRequest(newRequest);
      }

      return response;
    } catch (e) {
      print('❌ Error sending ride request: $e');
      return {};
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
