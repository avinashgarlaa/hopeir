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

final createdRidesProvider = FutureProvider.family<List<Ride>, String>((
  ref,
  userId,
) async {
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

    if (vehicle == null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: Text(
            'No vehicle found. Please add a vehicle first.',
            style: GoogleFonts.poppins(fontSize: 16, color: primaryColor),
          ),
        ),
      );
    }

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final ridesAsync = ref.watch(createdRidesProvider(user.userId));

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 10, bottom: 8),
              child: Row(
                children: [
                  Text(
                    "Your Rides",
                    style: GoogleFonts.luckiestGuy(
                      fontWeight: FontWeight.w300,
                      fontSize: 28,
                      color: primaryColor,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () async {
                      await showPostRideDialog(context, ref);
                    },
                    icon: Icon(FontAwesomeIcons.add, color: primaryColor),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ridesAsync.when(
                loading:
                    () => const Center(
                      child: CircularProgressIndicator(color: primaryColor),
                    ),
                error: (e, st) => Center(child: Text("Error: $e")),
                data: (rides) {
                  if (rides.isEmpty) {
                    return Center(
                      child: Text(
                        "No rides created yet",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: primaryColor,
                        ),
                      ),
                    );
                  }
                  rides.sort((a, b) => b.startTime.compareTo(a.startTime));
                  return ListView.builder(
                    itemCount: rides.length,
                    itemBuilder: (context, index) {
                      return RideCard(
                        ride: rides[index],
                        primaryColor: primaryColor,
                        onActionCompleted:
                            () => ref.invalidate(
                              createdRidesProvider(user.userId),
                            ),
                      );
                    },
                  );
                },
              ),
            ),
            SizedBox(height: 35),
          ],
        ),
      ),
    );
  }
}
