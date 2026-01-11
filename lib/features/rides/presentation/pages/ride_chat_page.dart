import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:hop_eir/features/auth/presentation/providers/auth_provider.dart';
import 'package:hop_eir/features/rides/presentation/controllers/ride_ws_controller.dart';
import 'package:hop_eir/features/rides/presentation/providers/ride_provider.dart'; // ✅ for rideByIdProvider

class RideChatPage extends ConsumerStatefulWidget {
  final int rideId;
  const RideChatPage({super.key, required this.rideId});

  @override
  ConsumerState<RideChatPage> createState() => _RideChatPageState();
}

class _RideChatPageState extends ConsumerState<RideChatPage> {
  final TextEditingController _textCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  static const primaryColor = Color.fromRGBO(137, 177, 98, 1);
  int _lastMsgCount = 0;

  /// ✅ Cache sender details: senderId -> Future<User?>
  /// This ensures we fetch each user only ONCE.
  final Map<String, Future<dynamic>> _senderFutureCache = HashMap();

  Future<dynamic> _getSenderUserFuture(String senderId) {
    if (_senderFutureCache.containsKey(senderId)) {
      return _senderFutureCache[senderId]!;
    }

    final fut = ref.read(getUserByIdProviders(senderId).future);
    _senderFutureCache[senderId] = fut;
    return fut;
  }

  String _safeFullName(dynamic user) {
    // Works if your user model has firstname/lastname
    // because you've used driver?.firstname in SentRequestsPage

    final first = (user?.firstname ?? "").toString().trim();
    final last = (user?.lastname ?? "").toString().trim();
    final full = "$first $last".trim();
    return full.isEmpty ? "Unknown" : full;
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r"\s+"));
    if (parts.isEmpty) return "?";

    final first = parts[0].isNotEmpty ? parts[0][0] : "";
    final second = parts.length > 1 && parts[1].isNotEmpty ? parts[1][0] : "";
    final initials = (first + second).toUpperCase();
    return initials.isEmpty ? "?" : initials;
  }

  @override
  Widget build(BuildContext context) {
    final wsState = ref.watch(rideWSControllerProvider(widget.rideId));
    final messages = wsState.chatMessages;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final myUser = ref.watch(authNotifierProvider).user;
    final myUserId = myUser?.userId.toString();

    /// ✅ Fetch ride info -> needed for DRIVER detection
    final rideAsync = ref.watch(rideByIdProvider(widget.rideId));

    // ✅ Auto-scroll only when new messages arrive
    if (messages.length != _lastMsgCount) {
      _lastMsgCount = messages.length;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.animateTo(
            _scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
          );
        }
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: rideAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Text(
              "Error loading ride info: $e",
              style: GoogleFonts.poppins(color: Colors.red),
            ),
          ),
          data: (ride) {
            final driverUserId =
                ride.user.toString(); // driver id (UUID string)

            return Column(
              children: [
                // ───────────── CHAT LIST ─────────────
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
                          Navigator.pop(context);
                        },
                        icon: const Icon(FontAwesomeIcons.backward,
                            color: primaryColor),
                        tooltip: "Post a new ride",
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: messages.isEmpty
                      ? _emptyState()
                      : ListView.builder(
                          controller: _scrollCtrl,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          itemCount: messages.length,
                          itemBuilder: (_, index) {
                            final msg = messages[index];

                            final senderId = msg.senderId.toString();
                            final isMe = senderId == myUserId;

                            // ✅ reduce repeated headers
                            final prevMsg =
                                index > 0 ? messages[index - 1] : null;
                            final bool sameSenderAsPrevious =
                                prevMsg?.senderId.toString() == senderId;

                            final showHeader = !isMe && !sameSenderAsPrevious;

                            // ✅ Determine role via senderId vs driverId
                            final role = (senderId == driverUserId)
                                ? "DRIVER"
                                : "PASSENGER";

                            // ✅ Use cached Future to fetch sender name only once
                            return FutureBuilder(
                              future: _getSenderUserFuture(senderId),
                              builder: (context, snap) {
                                final user = snap.data;
                                final senderName = snap.hasData
                                    ? _safeFullName(user)
                                    : "Loading...";

                                final initials = _getInitials(senderName);

                                return _chatBubble(
                                  isMe: isMe,
                                  showHeader: showHeader,
                                  senderLabel: isMe ? "You" : senderName,
                                  roleLabel: isMe ? "" : role,
                                  initials: initials,
                                  message: msg.message,
                                  timestamp: msg.timestamp,
                                );
                              },
                            );
                          },
                        ),
                ),

                // ───────────── INPUT BAR ─────────────
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _textCtrl,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: InputDecoration(
                                hintText: 'Type a message…',
                                hintStyle: GoogleFonts.poppins(fontSize: 14),
                                border: InputBorder.none,
                              ),
                              onSubmitted: (_) => _send(),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.send),
                            color: const Color.fromRGBO(137, 177, 98, 1),
                            onPressed: _send,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ───────────── SEND CHAT ─────────────
  void _send() {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;

    ref
        .read(rideWSControllerProvider(widget.rideId).notifier)
        .sendChatMessage(text);

    _textCtrl.clear();
  }

  // ───────────── CHAT BUBBLE ─────────────
  Widget _chatBubble({
    required bool isMe,
    required bool showHeader,
    required String senderLabel,
    required String roleLabel,
    required String initials,
    required String message,
    required DateTime timestamp,
  }) {
    final time = DateFormat('hh:mm a').format(timestamp.toLocal());

    final bubbleColor =
        isMe ? const Color.fromRGBO(137, 177, 98, 1) : Colors.white;
    final textColor = isMe ? Colors.white : Colors.black87;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Row(
          mainAxisAlignment:
              isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe) ...[
              CircleAvatar(
                radius: 16,
                backgroundColor:
                    const Color.fromRGBO(137, 177, 98, 1).withOpacity(0.15),
                child: Text(
                  initials,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color.fromRGBO(60, 90, 30, 1),
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Flexible(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                constraints: const BoxConstraints(maxWidth: 310),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                    bottomRight: isMe ? Radius.zero : const Radius.circular(16),
                  ),
                  boxShadow: [
                    if (!isMe)
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showHeader) ...[
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              senderLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          if (roleLabel.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                roleLabel,
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                    ],
                    Text(
                      message,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        time,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: isMe ? Colors.white70 : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────── EMPTY STATE ─────────────
  Widget _emptyState() {
    return Center(
      child: Text(
        'No messages yet\nStart the conversation 👋',
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(
          color: Colors.grey.shade600,
          fontSize: 14,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }
}
