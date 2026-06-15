import 'package:dio/dio.dart';
import 'package:hop_eir/base_url.dart';
import '../models/station_model.dart';

class StationApiService {
  final Dio dio = Dio();
  final String baseUrl = "$baseURL/stations/get/";

  Future<List<StationModel>> searchStations(
    String query, {
    double radiusKm = 3,
  }) async {
    if (query.trim().length < 3) {
      return [];
    }

    final response = await dio.get(
      "$baseURL/stations/search-by-place/",
      queryParameters: {
        'query': query,
        'radius_km': radiusKm,
      },
    );

    final data = response.data;

    final List stations = data['nearby_stations'] ?? [];

    return stations.map((json) {
      return StationModel(
        id: json['id'],
        name: json['name'],
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        address: '',
        city: '',
        country: '',
      );
    }).toList();
  }

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

  // added for map integration
  Future<List<StationModel>> fetchStationsWithValidLocation() async {
    final response = await dio.get(baseUrl);
    final data = response.data as List;

    return data
        .map((json) => StationModel.fromJson(json))
        .where((station) => station.latitude != 0.0 && station.longitude != 0.0)
        .toList();
  }
  // added upto here
}
