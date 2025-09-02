import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hop_eir/features/auth/presentation/providers/auth_provider.dart';
import 'package:hop_eir/features/rides/domain/entities/ride.dart';
import 'package:hop_eir/features/rides/presentation/providers/ride_provider.dart';
import 'package:hop_eir/features/rides/presentation/widgets/post_ride_dialog.dart';
import 'package:hop_eir/features/rides/presentation/widgets/ride_card.dart';
import 'package:hop_eir/features/vehicles/presentation/provider/vehicle_providers.dart';

final createdRidesProvider =
    FutureProvider.family<List<Ride>, String>((ref, userId) async {
  final rideController = ref.watch(rideControllerProvider.notifier);
  return await rideController.fetchCreatedRides(currentUserId: userId);
});

class PostRidePage extends ConsumerStatefulWidget {
  const PostRidePage({super.key});
  @override
  ConsumerState<PostRidePage> createState() => _PostRidePageState();
}

class _PostRidePageState extends ConsumerState<PostRidePage> {
  static const primaryColor = Color.fromRGBO(137, 177, 98, 1);
  static const backgroundColor = Color(0xFFF5F7FF);

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).user;
    final vehicle = ref.watch(vehicleControllerProvider).vehicle;

    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (vehicle == null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                'No vehicle found.\nPlease add a vehicle first to post a ride.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: primaryColor,
                ),
              ),
            ),
          ),
        ),
      );
    }

    final ridesAsync = ref.watch(createdRidesProvider(user.userId));

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding:
                      const EdgeInsets.only(left: 20, right: 10, bottom: 8),
                  child: Row(
                    children: [
                      Text(
                        "Your Rides",
                        style: GoogleFonts.luckiestGuy(
                          fontWeight: FontWeight.w300,
                          fontSize: isTablet ? 32 : 28,
                          color: primaryColor,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () async {
                          await showPostRideDialog(context, ref);
                          ref.invalidate(createdRidesProvider(user.userId));
                        },
                        icon: Icon(FontAwesomeIcons.plus, color: primaryColor),
                        tooltip: "Post a new ride",
                      ),
                    ],
                  ),
                ),

                // Ride List
                Expanded(
                  child: ridesAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: primaryColor),
                    ),
                    error: (e, st) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          "Error loading rides: $e",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.redAccent,
                          ),
                        ),
                      ),
                    ),
                    data: (rides) {
                      if (rides.isEmpty) {
                        return Center(
                          child: Text(
                            "You haven't posted any rides yet.",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: primaryColor,
                            ),
                          ),
                        );
                      }

                      rides.sort((a, b) => b.startTime.compareTo(a.startTime));

                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: rides.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          return RideCard(
                            ride: rides[index],
                            primaryColor: primaryColor,
                            onActionCompleted: () {
                              ref.invalidate(createdRidesProvider(user.userId));
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
