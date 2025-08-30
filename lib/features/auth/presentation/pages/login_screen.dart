import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hop_eir/features/auth/presentation/pages/sign_up_screen.dart';
import 'package:hop_eir/features/auth/presentation/providers/auth_provider.dart';
import 'package:hop_eir/features/vehicles/presentation/provider/vehicle_providers.dart';
import 'package:hop_eir/widgets/modern_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  static const primaryColor = Color.fromRGBO(137, 177, 98, 1);
  bool isLoadingOverlay = false;
  bool isPasswordVisible = false;

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      setState(() => isLoadingOverlay = true);

      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      final success = await ref
          .read(authNotifierProvider.notifier)
          .login(email, password, context);

      if (!mounted) return;

      if (success) {
        final user = ref.read(authNotifierProvider).user;
        if (user != null && user.userId != "") {
          await ref
              .read(vehicleControllerProvider.notifier)
              .fetchVehicleByUserId(user.userId);
        }
      } else {
        _passwordController.clear();
      }

      if (!mounted) return;
      setState(() => isLoadingOverlay = false);
    }
  }

  // Future<void> _signInWithGoogle() async {
  //   try {
  //     final GoogleSignIn googleSignIn = GoogleSignIn();

  //     // Force sign out previous session to show account picker every time
  //     await googleSignIn.signOut();

  //     final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

  //     // ✅ Handle the case where the user cancels sign-in
  //     if (googleUser == null) {
  //       debugPrint('Google Sign-In was cancelled by the user.');
  //       return; // Safely exit without crashing
  //     }

  //     final String email = googleUser.email;
  //     debugPrint('Google user: $email');

  //     // ✅ Prevent navigation if the widget was disposed
  //     if (!mounted) return;

  //     Navigator.push(
  //       context,
  //       MaterialPageRoute(builder: (_) => PasswordLoginScreen(email: email)),
  //     );
  //   } catch (e) {
  //     debugPrint('Google Sign-In failed: $e');
  //     showPopUp(
  //       context,
  //       icon: FontAwesomeIcons.triangleExclamation,
  //       message: "Google Sign-In failed. Please try again.",
  //     );
  //   }
  // }

  // Future<void> _signInWithApple() async {
  //   try {
  //     final credential = await SignInWithApple.getAppleIDCredential(
  //       scopes: [AppleIDAuthorizationScopes.email],
  //     );

  //     String? email = credential.email;

  //     // If the email is not provided (in some cases, Apple returns null)
  //     if (email == null || email.isEmpty) {
  //       // You can handle this based on your backend, or ask user to input email
  //       showPopUp(
  //         context,
  //         icon: FontAwesomeIcons.triangleExclamation,
  //         message: "Email not available from Apple Sign-In",
  //       );
  //       return;
  //     }

  //     debugPrint('Apple user: $email');

  //     Navigator.push(
  //       context,
  //       MaterialPageRoute(builder: (_) => PasswordLoginScreen(email: email)),
  //     );
  //   } catch (e) {
  //     showPopUp(
  //       context,
  //       icon: FontAwesomeIcons.triangleExclamation,
  //       message: "Failed",
  //     );
  //   }
  // }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
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
                                "Welcome Back",
                                style: GoogleFonts.racingSansOne(
                                  fontSize: height * 0.045,
                                  color: Colors.white.withOpacity(0.7),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Sign in to continue",
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 28),
                              _customTextField(
                                controller: _emailController,
                                label: "Email",
                                icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Email is required';
                                  }
                                  if (!value.contains('@')) {
                                    return 'Enter a valid email';
                                  }
                                  return null;
                                },
                                focusNode: _emailFocus,
                                nextFocus: _passwordFocus,
                              ),
                              const SizedBox(height: 18),
                              _passwordField(),
                              const SizedBox(height: 26),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ModernButton(
                                  label:
                                      state.isLoading ? 'Loading...' : 'Login',
                                  onTap: _login,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Don't have an account?",
                                    style: GoogleFonts.poppins(fontSize: 14),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const SignUpScreen(),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      "Sign Up",
                                      style: GoogleFonts.poppins(
                                        color: primaryColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Divider(color: Colors.grey[400]),
                              const SizedBox(height: 20),
                              // _socialLoginButtons(),
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
          if (isLoadingOverlay)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: const Center(
                child: CircularProgressIndicator(color: primaryColor),
              ),
            ),
        ],
      ),
    );
  }

  Widget _customTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    FocusNode? focusNode,
    FocusNode? nextFocus,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      focusNode: focusNode,
      style: GoogleFonts.poppins(),
      textInputAction:
          nextFocus != null ? TextInputAction.next : TextInputAction.done,
      onFieldSubmitted: (_) {
        if (nextFocus != null) {
          FocusScope.of(context).requestFocus(nextFocus);
        } else {
          FocusScope.of(context).unfocus();
        }
      },
      decoration: InputDecoration(
        hintText: label,
        hintStyle: GoogleFonts.poppins(color: primaryColor),
        prefixIcon: Icon(icon, color: primaryColor),
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
      validator: validator,
    );
  }

  Widget _passwordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: !isPasswordVisible,
      focusNode: _passwordFocus,
      keyboardType: TextInputType.visiblePassword,
      style: GoogleFonts.poppins(),
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
      decoration: InputDecoration(
        hintText: "Password",
        hintStyle: GoogleFonts.poppins(color: primaryColor),
        prefixIcon: Icon(Icons.lock_outline, color: primaryColor),
        suffixIcon: IconButton(
          icon: Icon(
            isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            color: primaryColor,
          ),
          onPressed: () {
            setState(() => isPasswordVisible = !isPasswordVisible);
          },
        ),
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
      validator: (value) {
        if (value == null || value.length < 6) return 'Min 6 characters';
        return null;
      },
    );
  }

  // Widget _socialLoginButtons() {
  //   return Column(
  //     children: [
  //       _socialButton(
  //         asset: 'assets/icons/7123025_logo_google_g_icon.png',
  //         label: 'Continue with Google',
  //         onPressed: _signInWithGoogle,
  //       ),
  //       const SizedBox(height: 16),
  //       _socialButton(
  //         asset: 'assets/icons/104490_apple_icon.png',
  //         label: 'Continue with Apple',
  //         onPressed: _signInWithApple,
  //       ),
  //     ],
  //   );
  // }

  //   Widget _socialButton({
  //     required String asset,
  //     required String label,
  //     required VoidCallback onPressed,
  //   }) {
  //     return SizedBox(
  //       width: double.infinity,
  //       height: 50,
  //       child: ElevatedButton(
  //         onPressed: onPressed,
  //         style: ElevatedButton.styleFrom(
  //           backgroundColor: Colors.white.withOpacity(0.9),
  //           shape: RoundedRectangleBorder(
  //             borderRadius: BorderRadius.circular(14),
  //           ),
  //           elevation: 3,
  //           padding: const EdgeInsets.symmetric(horizontal: 20),
  //         ),
  //         child: Row(
  //           mainAxisAlignment: MainAxisAlignment.center,
  //           children: [
  //             Image.asset(asset, height: 24),
  //             const SizedBox(width: 16),
  //             Text(
  //               label,
  //               style: GoogleFonts.poppins(
  //                 color: Colors.black87,
  //                 fontWeight: FontWeight.w500,
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //     );
  //   }
  // }
}
