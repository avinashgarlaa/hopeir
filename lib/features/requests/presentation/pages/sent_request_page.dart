import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hop_eir/features/rides/presentation/pages/rides_page.dart';
import 'package:hop_eir/features/rides/presentation/providers/ride_provider.dart';
import 'package:hop_eir/features/stations/presentation/providers/providers.dart';
import 'package:intl/intl.dart';
import 'package:hop_eir/features/auth/presentation/providers/auth_provider.dart';
import 'package:hop_eir/features/notifications/notification_service.dart';
import 'package:hop_eir/features/requests/domain/entities/ride_request.dart';
import 'package:hop_eir/features/requests/presentation/controllers/ride_request_ws_controller.dart';
import 'package:hop_eir/features/requests/presentation/controllers/passanger_ride_ws_controller.dart';

class SentRequestsPage extends ConsumerStatefulWidget {
  static const primaryColor = Color.fromRGBO(137, 177, 98, 1);
  const SentRequestsPage({super.key});

  @override
  ConsumerState<SentRequestsPage> createState() => _SentRequestsPageState();
}

class _SentRequestsPageState extends ConsumerState<SentRequestsPage> {
  List<RideRequest> _previousRequests = [];
  final Set<String> _listenedRideIds = {};
  final List<ProviderSubscription> _subscriptions = [];
  bool _listenerAttached = false;

  Future<void> _maybeConnectToRide(RideRequest request) async {
    if (_listenedRideIds.contains(request.rideId)) return;

    _listenedRideIds.add(request.rideId);

    final sub = ref.listenManual(passengerRideWSProvider(request.rideId), (
      prev,
      next,
    ) {
      if (!mounted || prev == next || next.toLowerCase() == 'pending') return;

      if (["completed", "cancelled"].contains(next.toLowerCase())) {
        Future.microtask(() {
          ref.invalidate(passengerRideWSProvider(request.rideId));
          _listenedRideIds.remove(request.rideId);
        });
      }
    });

    _subscriptions.add(sub);
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).user;
    final userId = user?.userId;

    if (userId == null) {
      return const Center(child: Text("Please log in."));
    }

    final wsProvider = rideRequestWSControllerProvider(userId.toString());
    final wsState = ref.watch(wsProvider);

    if (!_listenerAttached) {
      _listenerAttached = true;

      ref.listen(wsProvider, (prev, next) {
        final current = next.incomingRequests
            .where((r) => r.passengerId == userId.toString())
            .toList();

        final oldMap = {for (var r in _previousRequests) r.id: r};

        for (final request in current) {
          final old = oldMap[request.id];
          if (old != null && old.status != request.status) {
            LocalNotificationHelper.showNotification(
              '📢 Request Status Updated',
              'Your request for ride #${request.rideId} is now ${request.status.toUpperCase()}',
            );
          }
        }

        _previousRequests = List.from(current);
      });
    }

    final myRequests = wsState.incomingRequests
        .where((r) => r.passengerId == userId.toString())
        .toList()
      ..sort((a, b) {
        final timeA = DateTime.tryParse(a.requestedAt ?? '') ?? DateTime.now();
        final timeB = DateTime.tryParse(b.requestedAt ?? '') ?? DateTime.now();
        return timeB.compareTo(timeA);
      });

    if (myRequests.isEmpty) {
      return Center(
        child: Text(
          "You haven’t sent any ride requests yet.",
          style: GoogleFonts.poppins(fontSize: 16, color: primaryColor),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 40),
      itemCount: myRequests.length,
      itemBuilder: (context, index) {
        final request = myRequests[index];
        _maybeConnectToRide(request);
        final rideStatus = ref.watch(passengerRideWSProvider(request.rideId));
        return _SentRequestCard(request: request, rideStatus: rideStatus);
      },
    );
  }
}

class _SentRequestCard extends ConsumerWidget {
  final RideRequest request;
  final String rideStatus;

  const _SentRequestCard({required this.request, required this.rideStatus});

  static const Color primaryColor = Color.fromRGBO(137, 177, 98, 1);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestedTime = DateTime.tryParse(request.requestedAt ?? '');
    final formattedRequestedTime = requestedTime != null
        ? DateFormat.yMMMd().add_jm().format(requestedTime)
        : 'Unknown';

    final rideAsync = ref.watch(rideByIdProvider(int.parse(request.rideId)));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: rideAsync.when(
        loading: () => _mainLoading(),
        error: (e, _) => _errorRow("Error loading ride: $e"),
        data: (ride) {
          final fromStationAsync = ref.watch(
            stationByIdProvider(ride.startLocation),
          );
          final toStationAsync = ref.watch(
            stationByIdProvider(ride.endLocation),
          );
          final driverAsync = ref.watch(getUserByIdProviders(ride.user));

          final startTime = DateTime.tryParse(ride.startTime.toString());
          final formattedStartTime = startTime != null
              ? DateFormat.yMMMd().add_jm().format(startTime)
              : 'Unknown';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Route
              fromStationAsync.when(
                data: (from) => toStationAsync.when(
                  data: (to) => _infoRow(
                    Icons.route,
                    "${from.name} → ${to.name}",
                    primaryColor,
                  ),
                  loading: () => _skeletonLoader(),
                  error: (_, __) => _errorRow("To station error"),
                ),
                loading: () => _skeletonLoader(),
                error: (_, __) => _errorRow("From station error"),
              ),

              const SizedBox(height: 10),

              // Timing
              _infoRow(
                Icons.schedule,
                "Start: $formattedStartTime",
                Colors.teal,
              ),
              _infoRow(
                Icons.access_time,
                "Requested: $formattedRequestedTime",
                Colors.grey,
              ),

              const SizedBox(height: 10),

              // Driver Summary
              driverAsync.when(
                data: (driver) => Column(
                  children: [
                    _infoRow(
                      Icons.person,
                      "${driver?.firstname ?? 'N/A'} ${driver?.lastname ?? ''}",
                      Colors.black87,
                    ),
                    _infoRow(
                      Icons.phone,
                      driver?.username ?? "N/A",
                      Colors.black87,
                    ),
                  ],
                ),
                loading: () => _skeletonLoader(),
                error: (_, __) => _errorRow("Driver unavailable"),
              ),

              const SizedBox(height: 12),

              // Status Chips
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _statusChip(
                    "Ride",
                    rideStatus,
                    _getStatusIcon(rideStatus),
                    _getStatusColor(rideStatus),
                  ),
                  _statusChip(
                    "Request",
                    request.status,
                    _getStatusIcon(request.status),
                    _getRequestChipColor(request.status),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.hourglass_empty_rounded;
      case 'accepted':
        return Icons.check_circle_rounded;
      case 'rejected':
        return Icons.highlight_off_rounded;
      case 'ongoing':
        return Icons.directions_car_filled_rounded;
      case 'completed':
        return Icons.emoji_events_rounded;
      case 'cancelled':
        return Icons.do_not_disturb_on_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  Widget _infoRow(IconData icon, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String label, String value, IconData icon, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.black87),
          const SizedBox(width: 6),
          Text(
            "${label.toUpperCase()}: ${value.toUpperCase()}",
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _skeletonLoader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Container(height: 16, color: Colors.grey.shade300)),
        ],
      ),
    );
  }

  Widget _errorRow(String msg) {
    return Text(
      msg,
      style: GoogleFonts.poppins(fontSize: 13, color: Colors.red),
    );
  }

  Widget _mainLoading() {
    return const Center(child: CircularProgressIndicator(strokeWidth: 1.5));
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFFFF3CD); // Light Yellow
      case 'accepted':
        return const Color(0xFFD4EDDA); // Light Green
      case 'rejected':
        return const Color(0xFFF8D7DA); // Light Red
      case 'ongoing':
        return const Color(0xFFD1ECF1); // Light Blue
      case 'completed':
        return const Color(0xFFE2E3E5); // Pale Grey
      case 'cancelled':
        return const Color(0xFFF0F0F0); // Lightest Grey
      default:
        return const Color(0xFFEDEDED); // Neutral
    }
  }

  Color _getRequestChipColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFFFF8E1); // Soft Yellow
      case 'accepted':
        return const Color(0xFFE8F5E9); // Mint Green
      case 'rejected':
        return const Color(0xFFFFEBEE); // Soft Red
      default:
        return const Color(0xFFECEFF1); // Light Grey Blue
    }
  }
}
