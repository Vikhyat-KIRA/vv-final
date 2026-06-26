import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../models/message_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/dm_service.dart';
import '../../theme/colors.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String dmId;
  final String otherUserId;
  final String otherUsername;

  const ChatScreen({
    super.key,
    required this.dmId,
    required this.otherUserId,
    required this.otherUsername,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _markRead();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _markRead() {
    final currentUid = ref.read(authProvider)?.uid;
    if (currentUid != null) {
      DmService().markAsRead(widget.dmId, currentUid);
    }
  }

  Future<void> _handleSendText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final senderId = ref.read(authProvider)?.uid;
    if (senderId == null) return;

    _textController.clear();
    setState(() {}); // refresh send icon state

    try {
      await DmService().sendMessage(widget.dmId, senderId, text);
      _markRead();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = ref.watch(authProvider)?.uid ?? '';
    final accent = ref.watch(themeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            _buildInitialAvatar(widget.otherUsername, accent, radius: 16, fontSize: 14),
            const SizedBox(width: 10),
            Text(
              '@${widget.otherUsername}',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Message stream list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('dms')
                  .doc(widget.dmId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(accent),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading messages.'));
                }

                final docs = snapshot.data?.docs ?? [];
                final List<MessageModel> messages =
                    docs.map((doc) => MessageModel.fromFirestore(doc)).toList();

                // Trigger read mark on message list update
                WidgetsBinding.instance
                    .addPostFrameCallback((_) => _markRead());

                if (messages.isEmpty) {
                  return _buildConversationStarter();
                }

                return ListView.builder(
                  reverse: true,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderId == currentUid;

                    bool showDateSeparator = false;
                    if (index == messages.length - 1) {
                      showDateSeparator = true;
                    } else {
                      final prevMsg = messages[index + 1];
                      if (!_isSameDay(msg.timestamp, prevMsg.timestamp)) {
                        showDateSeparator = true;
                      }
                    }

                    return Column(
                      children: [
                        if (showDateSeparator)
                          _buildDateSeparator(msg.timestamp),
                        _buildMessageBubble(msg, isMe, accent),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // Text Input Bar
          _buildInputBar(accent),
        ],
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  /// Consistent colorful initial avatar used throughout the DM UI.
  Widget _buildInitialAvatar(String name, Color accent,
      {double radius = 20, double fontSize = 16}) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'L';
    return CircleAvatar(
      radius: radius,
      backgroundColor: accent,
      child: Text(
        initial,
        style: TextStyle(
          fontFamily: 'Space Grotesk',
          fontWeight: FontWeight.bold,
          fontSize: fontSize,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildConversationStarter() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.waving_hand_rounded,
            color: AppColors.textSecondary.withAlpha(80),
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Start of @${widget.otherUsername} conversation',
            style: TextStyle(
              fontFamily: 'Space Grotesk',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Say hi to begin studying together!',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Widget _buildDateSeparator(DateTime date) {
    final formatStr = DateFormat('MMMM d, y').format(date);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            formatStr,
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel msg, bool isMe, Color accentColor) {
    // Text-only bubble (image and voice types are no longer sent;
    // any legacy messages of those types fall through to text display)
    final bubbleContent = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isMe ? accentColor : AppColors.surface2,
        border: !isMe
            ? Border(left: BorderSide(color: accentColor, width: 3))
            : null,
        borderRadius: isMe
            ? const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(4),
              )
            : const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
      ),
      child: Text(
        msg.text,
        style: TextStyle(
          color: isMe ? Colors.white : AppColors.textPrimary,
          fontSize: 15,
          fontFamily: 'Plus Jakarta Sans',
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 16.0),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe) ...[
                CircleAvatar(
                  radius: 12,
                  backgroundColor: AppColors.surface2,
                  child: Text(
                    widget.otherUsername.isNotEmpty
                        ? widget.otherUsername[0].toUpperCase()
                        : 'L',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(child: bubbleContent),
              if (isMe) ...[
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 12,
                  backgroundColor: AppColors.surface2,
                  child: Consumer(
                    builder: (context, ref, child) {
                      final name = ref.watch(authProvider)?.displayName ?? 'L';
                      return Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'L',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: EdgeInsets.only(
              left: isMe ? 0 : 32.0,
              right: isMe ? 32.0 : 0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('hh:mm a').format(msg.timestamp),
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    msg.read ? Icons.done_all_rounded : Icons.done_rounded,
                    size: 14,
                    color: msg.read ? accentColor : AppColors.textSecondary,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(Color accentColor) {
    final hasText = _textController.text.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Message Input TextField
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _textController,
                  maxLines: 4,
                  minLines: 1,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Message...',
                    hintStyle: TextStyle(color: AppColors.textSecondary),
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onChanged: (text) {
                    setState(() {}); // swap send icon visibility
                  },
                  onSubmitted: (_) => _handleSendText(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Send button — animated in when text is available
            AnimatedScale(
              scale: hasText ? 1.0 : 0.7,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              child: GestureDetector(
                onTap: hasText ? _handleSendText : null,
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: hasText ? accentColor : AppColors.surface2,
                  child: Icon(
                    Icons.send_rounded,
                    color: hasText ? Colors.white : AppColors.textSecondary,
                    size: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
