import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hop_eir/features/auth/presentation/providers/auth_provider.dart';
import 'package:hop_eir/features/requests/presentation/controllers/ride_request_ws_controller.dart';
import 'package:hop_eir/features/rides/presentation/pages/post_ride_page.dart';
import 'package:hop_eir/features/rides/presentation/pages/rides_page.dart';
import 'package:hop_eir/profile_screen.dart';
import 'package:hop_eir/requests_page.dart';
import 'package:hop_eir/sos_page.dart';
import 'package:hop_eir/features/stations/presentation/providers/providers.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _selectedIndex = 0;

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if (index == 2) {
        ref.read(hasUnreadRequestsProvider.notifier).state = false;
      }
    });
  }

  static const Color darkBlue = Color(0xFF213693);
  static const Color tealAccent = Colors.tealAccent;
  static const Color backgroundColor = Colors.white;

  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return const RidesPage();
      case 1:
        return const PostRidePage();
      case 2:
        return const RequestsPage();
      case 3:
        return const SosPage();
      case 4:
        return const ProfileTabSwitcher();
      default:
        return const RidesPage();
    }
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final userId = ref.read(authNotifierProvider).user!.userId;
      ref.read(rideRequestWSControllerProvider(userId.toString()));
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          _getPage(_selectedIndex),
          Positioned(
            left: 20,
            right: 20,
            bottom: bottomPadding,
            child: _FancyBottomNavigationBar(
              selectedIndex: _selectedIndex,
              onTabSelected: _onTabTapped,
              darkBlue: darkBlue,
              tealAccent: tealAccent,
              height: screenHeight * 0.09,
            ),
          ),
        ],
      ),
    );
  }
}

class _FancyBottomNavigationBar extends ConsumerWidget {
  final int selectedIndex;
  final Function(int) onTabSelected;
  final Color darkBlue;
  final Color tealAccent;
  final double height;

  const _FancyBottomNavigationBar({
    required this.selectedIndex,
    required this.onTabSelected,
    required this.darkBlue,
    required this.tealAccent,
    required this.height,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasUnreadRequests = ref.watch(hasUnreadRequestsProvider);

    return Container(
      height: height.clamp(70, 90), // responsive height between 60-80
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: darkBlue.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: tealAccent.withOpacity(0.10),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(FontAwesomeIcons.magnifyingGlass, 'Search', 0),
          _navItem(FontAwesomeIcons.plus, 'Create', 1),
          _navItem(
            FontAwesomeIcons.envelopeOpenText,
            'Requests',
            2,
            showDot: hasUnreadRequests,
          ),
          _navItem(FontAwesomeIcons.triangleExclamation, 'SOS', 3),
          _navItem(FontAwesomeIcons.user, 'Profile', 4),
        ],
      ),
    );
  }

  Widget _navItem(
    IconData icon,
    String label,
    int index, {
    bool showDot = false,
  }) {
    final isSelected = selectedIndex == index;

    final gradient = LinearGradient(
      colors: [darkBlue, tealAccent],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    Widget gradientIcon(Icon icon) {
      return ShaderMask(
        shaderCallback: (bounds) => gradient
            .createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
        child: icon,
      );
    }

    return GestureDetector(
      onTap: () => onTabSelected(index),
      child: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color:
                  isSelected ? darkBlue.withOpacity(0.05) : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                isSelected
                    ? gradientIcon(Icon(icon, size: 15, color: Colors.white))
                    : Icon(icon,
                        size: 18, color: Colors.black.withOpacity(0.4)),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected
                        ? const Color.fromARGB(255, 97, 147, 46)
                        : Colors.black.withOpacity(0.5),
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          if (showDot)
            Positioned(
              right: 6,
              top: 4,
              child: Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
