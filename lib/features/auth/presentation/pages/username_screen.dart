import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hop_eir/features/auth/presentation/pages/login_screen.dart';
import 'package:hop_eir/features/auth/presentation/pages/user_travel_info_screen.dart';
import 'package:hop_eir/features/auth/presentation/providers/auth_provider.dart';
import 'package:hop_eir/widgets/error_dialog.dart';
import 'package:hop_eir/widgets/modern_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UsernameScreen extends ConsumerStatefulWidget {
  final String firstName;
  final String lastName;

  const UsernameScreen({
    super.key,
    required this.firstName,
    required this.lastName,
  });

  @override
  ConsumerState<UsernameScreen> createState() => _UsernameScreenState();
}

class _UsernameScreenState extends ConsumerState<UsernameScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  static const primaryColor = Color.fromRGBO(137, 177, 98, 1);

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('user_email');
      final password = prefs.getString('user_password');

      if (email == null ||
          password == null ||
          email.isEmpty ||
          password.isEmpty) {
        if (!mounted) return;
        errorDialog(
          context: context,
          heading: "Error",
          message: "Email or password not found. Please log in again.",
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
        return;
      }

      final success = await ref
          .read(authNotifierProvider.notifier)
          .createProfile(
            email: email,
            password: password,
            firstname: widget.firstName,
            lastname: widget.lastName,
            username: _usernameController.text.trim(),
          );

      if (!mounted) return;

      if (success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CommuteInfoScreen()),
        );
      } else {
        errorDialog(
          context: context,
          heading: "Creation Failed",
          message: "Could not create profile. Please try again.",
        );
      }
    } catch (e) {
      if (!mounted) return;
      errorDialog(
        context: context,
        heading: "Unexpected Error",
        message: "Something went wrong: ${e.toString()}",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authNotifierProvider);
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

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
                                "Enter Your Mobile Number",
                                style: GoogleFonts.racingSansOne(
                                  fontSize: height * 0.05,
                                  color: Colors.white.withOpacity(0.8),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "This will be your unique identity in HopEir.",
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.grey[700],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 28),
                              TextFormField(
                                controller: _usernameController,
                                style: GoogleFonts.poppins(fontSize: 16),
                                decoration: InputDecoration(
                                  hintText: "Mobile Number",
                                  hintStyle: GoogleFonts.poppins(
                                    color: primaryColor,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.person_outline,
                                    color: primaryColor,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.5),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: primaryColor,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter your mobile number';
                                  }
                                  if (value.trim().length < 10) {
                                    return 'Mobile Number must be at least 10 digits';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 26),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ModernButton(
                                  label:
                                      state.isLoading
                                          ? 'Creating...'
                                          : 'Create Profile',
                                  onTap: _submitProfile,
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
}
