import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hop_eir/features/auth/presentation/providers/dio_provider.dart';
import 'package:hop_eir/features/requests/data/datasources/request_remote_datasource_impl.dart';
import 'package:hop_eir/features/requests/data/repositories/request_repository_impl.dart';
import 'package:hop_eir/features/requests/domain/entities/ride_request.dart'
    show RideRequest;
import 'package:hop_eir/features/requests/domain/usecases/fetch_request_usecase.dart';
import 'package:hop_eir/features/requests/domain/usecases/fetch_sent_request.dart';

// --- existing providers for data source & repository ---

final requestRemoteDataSourceProvider = Provider(
  (ref) => RequestRemoteDataSourceImpl(ref.watch(dioProvider)),
);

final requestRepositoryProvider = Provider(
  (ref) => RequestRepositoryImpl(ref.watch(requestRemoteDataSourceProvider)),
);

// --- keep this as a normal Provider, since we want the useCase itself ---
final fetchRequestsUseCaseProvider = Provider<FetchRequestsUseCase>(
  (ref) => FetchRequestsUseCase(ref.watch(requestRepositoryProvider)),
);

// --- CHANGE THIS to a FutureProvider.family ---
// so we can do ref.watch(fetchSentRequestsUseCaseProvider(userId))
final fetchSentRequestsUseCaseProvider =
    FutureProvider.family<List<RideRequest>, String>((ref, userId) async {
  final useCase = FetchSentRequestsUseCase(
    ref.watch(requestRepositoryProvider),
  );
  // call the use case with the userId
  return useCase(userId);
});
