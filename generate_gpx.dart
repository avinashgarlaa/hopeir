import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

Future<void> main() async {
  // ✅ Your coordinates
  const startLat = 53.2709541957;
  const startLng = -6.2033409700;

  const endLat = 53.2779513736;
  const endLng = -6.2637857068;

  // ✅ Get real route from OSRM
  const url = 'https://router.project-osrm.org/route/v1/driving/'
      '$startLng,$startLat;$endLng,$endLat'
      '?overview=full&geometries=geojson';

  final res = await http.get(Uri.parse(url));

  if (res.statusCode != 200) {
    throw Exception("OSRM failed: ${res.statusCode} ${res.body}");
  }

  final data = jsonDecode(res.body);
  final coords = data['routes'][0]['geometry']['coordinates'] as List;

  // coords format: [ [lng, lat], [lng, lat]... ]
  // ✅ GPX: Use 1 second interval per point (smooth)
  final startTime = DateTime.now().toUtc();

  final buffer = StringBuffer();
  buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
  buffer.writeln(
      '<gpx version="1.1" creator="HopEir GPX Generator" xmlns="http://www.topografix.com/GPX/1/1">');
  buffer.writeln('  <metadata>');
  buffer.writeln(
      '    <name>Vantage Apartments → CRH Group - Rathfarnham (D16)</name>');
  buffer.writeln('  </metadata>');
  buffer.writeln('  <trk>');
  buffer.writeln('    <name>HopEir Driver Track</name>');
  buffer.writeln('    <trkseg>');

  for (int i = 0; i < coords.length; i++) {
    final c = coords[i];
    final lng = (c[0] as num).toDouble();
    final lat = (c[1] as num).toDouble();

    final t = startTime.add(Duration(seconds: i));
    final timeString = t.toIso8601String().replaceFirst('.000Z', 'Z');

    buffer.writeln(
        '      <trkpt lat="$lat" lon="$lng"><ele>10</ele><time>$timeString</time></trkpt>');
  }

  buffer.writeln('    </trkseg>');
  buffer.writeln('  </trk>');
  buffer.writeln('</gpx>');

  final file = File("route_vantage_to_crh.gpx");
  await file.writeAsString(buffer.toString());

}
