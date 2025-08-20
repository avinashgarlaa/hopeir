import 'package:dio/dio.dart';
import 'package:hop_eir/features/requests/data/models/ride_request_model.dart';
import 'request_remote_datasource.dart';

class RequestRemoteDataSourceImpl implements RequestRemoteDataSource {
  final Dio dio;

  RequestRemoteDataSourceImpl(this.dio);

  @override
  Future<List<RideRequestModel>> fetchRequestsForRide(int rideId) async {
    final response = await dio.get(
      'https://hopeir.onrender.com/rides/request/get/?ride_id=$rideId',
    );

    final data = response.data as List;
    return data.map((e) => RideRequestModel.fromJson(e)).toList();
  }

  @override
  Future<List<RideRequestModel>> fetchRequestsByUser(int userId) async {
    final response = await dio.get(
      'https://hopeir.onrender.com/rides/request/get/?user_id=$userId',
    );

    final data = response.data as List;
    return data.map((e) => RideRequestModel.fromJson(e)).toList();
  }

  @override
  Future<void> respondToRequest({
    required int requestId,
    required String action,
    required int userId,
  }) async {
    final response = await dio.put(
      'https://hopeir.onrender.com/rides/request/$requestId/respond/',
      data: {"request_status": action, "user_id": userId},
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to respond to request: ${response.statusCode}');
    }
  }
}
