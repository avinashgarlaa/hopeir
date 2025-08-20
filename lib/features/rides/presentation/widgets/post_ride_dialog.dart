// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hop_eir/features/auth/presentation/providers/auth_provider.dart';
import 'package:hop_eir/features/rides/presentation/controllers/ride_ws_controller.dart';
import 'package:hop_eir/features/rides/presentation/pages/post_ride_page.dart';
import 'package:hop_eir/features/rides/presentation/providers/ride_provider.dart';
import 'package:hop_eir/features/stations/domain/entities/station.dart';
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
  const primaryColor = Color.fromRGBO(137, 177, 98, 1);
  await showDialog<bool>(
    context: context,
    builder: (context) {
      return GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: StatefulBuilder(
          builder: (context, setState) {
            void showStationSelector({required bool isStart}) {
              final stationsAsync = ref.read(allStationsProvider);
              stationsAsync.whenData((stations) {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  builder: (context) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 12),
                          width: 50,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            "Select Station",
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            itemCount: stations.length,
                            separatorBuilder: (_, __) => const Divider(),
                            itemBuilder: (context, index) {
                              final station = stations[index];
                              return ListTile(
                                leading: const Icon(
                                  Icons.train,
                                  color: Colors.black,
                                ),
                                title: Text(
                                  station.name,
                                  style: GoogleFonts.poppins(),
                                ),
                                onTap: () {
                                  setState(() {
                                    if (isStart) {
                                      startStation = station;
                                    } else {
                                      destinationStation = station;
                                    }
                                  });
                                  Navigator.pop(context);
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                );
              });
            }

            void showSeatsSelector() {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (context) {
                  return SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Small handle bar
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 12),
                          width: 50,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            "Select Seats",
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),
                        ListView.builder(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          itemCount: 4,
                          itemBuilder: (context, index) {
                            final seat = index + 1;
                            return Column(
                              children: [
                                ListTile(
                                  leading: const Icon(
                                    Icons.event_seat,
                                    color: Colors.black,
                                  ),
                                  title: Text(
                                    '$seat Seat${seat > 1 ? 's' : ''}',
                                    style: GoogleFonts.poppins(),
                                  ),
                                  onTap: () {
                                    setState(() {
                                      selectedSeats = seat;
                                    });
                                    Navigator.pop(context);
                                  },
                                ),
                                SizedBox(height: 20),
                                const Divider(),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            }

            void pickDateTime() async {
              final now = DateTime.now();
              final date = await showDatePicker(
                context: context,
                initialDate: now,
                firstDate: now,
                lastDate: DateTime(now.year + 1),
              );
              if (date == null) return;
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(now),
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

            void createRide() async {
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

              final user = ref.read(authNotifierProvider).user;
              final vehicle = ref.read(vehicleControllerProvider).vehicle;

              if (user == null || vehicle == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('User or Vehicle missing')),
                );
                return;
              }

              final distance =
                  double.tryParse(distanceController.text.trim()) ?? 0;

              final createdRide = await ref
                  .read(rideControllerProvider.notifier)
                  .createRide(
                    user: user.userId,
                    vehicle: vehicle.id!,
                    totalSeats: selectedSeats!,
                    startLocation: startStation!.id,
                    endLocation: destinationStation!.id,
                    distance: distance,
                    startTime: selectedDateTime!,
                    endTime: selectedDateTime!.add(const Duration(hours: 1)),
                  );

              if (createdRide != null && context.mounted) {
                ref.read(rideWSControllerProvider(createdRide.id).notifier);
                print(
                  "🌐 Driver connected to ride WS for ride ID: ${createdRide.id}",
                );

                ref.invalidate(createdRidesProvider(user.userId));

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ride Created Successfully')),
                );
              }
            }

            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Text(
                        //   "Post Ride",
                        //   style: GoogleFonts.poppins(
                        //     fontSize: 24,
                        //     fontWeight: FontWeight.bold,
                        //     color: primaryColor,
                        //   ),
                        // ),
                        const SizedBox(height: 20),

                        _selectorTile(
                          label: startStation?.name ?? "Select Start Station",
                          icon: Icons.location_on_outlined,
                          onTap: () => showStationSelector(isStart: true),
                        ),
                        const SizedBox(height: 12),

                        _selectorTile(
                          label:
                              destinationStation?.name ?? "Select Destination",
                          icon: Icons.flag_outlined,
                          onTap: () => showStationSelector(isStart: false),
                        ),
                        const SizedBox(height: 12),

                        const SizedBox(height: 12),

                        _selectorTile(
                          label:
                              selectedSeats == null
                                  ? "Select Seats"
                                  : "$selectedSeats Seats",
                          icon: Icons.event_seat_outlined,
                          onTap: showSeatsSelector,
                        ),
                        const SizedBox(height: 12),

                        _buildInputField(
                          controller: distanceController,
                          label: "Distance (km)",
                          icon: Icons.social_distance,
                          inputType: TextInputType.number,
                        ),
                        const SizedBox(height: 12),

                        ElevatedButton.icon(
                          onPressed: pickDateTime,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 15,
                            ),
                            backgroundColor: primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),

                          label: Row(
                            children: [
                              SizedBox(width: 5),
                              const Icon(
                                Icons.calendar_today,
                                size: 25,
                                color: Color.fromARGB(255, 255, 255, 255),
                              ),
                              SizedBox(width: 20),
                              Text(
                                selectedDateTime == null
                                    ? 'Pick Date & Time'
                                    : DateFormat.yMMMd().add_jm().format(
                                      selectedDateTime!,
                                    ),
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: const Color.fromARGB(
                                    255,
                                    255,
                                    255,
                                    255,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: createRide,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    backgroundColor: Colors.black54,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    "Post Ride",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
    },
  );
}

// Reusable Input Field
Widget _buildInputField({
  required TextEditingController controller,
  required String label,
  required IconData icon,
  TextInputType? inputType,
}) {
  const primaryColor = Color.fromRGBO(137, 177, 98, 1);
  return TextFormField(
    controller: controller,
    keyboardType: inputType,
    validator: (value) => value == null || value.isEmpty ? 'Required' : null,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: primaryColor),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
    ),
  );
}

// Reusable Selector Tile Widget
Widget _selectorTile({
  required String label,
  required IconData icon,
  required VoidCallback onTap,
}) {
  const primaryColor = Color.fromRGBO(137, 177, 98, 1);
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: primaryColor),
          const SizedBox(width: 16),
          Expanded(
            child: Text(label, style: GoogleFonts.poppins(fontSize: 16)),
          ),
          const Icon(Icons.arrow_drop_down, color: Colors.grey),
        ],
      ),
    ),
  );
}
