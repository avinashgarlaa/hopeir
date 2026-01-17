import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hop_eir/features/rides/presentation/controllers/ride_ws_controller.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

const primaryColor = Color(0xFF2F54EB);

class RideMapPage extends ConsumerStatefulWidget {
  final double fromLat;
  final double fromLng;
  final double toLat;
  final double toLng;
  final String fromName;
  final String toName;
  final int rideId;

  const RideMapPage({
    super.key,
    required this.fromLat,
    required this.fromLng,
    required this.toLat,
    required this.toLng,
    required this.fromName,
    required this.toName,
    required this.rideId,
  });

  @override
  ConsumerState<RideMapPage> createState() => _RideMapPageState();
}

class _RideMapPageState extends ConsumerState<RideMapPage> {
  List<LatLng> routePoints = [];
  bool loading = true;

  late LatLng snappedStart;
  late LatLng snappedEnd;

  Timer? _forceReconnectTimer;

  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();

    // ✅ connect ws
    Future.microtask(() {
      ref.read(rideWSControllerProvider(widget.rideId).notifier).connect();
    });

    // ✅ reconnect if disconnected only
    _forceReconnectTimer = Timer.periodic(const Duration(seconds: 2), (t) {
      final s = ref.read(rideWSControllerProvider(widget.rideId));

      // once location comes, stop auto reconnect loop
      if (s.driverLatLng != null) {
        t.cancel();
        return;
      }

      if (!s.connected || s.lastError != null) {
        ref.read(rideWSControllerProvider(widget.rideId).notifier).connect();
      }
    });

    _prepareRoute();
  }

  @override
  void dispose() {
    _forceReconnectTimer?.cancel();
    _forceReconnectTimer = null;
    super.dispose();
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

    if (!mounted) return;

    setState(() {
      routePoints = coords.map((c) => LatLng(c[1], c[0])).toList();
      loading = false;
    });

    // ✅ fit to route initially
    Future.delayed(const Duration(milliseconds: 200), () {
      _fitRoute();
    });
  }

  // ───────── CAMERA HELPERS ─────────

  LatLngBounds _boundsRouteOnly() {
    if (routePoints.isEmpty) {
      return LatLngBounds(
        LatLng(widget.fromLat, widget.fromLng),
        LatLng(widget.toLat, widget.toLng),
      );
    }

    final b = LatLngBounds.fromPoints(routePoints);
    final latPad = (b.north - b.south) * 0.25;
    final lngPad = (b.east - b.west) * 0.25;

    return LatLngBounds(
      LatLng(b.south - latPad, b.west - lngPad),
      LatLng(b.north + latPad, b.east + lngPad),
    );
  }

  LatLngBounds _boundsWithDriver(LatLng? driver) {
    final points = <LatLng>[];

    if (routePoints.isNotEmpty) points.addAll(routePoints);
    points.add(snappedStart);
    points.add(snappedEnd);
    if (driver != null) points.add(driver);

    final b = LatLngBounds.fromPoints(points);

    final latPad = (b.north - b.south) * 0.25;
    final lngPad = (b.east - b.west) * 0.25;

    return LatLngBounds(
      LatLng(b.south - latPad, b.west - lngPad),
      LatLng(b.north + latPad, b.east + lngPad),
    );
  }

  void _fitRoute() {
    final b = _boundsRouteOnly();
    _mapController.fitCamera(
      CameraFit.bounds(bounds: b, padding: const EdgeInsets.all(48)),
    );
  }

  void _fitAll(LatLng? driver) {
    final b = _boundsWithDriver(driver);
    _mapController.fitCamera(
      CameraFit.bounds(bounds: b, padding: const EdgeInsets.all(48)),
    );
  }

  bool _isRideActive(String status) {
    final s = status.toLowerCase();
    return s == 'accepted' ||
        s == 'arriving' ||
        s == 'started' ||
        s == 'ongoing' ||
        s == 'in_progress';
  }

  // ───────── UI ─────────

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    final rideWSState = ref.watch(rideWSControllerProvider(widget.rideId));
    final driverLatLng = rideWSState.driverLatLng;
    final driverBearing = rideWSState.driverBearing;

    final rideActive = _isRideActive(rideWSState.status);
    final liveOn = driverLatLng != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  // HEADER
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
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            FontAwesomeIcons.backward,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // STATUS + BUTTON BAR
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            blurRadius: 10,
                            color: Colors.black12,
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          _statusPill(
                            icon: Icons.directions_car,
                            label: rideWSState.status.toUpperCase(),
                            color: rideActive ? Colors.green : Colors.orange,
                          ),
                          const SizedBox(width: 10),
                          _statusPill(
                            icon: Icons.circle,
                            label: liveOn ? "LIVE" : "OFF",
                            color: liveOn ? Colors.green : Colors.red,
                          ),
                          const Spacer(),

                          // ✅ Fit Route
                          _iconBtn(
                            tooltip: "Fit Route",
                            icon: Icons.alt_route,
                            onTap: _fitRoute,
                          ),

                          // ✅ Fit All (Route + Driver)
                          _iconBtn(
                            tooltip: "Fit All",
                            icon: Icons.center_focus_strong,
                            onTap: () => _fitAll(driverLatLng),
                          ),

                          // ✅ Reconnect
                          _iconBtn(
                            tooltip: "Reconnect",
                            icon: Icons.refresh,
                            onTap: () {
                              ref
                                  .read(rideWSControllerProvider(widget.rideId)
                                      .notifier)
                                  .connect();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  if (!liveOn)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        "Waiting for driver live location...",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                  // MAP
                  Expanded(
                    flex: 6,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCameraFit: CameraFit.bounds(
                              bounds: _boundsWithDriver(driverLatLng),
                              padding: const EdgeInsets.all(40),
                            ),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.hopeir.app',
                            ),
                            PolylineLayer(
                              polylines: [
                                Polyline(
                                  points: routePoints,
                                  strokeWidth: 8,
                                  color: Colors.black.withOpacity(0.12),
                                ),
                                Polyline(
                                  points: routePoints,
                                  strokeWidth: 5,
                                  color: primaryColor,
                                ),
                              ],
                            ),
                            MarkerLayer(
                              markers: [
                                _hopPin(snappedStart, Colors.green),
                                _hopPin(snappedEnd, Colors.red),
                                if (driverLatLng != null)
                                  _driverMarker(driverLatLng, driverBearing),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // LOCATION INFO
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
                          const SizedBox(height: 10),
                          if (rideWSState.lastError != null)
                            Text(
                              rideWSState.lastError!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.red,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ───────── UI COMPONENTS ─────────

  Widget _statusPill({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn({
    required String tooltip,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Tooltip(
          message: tooltip,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: primaryColor, size: 20),
          ),
        ),
      ),
    );
  }

  Marker _hopPin(LatLng point, Color color) {
    return Marker(
      point: point,
      width: 50,
      height: 50,
      alignment: Alignment.center,
      child: Transform.translate(
        offset: const Offset(0, -22),
        child: Icon(Icons.location_on, size: 44, color: color),
      ),
    );
  }

  Marker _driverMarker(LatLng point, double bearing) {
    return Marker(
      point: point,
      width: 60,
      height: 60,
      alignment: Alignment.center,
      child: Transform.rotate(
        angle: (bearing * 3.1415926535) / 180.0,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black26)],
          ),
          padding: const EdgeInsets.all(10),
          child: const Icon(
            Icons.directions_car,
            size: 30,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

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
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
