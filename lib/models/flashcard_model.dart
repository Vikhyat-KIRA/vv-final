import 'package:cloud_firestore/cloud_firestore.dart';

class FlashcardModel {
  final String id;
  final String front;
  final String back;
  final int reviewStatus; // 0=new, 1=learning, 2=mastered

  FlashcardModel({
    required this.id,
    required this.front,
    required this.back,
    required this.reviewStatus,
  });

  factory FlashcardModel.fromMap(Map<String, dynamic> map) {
    return FlashcardModel(
      id: map['id'] ?? '',
      front: map['front'] ?? '',
      back: map['back'] ?? '',
      reviewStatus: map['reviewStatus'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'front': front,
      'back': back,
      'reviewStatus': reviewStatus,
    };
  }
}

class DeckModel {
  final String id;
  final String name;
  final String subject;
  final List<FlashcardModel> cards;
  final double masteryPercent;
  final DateTime createdAt;

  DeckModel({
    required this.id,
    required this.name,
    required this.subject,
    required this.cards,
    required this.masteryPercent,
    required this.createdAt,
  });

  factory DeckModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final cardsList = (data['cards'] as List<dynamic>?) ?? [];
    final parsedCards = cardsList
        .map((c) => FlashcardModel.fromMap(c as Map<String, dynamic>))
        .toList();

    return DeckModel(
      id: doc.id,
      name: data['name'] ?? '',
      subject: data['subject'] ?? '',
      cards: parsedCards,
      masteryPercent: (data['masteryPercent'] as num?)?.toDouble() ?? 0.0,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'subject': subject,
      'cards': cards.map((c) => c.toMap()).toList(),
      'masteryPercent': masteryPercent,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
