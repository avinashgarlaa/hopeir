// ============================================================
// 🔥 RECEIVED REQUESTS PAGE - ULTRA PRO UI
// ============================================================
//
// ADD:
//
// flutter_animate:
// timeago:
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
import 'package:hop_eir/features/rides/presentation/providers/ride_provider.dart';
import 'package:hop_eir/features/stations/presentation/providers/providers.dart';

class ReceivedRequestsPage extends ConsumerWidget {
  const ReceivedRequestsPage({
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
          (r) => r.driverId == userId,
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

        return Padding(
          padding: const EdgeInsets.only(
            bottom: 14,
          ),
          child: _ReceivedRideCard(
            request: request,
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

// ============================================================
// CARD
// ============================================================

class _ReceivedRideCard extends ConsumerWidget {
  final RideRequest request;

  const _ReceivedRideCard({
    required this.request,
  });

  static const primaryColor = Color(0xFF89B162);

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final unreadMap = ref.watch(unreadRideProvider);
    final unreadCount = unreadMap[request.rideId] ?? 0;

    if (request.status.toLowerCase() == "accepted") {
      ref.watch(
        rideWSControllerProvider(
          request.rideId,
        ),
      );
    }

    final requestTime = DateTime.tryParse(
      request.requestedAt ?? '',
    )?.toLocal();

    final requestAgo = requestTime != null
        ? timeago.format(
            requestTime,
          )
        : '';
    final passengerId = request.passengerId.trim();

    if (passengerId.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        child: Text(
          "Passenger information unavailable",
          style: GoogleFonts.poppins(),
        ),
      );
    }

    final passengerAsync = ref.watch(
      getUserByIdProviders(passengerId),
    );

    final rideAsync = ref.watch(
      rideByIdProvider(
        request.rideId,
      ),
    );

    return Container(
      padding: const EdgeInsets.all(
        16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          24,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              0.04,
            ),
            blurRadius: 20,
            offset: const Offset(
              0,
              8,
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==================================================
          // TOP
          // ==================================================

          Row(
            children: [
              Container(
                width: 54,
                height: 54,
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
                    18,
                  ),
                ),
                child: const Icon(
                  Icons.person_rounded,
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
                      request.passengerName,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(
                      height: 3,
                    ),
                    Text(
                      "Requested $requestAgo",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              _statusChip(
                request.status,
              ),
            ],
          ),

          const SizedBox(
            height: 18,
          ),

          // ==================================================
          // PASSENGER INFO
          // ==================================================

          passengerAsync.when(
            data: (
              passenger,
            ) {
              return Container(
                padding: const EdgeInsets.all(
                  14,
                ),
                decoration: BoxDecoration(
                  color: const Color(
                    0xFFF8FBF4,
                  ),
                  borderRadius: BorderRadius.circular(
                    20,
                  ),
                ),
                child: Column(
                  children: [
                    _infoRow(
                      Icons.email_outlined,
                      passenger?.email ?? "Unavailable",
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    _infoRow(
                      Icons.phone_android_rounded,
                      passenger?.username ?? "Unavailable",
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
            height: 16,
          ),

          // ==================================================
          // RIDE DETAILS
          // ==================================================

          rideAsync.when(
            data: (ride) {
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

              return Column(
                children: [
                  fromAsync.when(
                    data: (
                      from,
                    ) {
                      return toAsync.when(
                        data: (
                          to,
                        ) {
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
                            child: Column(
                              children: [
                                _routeRow(
                                  Icons.my_location_rounded,
                                  from.name,
                                  Colors.green,
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  child: Divider(
                                    color: Colors.grey.withOpacity(
                                      0.2,
                                    ),
                                  ),
                                ),
                                _routeRow(
                                  Icons.location_on_rounded,
                                  to.name,
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
                    height: 14,
                  ),

                  // ==========================================
                  // START TIME
                  // ==========================================

                  Container(
                    padding: const EdgeInsets.all(
                      12,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(
                        0.08,
                      ),
                      borderRadius: BorderRadius.circular(
                        18,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(
                              14,
                            ),
                          ),
                          child: const Icon(
                            Icons.schedule_rounded,
                            color: Colors.white,
                            size: 18,
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
                                "Ride Starts",
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(
                                height: 2,
                              ),
                              Text(
                                "$rideTime • $rideDate",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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

          // ==================================================
          // ACTIONS
          // ==================================================

          if (request.status.toLowerCase() == "pending")
            Row(
              children: [
                Expanded(
                  child: _button(
                    text: "Reject",
                    color: Colors.redAccent,
                    icon: const Icon(Icons.close_rounded),
                    onTap: () async {
                      final notifier = ref.read(
                        rideRequestWSControllerProvider(
                          request.driverId,
                        ).notifier,
                      );

                      await notifier.respondToRequest(
                        requestId: int.parse(request.id),
                        isAccepted: false,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _button(
                    text: "Accept",
                    color: primaryColor,
                    icon: const Icon(Icons.check_rounded),
                    onTap: () async {
                      final notifier = ref.read(
                        rideRequestWSControllerProvider(
                          request.driverId,
                        ).notifier,
                      );

                      await notifier.respondToRequest(
                        requestId: int.parse(request.id),
                        isAccepted: true,
                      );
                    },
                  ),
                ),
              ],
            ),
          if (request.status.toLowerCase() == "accepted")
            SizedBox(
              width: double.infinity,
              child: _button(
                text: "Open Chat",
                color: Colors.blue,
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.chat_bubble_rounded),
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
                onTap: () {
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
    );
  }

  // ==========================================================
  // COMPONENTS
  // ==========================================================

  Widget _infoRow(
    IconData icon,
    String text,
  ) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(
              0.1,
            ),
            borderRadius: BorderRadius.circular(
              12,
            ),
          ),
          child: Icon(
            icon,
            color: primaryColor,
            size: 18,
          ),
        ),
        const SizedBox(
          width: 12,
        ),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _routeRow(
    IconData icon,
    String text,
    Color color,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          color: color,
          size: 18,
        ),
        const SizedBox(
          width: 10,
        ),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
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

  Widget _button({
    required String text,
    required Color color,
    required Widget icon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 50,
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
              16,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// EMPTY STATE
// ============================================================

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
            width: 110,
            height: 110,
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
              size: 55,
              color: Color(
                0xFF89B162,
              ),
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          Text(
            "No incoming requests",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
