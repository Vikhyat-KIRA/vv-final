import 'package:cloud_firestore/cloud_firestore.dart';

class ConversationModel {
  final String dmId;
  final String otherUserId;
  final String otherUsername;
  final String lastMessage;
  final DateTime lastTimestamp;
  final int unreadCount;

  ConversationModel({
    required this.dmId,
    required this.otherUserId,
    required this.otherUsername,
    required this.lastMessage,
    required this.lastTimestamp,
    required this.unreadCount,
  });

  factory ConversationModel.fromFirestore(DocumentSnapshot doc, String currentUid) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final participants = List<String>.from(data['participants'] ?? []);
    final otherUserId = participants.firstWhere((id) => id != currentUid, orElse: () => '');

    final usernames = data['usernames'] as Map<String, dynamic>? ?? {};
    final otherUsername = usernames[otherUserId] ?? 'Other Learner';

    final timestampVal = data['lastTimestamp'];
    DateTime lastTs;
    if (timestampVal is Timestamp) {
      lastTs = timestampVal.toDate();
    } else if (timestampVal is int) {
      lastTs = DateTime.fromMillisecondsSinceEpoch(timestampVal);
    } else {
      lastTs = DateTime.now();
    }

    return ConversationModel(
      dmId: doc.id,
      otherUserId: otherUserId,
      otherUsername: otherUsername,
      lastMessage: data['lastMessage'] ?? '',
      lastTimestamp: lastTs,
      unreadCount: data['unreadCount_$currentUid'] ?? 0,
    );
  }
}
