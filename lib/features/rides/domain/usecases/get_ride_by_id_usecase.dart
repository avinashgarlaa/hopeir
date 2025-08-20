import 'package:hop_eir/features/rides/domain/entities/ride.dart';
import 'package:hop_eir/features/rides/domain/repositories/ride_repository.dart';

class GetRideByIdUsecase {
  final RideRepository repository;

  GetRideByIdUsecase(this.repository);

  Future<Ride> call(int rideId) {
    return repository.getRideById(rideId: rideId);
  }
}
