import 'package:cloud_firestore/cloud_firestore.dart';

class GuildModel {
  final String id;
  final String name;
  final String description;
  final String inviteCode;
  final String createdBy;
  final String subjectFocus;
  final List<String> memberIds;
  final bool isOpen;
  final DateTime createdAt;

  GuildModel({
    required this.id,
    required this.name,
    required this.description,
    required this.inviteCode,
    required this.createdBy,
    required this.subjectFocus,
    required this.memberIds,
    required this.isOpen,
    required this.createdAt,
  });

  factory GuildModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final timestampVal = data['createdAt'];
    DateTime created;
    if (timestampVal is Timestamp) {
      created = timestampVal.toDate();
    } else if (timestampVal is int) {
      created = DateTime.fromMillisecondsSinceEpoch(timestampVal);
    } else {
      created = DateTime.now();
    }

    return GuildModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      inviteCode: data['inviteCode'] ?? '',
      createdBy: data['createdBy'] ?? '',
      subjectFocus: data['subjectFocus'] ?? '',
      memberIds: List<String>.from(data['memberIds'] ?? []),
      isOpen: data['isOpen'] ?? true,
      createdAt: created,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'inviteCode': inviteCode,
      'createdBy': createdBy,
      'subjectFocus': subjectFocus,
      'memberIds': memberIds,
      'isOpen': isOpen,
      'createdAt': createdAt,
    };
  }
}
