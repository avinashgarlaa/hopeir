import 'package:dio/dio.dart';

class RouteService {
  final Dio dio = Dio();

  Future<List<Map<String, double>>> getRoutePoints({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) async {
    final url = 'https://router.project-osrm.org/route/v1/driving/'
        '$startLng,$startLat;$endLng,$endLat'
        '?overview=full&geometries=geojson';

    final response = await dio.get(url);

    final coordinates = response.data['routes'][0]['geometry']['coordinates'];

    return coordinates.map<Map<String, double>>((point) {
      return {
        "lat": (point[1] as num).toDouble(),
        "lng": (point[0] as num).toDouble(),
      };
    }).toList();
  }
}
