import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hop_eir/features/banner/presentation/banner_widget.dart';
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
        builder: (context) => SearchedRidesPage(
          fromStation: _fromStation!,
          toStation: _toStation!,
          seats: _seats!,
        ),
      ),
    ).then((_) {
      setState(() {
        _fromStation = null;
        _toStation = null;
        _seats = null;
      });
    });
  }

  void _showStationSelector({required bool isFrom}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return _StationSearchSheet(
          isFrom: isFrom,
          onStationSelected: (station) {
            setState(() {
              if (isFrom) {
                _fromStation = station;
              } else {
                _toStation = station;
              }
            });
          },
        );
      },
    );
  }

  void _showSeatsSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.4,
            child: Column(
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
                    leading:
                        const Icon(Icons.event_seat, color: Colors.black54),
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
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final stationsAsync = ref.watch(allStationsProvider);
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 30,
              left: 0,
              right: 0,
              height: size.height * 0.32,
              child: Image.asset(
                "assets/images/Group 1 (4).png",
                fit: BoxFit.contain,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 30 : 20,
              ),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      "Find Your Ride",
                      style: GoogleFonts.luckiestGuy(
                        fontWeight: FontWeight.w300,
                        fontSize: isTablet ? 34 : 28,
                        color: primaryColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Card(
                    color: Colors.white,
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 24,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
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
                          const SizedBox(height: 16),
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
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: _showSeatsSelector,
                            child: _buildSelectorTile(
                              value: _seats != null
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
                                padding: EdgeInsets.symmetric(
                                  vertical: isTablet ? 18 : 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                "Search Ride",
                                style: GoogleFonts.poppins(
                                  fontSize: isTablet ? 20 : 18,
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
                  const SizedBox(height: 90),
                ],
              ),
            ),
            Positioned(
              top: 30,
              left: 0,
              right: 0,
              height: size.height * 0.32,
              child: const BannerWidget(),
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

  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();

    _debounce = Timer(
      const Duration(milliseconds: 400),
      () {
        setState(() {
          _query = value.trim();
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final stationsAsync = _query.length >= 3
        ? ref.watch(searchStationsProvider(_query))
        : const AsyncValue.data(<StationModel>[]);

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
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
              child: TextField(
                controller: _controller,
                onChanged: _onSearchChanged,
                decoration: const InputDecoration(
                  hintText: 'Search place...',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            Expanded(
              child: stationsAsync.when(
                data: (stations) {
                  if (_query.length < 3) {
                    return const Center(
                      child: Text(
                        'Enter at least 3 characters',
                      ),
                    );
                  }

                  if (stations.isEmpty) {
                    return const Center(
                      child: Text(
                        'No stations found',
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: stations.length,
                    itemBuilder: (context, index) {
                      final station = stations[index];

                      return ListTile(
                        leading: const Icon(Icons.train),
                        title: Text(station.name),
                        onTap: () {
                          widget.onStationSelected(station);
                          Navigator.pop(context);
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (e, _) => Center(
                  child: Text('Error: $e'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
