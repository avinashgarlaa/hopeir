// ignore_for_file: avoid_print

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hop_eir/features/auth/presentation/providers/auth_provider.dart';
import 'package:hop_eir/features/rides/domain/usecases/route_service.dart';
import 'package:hop_eir/features/rides/presentation/controllers/ride_ws_controller.dart';
import 'package:hop_eir/features/rides/presentation/pages/post_ride_page.dart';
import 'package:hop_eir/features/rides/presentation/pages/rides_page.dart';
import 'package:hop_eir/features/rides/presentation/providers/ride_provider.dart';
import 'package:hop_eir/features/rides/presentation/widgets/message_banner.dart';
import 'package:hop_eir/features/stations/data/models/station_model.dart';
import 'package:hop_eir/features/stations/domain/entities/station.dart';
import 'package:hop_eir/features/stations/domain/usecases/search_stations.dart';
import 'package:hop_eir/features/stations/presentation/providers/providers.dart';
import 'package:hop_eir/features/vehicles/presentation/provider/vehicle_providers.dart';
import 'package:intl/intl.dart';

Future<void> showPostRideDialog(BuildContext context, WidgetRef ref) async {
  final formKey = GlobalKey<FormState>();
  final distanceController = TextEditingController();
  DateTime? selectedDateTime;
  Station? startStation;
  Station? destinationStation;
  int? selectedSeats;
  bool isCreating = false;

  const primaryColor = Color.fromRGBO(137, 177, 98, 1);

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: StatefulBuilder(
          builder: (context, setState) {
            // Station Selector Bottom Sheet
            // In the showPostRideDialog function, update the station selector:

            void showStationSelector({required bool isStart}) {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                builder: (_) => _StationSearchSheet(
                  isFrom: isStart, // Use isFrom instead of isStart
                  onStationSelected: (station) {
                    setState(() {
                      if (isStart) {
                        startStation = station;
                      } else {
                        destinationStation = station;
                      }
                    });
                  },
                ),
              );
            }

            // Improved Seats Selector with +/- buttons
            void showSeatsSelector() {
              int tempSeats = selectedSeats ?? 1;

              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (_) {
                  return StatefulBuilder(
                    builder: (context, setSeatState) {
                      return SafeArea(
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height * 0.42,
                          child: Column(
                            children: [
                              const SizedBox(height: 12),
                              // Drag Handle
                              Container(
                                width: 50,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Title
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: Text(
                                  "Select Seats",
                                  style: GoogleFonts.poppins(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: primaryColor,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Subtitle
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: Text(
                                  "Choose number of seats you have",
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Seat Selector with +/- buttons
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 32),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Minus Button
                                    InkWell(
                                      onTap: () {
                                        if (tempSeats > 1) {
                                          setSeatState(() {
                                            tempSeats--;
                                          });
                                        }
                                      },
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        width: 56,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          color: tempSeats > 1
                                              ? primaryColor.withOpacity(0.1)
                                              : Colors.grey.shade100,
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          border: Border.all(
                                            color: tempSeats > 1
                                                ? primaryColor
                                                : Colors.grey.shade300,
                                            width: 2,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.remove_rounded,
                                          color: tempSeats > 1
                                              ? primaryColor
                                              : Colors.grey.shade400,
                                          size: 28,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 32),

                                    // Seat Count Display
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            primaryColor,
                                            primaryColor.withOpacity(0.7),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                primaryColor.withOpacity(0.3),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            '$tempSeats',
                                            style: GoogleFonts.poppins(
                                              fontSize: 32,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                          Text(
                                            tempSeats == 1 ? 'Seat' : 'Seats',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color:
                                                  Colors.white.withOpacity(0.8),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 32),

                                    // Plus Button
                                    InkWell(
                                      onTap: () {
                                        if (tempSeats < 4) {
                                          setSeatState(() {
                                            tempSeats++;
                                          });
                                        }
                                      },
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        width: 56,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          color: tempSeats < 4
                                              ? primaryColor.withOpacity(0.1)
                                              : Colors.grey.shade100,
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          border: Border.all(
                                            color: tempSeats < 4
                                                ? primaryColor
                                                : Colors.grey.shade300,
                                            width: 2,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.add_rounded,
                                          color: tempSeats < 4
                                              ? primaryColor
                                              : Colors.grey.shade400,
                                          size: 28,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Quick selection chips
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(4, (index) {
                                    final seat = index + 1;
                                    final isSelected = tempSeats == seat;
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4),
                                      child: FilterChip(
                                        label: Text(
                                          '$seat',
                                          style: GoogleFonts.poppins(
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.grey.shade700,
                                          ),
                                        ),
                                        selected: isSelected,
                                        onSelected: (_) {
                                          setSeatState(() {
                                            tempSeats = seat;
                                          });
                                        },
                                        backgroundColor: Colors.grey.shade100,
                                        selectedColor: primaryColor,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          side: BorderSide(
                                            color: isSelected
                                                ? primaryColor
                                                : Colors.transparent,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              ),

                              const Spacer(),

                              // Action Buttons
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 14),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                            side: BorderSide(
                                              color: Colors.grey.shade300,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          "Cancel",
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () {
                                          setState(() {
                                            selectedSeats = tempSeats;
                                          });
                                          Navigator.pop(context);
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: primaryColor,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 14),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                          ),
                                          elevation: 2,
                                        ),
                                        child: Text(
                                          "Confirm",
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            }

            // Improved DateTime Picker
            void pickDateTime() async {
              final now = DateTime.now();
              final date = await showDatePicker(
                context: context,
                initialDate: selectedDateTime ?? now,
                firstDate: now,
                lastDate: DateTime(now.year + 1),
                builder: (context, child) {
                  return Theme(
                    data: ThemeData.light().copyWith(
                      primaryColor: primaryColor,
                      colorScheme: const ColorScheme.light(
                        primary: Color.fromRGBO(137, 177, 98, 1),
                      ),
                      buttonTheme: const ButtonThemeData(
                        textTheme: ButtonTextTheme.primary,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (date == null) return;

              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(selectedDateTime ?? now),
                builder: (context, child) {
                  return Theme(
                    data: ThemeData.light().copyWith(
                      primaryColor: primaryColor,
                      colorScheme: const ColorScheme.light(
                        primary: Color.fromRGBO(137, 177, 98, 1),
                      ),
                      buttonTheme: const ButtonThemeData(
                        textTheme: ButtonTextTheme.primary,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (time == null) return;

              setState(() {
                selectedDateTime = DateTime(
                  date.year,
                  date.month,
                  date.day,
                  time.hour,
                  time.minute,
                );
              });
            }

            // Create Ride
            void createRide() async {
              if (isCreating) return;

              if (!formKey.currentState!.validate() ||
                  startStation == null ||
                  destinationStation == null ||
                  selectedDateTime == null ||
                  selectedSeats == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')),
                );
                return;
              }

              setState(() => isCreating = true);

              final user = ref.read(authNotifierProvider).user;
              final vehicle = ref.read(vehicleControllerProvider).vehicle;

              if (user == null || vehicle == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('User or Vehicle missing')),
                );
                setState(() => isCreating = false);
                return;
              }

              final distance =
                  double.tryParse(distanceController.text.trim()) ?? 0;

              final routeService = RouteService();

              final routePath = await routeService.getRoutePoints(
                startLat: startStation!.latitude,
                startLng: startStation!.longitude,
                endLat: destinationStation!.latitude,
                endLng: destinationStation!.longitude,
              );

              final createdRide = await ref
                  .read(rideControllerProvider.notifier)
                  .createRide(
                    user: user.userId,
                    vehicle: vehicle.id!,
                    totalSeats: selectedSeats!,
                    startLocation: startStation!.id,
                    endLocation: destinationStation!.id,
                    routePath: routePath,
                    distance: distance,
                    startTime: selectedDateTime!,
                    endTime: selectedDateTime!.add(const Duration(hours: 1)),
                  );

              if (createdRide != null && context.mounted) {
                ref.read(rideWSControllerProvider(createdRide.id).notifier);
                ref.invalidate(createdRidesProvider(user.userId));

                if (context.mounted) {
                  Navigator.pop(context);
                  showPopUp(context,
                      icon: Icons.check, message: "Ride Created Successfully");
                }
              } else {
                setState(() => isCreating = false);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text('Failed to create ride. Please try again.')),
                  );
                }
              }
            }

            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 24,
              ),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(
                  maxHeight: 650,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.drive_eta_rounded,
                                color: primaryColor,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "Post a Ride",
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1A1A2E),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Station Selectors
                        _selectorTile(
                          label: startStation?.name ?? "Select Start Station",
                          icon: Icons.location_on_outlined,
                          onTap: isCreating
                              ? null
                              : () => showStationSelector(isStart: true),
                        ),
                        const SizedBox(height: 12),
                        _selectorTile(
                          label:
                              destinationStation?.name ?? "Select Destination",
                          icon: Icons.flag_outlined,
                          onTap: isCreating
                              ? null
                              : () => showStationSelector(isStart: false),
                        ),
                        const SizedBox(height: 12),

                        // Seats Selector
                        _selectorTile(
                          label: selectedSeats == null
                              ? "Select Seats"
                              : "$selectedSeats Seat${selectedSeats! > 1 ? 's' : ''}",
                          icon: Icons.event_seat_outlined,
                          onTap: isCreating ? null : showSeatsSelector,
                        ),
                        const SizedBox(height: 12),

                        // Distance Input Field
                        _buildDistanceInputField(
                          controller: distanceController,
                          label: "Distance (km)",
                          icon: Icons.social_distance,
                          inputType: TextInputType.number,
                        ),
                        const SizedBox(height: 12),

                        // DateTime Picker Button
                        GestureDetector(
                          onTap: isCreating ? null : pickDateTime,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: selectedDateTime != null
                                    ? primaryColor
                                    : Colors.grey.shade300,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              color: selectedDateTime != null
                                  ? primaryColor.withOpacity(0.05)
                                  : Colors.white,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_month_rounded,
                                  color: selectedDateTime != null
                                      ? primaryColor
                                      : Colors.grey.shade500,
                                  size: 24,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    selectedDateTime == null
                                        ? 'Pick Date & Time'
                                        : DateFormat('EEE, MMM d • h:mm a')
                                            .format(selectedDateTime!),
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: selectedDateTime != null
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: selectedDateTime != null
                                          ? const Color(0xFF1A1A2E)
                                          : Colors.grey.shade500,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_drop_down,
                                  color: Colors.grey.shade400,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: isCreating
                                    ? null
                                    : () => Navigator.pop(context),
                                style: TextButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    side: BorderSide(
                                      color: Colors.grey.shade300,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  'Cancel',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: isCreating
                                        ? Colors.grey
                                        : Colors.black54,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: isCreating ? null : createRide,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      isCreating ? Colors.grey : primaryColor,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 2,
                                ),
                                child: isCreating
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            "Creating...",
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Text(
                                        "Post Ride",
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    },
  );
}

// 🔧 Reusable Distance Input Field
Widget _buildDistanceInputField({
  required TextEditingController controller,
  required String label,
  required IconData icon,
  TextInputType? inputType,
}) {
  const primaryColor = Color.fromRGBO(137, 177, 98, 1);
  return Container(
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey.shade300),
      borderRadius: BorderRadius.circular(14),
      color: Colors.white,
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Icon(icon, color: primaryColor, size: 24),
        ),
        Expanded(
          child: TextFormField(
            controller: controller,
            keyboardType: inputType,
            validator: (value) =>
                value == null || value.isEmpty ? 'Required' : null,
            decoration: InputDecoration(
              labelText: label,
              labelStyle: GoogleFonts.poppins(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 0,
                vertical: 16,
              ),
            ),
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: const Color(0xFF1A1A2E),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'km',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}

// 🔧 Reusable Selector Tile
Widget _selectorTile({
  required String label,
  required IconData icon,
  required VoidCallback? onTap,
}) {
  const primaryColor = Color.fromRGBO(137, 177, 98, 1);
  return Container(
    decoration: BoxDecoration(
      border: Border.all(
        color:
            onTap != null && label != "Select Seats" && !label.contains("Seat")
                ? primaryColor.withOpacity(0.3)
                : Colors.grey.shade300,
        width: 2,
      ),
      borderRadius: BorderRadius.circular(14),
      color: onTap == null
          ? Colors.grey.shade50
          : label != "Select Seats" && !label.contains("Seat")
              ? primaryColor.withOpacity(0.05)
              : Colors.white,
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(
              icon,
              color: onTap == null
                  ? Colors.grey
                  : label != "Select Seats" && !label.contains("Seat")
                      ? primaryColor
                      : Colors.grey.shade600,
              size: 22,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: label != "Select Seats" && !label.contains("Seat")
                      ? FontWeight.w500
                      : FontWeight.w400,
                  color: onTap == null
                      ? Colors.grey
                      : label != "Select Seats" && !label.contains("Seat")
                          ? const Color(0xFF1A1A2E)
                          : Colors.grey.shade700,
                ),
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: onTap == null ? Colors.grey : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    ),
  );
}

// The _StationSearchSheet should use the same size as the Rides page
// which is typically around 70-75% of the screen height

class _StationSearchSheet extends ConsumerStatefulWidget {
  final bool isFrom;
  final Function(StationModel) onStationSelected;

  const _StationSearchSheet({
    required this.isFrom,
    required this.onStationSelected,
  });

  @override
  ConsumerState<_StationSearchSheet> createState() =>
      _StationSearchSheetState();
}

class _StationSearchSheetState extends ConsumerState<_StationSearchSheet> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();

    _debounce = Timer(
      const Duration(milliseconds: 400),
      () {
        if (mounted) {
          setState(() {
            _query = value.trim();
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchResultAsync = _query.length >= 3
        ? ref.watch(searchStationsProvider(_query))
        : AsyncValue.data(
            StationSearchResult(matchedStations: [], nearbyStations: []),
          );

    return Container(
      // Same height as Rides page - 70% of screen height
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header - Matching Rides Page style
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          widget.isFrom
                              ? Icons.departure_board_rounded
                              : Icons.flag_rounded,
                          color: primaryColor,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          widget.isFrom
                              ? "Select Departure"
                              : "Select Destination",
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A1A2E),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Choose your station",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close_rounded,
                      color: Colors.grey.shade700,
                      size: 22,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Search Field - Matching Rides Page style
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _query.isNotEmpty
                      ? primaryColor.withOpacity(0.3)
                      : Colors.grey.shade200,
                  width: 2,
                ),
                boxShadow: [
                  if (_query.isNotEmpty)
                    BoxShadow(
                      color: primaryColor.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search for stations...',
                  hintStyle: GoogleFonts.poppins(
                    color: Colors.grey.shade400,
                    fontSize: 15,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color:
                        _query.isNotEmpty ? primaryColor : Colors.grey.shade400,
                    size: 24,
                  ),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _controller.clear();
                            setState(() => _query = '');
                            _focusNode.requestFocus();
                          },
                          icon: Icon(
                            Icons.clear_rounded,
                            color: Colors.grey.shade400,
                            size: 20,
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Results
          Expanded(
            child: searchResultAsync.when(
              data: (searchResult) {
                if (_query.isEmpty) {
                  return _buildEmptyState(
                    icon: Icons.search_rounded,
                    title: 'Search for a place',
                    subtitle: 'Type at least 3 characters to find stations',
                  );
                }

                if (_query.length < 3) {
                  return _buildEmptyState(
                    icon: Icons.text_fields_rounded,
                    title: 'Keep typing...',
                    subtitle: 'Enter at least 3 characters to search',
                  );
                }

                if (searchResult.matchedStations.isEmpty &&
                    searchResult.nearbyStations.isEmpty) {
                  return _buildEmptyState(
                    icon: Icons.train_rounded,
                    title: 'No stations found',
                    subtitle: 'Try adjusting your search terms',
                  );
                }

                return _buildResults(searchResult);
              },
              loading: () => const Center(
                child: CircularProgressIndicator.adaptive(),
              ),
              error: (e, _) => _buildEmptyState(
                icon: Icons.error_outline_rounded,
                title: 'Something went wrong',
                subtitle: 'Please try again',
                isError: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    bool isError = false,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: isError ? Colors.red.shade50 : Colors.grey.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 36,
              color: isError ? Colors.red.shade400 : Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isError ? Colors.red.shade700 : Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: isError ? Colors.red.shade400 : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(StationSearchResult searchResult) {
    final hasMatched = searchResult.matchedStations.isNotEmpty;
    final hasNearby = searchResult.nearbyStations.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        // Matched Stations Section
        if (hasMatched) ...[
          _buildSectionHeader(
            icon: Icons.star_rounded,
            title: 'Matched Stations',
            count: searchResult.matchedStations.length,
            color: primaryColor,
          ),
          const SizedBox(height: 8),
          ...searchResult.matchedStations
              .map((station) => _buildStationCard(station, isMatched: true)),
          if (hasNearby) const SizedBox(height: 24),
        ],

        // Nearby Stations Section
        if (hasNearby) ...[
          _buildSectionHeader(
            icon: Icons.location_on_rounded,
            title: 'Nearby Stations',
            count: searchResult.nearbyStations.length,
            color: Colors.blue.shade600,
          ),
          const SizedBox(height: 8),
          ...searchResult.nearbyStations
              .map((station) => _buildStationCard(station, isMatched: false)),
        ],

        // Info message when only nearby stations exist
        if (!hasMatched && hasNearby) ...[
          const SizedBox(height: 8),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primaryColor.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No exact matches found. Showing nearby stations instead.',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: primaryColor.withOpacity(0.8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required int count,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStationCard(StationModel station, {required bool isMatched}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isMatched ? primaryColor.withOpacity(0.3) : Colors.grey.shade200,
          width: isMatched ? 2 : 1.5,
        ),
        color: isMatched ? primaryColor.withOpacity(0.06) : Colors.white,
        boxShadow: [
          if (isMatched)
            BoxShadow(
              color: primaryColor.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: InkWell(
        onTap: () {
          widget.onStationSelected(station);
          Navigator.pop(context);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          child: Row(
            children: [
              // Icon with gradient background
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isMatched
                        ? [primaryColor, primaryColor.withOpacity(0.7)]
                        : [Colors.blue.shade400, Colors.blue.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isMatched ? Icons.star_rounded : Icons.train_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),

              // Station Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      station.name,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight:
                            isMatched ? FontWeight.w600 : FontWeight.w500,
                        color: const Color(0xFF1A1A2E),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          isMatched
                              ? Icons.star_rounded
                              : Icons.location_on_rounded,
                          size: 14,
                          color:
                              isMatched ? primaryColor : Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          station.distanceKm != null
                              ? '${station.distanceKm!.toStringAsFixed(1)} km'
                              : 'Distance unknown',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color:
                                isMatched ? primaryColor : Colors.grey.shade600,
                            fontWeight:
                                isMatched ? FontWeight.w500 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Distance Badge
              if (station.distanceKm != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isMatched
                          ? [primaryColor, primaryColor.withOpacity(0.7)]
                          : [Colors.blue.shade400, Colors.blue.shade600],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${station.distanceKm!.toStringAsFixed(1)} km',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      color: Colors.white,
                    ),
                  ),
                ),

              const SizedBox(width: 8),

              // Arrow indicator
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey.shade300,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
