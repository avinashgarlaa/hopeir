import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hop_eir/features/rides/presentation/pages/searched_rides_page.dart';
import 'package:hop_eir/features/rides/presentation/widgets/message_banner.dart';
import 'package:hop_eir/features/stations/data/models/station_model.dart';
import 'package:hop_eir/features/stations/presentation/providers/providers.dart';

class RidesPage extends ConsumerStatefulWidget {
  const RidesPage({super.key});

  @override
  ConsumerState<RidesPage> createState() => _RidesPageState();
}

class _RidesPageState extends ConsumerState<RidesPage> {
  StationModel? _fromStation;
  StationModel? _toStation;
  int? _seats;

  void _searchRides() {
    if (_fromStation == null || _toStation == null || _seats == null) {
      showPopUp(
        context,
        icon: Icons.warning,
        message: "Please fill all fields!",
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => SearchedRidesPage(
              fromStation: _fromStation!,
              toStation: _toStation!,
              seats: _seats!,
            ),
      ),
    );
  }

  void _showStationSelector({required bool isFrom}) {
    final stationsAsync = ref.read(allStationsProvider);
    stationsAsync.whenData((stations) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  "Select Station",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 20),
                  itemCount: stations.length,
                  itemBuilder: (context, index) {
                    final station = stations[index];
                    return ListTile(
                      leading: const Icon(Icons.train, color: Colors.black54),
                      title: Text(
                        station.name,
                        style: GoogleFonts.poppins(fontSize: 15),
                      ),
                      onTap: () {
                        setState(() {
                          if (isFrom) {
                            _fromStation = station;
                          } else {
                            _toStation = station;
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

  void _showSeatsSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                "Select Seats",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
            ),
            ...List.generate(4, (index) {
              final seat = index + 1;
              return ListTile(
                leading: const Icon(Icons.event_seat, color: Colors.black54),
                title: Text(
                  "$seat Seat${seat > 1 ? 's' : ''}",
                  style: GoogleFonts.poppins(fontSize: 15),
                ),
                onTap: () {
                  setState(() {
                    _seats = seat;
                  });
                  Navigator.pop(context);
                },
              );
            }),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final stationsAsync = ref.watch(allStationsProvider);
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        child: Stack(
          children: [
            SizedBox(
              height: height * 0.45,
              width: width,
              child: Image.asset("assets/images/Group 1 (4).png"),
            ),
            SafeArea(
              child: Text(
                "Find Your Ride",
                style: GoogleFonts.luckiestGuy(
                  fontWeight: FontWeight.w300,
                  fontSize: 28,
                  color: primaryColor,
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  height: height * 0.4,
                  child: Card(
                    color: Colors.white,
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(height * 0.025),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Text(
                          //   "Find Your Ride",
                          //   style: GoogleFonts.racingSansOne(
                          //     fontSize: 28,
                          //     fontWeight: FontWeight.w600,
                          //     color: primaryColor,
                          //   ),
                          // ),
                          const SizedBox(height: 20),

                          // From Station
                          GestureDetector(
                            onTap: () {
                              if (stationsAsync.hasValue) {
                                _showStationSelector(isFrom: true);
                              }
                            },
                            child: _buildSelectorTile(
                              value: _fromStation?.name ?? "From Station",
                              icon: Icons.location_on,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // To Station
                          GestureDetector(
                            onTap: () {
                              if (stationsAsync.hasValue) {
                                _showStationSelector(isFrom: false);
                              }
                            },
                            child: _buildSelectorTile(
                              value: _toStation?.name ?? "To Station",
                              icon: Icons.location_on_outlined,
                            ),
                          ),
                          const SizedBox(height: 12),

                          GestureDetector(
                            onTap: _showSeatsSelector,
                            child: _buildSelectorTile(
                              value:
                                  _seats != null
                                      ? "$_seats Seat${_seats! > 1 ? 's' : ''}"
                                      : "Select Seats",
                              icon: Icons.person_outline,
                            ),
                          ),
                          const SizedBox(height: 28),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _searchRides,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                  horizontal: 24,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                "Search Ride",
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
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
                SizedBox(height: height * 0.15),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectorTile({required String value, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        border: Border.all(color: primaryColor.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(14),
        color: Colors.grey[50],
      ),
      child: Row(
        children: [
          Icon(icon, color: primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Theme Colors
const primaryColor = Color.fromRGBO(137, 177, 98, 1);
const backgroundColor = Color(0xFFF5F7FF);
