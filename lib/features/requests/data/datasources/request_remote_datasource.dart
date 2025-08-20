import 'package:hop_eir/features/requests/data/models/ride_request_model.dart';

abstract class RequestRemoteDataSource {
  Future<List<RideRequestModel>> fetchRequestsForRide(int rideId);
  Future<List<RideRequestModel>> fetchRequestsByUser(int userId);
  Future<void> respondToRequest({
    required int requestId,
    required String action,
    required int userId,
  });
}
