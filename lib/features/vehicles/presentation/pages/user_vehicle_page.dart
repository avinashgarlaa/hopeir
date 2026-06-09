import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hop_eir/features/auth/presentation/providers/auth_provider.dart';
import 'package:hop_eir/features/rides/presentation/pages/rides_page.dart';
import 'package:hop_eir/features/vehicles/domain/entities/vehicle.dart';
import 'package:hop_eir/features/vehicles/presentation/provider/vehicle_providers.dart';

class VehiclePage extends ConsumerStatefulWidget {
  const VehiclePage({super.key});

  @override
  ConsumerState<VehiclePage> createState() => _VehiclePageState();
}

class _VehiclePageState extends ConsumerState<VehiclePage> {
  final _formKey = GlobalKey<FormState>();
  final _vehicleTypeController = TextEditingController();
  final _vehicleModelController = TextEditingController();
  final _vehicleYearController = TextEditingController();
  final _vehicleColorController = TextEditingController();
  final _vehicleLicensePlateController = TextEditingController();
  final _vehicleEngineTypeController = TextEditingController();

  @override
  void dispose() {
    _vehicleTypeController.dispose();
    _vehicleModelController.dispose();
    _vehicleYearController.dispose();
    _vehicleColorController.dispose();
    _vehicleLicensePlateController.dispose();
    _vehicleEngineTypeController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final user = ref.read(authNotifierProvider).user;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in')),
        );
        return;
      }

      final newVehicle = Vehicle(
        id: 0,
        user: user.userId,
        vehicleType: _vehicleTypeController.text.trim(),
        vehicleModel: _vehicleModelController.text.trim(),
        vehicleYear: int.tryParse(_vehicleYearController.text.trim()) ?? 0,
        vehicleColor: _vehicleColorController.text.trim(),
        vehicleLicensePlate: _vehicleLicensePlateController.text.trim(),
        vehicleEngineType: _vehicleEngineTypeController.text.trim(),
      );

      ref.read(vehicleControllerProvider.notifier).addVehicle(newVehicle);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vehicleControllerProvider);
    final vehicle = state.vehicle;

    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    const backgroundColor = Color(0xFFF5F7FF);
    const primaryColor = Color.fromRGBO(137, 177, 98, 1);
    const cardColor = Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 40 : 16,
                  vertical: 20,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: vehicle != null
                        ? _buildVehicleDetails(
                            vehicle, cardColor, primaryColor, isTablet)
                        : _buildVehicleForm(primaryColor, isTablet),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildVehicleForm(Color primaryColor, bool isTablet) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.08),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryColor, primaryColor.withOpacity(0.7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Icon(
                        FontAwesomeIcons.car,
                        color: Colors.white,
                        size: isTablet ? 36 : 28,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Add Your Vehicle",
                      style: GoogleFonts.poppins(
                        fontSize: isTablet ? 26 : 22,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Enter your vehicle details below",
                      style: GoogleFonts.poppins(
                        fontSize: isTablet ? 14 : 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              // Form Fields
              _buildFormField(
                "Vehicle Type",
                FontAwesomeIcons.car,
                _vehicleTypeController,
                primaryColor,
              ),
              const SizedBox(height: 12),
              _buildFormField(
                "Vehicle Model",
                FontAwesomeIcons.cogs,
                _vehicleModelController,
                primaryColor,
              ),
              const SizedBox(height: 12),
              _buildFormField(
                "Vehicle Year",
                FontAwesomeIcons.calendar,
                _vehicleYearController,
                primaryColor,
                isNumber: true,
              ),
              const SizedBox(height: 12),
              _buildFormField(
                "Color",
                FontAwesomeIcons.palette,
                _vehicleColorController,
                primaryColor,
              ),
              const SizedBox(height: 12),
              _buildFormField(
                "License Plate",
                FontAwesomeIcons.idCard,
                _vehicleLicensePlateController,
                primaryColor,
              ),
              const SizedBox(height: 12),
              _buildFormField(
                "Engine Type",
                FontAwesomeIcons.bolt,
                _vehicleEngineTypeController,
                primaryColor,
              ),
              const SizedBox(height: 28),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Save Vehicle',
                    style: GoogleFonts.poppins(
                      fontSize: isTablet ? 16 : 14,
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
    );
  }

  Widget _buildFormField(
    String label,
    IconData icon,
    TextEditingController controller,
    Color primaryColor, {
    bool isNumber = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style:
            GoogleFonts.poppins(fontSize: 15, color: const Color(0xFF1A1A2E)),
        validator: (value) =>
            value == null || value.isEmpty ? 'Enter $label' : null,
        decoration: InputDecoration(
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          prefixIcon: Icon(icon, color: primaryColor, size: 20),
          hintText: label,
          hintStyle: GoogleFonts.poppins(
            color: Colors.grey[400],
            fontSize: 14,
          ),
          filled: true,
          fillColor: Colors.transparent,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: primaryColor, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleDetails(
    Vehicle vehicle,
    Color cardColor,
    Color primaryColor,
    bool isTablet,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.08),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with Car Icon
          Container(
            margin: const EdgeInsets.only(bottom: 24),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor, primaryColor.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Icon(
                    FontAwesomeIcons.car,
                    color: Colors.white,
                    size: isTablet ? 36 : 28,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Your Vehicle",
                  style: GoogleFonts.poppins(
                    fontSize: isTablet ? 26 : 22,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Vehicle details registered with HopeIR",
                  style: GoogleFonts.poppins(
                    fontSize: isTablet ? 14 : 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Vehicle Details Cards
          _buildDetailCard(
            FontAwesomeIcons.car,
            "Type",
            vehicle.vehicleType,
            primaryColor,
            isTablet,
          ),
          const SizedBox(height: 12),
          _buildDetailCard(
            FontAwesomeIcons.cogs,
            "Model",
            vehicle.vehicleModel,
            primaryColor,
            isTablet,
          ),
          const SizedBox(height: 12),
          _buildDetailCard(
            FontAwesomeIcons.calendar,
            "Year",
            vehicle.vehicleYear.toString(),
            primaryColor,
            isTablet,
          ),
          const SizedBox(height: 12),
          _buildDetailCard(
            FontAwesomeIcons.palette,
            "Color",
            vehicle.vehicleColor,
            primaryColor,
            isTablet,
          ),
          const SizedBox(height: 12),
          _buildDetailCard(
            FontAwesomeIcons.idCard,
            "License Plate",
            vehicle.vehicleLicensePlate,
            primaryColor,
            isTablet,
          ),
          const SizedBox(height: 12),
          _buildDetailCard(
            FontAwesomeIcons.bolt,
            "Engine",
            vehicle.vehicleEngineType,
            primaryColor,
            isTablet,
          ),

          const SizedBox(height: 24),

          // Edit Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () {
                // Populate form for editing
                _vehicleTypeController.text = vehicle.vehicleType;
                _vehicleModelController.text = vehicle.vehicleModel;
                _vehicleYearController.text = vehicle.vehicleYear.toString();
                _vehicleColorController.text = vehicle.vehicleColor;
                _vehicleLicensePlateController.text =
                    vehicle.vehicleLicensePlate;
                _vehicleEngineTypeController.text = vehicle.vehicleEngineType;
              },
              icon: Icon(Icons.edit_rounded, color: primaryColor, size: 18),
              label: Text(
                "Edit Vehicle Details",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: primaryColor.withOpacity(0.3)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(
    IconData icon,
    String label,
    String value,
    Color primaryColor,
    bool isTablet,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFFF8F9FC), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: primaryColor, size: isTablet ? 20 : 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: isTablet ? 12 : 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[500],
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: isTablet ? 16 : 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A2E),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
