import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hop_eir/features/rides/presentation/pages/ride_chat_page.dart';
import 'package:hop_eir/features/rides/presentation/pages/ride_map_page.dart';
import 'package:intl/intl.dart';

import 'package:hop_eir/features/rides/domain/entities/ride.dart';
import 'package:hop_eir/features/rides/presentation/controllers/ride_ws_controller.dart';
import 'package:hop_eir/features/stations/presentation/providers/providers.dart';
import 'package:hop_eir/features/vehicles/presentation/provider/vehicle_providers.dart';

class RideCard extends ConsumerStatefulWidget {
  final Ride ride;
  final VoidCallback onActionCompleted;
  final Color primaryColor;

  const RideCard({
    super.key,
    required this.ride,
    required this.onActionCompleted,
    this.primaryColor = const Color.fromRGBO(137, 177, 98, 1),
  });

  @override
  ConsumerState<RideCard> createState() => _RideCardState();
}

class _RideCardState extends ConsumerState<RideCard> {
  bool _actionInProgress = false;

  bool _isRideActiveForTracking(String status) {
    final s = status.toLowerCase();
    return s == 'ongoing' || s == 'started' || s == 'in_progress';
  }

  @override
  Widget build(BuildContext context) {
    final ride = widget.ride;

    final wsState = ref.watch(rideWSControllerProvider(ride.id));
    final status = wsState.status.toLowerCase();

    final vehicleAsync = ref.watch(vehicleByIdProvider(ride.vehicle));
    final fromStationAsync = ref.watch(stationByIdProvider(ride.startLocation));
    final toStationAsync = ref.watch(stationByIdProvider(ride.endLocation));

    final formattedDate =
        DateFormat('EEE, MMM d | h:mm a').format(ride.startTime);

    final showStart = status == "pending" || status == "scheduled";
    final showEnd =
        status == "ongoing" || status == "in_progress" || status == "started";
    final showCancel = [
      "pending",
      "scheduled",
      "ongoing",
      "in_progress",
      "started"
    ].contains(status);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 🚏 Route Display
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.alt_route_rounded, color: Colors.deepPurple),
              const SizedBox(width: 10),

              // Route names
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAsyncText(fromStationAsync, (s) => s.name),
                    const SizedBox(height: 2),
                    const Icon(Icons.arrow_downward_rounded, size: 16),
                    const SizedBox(height: 2),
                    _buildAsyncText(toStationAsync, (s) => s.name),
                    const SizedBox(height: 8),

                    // 🗺️ View on Map button
                    Row(
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.map_outlined, size: 18),
                          label: const Text("View on Map"),
                          onPressed: () {
                            final fromStation = fromStationAsync.value;
                            final toStation = toStationAsync.value;
                            if (fromStation == null || toStation == null)
                              return;

                            // ✅ ensure WS connected for tracking updates
                            ref
                                .read(
                                    rideWSControllerProvider(ride.id).notifier)
                                .connect();

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RideMapPage(
                                  rideId: ride.id,
                                  fromLat: fromStation.latitude,
                                  fromLng: fromStation.longitude,
                                  toLat: toStation.latitude,
                                  toLng: toStation.longitude,
                                  fromName: fromStation.name,
                                  toName: toStation.name,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              _statusBadge(status),
            ],
          ),

          const SizedBox(height: 16),

          /// 🕓 Date & Time
          Row(
            children: [
              const Icon(Icons.access_time, size: 18, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                formattedDate,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          /// 🚗 Vehicle Info
          Row(
            children: [
              Icon(Icons.directions_car, color: widget.primaryColor),
              const SizedBox(width: 8),
              Expanded(
                child: _buildAsyncText(vehicleAsync, (v) {
                  return '${v.vehicleModel} (${v.vehicleLicensePlate}) • ${v.vehicleColor}';
                }),
              ),
            ],
          ),

          const SizedBox(height: 18),

          /// 🎯 Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (showStart) _buildActionButton("Start", widget.primaryColor),
              if (showEnd) _buildActionButton("End", Colors.orange),
              if (showCancel) _buildActionButton("Cancel", Colors.red.shade400),

              // 💬 CHAT BUTTON
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RideChatPage(rideId: ride.id),
                    ),
                  );
                },
                icon: const Icon(Icons.chat_bubble_outline, size: 18),
                label: Text(
                  "Chat",
                  style: GoogleFonts.poppins(fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),

          // ✅ Tracking status row
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.my_location, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                wsState.driverTrackingEnabled
                    ? "Live tracking ON"
                    : "Live tracking OFF",
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color:
                      wsState.driverTrackingEnabled ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          if (wsState.lastError != null) ...[
            const SizedBox(height: 6),
            Text(
              wsState.lastError!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.red),
            ),
          ],
        ],
      ),
    );
  }

  /// 🔖 Status Badge
  Widget _statusBadge(String status) {
    final color = _getStatusColor(status);
    final icon = _getStatusIcon(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            _capitalize(status),
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// 🚦 Action Buttons (Start / End / Cancel)
  Widget _buildActionButton(String label, Color color) {
    final action = _mapLabelToAction(label);

    return ElevatedButton.icon(
      onPressed: (_actionInProgress || action == null)
          ? null
          : () async {
              setState(() => _actionInProgress = true);

              final ws = ref.read(
                rideWSControllerProvider(widget.ride.id).notifier,
              );

              try {
                ws.connect();

                // ✅ send action
                ws.sendAction(action);

                // ✅ MAIN FIX:
                // start tracking AFTER backend updates status
                if (action == "start") {
                  // wait a bit for ride_status_update
                  await Future.delayed(const Duration(seconds: 1));

                  final latest =
                      ref.read(rideWSControllerProvider(widget.ride.id)).status;

                  // if still not active, wait again
                  if (!_isRideActiveForTracking(latest)) {
                    await Future.delayed(const Duration(seconds: 1));
                  }

                  // finally start tracking
                  await ws.startDriverLiveTracking();
                }

                if (action == "end" || action == "cancel") {
                  await ws.stopDriverLiveTracking();
                }
              } finally {
                if (mounted) setState(() => _actionInProgress = false);
                widget.onActionCompleted();
              }
            },
      icon: Icon(_getActionIcon(label), size: 18),
      label: Text(
        label,
        style: GoogleFonts.poppins(fontSize: 14),
      ),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
    );
  }

  String? _mapLabelToAction(String label) {
    switch (label.toLowerCase()) {
      case 'start':
        return 'start';
      case 'end':
        return 'end';
      case 'cancel':
        return 'cancel';
      default:
        return null;
    }
  }

  /// 🌐 Async Data Handler
  Widget _buildAsyncText<T>(
    AsyncValue<T> asyncValue,
    String Function(T) builder,
  ) {
    return asyncValue.when(
      data: (value) => Text(
        builder(value),
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      loading: () => _shimmerText(width: 120),
      error: (_, __) => Text(
        "Unavailable",
        style: GoogleFonts.poppins(color: Colors.redAccent),
      ),
    );
  }

  Widget _shimmerText({required double width}) {
    return Container(
      width: width,
      height: 16,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case "scheduled":
        return const Color(0xFF64B5F6);
      case "ongoing":
      case "in_progress":
      case "started":
        return const Color(0xFFFFA726);
      case "completed":
        return const Color(0xFF66BB6A);
      case "cancelled":
        return const Color(0xFFEF5350);
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case "scheduled":
        return Icons.schedule;
      case "ongoing":
      case "in_progress":
      case "started":
        return Icons.directions_run;
      case "completed":
        return Icons.check_circle_outline;
      case "cancelled":
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
  }

  IconData _getActionIcon(String label) {
    switch (label.toLowerCase()) {
      case "start":
        return Icons.play_arrow_rounded;
      case "end":
        return Icons.stop_rounded;
      case "cancel":
        return Icons.close_rounded;
      default:
        return Icons.flash_on;
    }
  }

  String _capitalize(String s) {
    return s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();
  }
}
