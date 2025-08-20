import 'package:hop_eir/features/requests/domain/entities/ride_request.dart';
import 'package:hop_eir/features/requests/domain/repositories/ride_request_repository.dart';

import 'package:hop_eir/features/requests/data/datasources/request_remote_datasource.dart';

class RequestRepositoryImpl implements RequestRepository {
  final RequestRemoteDataSource remoteDataSource;

  RequestRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<RideRequest>> fetchRequests(int rideId) async {
    try {
      final models = await remoteDataSource.fetchRequestsForRide(rideId);
      return models.map((model) => model.toEntity()).toList();
    } catch (e) {
      // Optionally log or rethrow a domain-specific exception
      rethrow;
    }
  }

  @override
  Future<void> respondToRequest({
    required int requestId,
    required String action,
    required int userId,
  }) async {
    return await remoteDataSource.respondToRequest(
      requestId: requestId,
      action: action,
      userId: userId,
    );
  }

  @override
  Future<List<RideRequest>> fetchSentRequests(int userId) async {
    try {
      final models = await remoteDataSource.fetchRequestsByUser(userId);
      return models.map((model) => model.toEntity()).toList();
    } catch (e) {
      // Optionally log or rethrow a domain-specific exception
      rethrow;
    }
  }
}
