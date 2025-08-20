import '../../data/models/station_model.dart';
import '../../data/services/station_api_service.dart';

class GetStationByIdUseCase {
  final StationApiService apiService;

  GetStationByIdUseCase(this.apiService);

  Future<StationModel> call(int id) => apiService.fetchStationById(id);
}
