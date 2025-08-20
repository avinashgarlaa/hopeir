import 'package:hop_eir/features/requests/domain/entities/ride_request.dart'
    show RideRequest;
import 'package:hop_eir/features/requests/domain/repositories/ride_request_repository.dart';

class FetchRequestsUseCase {
  final RequestRepository repository;

  FetchRequestsUseCase(this.repository);

  Future<List<RideRequest>> call(int rideId) {
    return repository.fetchRequests(rideId);
  }
}
