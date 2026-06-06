// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hop_eir/base_url.dart';
import 'package:hop_eir/features/auth/presentation/providers/auth_provider.dart';
import 'package:hop_eir/features/stations/data/models/station_model.dart';
import 'package:hop_eir/features/stations/presentation/providers/providers.dart';
import 'package:hop_eir/main_screen.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class CommuteInfoScreen extends ConsumerStatefulWidget {
  const CommuteInfoScreen({super.key});

  @override
  ConsumerState<CommuteInfoScreen> createState() => _CommuteInfoScreenState();
}

class _CommuteInfoScreenState extends ConsumerState<CommuteInfoScreen>
    with TickerProviderStateMixin {
  int _step = 0;

  String? _transportChoice;
  String? _customChoice;

  StationModel? _startStation;
  StationModel? _endStation;

  TimeOfDay? _travelTime;

  final _frequencyController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;

  final Color primaryColor = const Color(0xFF89B162);

  final List<Map<String, Object>> transportOptions = [
    {
      "title": "I drive my own car",
      "icon": Icons.directions_car,
    },
    {
      "title": "I ride with someone",
      "icon": Icons.groups,
    },
    {
      "title": "I use public transport",
      "icon": Icons.train,
    },
    {
      "title": "I bike or walk",
      "icon": Icons.directions_bike,
    },
    {
      "title": "Other",
      "icon": Icons.more_horiz,
    },
  ];

  void _nextStep() {
    if (_step < 2) {
      setState(() => _step++);
    }
  }

  void _prevStep() {
    if (_step > 0) {
      setState(() => _step--);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() => _travelTime = picked);
    }
  }

  void _selectStation(
    bool isStart,
    List<StationModel> stations,
  ) {
    final sortedStations = [...stations]..sort(
        (a, b) => a.name.toLowerCase().compareTo(
              b.name.toLowerCase(),
            ),
      );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.82,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(34),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 14),
              Container(
                width: 70,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(
                    20,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(22),
                child: Row(
                  children: [
                    Text(
                      "Select Station",
                      style: GoogleFonts.racingSansOne(
                        fontSize: 32,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: sortedStations.length,
                  itemBuilder: (_, i) {
                    final station = sortedStations[i];

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 6,
                      ),
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                          22,
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(
                            22,
                          ),
                          onTap: () {
                            setState(() {
                              if (isStart) {
                                _startStation = station;
                              } else {
                                _endStation = station;
                              }
                            });

                            Navigator.pop(
                              context,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(
                              18,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                22,
                              ),
                              border: Border.all(
                                color: Colors.grey.shade200,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(
                                    12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(
                                      0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      18,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.train,
                                    color: primaryColor,
                                  ),
                                ),
                                const SizedBox(
                                  width: 16,
                                ),
                                Expanded(
                                  child: Text(
                                    station.name,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: primaryColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submit(String userId) async {
    final transportFinalChoice =
        _transportChoice == 'Other' ? _customChoice?.trim() : _transportChoice;

    if (transportFinalChoice == null ||
        _startStation == null ||
        _endStation == null ||
        _travelTime == null ||
        _frequencyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complete all fields'),
        ),
      );

      return;
    }

    setState(() => _isLoading = true);

    final formattedTime = DateFormat(
      "HH:mm:ss",
    ).format(
      DateTime(
        0,
        1,
        1,
        _travelTime!.hour,
        _travelTime!.minute,
      ),
    );

    final data = {
      "user": userId,
      "starting": _startStation!.name,
      "destination": _endStation!.name,
      "preferred_route": "Via NH48",
      "choice": transportFinalChoice,
      "travel_time": formattedTime,
      "frequency": int.parse(
        _frequencyController.text.trim(),
      ),
    };

    try {
      final res = await http.post(
        Uri.parse(
          '$baseURL/model-data/post/',
        ),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode(data),
      );

      if (res.statusCode == 201 && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const MainScreen(),
          ),
        );
      } else {
        throw Exception(res.body);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Submission failed: $e"),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _stepIndicator() {
    return Row(
      children: List.generate(
        3,
        (index) => Expanded(
          child: AnimatedContainer(
            duration: const Duration(
              milliseconds: 350,
            ),
            margin: const EdgeInsets.symmetric(
              horizontal: 5,
            ),
            height: 8,
            decoration: BoxDecoration(
              color: index <= _step ? Colors.white : Colors.white24,
              borderRadius: BorderRadius.circular(
                30,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _glassContainer({
    required Widget child,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(34),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 20,
          sigmaY: 20,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(
            26,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(34),
            color: Colors.white.withOpacity(
              0.12,
            ),
            border: Border.all(
              color: Colors.white.withOpacity(
                0.2,
              ),
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _selectionTile({
    required String title,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(
          milliseconds: 250,
        ),
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white
              : Colors.white.withOpacity(
                  0.08,
                ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? Colors.white : Colors.white12,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    selected ? primaryColor.withOpacity(0.1) : Colors.white12,
                borderRadius: BorderRadius.circular(
                  16,
                ),
              ),
              child: Icon(
                icon,
                color: selected ? primaryColor : Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  color: selected ? Colors.black87 : Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            if (selected)
              Icon(
                Icons.check_circle,
                color: primaryColor,
              ),
          ],
        ),
      ),
    );
  }

  Widget _routeSelector({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(
            0.08,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white12,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(
                  16,
                ),
              ),
              child: Icon(
                icon,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 18,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).user;

    final stationAsync = ref.watch(allStationsProvider);

    if (user == null || stationAsync is AsyncLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final stations = stationAsync.asData!.value;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF7EA45A),
              Color(0xFF89B162),
              Color(0xFFB7D49B),
            ],
          ),
        ),
        child: SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 18,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Daily\nCommute",
                    style: GoogleFonts.racingSansOne(
                      fontSize: 54,
                      color: Colors.white,
                      height: 0.95,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Let’s personalize your travel experience",
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _stepIndicator(),
                  const SizedBox(height: 32),
                  AnimatedSwitcher(
                    duration: const Duration(
                      milliseconds: 350,
                    ),
                    child: _step == 0
                        ? _glassContainer(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "How do you usually travel?",
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24,
                                  ),
                                ),
                                const SizedBox(
                                  height: 24,
                                ),
                                ...transportOptions.map(
                                  (option) {
                                    final title = option["title"] as String;

                                    final icon = option["icon"] as IconData;

                                    return _selectionTile(
                                      title: title,
                                      icon: icon,
                                      selected: _transportChoice == title,
                                      onTap: () {
                                        setState(
                                          () {
                                            _transportChoice = title;
                                          },
                                        );

                                        if (title != "Other") {
                                          Future.delayed(
                                            const Duration(
                                              milliseconds: 200,
                                            ),
                                            _nextStep,
                                          );
                                        }
                                      },
                                    );
                                  },
                                ),
                                if (_transportChoice == "Other")
                                  TextField(
                                    onChanged: (v) => _customChoice = v,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.white,
                                      hintText: "Specify your transport...",
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          20,
                                        ),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          )
                        : _step == 1
                            ? _glassContainer(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Select Route",
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 24,
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 24,
                                    ),
                                    _routeSelector(
                                      title: _startStation?.name ??
                                          "Choose Starting Station",
                                      icon: Icons.train,
                                      onTap: () => _selectStation(
                                        true,
                                        stations,
                                      ),
                                    ),
                                    _routeSelector(
                                      title: _endStation?.name ??
                                          "Choose Destination",
                                      icon: Icons.location_on,
                                      onTap: () => _selectStation(
                                        false,
                                        stations,
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 58,
                                      child: ElevatedButton(
                                        onPressed: _startStation != null &&
                                                _endStation != null
                                            ? _nextStep
                                            : null,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor: primaryColor,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              22,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          "Continue",
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : _glassContainer(
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Travel Schedule",
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 24,
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 24,
                                      ),
                                      _routeSelector(
                                        title: _travelTime == null
                                            ? "Select Preferred Time"
                                            : _travelTime!.format(
                                                context,
                                              ),
                                        icon: Icons.access_time,
                                        onTap: _pickTime,
                                      ),
                                      TextFormField(
                                        controller: _frequencyController,
                                        keyboardType: TextInputType.number,
                                        style: GoogleFonts.poppins(),
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: Colors.white,
                                          hintText: "Trips per week",
                                          prefixIcon: const Icon(
                                            Icons.repeat,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              22,
                                            ),
                                            borderSide: BorderSide.none,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 28,
                                      ),
                                      SizedBox(
                                        width: double.infinity,
                                        height: 60,
                                        child: ElevatedButton(
                                          onPressed: _isLoading
                                              ? null
                                              : () {
                                                  _submit(
                                                    user.userId,
                                                  );
                                                },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            foregroundColor: primaryColor,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                24,
                                              ),
                                            ),
                                          ),
                                          child: _isLoading
                                              ? const CircularProgressIndicator()
                                              : Text(
                                                  "Complete Setup",
                                                  style: GoogleFonts.poppins(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 17,
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                  ),
                  const SizedBox(height: 30),
                  if (_step > 0)
                    Center(
                      child: TextButton(
                        onPressed: _prevStep,
                        child: Text(
                          "Back",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
