import 'package:hop_eir/features/rides/domain/repositories/ride_repository.dart';

class RequestRideUsecase {
  final RideRepository repository;

  RequestRideUsecase(this.repository);

  Future<Map<String, dynamic>> call({
    required String fromUser,
    required int ride,
  }) {
    return repository.requestRide(fromUser: fromUser, ride: ride);
  }
}
