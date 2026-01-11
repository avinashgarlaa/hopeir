// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hop_eir/features/auth/presentation/providers/auth_provider.dart';
import 'package:hop_eir/features/notifications/notification_service.dart';
import 'package:hop_eir/features/requests/presentation/controllers/passanger_ride_ws_controller.dart';
import 'package:hop_eir/features/rides/presentation/pages/ride_details_page.dart';
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

      await ref
          .read(rideControllerProvider.notifier)
          .requestRide(ride: ride, fromUser: fromUser, ref: ref);

      if (!mounted) return;
      Navigator.pop(context);

      setState(() {
        _requestedRides.add(ride);
      });

      ref.listenManual<String>(passengerRideWSProvider(ride), (
        previous,
        next,
      ) {
        if (next != previous && next != "pending") {
          print('🔔 Ride status updated to: $next');
          LocalNotificationHelper.showNotification(
            '🚘 Ride Status Updated',
            'Your ride is now $next',
          );
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🎯 Ride request sent successfully!')),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Failed to request ride: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final ridesAsyncValue = ref.watch(rideControllerProvider);
    final user = ref.watch(authNotifierProvider).user!;
    const primaryColor = Color.fromRGBO(137, 177, 98, 1);
    const backgroundColor = Color(0xFFF5F7FF);
    const cardColor = Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _topBar(context, primaryColor),
              const SizedBox(height: 10),
              Expanded(
                child: ridesAsyncValue.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, st) =>
                      Center(child: Text("Error: ${e.toString()}")),
                  data: (rides) {
                    final filteredRides = rides.where((ride) {
                      return ride.startLocation == widget.fromStation.id &&
                          ride.endLocation == widget.toStation.id &&
                          ride.seats >= widget.seats;
                    }).toList();

                    if (filteredRides.isEmpty) {
                      return const Center(child: Text('No rides found!'));
                    }

                    return ListView.builder(
                      itemCount: filteredRides.length,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(top: 10),
                      itemBuilder: (context, index) {
                        final ride = filteredRides[index];

                        final fromStationFuture =
                            ref.watch(stationByIdProvider(ride.startLocation));
                        final toStationFuture =
                            ref.watch(stationByIdProvider(ride.endLocation));

                        return fromStationFuture.when(
                          loading: () => const _LoadingCard(),
                          error: (e, st) => const _ErrorCard(),
                          data: (fromStation) {
                            return toStationFuture.when(
                              loading: () => const _LoadingCard(),
                              error: (e, st) => const _ErrorCard(),
                              data: (toStation) {
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            RideDetailsPage(ride: ride),
                                      ),
                                    );
                                  },
                                  child: _RideCard(
                                    vehicle: ride.vehicle,
                                    from: fromStation.name,
                                    to: toStation.name,
                                    dateTime: ride.startTime,
                                    driverName: ride.vehicle.toString(),
                                    cardColor: cardColor,
                                    primaryColor: primaryColor,
                                    isRequested:
                                        _requestedRides.contains(ride.id),
                                    onRequest: () => requestRide(
                                      ride: ride.id.toInt(),
                                      fromUser: user.userId,
                                      context: context,
                                    ),
                                  ),
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
      ),
    );
  }

  Widget _topBar(BuildContext context, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          ),
          Expanded(
            child: Text(
              'Available Rides',
              style: GoogleFonts.racingSansOne(
                fontSize: 26,
                color: primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _RideCard extends StatelessWidget {
  final String from;
  final String to;
  final DateTime dateTime;
  final String driverName;
  final Color cardColor;
  final Color primaryColor;
  final VoidCallback onRequest;
  final bool isRequested;
  final int vehicle;

  const _RideCard({
    required this.from,
    required this.to,
    required this.dateTime,
    required this.driverName,
    required this.cardColor,
    required this.primaryColor,
    required this.onRequest,
    required this.isRequested,
    required this.vehicle,
  });

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('dd MMM, hh:mm a').format(dateTime);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Card(
        color: cardColor,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(vertical: 10),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$from → $to',
                style: GoogleFonts.racingSansOne(
                  fontWeight: FontWeight.w500,
                  fontSize: 20,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                formattedDate,
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.directions_car_rounded, color: primaryColor),
                  const SizedBox(width: 8),
                  Consumer(
                    builder: (context, ref, _) {
                      final vehicleAsync =
                          ref.watch(vehicleByIdProvider(vehicle));
                      return vehicleAsync.when(
                        data: (vehicle) {
                          return Text(
                            '${vehicle.vehicleType} ${vehicle.vehicleModel} (${vehicle.vehicleLicensePlate})',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          );
                        },
                        loading: () => const Text('Loading vehicle...'),
                        error: (e, st) => const Text('Error loading vehicle'),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isRequested ? Colors.grey : primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: isRequested ? null : onRequest,
                  child: Text(
                    isRequested ? "Requested" : "Request Ride",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
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
  Widget build(BuildContext context) => const Padding(
      padding: EdgeInsets.all(20), child: CircularProgressIndicator());
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard();

  @override
  Widget build(BuildContext context) => const Padding(
      padding: EdgeInsets.all(20), child: Text("Error loading station"));
}
