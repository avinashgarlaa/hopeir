import 'package:hop_eir/features/rides/domain/entities/ride.dart';
import 'package:hop_eir/features/rides/domain/repositories/ride_repository.dart';

class GetRidesUsecase {
  final RideRepository repository;

  GetRidesUsecase(this.repository);

  Future<List<Ride>> call() {
    return repository.getRides();
  }
}
