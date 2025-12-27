import '../../data/models/station_model.dart';
import '../../data/services/station_api_service.dart';

class GetAllStationsUseCase {
  final StationApiService apiService;

  GetAllStationsUseCase(this.apiService);
  // before map integration
  // Future<List<StationModel>> call() => apiService.fetchAllStations();
  // added for map integration
  Future<List<StationModel>> call() =>
      apiService.fetchStationsWithValidLocation();
  // upto here
}
