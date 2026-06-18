import 'package:dio/dio.dart';
import 'package:hop_eir/base_url.dart';
import '../models/station_model.dart';

// Define a class for the search result
class StationSearchApiResult {
  final List<StationModel> matched;
  final List<StationModel> nearby;

  StationSearchApiResult({
    required this.matched,
    required this.nearby,
  });

  bool get isEmpty => matched.isEmpty && nearby.isEmpty;
  bool get isNotEmpty => !isEmpty;
  int get totalCount => matched.length + nearby.length;
}

class StationApiService {
  final Dio dio = Dio();
  final String baseUrl = "$baseURL/stations/get/";

  // Updated: Returns both matched and nearby stations separately
  Future<StationSearchApiResult> searchStationsWithMatches(
    String query, {
    double radiusKm = 3,
  }) async {
    if (query.trim().length < 3) {
      return StationSearchApiResult(
        matched: [],
        nearby: [],
      );
    }

    final response = await dio.get(
      "$baseURL/stations/search-by-place/",
      queryParameters: {
        'query': query,
        'radius_km': radiusKm,
      },
    );

    final data = response.data;

    final matchedJson = data['matched_stations'] as List? ?? [];
    final nearbyJson = data['nearby_stations'] as List? ?? [];

    final matched = matchedJson.map((json) {
      return StationModel(
        id: json['id'],
        name: json['name'],
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        address: json['address'] ?? '',
        city: json['city'] ?? '',
        country: json['country'] ?? '',
        distanceKm: (json['distance_km'] as num?)?.toDouble(),
      );
    }).toList();

    final nearby = nearbyJson.map((json) {
      return StationModel(
        id: json['id'],
        name: json['name'],
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        address: json['address'] ?? '',
        city: json['city'] ?? '',
        country: json['country'] ?? '',
        distanceKm: (json['distance_km'] as num?)?.toDouble(),
      );
    }).toList();

    return StationSearchApiResult(
      matched: matched,
      nearby: nearby,
    );
  }

  // Keep the original method for backward compatibility
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

    final matched = data['matched_stations'] as List? ?? [];
    final nearby = data['nearby_stations'] as List? ?? [];

    final stations = [...matched, ...nearby];

    return stations.map((json) {
      return StationModel(
        id: json['id'],
        name: json['name'],
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        address: json['address'] ?? '',
        city: json['city'] ?? '',
        country: json['country'] ?? '',
        distanceKm: (json['distance_km'] as num?)?.toDouble(),
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
}
