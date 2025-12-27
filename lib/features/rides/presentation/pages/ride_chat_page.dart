import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:hop_eir/features/auth/presentation/providers/auth_provider.dart';
import 'package:hop_eir/features/rides/presentation/controllers/ride_ws_controller.dart';

class RideChatPage extends ConsumerStatefulWidget {
  final int rideId;
  const RideChatPage({super.key, required this.rideId});

  @override
  ConsumerState<RideChatPage> createState() => _RideChatPageState();
}

class _RideChatPageState extends ConsumerState<RideChatPage> {
  final TextEditingController _textCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  int _lastMsgCount = 0;

  @override
  void initState() {
    super.initState();

    /// 🔹 Load previous chat ONCE
    // Future.microtask(() {
    //   ref
    //       .read(rideWSControllerProvider(widget.rideId).notifier)
    //       .loadChatHistory(
    //         ref.read(rideRepositoryProvider).fetchRideChatHistory,
    //       );
    // });
  }

  @override
  Widget build(BuildContext context) {
    final wsState = ref.watch(rideWSControllerProvider(widget.rideId));
    final messages = wsState.chatMessages;
    final myUserId = ref.watch(authNotifierProvider).user?.userId.toString();

    /// 🔹 Auto-scroll only when a new message is added
    if (messages.length != _lastMsgCount) {
      _lastMsgCount = messages.length;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.animateTo(
            _scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        elevation: 1,
        backgroundColor: const Color.fromRGBO(137, 177, 98, 1),
        title: Text(
          'Ride Chat',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          /// ───────────── CHAT LIST ─────────────
          Expanded(
            child: messages.isEmpty
                ? _emptyState()
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    itemCount: messages.length,
                    itemBuilder: (_, index) {
                      final msg = messages[index];
                      final isMe = msg.senderId == myUserId;

                      return _chatBubble(msg, isMe);
                    },
                  ),
          ),

          /// ───────────── INPUT BAR ─────────────
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
      ),
    );
  }

  /// ───────────── SEND CHAT ─────────────
  void _send() {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;

    ref
        .read(rideWSControllerProvider(widget.rideId).notifier)
        .sendChatMessage(text);

    _textCtrl.clear();
  }

  /// ───────────── CHAT BUBBLE ─────────────
  Widget _chatBubble(ChatMessage msg, bool isMe) {
    final time = DateFormat('hh:mm a').format(msg.timestamp.toLocal());

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: isMe ? const Color.fromRGBO(137, 177, 98, 1) : Colors.white,
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
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              msg.message,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: isMe ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: isMe ? Colors.white70 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ───────────── EMPTY STATE ─────────────
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
