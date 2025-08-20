import 'package:hop_eir/features/rides/domain/entities/ride.dart';

abstract class RideRemoteDatasource {
  Future<List<Map<String, dynamic>>> getRides();

  Future<Map<String, dynamic>> createRide({
    required String user,
    required int vehicle,
    required int seats,
    required int startLocation,
    required int endLocation,
    required double distance,
    required DateTime startTime,
    required DateTime endTime,
  });
  Future<Map<String, dynamic>> requestRide({
    required int ride,
    required String fromUser,
  });
  Future<List<Map<String, dynamic>>> createdRides({
    required String currentUserId,
  });
  Future<List<Map<String, dynamic>>> getRequests({
    required String currentUserId,
  });

  Future<Ride> getRideById({required int rideId});
}
