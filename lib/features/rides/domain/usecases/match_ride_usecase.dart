import 'package:hop_eir/features/rides/domain/repositories/ride_repository.dart';

class MatchRidesUseCase {
  final RideRepository repository;

  MatchRidesUseCase(this.repository);

  Future<List<Map<String, dynamic>>> call({
    required int riderStartStationId,
    required int riderEndStationId,
    required String riderUserId,
    int timeWindowMinutes = 60,
  }) async {
    return await repository.matchRides(
      riderStartStationId: riderStartStationId,
      riderEndStationId: riderEndStationId,
      riderUserId: riderUserId,
      timeWindowMinutes: timeWindowMinutes,
    );
  }
}
