import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hop_eir/features/rides/presentation/controllers/ride_ws_controller.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

const primaryColor = Color(0xFF6366F1);
const secondaryColor = Color(0xFF1E293B);
const accentGreen = Color(0xFF10B981);
const accentRed = Color(0xFFEF4444);
const accentYellow = Color(0xFFF59E0B);
const darkBg = Color(0xFF0F172A);

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
  LatLng? snappedStart;
  LatLng? snappedEnd;
  final MapController _mapController = MapController();
  bool _followDriver = true;

  ProviderSubscription<RideWSState>? _rideSub;
  LatLng? _driverPos;
  late final AnimationController _carAnimCtrl;

  DateTime _lastCameraMove = DateTime.now();
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    _carAnimCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    ref.read(rideWSControllerProvider(widget.rideId).notifier).connect();

    _rideSub =
        ref.listenManual(rideWSControllerProvider(widget.rideId), (prev, next) {
      if (!mounted || next.driverLatLng == null) return;

      final newPos = next.driverLatLng!;

      if (_driverPos == null) {
        setState(() => _driverPos = newPos);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_isMapReady) _fitAll();
        });
        return;
      }

      _animateCar(newPos);

      if (_followDriver && _isMapReady) {
        final now = DateTime.now();
        if (now.difference(_lastCameraMove).inMilliseconds > 1000) {
          _lastCameraMove = now;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_isMapReady) {
              _mapController.move(newPos, _mapController.camera.zoom);
            }
          });
        }
      }
    });

    _loadRoute();
  }

  @override
  void dispose() {
    _rideSub?.close();
    _carAnimCtrl.dispose();
    super.dispose();
  }

  void _animateCar(LatLng to) {
    final from = _driverPos!;
    _carAnimCtrl.stop();
    _carAnimCtrl.reset();
    _carAnimCtrl.addListener(() {
      final t = Curves.easeOutCubic.transform(_carAnimCtrl.value);
      final lat = from.latitude + (to.latitude - from.latitude) * t;
      final lng = from.longitude + (to.longitude - from.longitude) * t;
      if (mounted) setState(() => _driverPos = LatLng(lat, lng));
    });
    _carAnimCtrl.forward();
  }

  Future<void> _loadRoute() async {
    try {
      snappedStart = await _snapToRoad(widget.fromLat, widget.fromLng);
      snappedEnd = await _snapToRoad(widget.toLat, widget.toLng);
      await _fetchRoute(snappedStart!, snappedEnd!);
    } catch (e) {
      setState(() {
        routePoints = [
          LatLng(widget.fromLat, widget.fromLng),
          LatLng(widget.toLat, widget.toLng)
        ];
        loading = false;
      });
    }
  }

  Future<LatLng> _snapToRoad(double lat, double lng) async {
    try {
      final res = await http
          .get(Uri.parse(
              'https://router.project-osrm.org/nearest/v1/driving/$lng,$lat'))
          .timeout(const Duration(seconds: 3));
      final data = json.decode(res.body);
      if (data['waypoints']?.isNotEmpty == true) {
        final loc = data['waypoints'][0]['location'];
        return LatLng(loc[1], loc[0]);
      }
      // ignore: empty_catches
    } catch (e) {}
    return LatLng(lat, lng);
  }

  Future<void> _fetchRoute(LatLng start, LatLng end) async {
    try {
      final res = await http
          .get(Uri.parse(
              'https://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson'))
          .timeout(const Duration(seconds: 8));
      final data = json.decode(res.body);
      if (data['routes']?.isNotEmpty == true) {
        final coords = data['routes'][0]['geometry']['coordinates'] as List;
        setState(() {
          routePoints = coords.map((c) => LatLng(c[1], c[0])).toList();
          loading = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_isMapReady) _fitAll();
        });
      } else {
        throw Exception();
      }
    } catch (e) {
      setState(() {
        routePoints = [start, end];
        loading = false;
      });
    }
  }

  void _fitAll() {
    if (!_isMapReady) return;
    final points = [...routePoints];
    if (snappedStart != null) points.add(snappedStart!);
    if (snappedEnd != null) points.add(snappedEnd!);
    if (_driverPos != null) points.add(_driverPos!);

    if (points.isEmpty) return;

    final bounds = LatLngBounds.fromPoints(points);
    final latPad = (bounds.north - bounds.south) * 0.15;
    final lngPad = (bounds.east - bounds.west) * 0.15;

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds(
          LatLng(bounds.south - latPad, bounds.west - lngPad),
          LatLng(bounds.north + latPad, bounds.east + lngPad),
        ),
        padding: const EdgeInsets.all(40),
      ),
    );
  }

  String _getStatus(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return 'DRIVER ASSIGNED';
      case 'arriving':
        return 'ARRIVING SOON';
      case 'started':
        return 'TRIP IN PROGRESS';
      case 'ongoing':
        return 'ON THE WAY';
      default:
        return status.toUpperCase();
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return accentGreen;
      case 'arriving':
        return accentYellow;
      case 'started':
        return primaryColor;
      case 'ongoing':
        return primaryColor;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rideState = ref.watch(rideWSControllerProvider(widget.rideId));
    final isLive = _driverPos != null;
    final carPos = _driverPos ?? rideState.driverLatLng;

    if (loading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [darkBg, Color(0xFF1E1B4B)],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primaryColor.withOpacity(0.2),
                  ),
                  child: const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Loading your route...',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Full Screen Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              onMapReady: () {
                _isMapReady = true;
                _fitAll();
              },
              initialCameraFit: CameraFit.bounds(
                bounds: LatLngBounds.fromPoints(routePoints),
                padding: const EdgeInsets.all(40),
              ),
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              // Working Tile Layer - OpenStreetMap
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.hopeir.app',
                fallbackUrl:
                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              ),

              // Route Line
              if (routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    // Outer glow
                    Polyline(
                      points: routePoints,
                      strokeWidth: 8,
                      color: primaryColor.withOpacity(0.3),
                    ),
                    // Main route
                    Polyline(
                      points: routePoints,
                      strokeWidth: 4,
                      color: primaryColor,
                    ),
                    // Inner highlight
                    Polyline(
                      points: routePoints,
                      strokeWidth: 2,
                      color: Colors.white.withOpacity(0.4),
                    ),
                  ],
                ),

              MarkerLayer(
                markers: [
                  // Centered Pickup Marker
                  if (snappedStart != null)
                    Marker(
                      point: snappedStart!,
                      width: 100,
                      height: 100,
                      alignment: Alignment.center,
                      child: _buildPickupMarker(),
                    ),

                  // Centered Dropoff Marker
                  if (snappedEnd != null)
                    Marker(
                      point: snappedEnd!,
                      width: 100,
                      height: 100,
                      alignment: Alignment.center,
                      child: _buildDropoffMarker(),
                    ),

                  // Animated Car Marker
                  if (carPos != null)
                    Marker(
                      point: carPos,
                      width: 60,
                      height: 60,
                      alignment: Alignment.center,
                      child: _buildCarMarker(),
                    ),
                ],
              ),
            ],
          ),

          // Gradient Overlay for Top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Gradient Overlay for Bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Back Button
          Positioned(
            top: 50,
            left: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.15),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 18),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // Status Card
          Positioned(
            top: 50,
            left: 80,
            right: 16,
            child: TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 500),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: primaryColor.withOpacity(0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color:
                            _getStatusColor(rideState.status).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.directions_car_rounded,
                        color: _getStatusColor(rideState.status),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getStatus(rideState.status),
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isLive ? accentGreen : Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isLive
                                    ? 'Live location active'
                                    : 'Waiting for driver signal...',
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isLive
                              ? [accentGreen, accentGreen.withOpacity(0.7)]
                              : [Colors.grey, Colors.grey.withOpacity(0.7)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isLive ? 'LIVE' : 'OFFLINE',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Right Side Control Buttons
          Positioned(
            bottom: 140,
            right: 16,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.15),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(
                      _followDriver
                          ? Icons.gps_fixed_rounded
                          : Icons.gps_off_rounded,
                      color: _followDriver ? primaryColor : Colors.white,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() => _followDriver = !_followDriver);
                      if (_followDriver && carPos != null && _isMapReady) {
                        _mapController.move(carPos, _mapController.camera.zoom);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.15),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.center_focus_strong_rounded,
                        color: Colors.white, size: 20),
                    onPressed: () => _fitAll(),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Info Card
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 500),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Pickup Location
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            accentGreen.withOpacity(0.15),
                            accentGreen.withOpacity(0.05)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: accentGreen.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  accentGreen,
                                  accentGreen.withOpacity(0.8)
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: accentGreen.withOpacity(0.4),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.circle,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'PICKUP LOCATION',
                                  style: GoogleFonts.poppins(
                                    color: accentGreen,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.fromName,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Dropoff Location
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            accentRed.withOpacity(0.15),
                            accentRed.withOpacity(0.05)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: accentRed.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [accentRed, accentRed.withOpacity(0.8)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: accentRed.withOpacity(0.4),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.flag,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'DROPOFF LOCATION',
                                  style: GoogleFonts.poppins(
                                    color: accentRed,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.toName,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickupMarker() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accentGreen, accentGreen.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: accentGreen.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_on, color: Colors.white, size: 14),
                const SizedBox(width: 6),
                Text(
                  'PICKUP',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentGreen,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: accentGreen.withOpacity(0.6),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropoffMarker() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accentRed, accentRed.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: accentRed.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.flag, color: Colors.white, size: 14),
                const SizedBox(width: 6),
                Text(
                  'DROP',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentRed,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: accentRed.withOpacity(0.6),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarMarker() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [primaryColor, primaryColor.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.6),
            blurRadius: 20,
            spreadRadius: 4,
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: const Icon(
        Icons.directions_car_rounded,
        color: Colors.white,
        size: 22,
      ),
    );
  }
}
