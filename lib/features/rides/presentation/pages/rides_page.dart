import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hop_eir/features/banner/presentation/banner_widget.dart';
import 'package:hop_eir/features/rides/presentation/pages/searched_rides_page.dart';
import 'package:hop_eir/features/rides/presentation/widgets/message_banner.dart';
import 'package:hop_eir/features/stations/data/models/station_model.dart';
import 'package:hop_eir/features/stations/domain/usecases/search_stations.dart';
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

  final TextEditingController _seatsController = TextEditingController();
  final FocusNode _seatsFocusNode = FocusNode();

  @override
  void dispose() {
    _seatsController.dispose();
    _seatsFocusNode.dispose();
    super.dispose();
  }

  void _searchRides() {
    if (_fromStation == null || _toStation == null || _seats == null) {
      showPopUp(
        context,
        icon: FontAwesomeIcons.warning,
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
        _seatsController.clear();
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
                  Row(
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
                      // ElevatedButton(
                      //   onPressed: () async {
                      //     // Clear any previous notifications
                      //     await LocalNotificationHelper
                      //         .cancelAllNotifications();

                      //     // Step 1: Check if initialized
                      //     print('🔔 Step 1: Checking initialization...');

                      //     // Step 2: Check permission status
                      //     print('🔔 Step 2: Checking permission...');
                      //     bool hasPermission =
                      //         await LocalNotificationHelper.hasPermission();
                      //     print('  → Permission status: $hasPermission');

                      //     if (!hasPermission) {
                      //       print('🔔 Step 3: Requesting permission...');
                      //       bool requested = await LocalNotificationHelper
                      //           .requestPermissions();
                      //       print('  → Permission requested: $requested');

                      //       if (!requested) {
                      //         print('❌ Permission denied!');
                      //         // Show dialog to enable in settings
                      //         if (context.mounted) {
                      //           await LocalNotificationHelper
                      //               .showEnableNotificationDialog(context);
                      //         }
                      //         return;
                      //       }
                      //     }

                      //     // Step 4: Show notification
                      //     print('🔔 Step 4: Showing notification...');
                      //     bool result =
                      //         await LocalNotificationHelper.showNotification(
                      //       'HopÉir Test',
                      //       'This is a test notification',
                      //     );

                      //     print('  → Notification result: $result');

                      //     // Step 5: Show feedback
                      //     if (context.mounted) {
                      //       ScaffoldMessenger.of(context).showSnackBar(
                      //         SnackBar(
                      //           content: Text(
                      //             result
                      //                 ? '✅ Notification sent! Check your notifications.'
                      //                 : '❌ Failed to send notification. Check logs.',
                      //           ),
                      //           backgroundColor:
                      //               result ? Colors.green : Colors.red,
                      //           duration: const Duration(seconds: 3),
                      //         ),
                      //       );
                      //     }

                      //     print('🔔 Step 5: Test complete ✅');
                      //   },
                      //   child: const Text('🔔 Test'),
                      // ),
                    ],
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
                          // Seats Text Field
                          _buildSeatsTextField(),
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

  Widget _buildSeatsTextField() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: primaryColor.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(14),
        color: Colors.grey[50],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: const Icon(
              Icons.person_outline,
              color: primaryColor,
            ),
          ),
          Expanded(
            child: TextField(
              controller: _seatsController,
              focusNode: _seatsFocusNode,
              keyboardType: TextInputType.number,
              maxLength: 1,
              decoration: InputDecoration(
                hintText: "Select Seats (1-4)",
                hintStyle: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey.shade400,
                ),
                border: InputBorder.none,
                counterText: '',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 0,
                  vertical: 16,
                ),
              ),
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
              onChanged: (value) {
                if (value.isEmpty) {
                  setState(() {
                    _seats = null;
                  });
                  return;
                }

                final seatCount = int.tryParse(value);
                if (seatCount != null && seatCount >= 1 && seatCount <= 4) {
                  setState(() {
                    _seats = seatCount;
                  });
                } else {
                  // If invalid, keep the previous valid value
                  if (_seats != null) {
                    _seatsController.text = _seats.toString();
                  }
                }
              },
            ),
          ),
          // Optional: Add + and - buttons as small icons in the text field
          Row(
            children: [
              IconButton(
                onPressed: () {
                  final currentSeats = _seats ?? 1;
                  if (currentSeats > 1) {
                    final newSeats = currentSeats - 1;
                    setState(() {
                      _seats = newSeats;
                      _seatsController.text = newSeats.toString();
                    });
                  }
                },
                icon: Icon(
                  Icons.remove_circle_outline,
                  color: primaryColor.withOpacity(0.6),
                  size: 24,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  final currentSeats = _seats ?? 0;
                  if (currentSeats < 4) {
                    final newSeats = currentSeats + 1;
                    setState(() {
                      _seats = newSeats;
                      _seatsController.text = newSeats.toString();
                    });
                  }
                },
                icon: Icon(
                  Icons.add_circle_outline,
                  color: primaryColor.withOpacity(0.6),
                  size: 24,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 14),
            ],
          ),
        ],
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
          const Icon(
            Icons.arrow_drop_down,
            color: Colors.grey,
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
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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

          // Header
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

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _query.isNotEmpty
                      ? primaryColor.withOpacity(0.5)
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
