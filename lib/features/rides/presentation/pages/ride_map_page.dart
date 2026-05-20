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

class _RideMapPageState extends ConsumerState<RideMapPage>
    with SingleTickerProviderStateMixin {
  List<LatLng> routePoints = [];
  bool loading = true;
  bool _mapReady = false;

  LatLng? snappedStart;
  LatLng? snappedEnd;

  final MapController _mapController = MapController();

  /// Camera follow
  bool _followDriver = true;
  bool _didFitOnce = false;

  /// Riverpod subscription
  ProviderSubscription<RideWSState>? _rideSub;

  /// Smooth marker animation
  LatLng? _animatedPos;
  // ignore: unused_field
  LatLng? _targetPos;

  late final AnimationController _carAnimCtrl;

  /// Camera throttle so map doesn't shake
  DateTime _lastCameraMove = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();

    _carAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    ref.read(rideWSControllerProvider(widget.rideId).notifier).connect();

    /// ✅ Listen for driver location updates
    _rideSub = ref.listenManual<RideWSState>(
      rideWSControllerProvider(widget.rideId),
      (prev, next) {
        if (!mounted) return;

        final nextDriver = next.driverLatLng;
        if (nextDriver == null) return;

        // ✅ first point
        if (_animatedPos == null) {
          setState(() {
            _animatedPos = nextDriver;
            _targetPos = nextDriver;
          });

          // Fit once when map is ready
          if (!_didFitOnce) {
            _didFitOnce = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted || !_mapReady) return;
              _fitAll(nextDriver);
            });
          }
          return;
        }

        // ✅ animate smoothly between old and new
        _startCarAnimation(to: nextDriver);

        // ✅ Follow (camera) ONLY IF enabled and only every 1.2 sec
        if (_followDriver && _mapReady) {
          final now = DateTime.now();
          if (now.difference(_lastCameraMove).inMilliseconds > 1200) {
            _lastCameraMove = now;

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted || !_mapReady) return;
              _mapController.move(nextDriver, _mapController.camera.zoom);
            });
          }
        }
      },
    );

    _prepareRoute();
  }

  @override
  void dispose() {
    _rideSub?.close();
    _rideSub = null;

    _carAnimCtrl.dispose();
    super.dispose();
  }

  // ───────────────────────────
  // ✅ Car Smooth Animation
  // ───────────────────────────
  void _startCarAnimation({required LatLng to}) {
    final from = _animatedPos!;
    _targetPos = to;

    _carAnimCtrl.stop();
    _carAnimCtrl.reset();

    _carAnimCtrl.addListener(() {
      final p = Curves.easeInOut.transform(_carAnimCtrl.value);

      final lat = from.latitude + (to.latitude - from.latitude) * p;
      final lng = from.longitude + (to.longitude - from.longitude) * p;

      if (!mounted) return;
      setState(() => _animatedPos = LatLng(lat, lng));
    });

    _carAnimCtrl.forward();
  }

  // ───────────────────────────
  // ROUTE
  // ───────────────────────────
  Future<void> _prepareRoute() async {
    try {
      final start = await _snap(widget.fromLat, widget.fromLng);
      final end = await _snap(widget.toLat, widget.toLng);

      snappedStart = start;
      snappedEnd = end;

      if (!mounted) return;
      setState(() {});

      await _fetchRoute(start, end);
    } catch (e) {
      debugPrint("❌ _prepareRoute error: $e");
      if (!mounted) return;
      setState(() => loading = false);
    }
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_mapReady) return;
      _fitRoute();
    });
  }

  // ───────────────────────────
  // CAMERA HELPERS
  // ───────────────────────────
  LatLngBounds _boundsWithDriver(LatLng? driver) {
    final points = <LatLng>[];
    if (routePoints.isNotEmpty) points.addAll(routePoints);
    if (snappedStart != null) points.add(snappedStart!);
    if (snappedEnd != null) points.add(snappedEnd!);
    if (driver != null) points.add(driver);

    if (points.isEmpty) {
      return LatLngBounds(
        LatLng(widget.fromLat, widget.fromLng),
        LatLng(widget.toLat, widget.toLng),
      );
    }

    final b = LatLngBounds.fromPoints(points);
    final latPad = (b.north - b.south) * 0.25;
    final lngPad = (b.east - b.west) * 0.25;

    return LatLngBounds(
      LatLng(b.south - latPad, b.west - lngPad),
      LatLng(b.north + latPad, b.east + lngPad),
    );
  }

  LatLngBounds _boundsRouteOnly() {
    if (routePoints.isEmpty) {
      return LatLngBounds(
        LatLng(widget.fromLat, widget.fromLng),
        LatLng(widget.toLat, widget.toLng),
      );
    }
    return LatLngBounds.fromPoints(routePoints);
  }

  void _fitRoute() {
    if (!_mapReady) return;
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: _boundsRouteOnly(),
        padding: const EdgeInsets.all(48),
      ),
    );
  }

  void _fitAll(LatLng? driver) {
    if (!_mapReady) return;
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: _boundsWithDriver(driver),
        padding: const EdgeInsets.all(48),
      ),
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

  // ───────────────────────────
  // UI
  // ───────────────────────────
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    final rideWSState = ref.watch(rideWSControllerProvider(widget.rideId));

    final driverLatLng = rideWSState.driverLatLng;
    final carPos = _animatedPos ?? driverLatLng;

    final rideActive = _isRideActive(rideWSState.status);
    final liveOn = carPos != null;

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

                  // STATUS BAR
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
                          BoxShadow(blurRadius: 10, color: Colors.black12),
                        ],
                      ),
                      child: Row(
                        children: [
                          _statusPill(
                            icon: Icons.directions_car,
                            label: rideWSState.status.toUpperCase(),
                            color: rideActive ? Colors.green : Colors.orange,
                          ),
                          const SizedBox(width: 6),
                          _statusPill(
                            icon: Icons.circle,
                            label: liveOn ? "LIVE" : "OFF",
                            color: liveOn ? Colors.green : Colors.red,
                          ),
                          const Spacer(),
                          _iconBtn(
                            tooltip: "Fit Route",
                            icon: Icons.alt_route,
                            onTap: _fitRoute,
                          ),
                          _iconBtn(
                            tooltip: "Fit All",
                            icon: Icons.center_focus_strong,
                            onTap: () => _fitAll(carPos),
                          ),
                          _iconBtn(
                            tooltip: _followDriver
                                ? "Disable Follow"
                                : "Enable Follow",
                            icon:
                                _followDriver ? Icons.gps_off : Icons.gps_fixed,
                            onTap: () {
                              setState(() => _followDriver = !_followDriver);
                              if (_followDriver &&
                                  carPos != null &&
                                  _mapReady) {
                                _mapController.move(
                                  carPos,
                                  _mapController.camera.zoom,
                                );
                              }
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
                            onMapReady: () {
                              _mapReady = true;
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (!mounted) return;
                                if (carPos != null) {
                                  _fitAll(carPos);
                                } else {
                                  _fitRoute();
                                }
                              });
                            },
                            initialCameraFit: CameraFit.bounds(
                              bounds: _boundsWithDriver(carPos),
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
                                if (snappedStart != null)
                                  _hopPin(snappedStart!, Colors.green),
                                if (snappedEnd != null)
                                  _hopPin(snappedEnd!, Colors.red),

                                /// ✅ ONLY CAR MOVES (MAP DOESN'T MOVE)
                                if (carPos != null) _carMarker(carPos),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // INFO
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _infoRow(
                            Icons.location_on,
                            widget.fromName,
                            Colors.green,
                          ),
                          const SizedBox(height: 12),
                          _infoRow(
                            Icons.location_on,
                            widget.toName,
                            Colors.red,
                          ),
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

  // ───────── UI Components ─────────

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

  /// ✅ Uber-like small car
  Marker _carMarker(LatLng point) {
    return Marker(
      point: point,
      width: 28,
      height: 28,
      alignment: Alignment.center,
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(blurRadius: 5, color: Colors.black26),
          ],
        ),
        padding: const EdgeInsets.all(4),
        child: const Icon(
          Icons.directions_car,
          size: 14,
          color: Colors.black,
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
