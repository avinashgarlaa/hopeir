// Keep your imports unchanged...

import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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

class _CommuteInfoScreenState extends ConsumerState<CommuteInfoScreen> {
  int _step = 0;
  String? _transportChoice;
  String? _customChoice;
  StationModel? _startStation;
  StationModel? _endStation;
  TimeOfDay? _travelTime;
  final _frequencyController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  List<String> transportOptions = [
    'I drive my own car',
    'I ride with someone (carpool)',
    'I use public transport',
    'I bike or walk',
    'Other',
  ];

  void _nextStep() {
    if (_step < 2) setState(() => _step++);
  }

  void _prevStep() {
    if (_step > 0) setState(() => _step--);
  }

  void _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) setState(() => _travelTime = picked);
  }

  void _selectStation(bool isStart, List<StationModel> stations) {
    // Create a sorted copy of the stations list (case-insensitive sort)
    final sortedStations = [...stations]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ListView.builder(
        itemCount: sortedStations.length,
        itemBuilder: (_, i) => ListTile(
          leading: const Icon(Icons.train, color: Colors.white),
          title: Text(
            sortedStations[i].name,
            style: const TextStyle(color: Colors.white),
          ),
          onTap: () {
            setState(() {
              if (isStart) {
                _startStation = sortedStations[i];
              } else {
                _endStation = sortedStations[i];
              }
              if (_startStation != null && _endStation != null) {
                _nextStep();
              }
            });
            Navigator.pop(context);
          },
        ),
      ),
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
        const SnackBar(content: Text('Please complete all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final formattedTime = DateFormat(
      "HH:mm:ss",
    ).format(DateTime(0, 1, 1, _travelTime!.hour, _travelTime!.minute));

    final data = {
      "user": userId,
      "starting": _startStation!.name,
      "destination": _endStation!.name,
      "preferred_route": "Via NH48",
      "choice": transportFinalChoice,
      "travel_time": formattedTime,
      "frequency": int.parse(_frequencyController.text.trim()),
    };

    try {
      final res = await http.post(
        Uri.parse('https://hopeir.onrender.com/model-data/post/'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );

      if (res.statusCode == 201 && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      } else {
        throw Exception(res.body);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Submission failed: $e")));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).user;
    final stationAsync = ref.watch(allStationsProvider);

    if (user == null || stationAsync is AsyncLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final stations = stationAsync.asData!.value;
    final size = MediaQuery.of(context).size;
    final height = size.height;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF89B162), Color(0xFFF5F7FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: size.width * 0.08),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                      child: Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 35,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              "Your Daily Commute",
                              style: GoogleFonts.racingSansOne(
                                fontSize: height * 0.04,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: ColorScheme.light(
                                  primary: const Color(0xFF89B162),
                                  onSurface: Colors.white,
                                ),
                              ),
                              child: Stepper(
                                currentStep: _step,
                                onStepContinue: _step < 2 ? _nextStep : null,
                                onStepCancel: _prevStep,
                                controlsBuilder: (_, __) => const SizedBox(),
                                type: StepperType.vertical,
                                steps: [
                                  Step(
                                    title: Text(
                                      "1. How do you travel?",
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        color: Colors.black45,
                                      ),
                                    ),
                                    isActive: _step >= 0,
                                    content: Column(
                                      children: [
                                        ...transportOptions.map(
                                          (opt) => RadioListTile<String>(
                                            value: opt,
                                            groupValue: _transportChoice,
                                            onChanged: (val) {
                                              setState(() {
                                                _transportChoice = val;
                                                if (val != 'Other') {
                                                  _customChoice = null;
                                                  _nextStep();
                                                }
                                              });
                                            },
                                            title: Text(
                                              opt,
                                              style: const TextStyle(
                                                color: Colors.black45,
                                              ),
                                            ),
                                          ),
                                        ),
                                        if (_transportChoice == 'Other')
                                          TextFormField(
                                            style: const TextStyle(
                                              color: Colors.black45,
                                            ),
                                            decoration: const InputDecoration(
                                              hintText: "Please specify",
                                              hintStyle: TextStyle(
                                                color: Colors.white54,
                                              ),
                                            ),
                                            onChanged: (val) =>
                                                _customChoice = val.trim(),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Step(
                                    title: Text(
                                      "2. What's the route?",
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        color: Colors.black45,
                                      ),
                                    ),
                                    isActive: _step >= 1,
                                    content: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        TextButton.icon(
                                          icon: const Icon(
                                            Icons.train,
                                            color: Colors.white,
                                          ),
                                          label: Text(
                                            _startStation?.name ??
                                                "Choose Starting Point",
                                            style: const TextStyle(
                                              color: Colors.black45,
                                            ),
                                          ),
                                          onPressed: () => _selectStation(
                                            true,
                                            stations,
                                          ),
                                        ),
                                        TextButton.icon(
                                          icon: const Icon(
                                            Icons.location_on,
                                            color: Colors.white,
                                          ),
                                          label: Text(
                                            _endStation?.name ??
                                                "Choose Destination",
                                            style: const TextStyle(
                                              color: Colors.black45,
                                            ),
                                          ),
                                          onPressed: () => _selectStation(
                                            false,
                                            stations,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Step(
                                    title: Text(
                                      "3. Your Schedule",
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        color: Colors.black45,
                                      ),
                                    ),
                                    isActive: _step >= 2,
                                    content: Form(
                                      key: _formKey,
                                      child: Column(
                                        children: [
                                          TextButton.icon(
                                            icon: const Icon(
                                              Icons.access_time,
                                              color: Colors.black45,
                                            ),
                                            label: Text(
                                              _travelTime == null
                                                  ? "Pick Travel Time"
                                                  : _travelTime!.format(
                                                      context,
                                                    ),
                                              style: const TextStyle(
                                                color: Colors.black45,
                                              ),
                                            ),
                                            onPressed: _pickTime,
                                          ),
                                          const SizedBox(height: 12),
                                          TextFormField(
                                            controller: _frequencyController,
                                            keyboardType: TextInputType.number,
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                            decoration: const InputDecoration(
                                              labelText: "Times per week",
                                              labelStyle: TextStyle(
                                                color: Colors.black45,
                                              ),
                                              prefixIcon: Icon(
                                                Icons.repeat,
                                                color: Colors.black45,
                                              ),
                                              enabledBorder:
                                                  UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                            validator: (val) {
                                              if (val == null || val.isEmpty) {
                                                return 'Please enter frequency';
                                              }
                                              return null;
                                            },
                                          ),
                                          const SizedBox(height: 20),
                                          ElevatedButton(
                                            onPressed: _isLoading
                                                ? null
                                                : () {
                                                    if (_formKey.currentState!
                                                        .validate()) {
                                                      _submit(user.userId);
                                                    }
                                                  },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(
                                                0xFF89B162,
                                              ),
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 40,
                                                vertical: 14,
                                              ),
                                            ),
                                            child: Text(
                                              _isLoading
                                                  ? "Submitting..."
                                                  : "Submit",
                                              style: const TextStyle(
                                                fontSize: 18,
                                              ),
                                            ),
                                          ),
                                        ],
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
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
