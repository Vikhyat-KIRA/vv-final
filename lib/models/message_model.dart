import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String content;
  final bool isUser;
  final bool isLoading;
  final DateTime timestamp;

  // DM fields
  final String senderId;
  final String text;
  final String messageType; // always 'text' — image/voice removed
  final bool read;

  const MessageModel({
    required this.id,
    this.content = '',
    this.isUser = true,
    this.isLoading = false,
    required this.timestamp,
    this.senderId = '',
    this.text = '',
    this.messageType = 'text',
    this.read = false,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final timestampVal = data['timestamp'];
    DateTime ts;
    if (timestampVal is Timestamp) {
      ts = timestampVal.toDate();
    } else if (timestampVal is int) {
      ts = DateTime.fromMillisecondsSinceEpoch(timestampVal);
    } else {
      ts = DateTime.now();
    }

    return MessageModel(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      content: data['text'] ?? data['content'] ?? '',
      messageType: data['messageType'] ?? 'text',
      timestamp: ts,
      read: data['read'] ?? false,
      isUser: data['isUser'] ?? true,
      isLoading: data['isLoading'] ?? false,
    );
  }

  MessageModel copyWith({
    String? id,
    String? content,
    bool? isUser,
    bool? isLoading,
    DateTime? timestamp,
    String? senderId,
    String? text,
    String? messageType,
    bool? read,
  }) {
    return MessageModel(
      id: id ?? this.id,
      content: content ?? this.content,
      isUser: isUser ?? this.isUser,
      isLoading: isLoading ?? this.isLoading,
      timestamp: timestamp ?? this.timestamp,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      messageType: messageType ?? this.messageType,
      read: read ?? this.read,
    );
  }
}
