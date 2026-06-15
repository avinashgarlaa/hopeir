import '../../data/models/station_model.dart';
import '../../data/services/station_api_service.dart';

class SearchStationsUseCase {
  final StationApiService apiService;

  SearchStationsUseCase(this.apiService);

  Future<List<StationModel>> call(
    String query, {
    double radiusKm = 3,
  }) {
    return apiService.searchStations(
      query,
      radiusKm: radiusKm,
    );
  }
}
