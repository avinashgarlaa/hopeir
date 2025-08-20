import 'package:hop_eir/features/rides/domain/entities/ride.dart';
import 'package:hop_eir/features/rides/domain/repositories/ride_repository.dart';

class CreateRideUsecase {
  final RideRepository repository;

  CreateRideUsecase(this.repository);

  Future<Ride> call({
    required String user,
    required int vehicle,
    required int seats,
    required int startLocation,
    required int endLocation,
    required double distance,
    required DateTime startTime,
    required DateTime endTime,
  }) {
    return repository.createRide(
      user: user,
      vehicle: vehicle,
      seats: seats,
      startLocation: startLocation,
      endLocation: endLocation,
      distance: distance,
      startTime: startTime,
      endTime: endTime,
    );
  }
}
