import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hop_eir/features/auth/presentation/pages/login_screen.dart';
import 'package:hop_eir/features/auth/presentation/providers/auth_provider.dart';
import 'package:http/http.dart' as http;

class MyProfileSection extends ConsumerWidget {
  const MyProfileSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).user;

    const Color primaryColor = Color.fromRGBO(137, 177, 98, 1);
    const Color bgColor = Color(0xFFF7F8FA);
    const Color cardColor = Colors.white;

    if (user == null) {
      return Center(
        child: Text(
          "User not logged in",
          style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    Future<void> deleteAccount(BuildContext context, String email) async {
      try {
        final response = await http.delete(
          Uri.parse('https://hopeir.onrender.com/delete-user/'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email}),
        );

        print(response.body);
        if (!context.mounted) return;

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Account deleted successfully.')),
          );

          final container = ProviderScope.containerOf(context, listen: false);
          await container.read(authNotifierProvider.notifier).logout(ref);

          if (!context.mounted) return;

          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => LoginScreen()),
            (route) => false,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete account. Please try again.'),
            ),
          );
        }
      } catch (e) {
        if (!context.mounted) return;

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }

    Future<void> showDeleteAccountDialog(BuildContext context) async {
      return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(FontAwesomeIcons.userSlash, color: primaryColor),
                SizedBox(width: 20),
                Expanded(
                  child: Text(
                    'Delete Account',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      fontSize: 22,
                    ),
                  ),
                ),
              ],
            ),
            content: Text(
              'Are you sure you want to delete your account? This action cannot be undone.',
              style: GoogleFonts.poppins(color: Colors.black87, fontSize: 16),
            ),
            actionsPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            actions: [
              TextButton(
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(color: Colors.black, fontSize: 16),
                ),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Delete',
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
                ),
                onPressed: () async {
                  final userEmail = ref.watch(authNotifierProvider).user!.email;
                  Navigator.of(dialogContext).pop();
                  await deleteAccount(context, userEmail);
                },
              ),
            ],
          );
        },
      );
    }

    return Container(
      color: bgColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black12.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 45,
                      backgroundColor: primaryColor.withOpacity(0.1),
                      child: const Icon(
                        Icons.person,
                        size: 42,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16, width: 10),
                    Column(
                      children: [
                        Text(
                          '${user.firstname} ${user.lastname}',
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          user.email,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),
              _buildProfileItem(
                icon: FontAwesomeIcons.envelope,
                label: "Email",
                value: user.email,
                color: primaryColor,
              ),
              const SizedBox(height: 16),
              _buildProfileItem(
                icon: FontAwesomeIcons.user,
                label: "Mobile Number",
                value: user.username,
                color: primaryColor,
              ),
              const SizedBox(height: 16),
              _buildProfileItem(
                icon: FontAwesomeIcons.userShield,
                label: "Role",
                value: user.role,
                color: primaryColor,
              ),
              const SizedBox(height: 36),
              Row(
                children: [
                  Text(
                    "Delete Your Account",
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      color: primaryColor,
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    onPressed: () => showDeleteAccountDialog(context),
                    icon: Icon(FontAwesomeIcons.userXmark, color: Colors.black),
                  ),
                ],
              ),
            ],
          ),
        ),
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
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 15.5,
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
