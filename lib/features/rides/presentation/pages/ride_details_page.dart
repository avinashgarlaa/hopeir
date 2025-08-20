import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hop_eir/features/auth/domain/entities/user.dart';
import 'package:hop_eir/features/auth/presentation/providers/auth_provider.dart';
import 'package:hop_eir/features/rides/domain/entities/ride.dart';
import 'package:hop_eir/features/stations/presentation/providers/providers.dart';
import 'package:hop_eir/features/vehicles/domain/entities/vehicle.dart';
import 'package:hop_eir/features/vehicles/presentation/provider/vehicle_providers.dart';
import 'package:intl/intl.dart';

class RideDetailsPage extends ConsumerWidget {
  final Ride ride;
  const RideDetailsPage({super.key, required this.ride});

  String formatDateTime(DateTime dateTime) {
    return DateFormat('dd MMM yyyy – hh:mm a').format(dateTime);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authNotifier = ref.read(authNotifierProvider.notifier);
    final vehicleNotifier = ref.read(vehicleControllerProvider.notifier);
    final fromStationAsync = ref.watch(stationByIdProvider(ride.startLocation));
    final toStationAsync = ref.watch(stationByIdProvider(ride.endLocation));

    const primaryColor = Color.fromRGBO(137, 177, 98, 1);
    const backgroundColor = Color(0xFFF5F7FF);

    final userFuture = authNotifier.getUserByuserId(ride.user);
    final vehicleFuture = vehicleNotifier.getVehicleForUser(ride.user);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(context, primaryColor),
            Expanded(
              child: FutureBuilder(
                future: Future.wait([userFuture, vehicleFuture]),
                builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _mainLoading(primaryColor);
                  } else if (snapshot.hasError || !snapshot.hasData) {
                    return _errorWidget("Failed to load ride data");
                  }

                  final user = snapshot.data![0] as User;
                  final vehicle = snapshot.data![1] as Vehicle;

                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      child: ListView(
                        children: [
                          _sectionTitle("Route", primaryColor),
                          fromStationAsync.when(
                            data: (fromStation) {
                              return toStationAsync.when(
                                data: (toStation) {
                                  return _infoRow(
                                    Icons.route,
                                    '${fromStation.name} → ${toStation.name}',
                                    primaryColor,
                                  );
                                },
                                loading: () => _skeletonLoader(),
                                error:
                                    (_, __) =>
                                        _errorRow("Error loading stations"),
                              );
                            },
                            loading: () => _skeletonLoader(),
                            error:
                                (_, __) => _errorRow("Error loading stations"),
                          ),
                          const SizedBox(height: 15),

                          _sectionTitle("Timing", primaryColor),
                          _infoRow(
                            Icons.calendar_month,
                            formatDateTime(ride.startTime),
                            primaryColor,
                          ),
                          const SizedBox(height: 15),

                          _sectionTitle("Driver Info", primaryColor),
                          _infoRow(Icons.person, user.firstname, primaryColor),
                          _infoRow(Icons.email, user.email, primaryColor),
                          _infoRow(
                            Icons.phone,
                            "user.phone",
                            primaryColor,
                          ), // correct phone if needed
                          const SizedBox(height: 15),

                          _sectionTitle("Vehicle Info", primaryColor),
                          _infoRow(
                            Icons.directions_car,
                            vehicle.vehicleType,
                            primaryColor,
                          ),
                          _infoRow(
                            Icons.car_repair,
                            vehicle.vehicleModel,
                            primaryColor,
                          ),
                          _infoRow(
                            Icons.confirmation_number,
                            vehicle.vehicleLicensePlate,
                            primaryColor,
                          ),
                          _infoRow(
                            Icons.color_lens,
                            vehicle.vehicleColor,
                            primaryColor,
                          ),
                          const SizedBox(height: 15),

                          _sectionTitle("Ride Details", primaryColor),
                          _infoRow(
                            Icons.event_seat,
                            '${ride.seats} seats available',
                            primaryColor,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          ),
          Expanded(
            child: Text(
              'Ride Details',
              style: GoogleFonts.racingSansOne(
                fontSize: 26,
                color: primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(
            width: 48,
          ), // keep same width as back button to center title
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mainLoading(Color primaryColor) {
    return Center(
      child: CircularProgressIndicator(color: primaryColor, strokeWidth: 3),
    );
  }

  Widget _errorWidget(String message) {
    return Center(
      child: Text(
        message,
        style: GoogleFonts.poppins(color: Colors.red, fontSize: 16),
      ),
    );
  }

  Widget _errorRow(String msg) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(msg, style: GoogleFonts.poppins(color: Colors.red)),
    );
  }

  Widget _skeletonLoader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Container(height: 18, color: Colors.grey.shade300)),
        ],
      ),
    );
  }
}
