import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hop_eir/features/auth/presentation/providers/auth_provider.dart';
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
                  horizontal: isTablet ? 40 : 20,
                  vertical: 24,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 700),
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
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildFormField(
                  "Vehicle Type", FontAwesomeIcons.car, _vehicleTypeController),
              _buildFormField("Vehicle Model", FontAwesomeIcons.cogs,
                  _vehicleModelController),
              _buildFormField("Vehicle Year", FontAwesomeIcons.calendar,
                  _vehicleYearController,
                  isNumber: true),
              _buildFormField(
                  "Color", FontAwesomeIcons.palette, _vehicleColorController),
              _buildFormField("License Plate", FontAwesomeIcons.idCard,
                  _vehicleLicensePlateController),
              _buildFormField("Engine Type", FontAwesomeIcons.bolt,
                  _vehicleEngineTypeController),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'Save Vehicle',
                  style: GoogleFonts.poppins(
                    fontSize: isTablet ? 18 : 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
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
    TextEditingController controller, {
    bool isNumber = false,
  }) {
    const primaryColor = Color.fromRGBO(137, 177, 98, 1);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextFormField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          style: GoogleFonts.poppins(fontSize: 16),
          validator: (value) =>
              value == null || value.isEmpty ? 'Enter $label' : null,
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            prefixIcon: Icon(icon, color: primaryColor),
            hintText: label,
            hintStyle: GoogleFonts.poppins(color: primaryColor),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildProfileItem(FontAwesomeIcons.car, "Type", vehicle.vehicleType,
              primaryColor, isTablet),
          _buildProfileItem(FontAwesomeIcons.cogs, "Model",
              vehicle.vehicleModel, primaryColor, isTablet),
          _buildProfileItem(FontAwesomeIcons.calendar, "Year",
              vehicle.vehicleYear.toString(), primaryColor, isTablet),
          _buildProfileItem(FontAwesomeIcons.palette, "Color",
              vehicle.vehicleColor, primaryColor, isTablet),
          _buildProfileItem(FontAwesomeIcons.idCard, "License Plate",
              vehicle.vehicleLicensePlate, primaryColor, isTablet),
          _buildProfileItem(FontAwesomeIcons.bolt, "Engine",
              vehicle.vehicleEngineType, primaryColor, isTablet),
        ],
      ),
    );
  }

  Widget _buildProfileItem(
    IconData icon,
    String label,
    String value,
    Color color,
    bool isTablet,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F2F6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: isTablet ? 24 : 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: isTablet ? 13.5 : 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: isTablet ? 16.5 : 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
