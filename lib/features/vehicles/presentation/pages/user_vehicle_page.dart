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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User not logged in')));
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

    const backgroundColor = Color(0xFFF5F7FF);
    const primaryColor = Color.fromRGBO(137, 177, 98, 1);
    const cardColor = Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child:
            state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                  padding: const EdgeInsets.all(20),
                  child:
                      vehicle != null
                          ? _buildVehicleDetails(
                            vehicle,
                            cardColor,
                            primaryColor,
                          )
                          : _buildVehicleForm(primaryColor),
                ),
      ),
    );
  }

  Widget _buildVehicleForm(Color primaryColor) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
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
            children: [
              const SizedBox(height: 16),
              _buildFormField(
                "Vehicle Type",
                FontAwesomeIcons.car,
                _vehicleTypeController,
              ),
              const SizedBox(height: 16),
              _buildFormField(
                "Vehicle Model",
                FontAwesomeIcons.cogs,
                _vehicleModelController,
              ),
              const SizedBox(height: 16),
              _buildFormField(
                "Vehicle Year",
                FontAwesomeIcons.calendar,
                _vehicleYearController,
                isNumber: true,
              ),
              const SizedBox(height: 16),
              _buildFormField(
                "Color",
                FontAwesomeIcons.palette,
                _vehicleColorController,
              ),
              const SizedBox(height: 16),
              _buildFormField(
                "License Plate",
                FontAwesomeIcons.idCard,
                _vehicleLicensePlateController,
              ),
              const SizedBox(height: 16),
              _buildFormField(
                "Engine Type",
                FontAwesomeIcons.bolt,
                _vehicleEngineTypeController,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    'Save Vehicle',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
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

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: GoogleFonts.poppins(fontSize: 16),
        validator:
            (value) => value == null || value.isEmpty ? 'Enter $label' : null,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(
            vertical: 20,
            horizontal: 16,
          ),
          prefixIcon: Icon(icon, color: primaryColor),
          hintText: label,
          hintStyle: GoogleFonts.poppins(color: primaryColor),
          filled: true,
          fillColor: Colors.transparent, // because container has background
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
    );
  }

  Widget _buildVehicleDetails(
    Vehicle vehicle,
    Color cardColor,
    Color primaryColor,
  ) {
    return Container(
      height: 700,
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
      child: ListView(
        children: [
          _buildProfileItem(
            icon: FontAwesomeIcons.car,
            label: "Type",
            value: vehicle.vehicleType,
            color: primaryColor,
          ),
          const SizedBox(height: 10),
          _buildProfileItem(
            icon: FontAwesomeIcons.cogs,
            label: "Model",
            value: vehicle.vehicleModel,
            color: primaryColor,
          ),
          const SizedBox(height: 10),
          _buildProfileItem(
            icon: FontAwesomeIcons.calendar,
            label: "Year",
            value: vehicle.vehicleYear.toString(),
            color: primaryColor,
          ),
          const SizedBox(height: 10),
          _buildProfileItem(
            icon: FontAwesomeIcons.palette,
            label: "Color",
            value: vehicle.vehicleColor,
            color: primaryColor,
          ),
          const SizedBox(height: 10),
          _buildProfileItem(
            icon: FontAwesomeIcons.idCard,
            label: "Liscence Plate",
            value: vehicle.vehicleLicensePlate,
            color: primaryColor,
          ),
          const SizedBox(height: 10),
          _buildProfileItem(
            icon: FontAwesomeIcons.bolt,
            label: "Engine",
            value: vehicle.vehicleEngineType,
            color: primaryColor,
          ),
          const SizedBox(height: 10),
          // SizedBox(
          //   width: double.infinity,
          //   child: ElevatedButton(
          //     onPressed: () {},
          //     style: ElevatedButton.styleFrom(
          //       backgroundColor: primaryColor,
          //       shape: RoundedRectangleBorder(
          //         borderRadius: BorderRadius.circular(12),
          //       ),
          //       padding: const EdgeInsets.symmetric(vertical: 16),
          //     ),
          //     child: Text(
          //       'Edit Vehicle',
          //       style: GoogleFonts.poppins(
          //         fontSize: 18,
          //         fontWeight: FontWeight.w600,
          //         color: Colors.white,
          //       ),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildProfileItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 15),
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
            child: Icon(icon, color: color, size: 25),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
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
