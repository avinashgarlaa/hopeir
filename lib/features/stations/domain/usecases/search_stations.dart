import '../../data/models/station_model.dart';
import '../../data/services/station_api_service.dart';

class StationSearchResult {
  final List<StationModel> matchedStations;
  final List<StationModel> nearbyStations;

  StationSearchResult({
    required this.matchedStations,
    required this.nearbyStations,
  });

  bool get isEmpty => matchedStations.isEmpty && nearbyStations.isEmpty;
  bool get isNotEmpty => !isEmpty;
  int get totalCount => matchedStations.length + nearbyStations.length;
}

class SearchStationsUseCase {
  final StationApiService apiService;

  SearchStationsUseCase(this.apiService);

  // New method that returns separated results
  Future<StationSearchResult> callWithMatches(
    String query, {
    double radiusKm = 3,
  }) async {
    if (query.trim().length < 3) {
      return StationSearchResult(
        matchedStations: [],
        nearbyStations: [],
      );
    }

    final result = await apiService.searchStationsWithMatches(
      query,
      radiusKm: radiusKm,
    );

    return StationSearchResult(
      matchedStations: result.matched,
      nearbyStations: result.nearby,
    );
  }
}
