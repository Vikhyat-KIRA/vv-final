import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/message_model.dart';
import 'xp_provider.dart';

class ChatNotifier extends StateNotifier<List<MessageModel>> {
  final Ref ref;
  ChatNotifier(this.ref) : super([]) {
    _loadWelcomeMessage();
  }

  Future<void> _loadWelcomeMessage() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_name') ?? 'Learner';
    final target = prefs.getDouble('user_target_percentage') ?? 90.0;
    final current = prefs.getDouble('user_percentage') ?? 60.0;
    final delta = (target - current).clamp(0.0, 100.0);

    final welcomeText =
        'Hi $name! You are targeting ${target.toInt()}% from ${current.toInt()}%. '
        'That is a ${delta.toInt()}% gap. What are we working on today?';

    state = [
      MessageModel(
        id: 'welcome',
        content: welcomeText,
        isUser: false,
        isLoading: false,
        timestamp: DateTime.now(),
      ),
    ];
  }

  void addUserMessage(String text) {
    final userMessage = MessageModel(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}_user',
      content: text,
      isUser: true,
      timestamp: DateTime.now(),
    );
    state = [userMessage, ...state];
  }

  /// Adds a streaming AI message and returns its id.
  /// Call [appendToMessage] to add tokens one by one.
  String beginStreamingMessage() {
    final id = 'msg_${DateTime.now().millisecondsSinceEpoch}_ai';
    final placeholder = MessageModel(
      id: id,
      content: '',
      isUser: false,
      isLoading: false,
      timestamp: DateTime.now(),
    );
    state = [placeholder, ...state];
    return id;
  }

  /// Appends a text chunk to an existing streaming message
  void appendToMessage(String id, String chunk) {
    state = [
      for (final msg in state)
        if (msg.id == id) msg.copyWith(content: msg.content + chunk) else msg,
    ];
  }

  /// Legacy non-streaming add (kept for error paths)
  void addAIMessage(String text) {
    final aiMessage = MessageModel(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}_ai',
      content: text,
      isUser: false,
      timestamp: DateTime.now(),
    );
    state = [aiMessage, ...state];
    // Award the "first_ai_message" achievement if not already earned
    final xpNotifier = ref.read(xpProvider.notifier);
    if (!xpNotifier.state.earnedAchievements.contains('first_ai_message')) {
      xpNotifier.earnAchievement('first_ai_message');
    }
  }

  /// Called once streaming is fully done — award achievement
  void onStreamingComplete(String id) {
    final xpNotifier = ref.read(xpProvider.notifier);
    if (!xpNotifier.state.earnedAchievements.contains('first_ai_message')) {
      xpNotifier.earnAchievement('first_ai_message');
    }
  }

  void setTyping(bool val) {
    if (val) {
      if (!state.any((m) => m.id == 'typing')) {
        state = [
          MessageModel(
            id: 'typing',
            content: '',
            isUser: false,
            isLoading: true,
            timestamp: DateTime.now(),
          ),
          ...state,
        ];
      }
    } else {
      state = state.where((m) => m.id != 'typing').toList();
    }
  }

  void clearChat() {
    state = [];
    _loadWelcomeMessage();
  }
}

final chatProvider =
    StateNotifierProvider<ChatNotifier, List<MessageModel>>((ref) {
  return ChatNotifier(ref);
});
