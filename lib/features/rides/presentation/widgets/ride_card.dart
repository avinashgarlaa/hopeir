import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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

  @override
  Widget build(BuildContext context) {
    final ride = widget.ride;
    final wsState = ref.watch(rideWSControllerProvider(ride.id));
    final status = wsState.status;

    final vehicleAsync = ref.watch(vehicleByIdProvider(ride.vehicle));
    final fromStationAsync = ref.watch(stationByIdProvider(ride.startLocation));
    final toStationAsync = ref.watch(stationByIdProvider(ride.endLocation));

    final formattedDate =
        DateFormat('EEE, MMM d | h:mm a').format(ride.startTime);

    final showStart = status == "pending" || status == "scheduled";
    final showEnd = status == "ongoing";
    final showCancel = ["pending", "scheduled", "ongoing"].contains(status);

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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAsyncText(fromStationAsync, (s) => s.name),
                    const SizedBox(height: 2),
                    const Icon(Icons.arrow_downward_rounded, size: 16),
                    const SizedBox(height: 2),
                    _buildAsyncText(toStationAsync, (s) => s.name),
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
            ],
          ),
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

  /// 🚦 Action Buttons (Start/End/Cancel)
  Widget _buildActionButton(String label, Color color) {
    return ElevatedButton.icon(
      onPressed: _actionInProgress
          ? null
          : () async {
              setState(() => _actionInProgress = true);
              await ref
                  .read(rideWSControllerProvider(widget.ride.id).notifier)
                  .sendAction(label.toLowerCase());
              if (mounted) {
                setState(() => _actionInProgress = false);
              }
              widget.onActionCompleted();
            },
      icon: Icon(_getActionIcon(label), size: 18),
      label: Text(label, style: GoogleFonts.poppins(fontSize: 14)),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
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

  /// 💫 Shimmer Placeholder
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

  /// 🎨 Status Colors
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case "scheduled":
        return const Color(0xFF64B5F6); // Blue
      case "ongoing":
        return const Color(0xFFFFA726); // Orange
      case "completed":
        return const Color(0xFF66BB6A); // Green
      case "cancelled":
        return const Color(0xFFEF5350); // Red
      default:
        return Colors.grey;
    }
  }

  /// 🧩 Status Icons
  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case "scheduled":
        return Icons.schedule;
      case "ongoing":
        return Icons.directions_run;
      case "completed":
        return Icons.check_circle_outline;
      case "cancelled":
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
  }

  /// 🧩 Action Icons
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

  /// 🔤 Capitalize Status
  String _capitalize(String s) {
    return s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();
  }
}
