import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../models/message_model.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/colors.dart';

class ChatBubble extends ConsumerWidget {
  final MessageModel message;

  const ChatBubble({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = ref.watch(themeProvider);
    final userState = ref.watch(authProvider);
    final userInitial = userState?.displayName.isNotEmpty == true
        ? userState!.displayName.substring(0, 1).toUpperCase()
        : 'L';

    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser) ...[
                CircleAvatar(
                  radius: 14,
                  backgroundColor: accent,
                  foregroundColor: AppColors.background,
                  child: Icon(Icons.psychology_outlined, size: 16),
                ),
                SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUser ? accent : AppColors.surface2,
                    border: !isUser
                        ? Border(
                            left: BorderSide(color: accent, width: 3),
                          )
                        : null,
                    borderRadius: isUser
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
                  child: message.isLoading
                      ? _buildTypingIndicator()
                      : Text(
                          message.content,
                          style: TextStyle(
                            color: isUser ? AppColors.background : AppColors.textPrimary,
                            fontSize: 15,
                          ),
                        ),
                ),
              ),
              if (isUser) ...[
                SizedBox(width: 8),
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.surface2,
                  foregroundColor: AppColors.textPrimary,
                  child: Text(
                    userInitial,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 4),
          Padding(
            padding: EdgeInsets.only(
              left: isUser ? 0 : 36.0,
              right: isUser ? 36.0 : 0,
            ),
            child: Text(
              DateFormat('hh:mm a').format(message.timestamp),
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: AppColors.textSecondary,
            shape: BoxShape.circle,
          ),
        )
            .animate(onPlay: (controller) => controller.repeat())
            .scaleXY(
              begin: 0.6,
              end: 1.2,
              duration: 600.ms,
              curve: Curves.easeInOut,
            )
            .then(delay: (200 * i).ms);
      }),
    );
  }
}
