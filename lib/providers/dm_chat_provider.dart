import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message_model.dart';
import '../services/dm_service.dart';

// State for the paginated chat
class DmChatState {
  final List<MessageModel> messages;
  final bool isLoadingMore;
  final bool hasMore;
  final DocumentSnapshot? lastDoc;

  const DmChatState({
    this.messages = const [],
    this.isLoadingMore = false,
    this.hasMore = true,
    this.lastDoc,
  });

  DmChatState copyWith({
    List<MessageModel>? messages,
    bool? isLoadingMore,
    bool? hasMore,
    DocumentSnapshot? lastDoc,
  }) {
    return DmChatState(
      messages: messages ?? this.messages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      lastDoc: lastDoc ?? this.lastDoc,
    );
  }
}

class DmChatNotifier extends StateNotifier<DmChatState> {
  final String dmId;
  DmChatNotifier(this.dmId) : super(const DmChatState()) {
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    try {
      final (docs, lastDoc) = await DmService().getMessages(dmId);
      final messages = docs
          .map((d) => MessageModel.fromFirestore(d))
          .toList();
      state = state.copyWith(
        messages: messages,
        lastDoc: lastDoc,
        hasMore: docs.length >= 20,
      );
    } catch (_) {}
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore || state.lastDoc == null) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final (docs, lastDoc) = await DmService()
          .getOlderMessages(dmId, state.lastDoc!);
      final older = docs.map((d) => MessageModel.fromFirestore(d)).toList();
      state = state.copyWith(
        messages: [...state.messages, ...older],
        lastDoc: lastDoc,
        hasMore: docs.length >= 20,
        isLoadingMore: false,
      );
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  /// Add an optimistic local bubble before the upload completes
  void addOptimisticMessage(MessageModel msg) {
    state = state.copyWith(messages: [msg, ...state.messages]);
  }

  /// Replace an optimistic bubble with the real Firestore document
  void resolveOptimistic(String tempId, MessageModel real) {
    state = state.copyWith(
      messages: [
        for (final m in state.messages)
          if (m.id == tempId) real else m,
      ],
    );
  }

  /// Remove a failed optimistic bubble
  void removeOptimistic(String tempId) {
    state = state.copyWith(
      messages: state.messages.where((m) => m.id != tempId).toList(),
    );
  }

  /// Merge a live stream snapshot into the top of the list
  void mergeSnapshot(List<MessageModel> incoming) {
    final existingIds = state.messages.map((m) => m.id).toSet();
    final newMessages =
        incoming.where((m) => !existingIds.contains(m.id)).toList();
    if (newMessages.isEmpty) return;
    state = state.copyWith(
      messages: [...newMessages, ...state.messages],
    );
  }
}

final dmChatProvider = StateNotifierProvider.autoDispose
    .family<DmChatNotifier, DmChatState, String>(
  (ref, dmId) => DmChatNotifier(dmId),
);
