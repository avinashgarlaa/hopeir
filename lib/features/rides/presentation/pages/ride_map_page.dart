import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hop_eir/features/rides/presentation/pages/rides_page.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

class RideMapPage extends StatefulWidget {
  final double fromLat;
  final double fromLng;
  final double toLat;
  final double toLng;
  final String fromName;
  final String toName;

  const RideMapPage({
    super.key,
    required this.fromLat,
    required this.fromLng,
    required this.toLat,
    required this.toLng,
    required this.fromName,
    required this.toName,
  });

  @override
  State<RideMapPage> createState() => _RideMapPageState();
}

class _RideMapPageState extends State<RideMapPage> {
  List<LatLng> routePoints = [];
  bool loading = true;

  late LatLng snappedStart;
  late LatLng snappedEnd;

  @override
  void initState() {
    super.initState();
    _prepareRoute();
  }

  // ───────── ROUTE ─────────

  Future<void> _prepareRoute() async {
    snappedStart = await _snap(widget.fromLat, widget.fromLng);
    snappedEnd = await _snap(widget.toLat, widget.toLng);
    await _fetchRoute(snappedStart, snappedEnd);
  }

  Future<LatLng> _snap(double lat, double lng) async {
    final res = await http.get(
      Uri.parse('https://router.project-osrm.org/nearest/v1/driving/$lng,$lat'),
    );
    final data = json.decode(res.body);
    final loc = data['waypoints'][0]['location'];
    return LatLng(loc[1], loc[0]);
  }

  Future<void> _fetchRoute(LatLng start, LatLng end) async {
    final res = await http.get(
      Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${start.longitude},${start.latitude};'
        '${end.longitude},${end.latitude}'
        '?overview=full&geometries=geojson',
      ),
    );

    final data = json.decode(res.body);
    final coords = data['routes'][0]['geometry']['coordinates'] as List;

    setState(() {
      routePoints = coords.map((c) => LatLng(c[1], c[0])).toList();
      loading = false;
    });
  }

  // ───────── CAMERA ─────────

  LatLngBounds _bounds() {
    final b = LatLngBounds.fromPoints(routePoints);
    final latPad = (b.north - b.south) * 0.3;
    final lngPad = (b.east - b.west) * 0.35;

    return LatLngBounds(
      LatLng(b.south - latPad, b.west - lngPad),
      LatLng(b.north + latPad, b.east + lngPad),
    );
  }

  // ───────── UI ─────────

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 20, right: 10, bottom: 8),
                    child: Row(
                      children: [
                        Text(
                          "Your Route",
                          style: GoogleFonts.luckiestGuy(
                            fontWeight: FontWeight.w300,
                            fontSize: isTablet ? 32 : 28,
                            color: primaryColor,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () async {
                            Navigator.pop(context);
                          },
                          icon: const Icon(FontAwesomeIcons.backward,
                              color: primaryColor),
                          tooltip: "Post a new ride",
                        ),
                      ],
                    ),
                  ),

                  // MAP (Uber-style big map)
                  Expanded(
                    flex: 6,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: FlutterMap(
                          options: MapOptions(
                            initialCameraFit: CameraFit.bounds(
                              bounds: _bounds(),
                              padding: const EdgeInsets.all(40),
                            ),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.hopeir.app',
                            ),

                            // ROUTE
                            PolylineLayer(
                              polylines: [
                                Polyline(
                                  points: routePoints,
                                  strokeWidth: 8,
                                  color: Colors.black.withOpacity(0.15),
                                ),
                                Polyline(
                                  points: routePoints,
                                  strokeWidth: 5,
                                  color: Colors.blue,
                                ),
                              ],
                            ),

                            // PINS (UBER STYLE)
                            MarkerLayer(
                              markers: [
                                _hopPin(snappedStart, Colors.green),
                                _hopPin(snappedEnd, Colors.red),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // LOCATION INFO (Uber style)
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _infoRow(
                              Icons.location_on, widget.fromName, Colors.green),
                          const SizedBox(height: 12),
                          _infoRow(
                              Icons.location_on, widget.toName, Colors.red),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ───────── UBER PIN ─────────

  Marker _hopPin(LatLng point, Color color) {
    return Marker(
      point: point,
      width: 50,
      height: 50,
      alignment: Alignment.center,
      child: Transform.translate(
        offset: const Offset(0, -22), // 🔥 THIS IS THE KEY
        child: Icon(
          Icons.location_on,
          size: 44,
          color: color,
        ),
      ),
    );
  }

  // ───────── INFO ROW ─────────

  Widget _infoRow(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
