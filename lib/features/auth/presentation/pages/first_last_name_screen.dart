import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hop_eir/features/auth/presentation/pages/username_screen.dart';
import 'package:hop_eir/widgets/modern_button.dart';

class FirstLastNameScreen extends StatefulWidget {
  const FirstLastNameScreen({super.key});

  @override
  State<FirstLastNameScreen> createState() => _FirstLastNameScreenState();
}

class _FirstLastNameScreenState extends State<FirstLastNameScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  static const primaryColor = Color.fromRGBO(137, 177, 98, 1);

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

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
                  padding: EdgeInsets.symmetric(horizontal: width * 0.08),
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
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Enter Your Name",
                                style: GoogleFonts.racingSansOne(
                                  fontSize: height * 0.05,
                                  color: Colors.white.withOpacity(0.7),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "Please provide your first and last name to continue.",
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.grey[700],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 28),
                              _customTextField(
                                controller: _firstNameController,
                                label: "First Name",
                              ),
                              const SizedBox(height: 20),
                              _customTextField(
                                controller: _lastNameController,
                                label: "Last Name",
                              ),
                              const SizedBox(height: 26),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ModernButton(
                                  label: 'Next',
                                  onTap: () {
                                    if (_formKey.currentState!.validate()) {
                                      FocusScope.of(context).unfocus();
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (_) => UsernameScreen(
                                                firstName:
                                                    _firstNameController.text
                                                        .trim(),
                                                lastName:
                                                    _lastNameController.text
                                                        .trim(),
                                              ),
                                        ),
                                      );
                                    }
                                  },
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
          ),
        ],
      ),
    );
  }

  Widget _customTextField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextFormField(
      controller: controller,
      style: GoogleFonts.poppins(fontSize: 16),
      decoration: InputDecoration(
        hintText: label,
        hintStyle: GoogleFonts.poppins(color: primaryColor),
        prefixIcon: const Icon(Icons.person_outline, color: primaryColor),
        filled: true,
        fillColor: Colors.white.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primaryColor, width: 1.5),
        ),
      ),
      validator:
          (value) => value == null || value.isEmpty ? 'Enter $label' : null,
    );
  }
}
