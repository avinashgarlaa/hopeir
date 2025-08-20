// ignore_for_file: avoid_print

import 'package:dio/dio.dart';
import 'package:hop_eir/features/rides/data/datasources/ride_remote_datasource.dart';
import 'package:hop_eir/features/rides/data/models/ride_model.dart';
import 'package:hop_eir/features/rides/domain/entities/ride.dart';

class RideRemoteDatasourceImpl extends RideRemoteDatasource {
  final Dio dio;

  RideRemoteDatasourceImpl(this.dio);

  @override
  Future<Map<String, dynamic>> createRide({
    required String user,
    required int vehicle,
    required int seats,
    required int startLocation,
    required int endLocation,
    required double distance,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    final response = await dio.post(
      'https://hopeir.onrender.com/rides/create/',
      data: {
        "start_time": startTime.toIso8601String(),
        "end_time": endTime.toIso8601String(),
        "distance": distance,
        "seats": seats,
        "status": "pending",
        "user": user,
        "vehicle": vehicle,
        "start_location": startLocation,
        "end_location": endLocation,
      },
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return response.data;
    } else {
      throw Exception('Failed to create ride: ${response.statusCode}');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getRides() async {
    final response = await dio.get('https://hopeir.onrender.com/rides/get/');
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = response.data;
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Unexpected response format: Expected List');
      }
    } else {
      throw Exception('Failed to get rides: ${response.statusCode}');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> createdRides({
    required String currentUserId,
  }) async {
    final response = await dio.get(
      'https://hopeir.onrender.com/rides/get/?user_id=$currentUserId',
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = response.data;
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Unexpected response format: Expected List');
      }
    } else {
      throw Exception('Failed to get rides: ${response.statusCode}');
    }
  }

  @override
  Future<Map<String, dynamic>> requestRide({
    required int ride,
    required String fromUser,
  }) async {
    final response = await dio.post(
      'https://hopeir.onrender.com/rides/request/',
      data: {"ride": ride, "from_user": fromUser},
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      print(response.statusCode);
      return response.data;
    } else {
      throw Exception('Failed to create ride: ${response.statusCode}');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getRequests({
    required String currentUserId,
  }) async {
    final response = await dio.get(
      'https://hopeir.onrender.com/rides/request/get/?user_id=$currentUserId',
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = response.data;

      if (data is List) {
        return data.map<Map<String, dynamic>>((item) {
          return Map<String, dynamic>.from(item);
        }).toList();
      } else {
        throw Exception('Unexpected response format: Expected List');
      }
    } else {
      throw Exception('Failed to get rides: ${response.statusCode}');
    }
  }

  @override
  Future<Ride> getRideById({required int rideId}) async {
    final response = await dio.get(
      'https://hopeir.onrender.com/rides/get/?ride_id=$rideId',
    );

    if (response.statusCode == 200) {
      final data = response.data as List;
      final rideJson = data.first;
      return RideModel.fromJson(rideJson) as Ride;
    } else {
      throw Exception('Failed to fetch ride');
    }
  }
}
