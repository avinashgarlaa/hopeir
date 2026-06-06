import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
    this.primaryColor = const Color(0xFF89B162),
  });

  @override
  ConsumerState<RideCard> createState() => _RideCardState();
}

class _RideCardState extends ConsumerState<RideCard> {
  bool _actionInProgress = false;

  bool _isRideActiveForTracking(
    String status,
  ) {
    final s = status.toLowerCase();

    return s == 'ongoing' || s == 'started' || s == 'in_progress';
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final ride = widget.ride;

    final wsState = ref.watch(
      rideWSControllerProvider(
        ride.id,
      ),
    );

    final status = wsState.status.toLowerCase();

    final vehicleAsync = ref.watch(
      vehicleByIdProvider(
        ride.vehicle,
      ),
    );

    final fromAsync = ref.watch(
      stationByIdProvider(
        ride.startLocation,
      ),
    );

    final toAsync = ref.watch(
      stationByIdProvider(
        ride.endLocation,
      ),
    );

    final formattedDate = DateFormat(
      'EEE, MMM d',
    ).format(ride.startTime);

    final formattedTime = DateFormat(
      'hh:mm a',
    ).format(ride.startTime);

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
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          28,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              0.05,
            ),
            blurRadius: 30,
            offset: const Offset(
              0,
              12,
            ),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(
          18,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===================================================
            // HEADER
            // ===================================================

            Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(
                          0xFF89B162,
                        ),
                        Color(
                          0xFFAED581,
                        ),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(
                      20,
                    ),
                  ),
                  child: const Icon(
                    Icons.directions_car_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(
                  width: 14,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Ride Journey",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      Text(
                        "$formattedDate • $formattedTime",
                        style: GoogleFonts.poppins(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                _statusBadge(
                  status,
                ),
              ],
            ),

            const SizedBox(
              height: 22,
            ),

            // ===================================================
            // ROUTE SECTION
            // ===================================================

            fromAsync.when(
              data: (from) {
                return toAsync.when(
                  data: (to) {
                    return Container(
                      padding: const EdgeInsets.all(
                        18,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(
                          0xFFF8FBF4,
                        ),
                        borderRadius: BorderRadius.circular(
                          24,
                        ),
                      ),
                      child: Column(
                        children: [
                          _routeTile(
                            "Pickup",
                            from.name,
                            Icons.my_location_rounded,
                            Colors.green,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                            ),
                            child: Row(
                              children: List.generate(
                                40,
                                (
                                  index,
                                ) {
                                  return Expanded(
                                    child: Container(
                                      height: 1,
                                      color: index.isEven
                                          ? Colors.grey.withOpacity(
                                              0.2,
                                            )
                                          : Colors.transparent,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          _routeTile(
                            "Destination",
                            to.name,
                            Icons.location_on_rounded,
                            Colors.redAccent,
                          ),
                          const SizedBox(
                            height: 16,
                          ),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                final fromStation = fromAsync.value;

                                final toStation = toAsync.value;

                                if (fromStation == null || toStation == null) {
                                  return;
                                }

                                ref
                                    .read(
                                      rideWSControllerProvider(
                                        ride.id,
                                      ).notifier,
                                    )
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
                              icon: const Icon(
                                Icons.map_rounded,
                                size: 18,
                              ),
                              label: Text(
                                "View Route Map",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: widget.primaryColor,
                                side: BorderSide(
                                  color: widget.primaryColor.withOpacity(
                                    0.4,
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  loading: () => const SizedBox(),
                  error: (
                    _,
                    __,
                  ) =>
                      const SizedBox(),
                );
              },
              loading: () => const SizedBox(),
              error: (
                _,
                __,
              ) =>
                  const SizedBox(),
            ),

            const SizedBox(
              height: 18,
            ),

            // ===================================================
            // VEHICLE
            // ===================================================

            vehicleAsync.when(
              data: (vehicle) {
                return Container(
                  padding: const EdgeInsets.all(
                    14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(
                      20,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: widget.primaryColor.withOpacity(
                            0.1,
                          ),
                          borderRadius: BorderRadius.circular(
                            14,
                          ),
                        ),
                        child: Icon(
                          Icons.electric_car_rounded,
                          color: widget.primaryColor,
                        ),
                      ),
                      const SizedBox(
                        width: 12,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              vehicle.vehicleModel,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(
                              height: 3,
                            ),
                            Text(
                              "${vehicle.vehicleLicensePlate} • ${vehicle.vehicleColor}",
                              style: GoogleFonts.poppins(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const SizedBox(),
              error: (
                _,
                __,
              ) =>
                  const SizedBox(),
            ),

            const SizedBox(
              height: 20,
            ),

            // ===================================================
            // LIVE TRACKING STATUS
            // ===================================================

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: wsState.driverTrackingEnabled
                    ? Colors.green.withOpacity(
                        0.08,
                      )
                    : Colors.red.withOpacity(
                        0.08,
                      ),
                borderRadius: BorderRadius.circular(
                  18,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.my_location_rounded,
                    color: wsState.driverTrackingEnabled
                        ? Colors.green
                        : Colors.red,
                    size: 18,
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Text(
                    wsState.driverTrackingEnabled
                        ? "Live tracking enabled"
                        : "Live tracking disabled",
                    style: GoogleFonts.poppins(
                      color: wsState.driverTrackingEnabled
                          ? Colors.green
                          : Colors.red,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            // ===================================================
            // ACTIONS
            // ===================================================

            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                if (showStart)
                  _actionButton(
                    "Start Ride",
                    Icons.play_arrow_rounded,
                    widget.primaryColor,
                  ),
                if (showEnd)
                  _actionButton(
                    "End Ride",
                    Icons.stop_rounded,
                    Colors.orange,
                  ),
                if (showCancel)
                  _actionButton(
                    "Cancel",
                    Icons.close_rounded,
                    Colors.redAccent,
                  ),
                _chatButton(),
              ],
            ),

            if (wsState.lastError != null) ...[
              const SizedBox(
                height: 12,
              ),
              Text(
                wsState.lastError!,
                style: GoogleFonts.poppins(
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(
          duration: 450.ms,
        )
        .slideY(
          begin: 0.08,
          end: 0,
        );
  }

  // ===========================================================
  // ACTION BUTTON
  // ===========================================================

  Widget _actionButton(
    String label,
    IconData icon,
    Color color,
  ) {
    final action = _mapLabelToAction(label);

    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: (_actionInProgress || action == null)
            ? null
            : () async {
                setState(
                  () => _actionInProgress = true,
                );

                final ws = ref.read(
                  rideWSControllerProvider(
                    widget.ride.id,
                  ).notifier,
                );

                try {
                  ws.connect();

                  ws.sendAction(
                    action,
                  );

                  if (action == "start") {
                    await Future.delayed(
                      const Duration(
                        seconds: 1,
                      ),
                    );

                    final latest = ref
                        .read(
                          rideWSControllerProvider(
                            widget.ride.id,
                          ),
                        )
                        .status;

                    if (!_isRideActiveForTracking(
                      latest,
                    )) {
                      await Future.delayed(
                        const Duration(
                          seconds: 1,
                        ),
                      );
                    }

                    await ws.startDriverLiveTracking();
                  }

                  if (action == "end" || action == "cancel") {
                    await ws.stopDriverLiveTracking();
                  }
                } finally {
                  if (mounted) {
                    setState(
                      () => _actionInProgress = false,
                    );
                  }

                  widget.onActionCompleted();
                }
              },
        icon: Icon(
          icon,
          size: 18,
        ),
        label: Text(
          label,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              18,
            ),
          ),
        ),
      ),
    );
  }

  Widget _chatButton() {
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RideChatPage(
                rideId: widget.ride.id,
              ),
            ),
          );
        },
        icon: const Icon(
          Icons.chat_bubble_rounded,
          size: 18,
        ),
        label: Text(
          "Chat",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueGrey,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              18,
            ),
          ),
        ),
      ),
    );
  }

  Widget _routeTile(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          color: color,
          size: 20,
        ),
        const SizedBox(
          width: 12,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: Colors.grey,
                  fontSize: 11,
                ),
              ),
              const SizedBox(
                height: 3,
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statusBadge(
    String status,
  ) {
    final color = _getStatusColor(status);

    final icon = _getStatusIcon(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(
          0.1,
        ),
        borderRadius: BorderRadius.circular(
          50,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(
            width: 5,
          ),
          Text(
            _capitalize(status),
            style: GoogleFonts.poppins(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  String? _mapLabelToAction(
    String label,
  ) {
    switch (label.toLowerCase()) {
      case 'start ride':
        return 'start';

      case 'end ride':
        return 'end';

      case 'cancel':
        return 'cancel';

      default:
        return null;
    }
  }

  Color _getStatusColor(
    String status,
  ) {
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

  IconData _getStatusIcon(
    String status,
  ) {
    switch (status.toLowerCase()) {
      case "scheduled":
        return Icons.schedule;

      case "ongoing":
      case "in_progress":
      case "started":
        return Icons.directions_run;

      case "completed":
        return Icons.check_circle;

      case "cancelled":
        return Icons.cancel;

      default:
        return Icons.help_outline;
    }
  }

  String _capitalize(
    String s,
  ) {
    return s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
  }
}
