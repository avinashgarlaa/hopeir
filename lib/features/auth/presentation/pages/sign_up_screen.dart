import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hop_eir/features/auth/presentation/pages/login_screen.dart';
import 'package:hop_eir/features/auth/presentation/providers/auth_provider.dart';
import 'package:hop_eir/widgets/modern_button.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  void _signUp() {
    FocusScope.of(context).unfocus(); // Close keyboard

    if (_formKey.currentState!.validate()) {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      ref.read(authNotifierProvider.notifier).signUp(email, password, context);
    } else {
      _passwordController.clear();
    }
  }

  // Future<void> _signInWithGoogle() async {
  //   try {
  //     final GoogleSignIn googleSignIn = GoogleSignIn();

  //     // Force sign out to always show the account picker
  //     await googleSignIn.signOut();

  //     final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

  //     // ✅ Handle the case where the user cancels the sign-in
  //     if (googleUser == null) {
  //       debugPrint('Google Sign-In was cancelled by the user.');
  //       return; // Safe exit
  //     }

  //     final String email = googleUser.email;
  //     debugPrint('Google user: $email');

  //     // ✅ Prevent navigation if widget is disposed
  //     if (!mounted) return;

  //     Navigator.push(
  //       context,
  //       MaterialPageRoute(builder: (_) => PasswordEntryScreen(email: email)),
  //     );
  //   } catch (e) {
  //     debugPrint('Google Sign-In failed: $e');

  //     // ✅ Optional: Show a user-friendly error message
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

  //     if (email == null || email.isEmpty) {
  //       debugPrint("Apple login failed: Email not provided");
  //       return;
  //     }

  //     debugPrint('Apple user: $email');

  //     Navigator.push(
  //       context,
  //       MaterialPageRoute(builder: (_) => PasswordEntryScreen(email: email)),
  //     );
  //   } catch (e) {
  //     debugPrint("Apple login failed: $e");
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF89B162), Color(0xFFF5F7FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Main UI
          Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: width * 0.08),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                      child: Container(
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
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
                              Text(
                                "Create Account",
                                style: GoogleFonts.racingSansOne(
                                  fontSize: height * 0.044,
                                  color: Colors.white.withOpacity(0.7),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                "Sign up to get started",
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 30),

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
                              ),

                              const SizedBox(height: 20),

                              _passwordField(),

                              const SizedBox(height: 30),

                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ModernButton(
                                  label:
                                      authState.isLoading
                                          ? "Loading..."
                                          : "Sign Up",
                                  onTap: () {
                                    authState.isLoading ? null : _signUp();
                                  },
                                ),
                              ),

                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Already have an account?",
                                    style: GoogleFonts.poppins(fontSize: 14),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const LoginScreen(),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      "Login",
                                      style: GoogleFonts.poppins(
                                        color: const Color(0xFF89B162),
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

          // Loading Overlay
          if (authState.isLoading)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
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
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: GoogleFonts.poppins(color: Colors.black87),
      decoration: InputDecoration(
        hintText: label,
        hintStyle: GoogleFonts.poppins(color: const Color(0xFF89B162)),
        prefixIcon: Icon(icon, color: const Color(0xFF89B162)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF89B162), width: 1.5),
        ),
      ),
      validator: validator,
    );
  }

  Widget _passwordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: !_isPasswordVisible,
      style: GoogleFonts.poppins(color: Colors.black87),
      decoration: InputDecoration(
        hintText: "Password",
        hintStyle: GoogleFonts.poppins(color: const Color(0xFF89B162)),
        prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF89B162)),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            color: const Color(0xFF89B162),
          ),
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
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
          borderSide: const BorderSide(color: Color(0xFF89B162), width: 1.5),
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
  //           backgroundColor: Colors.white.withOpacity(0.8),
  //           shape: RoundedRectangleBorder(
  //             borderRadius: BorderRadius.circular(14),
  //           ),
  //           elevation: 2,
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
