import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hop_eir/features/auth/presentation/pages/login_screen.dart';
import 'package:hop_eir/features/auth/presentation/pages/profile_section.dart';
import 'package:hop_eir/features/auth/presentation/providers/auth_provider.dart';
import 'package:hop_eir/features/vehicles/presentation/pages/user_vehicle_page.dart';

class ProfileTabSwitcher extends ConsumerStatefulWidget {
  const ProfileTabSwitcher({super.key});

  @override
  ConsumerState<ProfileTabSwitcher> createState() => _ProfileTabSwitcherState();
}

class _ProfileTabSwitcherState extends ConsumerState<ProfileTabSwitcher>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final LinearGradient gradient = const LinearGradient(
    colors: [Color(0xFF213693), Colors.tealAccent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  final Color darkBlue = const Color(0xFF213693);
  int _selectedIndex = 0;

  void _logout() async {
    await ref.read(authNotifierProvider.notifier).logout(ref);
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _selectedIndex = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    const primaryColor = Color.fromRGBO(137, 177, 98, 1);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with logout
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                  child: Row(
                    children: [
                      Text(
                        "Profile",
                        style: GoogleFonts.luckiestGuy(
                          fontWeight: FontWeight.w300,
                          fontSize: isTablet ? 36 : 28,
                          color: primaryColor,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _logout,
                        icon: const Icon(
                          FontAwesomeIcons.signOut,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                  child: Text(
                    'View and manage your account',
                    style: GoogleFonts.poppins(
                      fontSize: isTablet ? 18 : 15,
                      color: Colors.grey[600],
                    ),
                  ),
                ),

                // Tab Bar
                Container(
                  margin: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.04,
                    vertical: 20,
                  ),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TabBar(
                    dividerColor: Colors.transparent,
                    controller: _tabController,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: darkBlue.withOpacity(0.065),
                    ),
                    labelPadding: const EdgeInsets.symmetric(vertical: 12),
                    indicatorSize: TabBarIndicatorSize.tab,
                    tabs: List.generate(2, (index) {
                      final tabText = index == 0 ? 'My Profile' : 'My Vehicle';
                      final selected = _selectedIndex == index;

                      return Center(
                        child: ShaderMask(
                          shaderCallback: (bounds) {
                            return (selected
                                    ? gradient
                                    : LinearGradient(
                                        colors: [
                                          Colors.grey.shade600,
                                          Colors.grey.shade600
                                        ],
                                      ))
                                .createShader(Rect.fromLTWH(
                                    0, 0, bounds.width, bounds.height));
                          },
                          child: Text(
                            tabText,
                            style: GoogleFonts.poppins(
                              fontSize: isTablet ? 16 : 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),

                // Tab Views
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: const [
                      MyProfileSection(),
                      VehiclePage(),
                    ],
                  ),
                ),

                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
