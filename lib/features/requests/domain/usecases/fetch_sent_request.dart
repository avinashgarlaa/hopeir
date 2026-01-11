import 'package:hop_eir/features/requests/domain/repositories/ride_request_repository.dart';

import '../entities/ride_request.dart';

class FetchSentRequestsUseCase {
  final RequestRepository repository;

  FetchSentRequestsUseCase(this.repository);

  Future<List<RideRequest>> call(String userId) {
    return repository.fetchSentRequests(userId);
  }
}
