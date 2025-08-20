import 'package:dio/dio.dart';
import '../models/station_model.dart';

class StationApiService {
  final Dio dio = Dio();
  final String baseUrl = "https://hopeir.onrender.com/stations/get/";

  Future<List<StationModel>> fetchAllStations() async {
    final response = await dio.get(baseUrl);
    final data = response.data as List;
    return data.map((json) => StationModel.fromJson(json)).toList();
  }

  Future<StationModel> fetchStationById(int stationId) async {
    final response = await dio.get("$baseUrl?station_id=$stationId");
    final data = (response.data as List).first;
    return StationModel.fromJson(data);
  }
}
