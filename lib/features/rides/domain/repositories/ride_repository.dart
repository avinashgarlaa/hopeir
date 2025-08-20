import 'package:hop_eir/features/rides/domain/entities/ride.dart';

abstract class RideRepository {
  Future<List<Ride>> getRides();
  Future<List<Ride>> createdRides({required String currentUserId});
  Future<Ride> createRide({
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
    required String fromUser,
    required int ride,
  });

  Future<List<Map<String, dynamic>>> getRequests({
    required String currentUserId,
  });

  Future<Ride> getRideById({required int rideId});
}
