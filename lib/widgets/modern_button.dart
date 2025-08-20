// ignore_for_file: use_super_parameters

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ModernButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isLoading;

  const ModernButton({
    Key? key,
    required this.label,
    required this.onTap,
    this.isLoading = false,
  }) : super(key: key);

  static const Color primaryColor = Color(0xFF89B162);
  static const Color secondaryColor = Color(0xFFA4C98C);
  static const Color overlayColor = Colors.white24;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [primaryColor, secondaryColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: 55,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: overlayColor.withOpacity(0.2),
                border: Border.all(
                  color: Colors.white.withOpacity(0.4),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child:
                  isLoading
                      ? const SizedBox(
                        height: 26,
                        width: 26,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                      : Text(
                        label,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
            ),
          ),
        ),
      ),
    );
  }
}
