// ignore_for_file: avoid_print

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hop_eir/features/auth/presentation/providers/auth_provider.dart';
import 'package:hop_eir/features/notifications/notification_service.dart';
import 'package:hop_eir/features/requests/presentation/controllers/passanger_ride_ws_controller.dart';
import 'package:hop_eir/features/rides/presentation/providers/ride_provider.dart';
import 'package:hop_eir/features/stations/data/models/station_model.dart';
import 'package:hop_eir/features/stations/presentation/providers/providers.dart';
import 'package:hop_eir/features/vehicles/presentation/provider/vehicle_providers.dart';
import 'package:intl/intl.dart';

class SearchedRidesPage extends ConsumerStatefulWidget {
  final StationModel fromStation;
  final StationModel toStation;
  final int seats;

  const SearchedRidesPage({
    super.key,
    required this.fromStation,
    required this.toStation,
    required this.seats,
  });

  @override
  ConsumerState<SearchedRidesPage> createState() => _SearchedRidesPageState();
}

class _SearchedRidesPageState extends ConsumerState<SearchedRidesPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;

  final Set<int> _requestedRides = {};

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> requestRide({
    required int ride,
    required String fromUser,
    required BuildContext context,
  }) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      await ref.read(rideControllerProvider.notifier).requestRide(
            ride: ride,
            fromUser: fromUser,
            ref: ref,
          );

      if (!mounted) return;

      Navigator.pop(context);

      setState(() {
        _requestedRides.add(ride);
      });

      ref.listenManual<String>(
        passengerRideWSProvider(ride),
        (previous, next) {
          if (next != previous && next != "pending") {
            LocalNotificationHelper.showNotification(
              '🚘 Ride Status Updated',
              'Your ride is now $next',
            );
          }
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎯 Ride request sent successfully!'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '❌ Failed to request ride: $e',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).user!;

    const primaryColor = Color.fromRGBO(137, 177, 98, 1);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: SafeArea(
        child: Column(
          children: [
            _topBar(context, primaryColor),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: ref.read(rideControllerProvider.notifier).matchRides(
                      riderStartStationId: widget.fromStation.id,
                      riderEndStationId: widget.toStation.id,
                      riderUserId: user.userId,
                    ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        "No rides found",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                        ),
                      ),
                    );
                  }

                  final rides = snapshot.data ?? [];

                  if (rides.isEmpty) {
                    return Center(
                      child: Text(
                        "No matching rides",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(
                      top: 12,
                      bottom: 24,
                    ),
                    itemCount: rides.length,
                    itemBuilder: (context, index) {
                      final match = rides[index];

                      final ride = match['ride'];

                      final matchZone = match['match_zone'] ?? 'partial_route';

                      final score = match['score'] ?? 0;
                      final fromStationAsync = ref.watch(
                        stationByIdProvider(
                          match['start_location'] as int,
                        ),
                      );

                      final toStationAsync = ref.watch(
                        stationByIdProvider(
                          match['end_location'] as int,
                        ),
                      );

                      return fromStationAsync.when(
                        loading: () => const _LoadingCard(),
                        error: (e, st) => const _ErrorCard(),
                        data: (fromStation) {
                          return toStationAsync.when(
                            loading: () => const _LoadingCard(),
                            error: (e, st) => const _ErrorCard(),
                            data: (toStation) {
                              return _RideCard(
                                rideId: match['id'],
                                vehicle: match['vehicle'],
                                from: fromStation.name,
                                to: toStation.name,
                                dateTime: DateTime.parse(
                                  match['start_time'],
                                ),
                                matchZone: matchZone,
                                score: score,
                                isRequested: _requestedRides.contains(
                                  match['id'],
                                ),
                                onRequest: () => requestRide(
                                  ride: match['id'],
                                  fromUser: user.userId,
                                  context: context,
                                ),
                                primaryColor: primaryColor,
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar(
    BuildContext context,
    Color primaryColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 18,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Available Rides",
                  style: GoogleFonts.racingSansOne(
                    fontSize: 28,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${widget.fromStation.name} → ${widget.toStation.name}",
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RideCard extends ConsumerWidget {
  final int rideId;
  final int vehicle;
  final String from;
  final String to;
  final DateTime dateTime;
  final String matchZone;
  final int score;
  final bool isRequested;
  final VoidCallback onRequest;
  final Color primaryColor;

  const _RideCard({
    required this.rideId,
    required this.vehicle,
    required this.from,
    required this.to,
    required this.dateTime,
    required this.matchZone,
    required this.score,
    required this.isRequested,
    required this.onRequest,
    required this.primaryColor,
  });

  String getMatchText() {
    switch (matchZone) {
      case 'exact':
        return 'Perfect Match';

      case 'same_start':
        return 'Same Pickup';

      case 'same_end':
        return 'Same Destination';

      case 'both_on_route':
        return 'Along Route';

      case 'partial_route':
        return 'Partial Match';

      default:
        return 'Ride Match';
    }
  }

  Color getMatchColor() {
    switch (matchZone) {
      case 'exact':
        return Colors.green;

      case 'same_start':
        return Colors.blue;

      case 'same_end':
        return Colors.orange;

      case 'both_on_route':
        return Colors.purple;

      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formattedDate = DateFormat(
      'dd MMM • hh:mm a',
    ).format(dateTime);

    final vehicleAsync = ref.watch(vehicleByIdProvider(vehicle));

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 8,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "$from → $to",
                      style: GoogleFonts.racingSansOne(
                        fontSize: 21,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: getMatchColor(),
                      borderRadius: BorderRadius.circular(
                        30,
                      ),
                    ),
                    child: Text(
                      getMatchText(),
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(
                    Icons.schedule,
                    size: 18,
                    color: Colors.black54,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    formattedDate,
                    style: GoogleFonts.poppins(
                      color: Colors.black54,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    "$score% Match",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: getMatchColor(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              vehicleAsync.when(
                data: (vehicleData) {
                  return Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(
                          10,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(
                            0.1,
                          ),
                          borderRadius: BorderRadius.circular(
                            14,
                          ),
                        ),
                        child: Icon(
                          Icons.directions_car_rounded,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${vehicleData.vehicleType} ${vehicleData.vehicleModel}",
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              vehicleData.vehicleLicensePlate,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (e, st) => const Text(
                  "Vehicle load failed",
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isRequested ? null : onRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isRequested ? Colors.grey : primaryColor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        16,
                      ),
                    ),
                  ),
                  child: Text(
                    isRequested ? "Requested" : "Request Ride",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(30),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(30),
      child: Center(
        child: Text(
          "Error loading ride",
        ),
      ),
    );
  }
}
