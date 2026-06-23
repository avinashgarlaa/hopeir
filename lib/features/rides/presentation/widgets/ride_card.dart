import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hop_eir/features/rides/presentation/controllers/ride_ws_controller.dart';
import 'package:hop_eir/features/rides/presentation/pages/ride_chat_page.dart';
import 'package:hop_eir/features/rides/presentation/pages/ride_map_page.dart';
import 'package:intl/intl.dart';

import 'package:hop_eir/features/rides/domain/entities/ride.dart';
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
    this.primaryColor = const Color(0xFF89B162),
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
    final fromAsync = ref.watch(stationByIdProvider(ride.startLocation));
    final toAsync = ref.watch(stationByIdProvider(ride.endLocation));
    final formattedDate = DateFormat('EEE, MMM d').format(ride.startTime);
    final formattedTime = DateFormat('hh:mm a').format(ride.startTime);

    final showStart = status == "pending" || status == "scheduled";
    final showEnd =
        status == "ongoing" || status == "started" || status == "in_progress";
    final showCancel = [
      "pending",
      "scheduled",
      "ongoing",
      "in_progress",
      "started"
    ].contains(status);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Section
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          widget.primaryColor,
                          widget.primaryColor.withOpacity(0.7)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.directions_car_rounded,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Ride ${ride.status}",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: const Color(0xFF1A1A2E),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.calendar_today,
                                    size: 10, color: Colors.grey[500]),
                                const SizedBox(width: 4),
                                Text(
                                  formattedDate,
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey[600],
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              width: 3,
                              height: 3,
                              decoration: BoxDecoration(
                                color: Colors.grey[400],
                                shape: BoxShape.circle,
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.access_time,
                                    size: 10, color: Colors.grey[500]),
                                const SizedBox(width: 4),
                                Text(
                                  formattedTime,
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey[600],
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(status),
                ],
              ),

              const SizedBox(height: 16),

              // Route Section
              fromAsync.when(
                data: (from) {
                  return toAsync.when(
                    data: (to) {
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FBF4),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          children: [
                            _buildRouteTile("Pickup", from.name,
                                Icons.my_location_rounded, Colors.green),
                            const SizedBox(height: 8),
                            _buildRouteTile("Destination", to.name,
                                Icons.location_on_rounded, Colors.redAccent),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  final fromStation = fromAsync.value;
                                  final toStation = toAsync.value;
                                  if (fromStation == null ||
                                      toStation == null) {
                                    return;
                                  }

                                  ref
                                      .read(rideWSControllerProvider(ride.id)
                                          .notifier)
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
                                icon: Icon(Icons.map_rounded,
                                    size: 16, color: widget.primaryColor),
                                label: Text(
                                  "View Route Map",
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                    color: widget.primaryColor,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                      color:
                                          widget.primaryColor.withOpacity(0.3)),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),

              const SizedBox(height: 14),

              // Vehicle Section
              vehicleAsync.when(
                data: (vehicle) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FC),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: widget.primaryColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.electric_car_rounded,
                              color: widget.primaryColor, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                vehicle.vehicleModel,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: const Color(0xFF1A1A2E),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Wrap(
                                spacing: 8,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.confirmation_number,
                                          size: 10, color: Colors.grey[500]),
                                      const SizedBox(width: 3),
                                      Text(
                                        vehicle.vehicleLicensePlate,
                                        style: GoogleFonts.poppins(
                                          color: Colors.grey[600],
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.palette,
                                          size: 10, color: Colors.grey[500]),
                                      const SizedBox(width: 3),
                                      Text(
                                        vehicle.vehicleColor,
                                        style: GoogleFonts.poppins(
                                          color: Colors.grey[600],
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),

              const SizedBox(height: 14),

              // Live Tracking Status
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: wsState.driverTrackingEnabled
                      ? Colors.green.withOpacity(0.08)
                      : Colors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: wsState.driverTrackingEnabled
                            ? Colors.green
                            : Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.my_location_rounded,
                        color: Colors.white,
                        size: 10,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        wsState.driverTrackingEnabled
                            ? "Live tracking active"
                            : "Live tracking inactive",
                        style: GoogleFonts.poppins(
                          color: wsState.driverTrackingEnabled
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Action Buttons
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (showStart)
                    _buildActionButton(
                      "Start",
                      Icons.play_arrow_rounded,
                      widget.primaryColor,
                      "start",
                    ),
                  if (showEnd)
                    _buildActionButton(
                      "End",
                      Icons.stop_rounded,
                      Colors.orange,
                      "end",
                    ),
                  if (showCancel)
                    _buildActionButton(
                      "Cancel",
                      Icons.cancel_rounded,
                      Colors.redAccent,
                      "cancel",
                    ),
                  _buildChatButton(),
                ],
              ),

              if (wsState.lastError != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline,
                          size: 14, color: Colors.red[400]),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          wsState.lastError!,
                          style: GoogleFonts.poppins(
                            color: Colors.red[400],
                            fontSize: 10,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 450.ms).slideY(begin: 0.08, end: 0);
  }

  Widget _buildRouteTile(
      String title, String value, IconData icon, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: Colors.grey[500],
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: const Color(0xFF1A1A2E),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = _getStatusColor(status);
    final icon = _getStatusIcon(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            _capitalize(status),
            style: GoogleFonts.poppins(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 9,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      String label, IconData icon, Color color, String actionType) {
    return SizedBox(
      height: 42,
      child: ElevatedButton.icon(
        onPressed: (_actionInProgress)
            ? null
            : () async {
                setState(() => _actionInProgress = true);
                final ws =
                    ref.read(rideWSControllerProvider(widget.ride.id).notifier);

                try {
                  ws.connect();
                  ws.sendAction(actionType);

                  if (actionType == "start") {
                    await Future.delayed(const Duration(seconds: 1));
                    final latest = ref
                        .read(rideWSControllerProvider(widget.ride.id))
                        .status;
                    if (!_isRideActiveForTracking(latest)) {
                      await Future.delayed(const Duration(seconds: 1));
                    }
                    await ws.startDriverLiveTracking();
                  }

                  if (actionType == "end" || actionType == "cancel") {
                    await ws.stopDriverLiveTracking();
                  }
                } finally {
                  if (mounted) {
                    setState(() => _actionInProgress = false);
                  }
                  widget.onActionCompleted();
                }
              },
        icon: Icon(icon, size: 16),
        label: Text(
          label,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildChatButton() {
    final unreadMap = ref.watch(unreadRideProvider);
    final unreadCount = unreadMap[widget.ride.id] ?? 0;

    return SizedBox(
      height: 42,
      child: ElevatedButton.icon(
        onPressed: () {
          ref.read(unreadRideProvider.notifier).clearUnread(widget.ride.id);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RideChatPage(
                rideId: widget.ride.id,
              ),
            ),
          );
        },
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(
              Icons.chat_bubble_rounded,
              size: 16,
            ),
            if (unreadCount > 0)
              Positioned(
                right: -10,
                top: -8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        label: Text(
          unreadCount > 0 ? "Chat ($unreadCount)" : "Chat",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6C757D),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case "scheduled":
        return Colors.blue;
      case "ongoing":
      case "in_progress":
      case "started":
        return Colors.orange;
      case "completed":
        return Colors.green;
      case "cancelled":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case "scheduled":
        return Icons.schedule_rounded;
      case "ongoing":
      case "in_progress":
      case "started":
        return Icons.directions_car_rounded;
      case "completed":
        return Icons.check_circle_rounded;
      case "cancelled":
        return Icons.cancel_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  String _capitalize(String s) {
    return s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
  }
}
