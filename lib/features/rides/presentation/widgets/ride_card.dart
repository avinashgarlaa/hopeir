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

    final formattedDate = DateFormat('dd MMM, hh:mm a').format(ride.startTime);
    final showStart = status == "pending" || status == "scheduled";
    final showEnd = status == "ongoing";
    final showCancel = ["pending", "scheduled", "ongoing"].contains(status);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 🔼 Route Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.alt_route_rounded, color: Colors.indigo),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAsyncText(fromStationAsync, (s) => s.name),
                    const SizedBox(height: 2),
                    const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                    const SizedBox(height: 2),
                    _buildAsyncText(toStationAsync, (s) => s.name),
                  ],
                ),
              ),
              _statusBadge(status),
            ],
          ),

          const SizedBox(height: 16),

          /// 🗓 Date and Time
          Row(
            children: [
              const Icon(
                Icons.calendar_today_rounded,
                size: 18,
                color: Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                formattedDate,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          /// 🚗 Vehicle Info
          Row(
            children: [
              Icon(Icons.directions_car_rounded, color: widget.primaryColor),
              const SizedBox(width: 8),
              Expanded(
                child: _buildAsyncText(vehicleAsync, (v) {
                  return '${v.vehicleType} ${v.vehicleModel} '
                      '(${v.vehicleLicensePlate}) • ${v.vehicleColor}';
                }),
              ),
            ],
          ),

          const SizedBox(height: 20),

          /// 🧭 Action Buttons
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

  /// 🎯 Stylish Status Badge
  Widget _statusBadge(String status) {
    final color = _getStatusColor(status);
    final icon = _getStatusIcon(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 5),
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

  /// 🟢 Start / End / Cancel Buttons
  Widget _buildActionButton(String label, Color color) {
    return ElevatedButton.icon(
      onPressed:
          _actionInProgress
              ? null
              : () {
                setState(() => _actionInProgress = true);
                ref
                    .read(rideWSControllerProvider(widget.ride.id).notifier)
                    .sendAction(label.toLowerCase());
                setState(() => _actionInProgress = false);
                widget.onActionCompleted();
              },
      icon: Icon(_getActionIcon(label), size: 18),
      label: Text(label, style: GoogleFonts.poppins(fontSize: 15)),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  /// 🔤 Capitalize status
  String _capitalize(String s) {
    return s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  /// 📦 Async Text Builder
  Widget _buildAsyncText<T>(
    AsyncValue<T> asyncValue,
    String Function(T) builder,
  ) {
    return asyncValue.when(
      data:
          (value) => Text(
            builder(value),
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
      loading: () => _shimmerText(width: 120),
      error:
          (_, __) => Text(
            "Unavailable",
            style: GoogleFonts.poppins(color: Colors.redAccent),
          ),
    );
  }

  /// 🌫 Loading placeholder
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

  /// 🎨 Status Color Palette
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case "scheduled":
        return const Color(0xFF64B5F6); // soft blue
      case "ongoing":
        return const Color(0xFFFFA726); // soft orange
      case "completed":
        return const Color(0xFF66BB6A); // soft green
      case "cancelled":
        return const Color(0xFFEF5350); // soft red
      default:
        return Colors.grey;
    }
  }

  /// 🎈 Status Icons
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

  /// ⏯ Action Icons
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
}
