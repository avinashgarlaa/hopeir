import 'package:hop_eir/features/rides/domain/entities/ride.dart';
import 'package:hop_eir/features/rides/domain/repositories/ride_repository.dart';

class CreatedRidesUsecase {
  final RideRepository repository;

  CreatedRidesUsecase(this.repository);

  Future<List<Ride>> call({required String currentUserId}) {
    return repository.createdRides(currentUserId: currentUserId);
  }
}
