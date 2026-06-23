// ============================================================
// 🔥 ULTRA PRO SENT REQUEST PAGE
// ============================================================
//
// IMPROVEMENTS DONE:
// ✅ Better alignment
// ✅ Proper driver section
// ✅ Driver phone number added
// ✅ Cleaner spacing
// ✅ More premium hierarchy
// ✅ Better vehicle layout
// ✅ Better info containers
// ✅ More professional card structure
// ✅ Better status positioning
// ✅ Better responsiveness
//
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:hop_eir/features/auth/presentation/providers/auth_provider.dart';
import 'package:hop_eir/features/requests/domain/entities/ride_request.dart';
import 'package:hop_eir/features/requests/presentation/controllers/ride_request_ws_controller.dart';
import 'package:hop_eir/features/rides/presentation/controllers/ride_ws_controller.dart';
import 'package:hop_eir/features/rides/presentation/pages/ride_chat_page.dart';
import 'package:hop_eir/features/rides/presentation/pages/ride_map_page.dart';
import 'package:hop_eir/features/rides/presentation/providers/ride_provider.dart';
import 'package:hop_eir/features/stations/presentation/providers/providers.dart';
import 'package:hop_eir/features/vehicles/presentation/provider/vehicle_providers.dart';

class SentRequestsPage extends ConsumerWidget {
  const SentRequestsPage({
    super.key,
  });

  static const primaryColor = Color(0xFF89B162);

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final user = ref
        .watch(
          authNotifierProvider,
        )
        .user;

    final userId = user?.userId.toString() ?? '';

    final state = ref.watch(
      rideRequestWSControllerProvider(
        userId,
      ),
    );

    final requests = state.incomingRequests
        .where(
          (r) => r.passengerId == userId,
        )
        .toList()
      ..sort((a, b) {
        final aTime = DateTime.tryParse(
              a.requestedAt ?? '',
            ) ??
            DateTime.now();

        final bTime = DateTime.tryParse(
              b.requestedAt ?? '',
            ) ??
            DateTime.now();

        return bTime.compareTo(
          aTime,
        );
      });

    if (requests.isEmpty) {
      return const _EmptyState();
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        120,
      ),
      itemCount: requests.length,
      itemBuilder: (
        context,
        index,
      ) {
        final request = requests[index];

        String rideStatus = "pending";

        if (request.status.toLowerCase() == 'accepted') {
          final rideWsState = ref.watch(
            rideWSControllerProvider(request.rideId),
          );

          if (rideWsState.status.isNotEmpty &&
              rideWsState.status.toLowerCase() != 'pending') {
            rideStatus = rideWsState.status;
          }
        }

        final canChat = request.status.toLowerCase() == 'accepted' &&
            rideStatus.toLowerCase() != 'completed' &&
            rideStatus.toLowerCase() != 'cancelled';
        return Padding(
          padding: const EdgeInsets.only(
            bottom: 14,
          ),
          child: _RideCard(
            request: request,
            rideStatus: rideStatus,
            canChat: canChat,
          )
              .animate()
              .fadeIn(
                duration: 450.ms,
              )
              .slideY(
                begin: 0.08,
                end: 0,
              ),
        );
      },
    );
  }
}

class _RideCard extends ConsumerWidget {
  final RideRequest request;
  final String rideStatus;
  final bool canChat;

  const _RideCard({
    required this.request,
    required this.rideStatus,
    required this.canChat,
  });

  static const primaryColor = Color(0xFF89B162);

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final rideAsync = ref.watch(
      rideByIdProvider(
        request.rideId,
      ),
    );

    final requestedTime = DateTime.tryParse(
      request.requestedAt ?? '',
    )?.toLocal();

    final requestedAgo = requestedTime != null
        ? timeago.format(
            requestedTime,
          )
        : '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          28,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              0.045,
            ),
            blurRadius: 25,
            offset: const Offset(
              0,
              10,
            ),
          ),
        ],
      ),
      child: rideAsync.when(
        loading: () => const SizedBox(
          height: 220,
        ),
        error: (_, __) => const SizedBox(),
        data: (ride) {
          final driverAsync = ref.watch(
            getUserByIdProviders(
              ride.user,
            ),
          );

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

          final startTime = DateTime.tryParse(
            ride.startTime.toString(),
          )?.toLocal();

          final rideTime = startTime != null
              ? DateFormat('hh:mm a').format(
                  startTime.subtract(
                    const Duration(
                      hours: 5,
                      minutes: 30,
                    ),
                  ),
                )
              : '';

          final rideDate = startTime != null
              ? DateFormat(
                  'MMM dd',
                ).format(
                  startTime,
                )
              : '';

          final unreadMap = ref.watch(unreadRideProvider);
          final unreadCount = unreadMap[request.rideId] ?? 0;

          return Padding(
            padding: const EdgeInsets.all(
              18,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // =====================================================
                // DRIVER SECTION
                // =====================================================

                driverAsync.when(
                  data: (driver) {
                    return vehicleAsync.when(
                      data: (
                        vehicle,
                      ) {
                        return Container(
                          padding: const EdgeInsets.all(
                            16,
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
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 64,
                                    height: 64,
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
                                        22,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        driver!.firstname
                                            .substring(
                                              0,
                                              1,
                                            )
                                            .toUpperCase(),
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 24,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 14,
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                "${driver.firstname} ${driver.lastname}",
                                                style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 17,
                                                ),
                                              ),
                                            ),
                                            _statusChip(
                                              request.status,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(
                                          height: 6,
                                        ),
                                        Text(
                                          requestedAgo,
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 12,
                                        ),
                                        Row(
                                          children: [
                                            _infoPill(
                                              Icons.directions_car_rounded,
                                              "${vehicle.vehicleColor} ${vehicle.vehicleModel}",
                                            ),
                                          ],
                                        ),
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        Wrap(
                                          spacing: 10,
                                          runSpacing: 10,
                                          children: [
                                            _miniInfoCard(
                                              Icons.badge_rounded,
                                              vehicle.vehicleLicensePlate,
                                            ),
                                            _miniInfoCard(
                                              Icons.phone_rounded,
                                              driver.username,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
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

                // =====================================================
                // ROUTE
                // =====================================================

                fromAsync.when(
                  data: (from) {
                    return toAsync.when(
                      data: (to) {
                        return Container(
                          padding: const EdgeInsets.all(
                            16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(
                              24,
                            ),
                            border: Border.all(
                              color: Colors.grey.withOpacity(
                                0.08,
                              ),
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
                                child: Divider(
                                  color: Colors.grey.withOpacity(
                                    0.18,
                                  ),
                                ),
                              ),
                              _routeTile(
                                "Destination",
                                to.name,
                                Icons.location_on_rounded,
                                Colors.redAccent,
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
                  height: 16,
                ),

                // =====================================================
                // RIDE START
                // =====================================================

                Container(
                  padding: const EdgeInsets.all(
                    14,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryColor.withOpacity(
                          0.12,
                        ),
                        primaryColor.withOpacity(
                          0.05,
                        ),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(
                      20,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(
                            16,
                          ),
                        ),
                        child: const Icon(
                          Icons.schedule_rounded,
                          color: Colors.white,
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
                              "Ride Starts",
                              style: GoogleFonts.poppins(
                                color: Colors.grey,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(
                              height: 3,
                            ),
                            Text(
                              "$rideTime • $rideDate",
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: _rideStatusColor(
                            rideStatus,
                          ).withOpacity(
                            0.12,
                          ),
                          borderRadius: BorderRadius.circular(
                            50,
                          ),
                        ),
                        child: Text(
                          rideStatus.toUpperCase(),
                          style: GoogleFonts.poppins(
                            color: _rideStatusColor(
                              rideStatus,
                            ),
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      )
                    ],
                  ),
                ),

                const SizedBox(
                  height: 18,
                ),

                // =====================================================
                // BUTTONS
                // =====================================================

                if (canChat)
                  Row(
                    children: [
                      Expanded(
                        child: _button(
                          text: "Track Ride",
                          icon: const Icon(Icons.map_rounded),
                          color: Colors.blue,
                          onTap: () async {
                            ref
                                .read(
                                  rideWSControllerProvider(
                                    request.rideId,
                                  ).notifier,
                                )
                                .connect();

                            final from = await ref.read(
                              stationByIdProvider(
                                ride.startLocation,
                              ).future,
                            );

                            final to = await ref.read(
                              stationByIdProvider(
                                ride.endLocation,
                              ).future,
                            );

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RideMapPage(
                                  rideId: request.rideId,
                                  fromLat: (from.latitude as num).toDouble(),
                                  fromLng: (from.longitude as num).toDouble(),
                                  toLat: (to.latitude as num).toDouble(),
                                  toLng: (to.longitude as num).toDouble(),
                                  fromName: from.name,
                                  toName: to.name,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(
                        width: 12,
                      ),
                      Expanded(
                        child: _button(
                          text: "Chat Driver",
                          icon: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              const Icon(Icons.chat_bubble_rounded),
                              if (unreadCount > 0)
                                Positioned(
                                  top: -2,
                                  right: -2,
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          color: primaryColor,
                          onTap: () {
                            ref
                                .read(unreadRideProvider.notifier)
                                .clearUnread(request.rideId);

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RideChatPage(
                                  rideId: request.rideId,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
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
                  fontSize: 11,
                  color: Colors.grey,
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

  Widget _button({
    required Widget icon,
    required String text,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 54,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: icon,
        label: Text(
          text,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              18,
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusChip(
    String status,
  ) {
    Color color;

    switch (status.toLowerCase()) {
      case 'accepted':
        color = Colors.green;
        break;

      case 'rejected':
        color = Colors.red;
        break;

      default:
        color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(
          0.12,
        ),
        borderRadius: BorderRadius.circular(
          50,
        ),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.poppins(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _miniInfoCard(
    IconData icon,
    String text,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          14,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: primaryColor,
          ),
          const SizedBox(
            width: 7,
          ),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoPill(
    IconData icon,
    String text,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(
          0.9,
        ),
        borderRadius: BorderRadius.circular(
          14,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: primaryColor,
          ),
          const SizedBox(
            width: 7,
          ),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _rideStatusColor(
    String status,
  ) {
    switch (status.toLowerCase()) {
      case "ongoing":
      case "started":
      case "in_progress":
        return Colors.blue;

      case "completed":
        return Colors.green;

      case "cancelled":
        return Colors.red;

      default:
        return Colors.orange;
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(
    BuildContext context,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(
                0xFF89B162,
              ).withOpacity(
                0.1,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_taxi_rounded,
              size: 60,
              color: Color(
                0xFF89B162,
              ),
            ),
          ),
          const SizedBox(
            height: 24,
          ),
          Text(
            "No sent requests",
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          Text(
            "Your ride requests will appear here",
            style: GoogleFonts.poppins(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
