// features/stations/presentation/providers/station_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hop_eir/features/stations/domain/usecases/get_all_stations.dart';
import 'package:hop_eir/features/stations/domain/usecases/get_station_by_id.dart';
import 'package:hop_eir/features/stations/domain/usecases/search_stations.dart';
import '../../data/services/station_api_service.dart';
import '../../data/models/station_model.dart';

// API Service Provider
final stationApiServiceProvider = Provider((ref) => StationApiService());

// UseCase Providers
final getAllStationsUseCaseProvider = Provider((ref) {
  final service = ref.read(stationApiServiceProvider);
  return GetAllStationsUseCase(service);
});

final getStationByIdUseCaseProvider = Provider((ref) {
  final service = ref.read(stationApiServiceProvider);
  return GetStationByIdUseCase(service);
});

final searchStationsUseCaseProvider = Provider((ref) {
  final service = ref.read(stationApiServiceProvider);
  return SearchStationsUseCase(service);
});

// Station Providers
final allStationsProvider = FutureProvider<List<StationModel>>((ref) async {
  final useCase = ref.read(getAllStationsUseCaseProvider);
  return await useCase.call();
});

final stationByIdProvider = FutureProvider.family<StationModel, int>((
  ref,
  id,
) async {
  final useCase = ref.read(getStationByIdUseCaseProvider);
  return await useCase.call(id);
});

final searchStationsProvider =
    FutureProvider.family<StationSearchResult, String>((ref, query) async {
  if (query.trim().length < 3) {
    return StationSearchResult(
      matchedStations: [],
      nearbyStations: [],
    );
  }

  final useCase = ref.read(searchStationsUseCaseProvider);

  // Use the new method that returns separated results
  return await useCase.callWithMatches(query);
});

// Additional providers
final hasUnreadRequestsProvider = StateProvider<bool>((ref) => false);

final unreadRideProvider =
    StateNotifierProvider<UnreadRideNotifier, Map<int, int>>(
  (ref) => UnreadRideNotifier(),
);

class UnreadRideNotifier extends StateNotifier<Map<int, int>> {
  UnreadRideNotifier() : super({});

  void addUnread(int rideId) {
    state = {
      ...state,
      rideId: (state[rideId] ?? 0) + 1,
    };
  }

  void clearUnread(int rideId) {
    final updated = Map<int, int>.from(state);
    updated.remove(rideId);
    state = updated;
  }
}
