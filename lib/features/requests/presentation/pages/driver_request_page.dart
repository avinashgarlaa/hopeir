import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:hop_eir/features/auth/presentation/providers/auth_provider.dart';
import 'package:hop_eir/features/requests/domain/entities/ride_request.dart';
import 'package:hop_eir/features/requests/presentation/controllers/ride_request_ws_controller.dart';
import 'package:hop_eir/features/rides/presentation/controllers/ride_ws_controller.dart';
import 'package:hop_eir/features/rides/presentation/providers/ride_provider.dart';
import 'package:hop_eir/features/stations/presentation/providers/providers.dart';

// 🔁 Replace with your actual chat page
import 'package:hop_eir/features/rides/presentation/pages/ride_chat_page.dart';

class ReceivedRequestsPage extends ConsumerWidget {
  static const primaryColor = Color.fromRGBO(137, 177, 98, 1);

  const ReceivedRequestsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).user;
    final userId = user?.userId ?? '';

    final wsState = ref.watch(
      rideRequestWSControllerProvider(userId),
    );

    final receivedRequests = wsState.incomingRequests
        .where((r) => r.driverId == userId) // ✅ correct filter
        .toList()
      ..sort((a, b) {
        final timeA = DateTime.tryParse(a.requestedAt ?? '') ?? DateTime.now();
        final timeB = DateTime.tryParse(b.requestedAt ?? '') ?? DateTime.now();
        return timeB.compareTo(timeA);
      });

    if (receivedRequests.isEmpty) {
      return Center(
        child: Text(
          "No incoming ride requests yet.",
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: primaryColor,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 40),
      itemCount: receivedRequests.length,
      itemBuilder: (context, index) {
        final request = receivedRequests[index];

        return _RideRequestCard(
          request: request,
          userId: userId,
          ref: ref,
          onAction: (status) async {
            final notifier = ref.read(
              rideRequestWSControllerProvider(userId).notifier,
            );

            await notifier.respondToRequest(
              requestId: request.id,
              isAccepted: status == 'accepted',
            );
          },
        );
      },
    );
  }
}

class _RideRequestCard extends StatelessWidget {
  final RideRequest request;
  final void Function(String status) onAction;
  final String userId;
  final WidgetRef ref;

  const _RideRequestCard({
    required this.request,
    required this.onAction,
    required this.userId,
    required this.ref,
  });

  final LinearGradient gradient = const LinearGradient(
    colors: [Color(0xFF7F7FD5), Color(0xFF86A8E7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  Widget build(BuildContext context) {
    // 🔥 Connect Ride WS ONLY after accepted
    if (request.status.toLowerCase() == 'accepted') {
      ref.watch(
        rideWSControllerProvider(request.rideId),
      );
    }

    final requestedTime = DateTime.tryParse(request.requestedAt ?? '');
    final formattedTime = requestedTime != null
        ? DateFormat.yMMMd().add_jm().format(requestedTime)
        : 'Unknown';

    final passengerAsync = request.passengerId.isEmpty
        ? const AsyncValue.loading()
        : ref.watch(
            getUserByIdProviders(request.passengerId),
          );

    final rideAsync = ref.watch(
      rideByIdProvider(request.rideId),
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 👤 Passenger Header
          Row(
            children: [
              const CircleAvatar(
                radius: 22,
                backgroundColor: Color(0xFFD1E8FF),
                child: Icon(Icons.person, color: Color(0xFF3366CC)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ShaderMask(
                  shaderCallback: (bounds) => gradient.createShader(
                    Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                  ),
                  child: Text(
                    request.passengerName,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              _statusChip(request.status),
            ],
          ),

          const SizedBox(height: 12),

          /// 👥 Passenger Details
          passengerAsync.when(
            data: (passenger) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow(
                  Icons.email_outlined,
                  passenger?.email ?? 'Email unavailable',
                ),
                _infoRow(
                  Icons.phone_android_rounded,
                  passenger?.username ?? 'Username unavailable',
                ),
              ],
            ),
            loading: () => const LinearProgressIndicator(minHeight: 2),
            error: (_, __) => _infoRow(Icons.error, 'Failed to load user info'),
          ),

          const SizedBox(height: 12),

          /// 🚘 Ride Details
          rideAsync.when(
            data: (ride) {
              final fromStationAsync = ref.watch(
                stationByIdProvider(ride.startLocation),
              );
              final toStationAsync = ref.watch(
                stationByIdProvider(ride.endLocation),
              );

              final startTime = DateTime.tryParse(ride.startTime.toString());

              final formattedStartTime = startTime != null
                  ? DateFormat.yMMMd().add_jm().format(startTime)
                  : 'Unknown';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  fromStationAsync.when(
                    data: (from) => toStationAsync.when(
                      data: (to) => _infoRow(
                        Icons.route_outlined,
                        '${from.name} → ${to.name}',
                      ),
                      loading: () =>
                          _infoRow(Icons.route, 'Loading destination...'),
                      error: (_, __) =>
                          _infoRow(Icons.route, 'Destination unavailable'),
                    ),
                    loading: () => _infoRow(Icons.route, 'Loading origin...'),
                    error: (_, __) =>
                        _infoRow(Icons.route, 'Origin unavailable'),
                  ),
                  const SizedBox(height: 4),
                  _infoRow(
                    Icons.schedule_rounded,
                    "Start Time: $formattedStartTime",
                  ),
                ],
              );
            },
            loading: () => const LinearProgressIndicator(minHeight: 2),
            error: (_, __) => _infoRow(Icons.error, 'Failed to load ride info'),
          ),

          const SizedBox(height: 10),

          /// 🕓 Request Time
          _infoRow(
            Icons.access_time_rounded,
            "Requested at: $formattedTime",
          ),

          /// ✅ ACTIONS
          if (request.status.toLowerCase() == 'pending') ...[
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => onAction('rejected'),
                  icon: const Icon(Icons.cancel_rounded, color: Colors.red),
                  label: const Text(
                    "Reject",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () => onAction('accepted'),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text("Accept"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ] else if (request.status.toLowerCase() == 'accepted') ...[
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RideChatPage(
                        rideId: request.rideId,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text("Open Chat"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3366CC),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// ℹ️ Info Row
  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.blueGrey[700]),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// 🎯 Status Chip
  Widget _statusChip(String status) {
    final color = _getStatusColor(status);
    final icon = _getStatusIcon(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 5),
          Text(
            status.toUpperCase(),
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return const Color(0xFF4CAF50);
      case 'rejected':
        return const Color(0xFFFF6B6B);
      case 'pending':
        return const Color(0xFFFFB74D);
      default:
        return const Color(0xFF90A4AE);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Icons.check_circle_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      case 'pending':
        return Icons.hourglass_top_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }
}
