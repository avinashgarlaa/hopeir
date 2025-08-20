import 'package:hop_eir/features/rides/domain/repositories/ride_repository.dart';

class GetRequestsUsecase {
  final RideRepository repository;

  GetRequestsUsecase(this.repository);

  Future<List<Map<String, dynamic>>> call(
    int id, {
    required String currentUserId,
  }) {
    return repository.getRequests(currentUserId: currentUserId);
  }
}
