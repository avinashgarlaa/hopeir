import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hop_eir/features/rides/domain/entities/ride.dart';
import 'package:hop_eir/features/rides/domain/usecases/create_ride_usecase.dart';
import 'package:hop_eir/features/rides/domain/usecases/created_rides_usecase.dart';
import 'package:hop_eir/features/rides/domain/usecases/get_requests_usecase.dart';
import 'package:hop_eir/features/rides/domain/usecases/get_ride_by_id_usecase.dart';
import 'package:hop_eir/features/rides/domain/usecases/get_rides_usecase.dart';
import 'package:hop_eir/features/rides/domain/usecases/request_ride_usecase.dart';
import 'package:hop_eir/features/rides/presentation/controllers/ride_controller.dart';
import 'package:hop_eir/features/rides/presentation/providers/ride_repository_provider.dart';

final getRidesUsecaseProvider = Provider<GetRidesUsecase>((ref) {
  final repository = ref.read(rideRepositoryProvider);
  return GetRidesUsecase(repository);
});

final creatRideUsecaseProvider = Provider<CreateRideUsecase>((ref) {
  final repository = ref.read(rideRepositoryProvider);
  return CreateRideUsecase(repository);
});

final createdRidesUsecaseProvider = Provider<CreatedRidesUsecase>((ref) {
  final repository = ref.read(rideRepositoryProvider);
  return CreatedRidesUsecase(repository);
});

final requestRideUsecaseProvider = Provider<RequestRideUsecase>((ref) {
  final repository = ref.read(rideRepositoryProvider);
  return RequestRideUsecase(repository);
});

final getRequestUsecaseProvider = Provider<GetRequestsUsecase>((ref) {
  final repository = ref.read(rideRepositoryProvider);
  return GetRequestsUsecase(repository);
});

final getRideByIdUsecaseProvider = Provider<GetRideByIdUsecase>((ref) {
  final repo = ref.read(rideRepositoryProvider);
  return GetRideByIdUsecase(repo);
});

final rideByIdProvider = FutureProvider.family<Ride, int>((ref, rideId) async {
  final usecase = ref.read(getRideByIdUsecaseProvider);
  final ride = await usecase.call(rideId);
  return ride;
});

final rideControllerProvider =
    AutoDisposeAsyncNotifierProvider<RideController, List<Ride>>(() {
      return RideController();
    });
