import 'package:hop_eir/features/requests/domain/entities/ride_request.dart';

abstract class RequestRepository {
  Future<List<RideRequest>> fetchRequests(int rideId);
  Future<List<RideRequest>> fetchSentRequests(String userId);
  Future<void> respondToRequest({
    required int requestId,
    required String action,
    required String userId,
  });
}
