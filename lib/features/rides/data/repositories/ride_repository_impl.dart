// ignore_for_file: avoid_print

import 'package:hop_eir/features/rides/data/datasources/ride_remote_datasource.dart';
import 'package:hop_eir/features/rides/data/models/ride_model.dart';
import 'package:hop_eir/features/rides/domain/entities/ride.dart';
import 'package:hop_eir/features/rides/domain/repositories/ride_repository.dart';

class RideRepositoryImpl extends RideRepository {
  final RideRemoteDatasource remoteDatasource;

  RideRepositoryImpl(this.remoteDatasource);

  @override
  Future<Ride> createRide({
    required String user,
    required int vehicle,
    required int seats,
    required int startLocation,
    required int endLocation,
    required List routePath,
    required double distance,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    final response = await remoteDatasource.createRide(
      user: user,
      vehicle: vehicle,
      seats: seats,
      startLocation: startLocation,
      endLocation: endLocation,
      routePath: routePath,
      distance: distance,
      startTime: startTime,
      endTime: endTime,
    );
    return RideModel.fromJson(response);
  }

  @override
  Future<List<Ride>> getRides() async {
    final response = await remoteDatasource.getRides();
    return response.map((rideJson) => RideModel.fromJson(rideJson)).toList();
  }

  @override
  Future<List<Ride>> createdRides({required String currentUserId}) async {
    final response = await remoteDatasource.createdRides(
      currentUserId: currentUserId,
    );
    return response.map((rideJson) => RideModel.fromJson(rideJson)).toList();
  }

  @override
  Future<Map<String, dynamic>> requestRide({
    required String fromUser,
    required int ride,
  }) async {
    final response = await remoteDatasource.requestRide(
      ride: ride,
      fromUser: fromUser,
    );
    return response;
  }

  @override
  Future<List<Map<String, dynamic>>> getRequests({
    required String currentUserId,
  }) async {
    final response = await remoteDatasource.getRequests(
      currentUserId: currentUserId,
    );
    return response;
  }

  @override
  Future<Ride> getRideById({required int rideId}) {
    return remoteDatasource.getRideById(rideId: rideId);
  }

  @override
  Future<List<Map<String, dynamic>>> matchRides({
    required int riderStartStationId,
    required int riderEndStationId,
    required String riderUserId,
    int timeWindowMinutes = 60,
  }) async {
    final response = await remoteDatasource.matchRides(
      riderStartStationId: riderStartStationId,
      riderEndStationId: riderEndStationId,
      riderUserId: riderUserId,
      timeWindowMinutes: timeWindowMinutes,
    );

    return response;
  }
}
