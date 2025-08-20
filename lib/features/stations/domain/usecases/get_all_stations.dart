import '../../data/models/station_model.dart';
import '../../data/services/station_api_service.dart';

class GetAllStationsUseCase {
  final StationApiService apiService;

  GetAllStationsUseCase(this.apiService);

  Future<List<StationModel>> call() => apiService.fetchAllStations();
}
