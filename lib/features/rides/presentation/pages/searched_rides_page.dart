// ignore_for_file: avoid_print

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hop_eir/features/auth/presentation/providers/auth_provider.dart';
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
                                seats: match['seats'],
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
                  style: GoogleFonts.luckiestGuy(
                    fontWeight: FontWeight.w300,
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
  final int seats;
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
    required this.seats,
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
        return 'Perfect';
      case 'same_start':
        return 'Same Pickup';
      case 'same_end':
        return 'Same Drop';
      case 'both_on_route':
        return 'On Route';
      default:
        return 'Match';
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
    final formattedTime = DateFormat('hh:mm a').format(dateTime);
    final formattedDate = DateFormat('dd MMM').format(dateTime);
    final vehicleAsync = ref.watch(vehicleByIdProvider(vehicle));

    return Container(
      margin: const EdgeInsets.only(bottom: 12, left: 10, right: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Date, Time, Match Score
                Row(
                  children: [
                    // Date & Time
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_today,
                              size: 12, color: primaryColor),
                          const SizedBox(width: 6),
                          Text(
                            formattedDate,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.access_time,
                              size: 12, color: primaryColor),
                          const SizedBox(width: 6),
                          Text(
                            formattedTime,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Score Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: getMatchColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.trending_up,
                            size: 12,
                            color: getMatchColor(),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "$score%",
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: getMatchColor(),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Match",
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: getMatchColor(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Locations
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Location Icons Column
                    Column(
                      children: [
                        const Icon(Icons.circle, size: 12, color: Colors.green),
                        Container(
                          width: 2,
                          height: 30,
                          color: Colors.grey[300],
                        ),
                        const Icon(Icons.location_on,
                            size: 12, color: Colors.red),
                      ],
                    ),
                    const SizedBox(width: 12),
                    // Location Text Column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            from,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            to,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Match Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: getMatchColor(),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        getMatchText(),
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Vehicle Info
                vehicleAsync.when(
                  data: (vehicleData) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FC),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.directions_car,
                              color: primaryColor,
                              size: 18,
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
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  vehicleData.vehicleLicensePlate,
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "$seats seats",
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  loading: () => Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FC),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: SizedBox(
                        height: 30,
                        width: 30,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                  error: (e, st) => Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error, size: 16, color: Colors.red[400]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Vehicle info unavailable",
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.red[400],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Request Button
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: isRequested ? null : onRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isRequested ? Colors.grey[400] : primaryColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isRequested
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle,
                                  size: 18, color: Colors.white),
                              const SizedBox(width: 8),
                              Text(
                                "Request Sent",
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            "Request Ride",
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 20, color: Colors.red[400]),
          const SizedBox(width: 8),
          Text(
            "Error loading ride details",
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
