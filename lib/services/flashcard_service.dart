import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/flashcard_model.dart';

class FlashcardService {
  static final FlashcardService _instance = FlashcardService._internal();
  factory FlashcardService() => _instance;
  FlashcardService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Saves a deck metadata and card collection to Firestore
  Future<void> saveDeck(String uid, DeckModel deck) async {
    try {
      await _firestore
          .collection('flashcard_decks')
          .doc(uid)
          .collection('decks')
          .doc(deck.id)
          .set(deck.toFirestore(), SetOptions(merge: true));
    } on FirebaseException catch (e, stack) {
      debugPrint('FirebaseException in saveDeck: ${e.message}\n$stack');
      rethrow;
    } catch (e, stack) {
      debugPrint('Unknown error in saveDeck: $e\n$stack');
      rethrow;
    }
  }

  /// Streams list of all decks for a user
  Stream<List<DeckModel>> getDecks(String uid) {
    return _firestore
        .collection('flashcard_decks')
        .doc(uid)
        .collection('decks')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DeckModel.fromFirestore(doc))
            .toList());
  }

  /// Updates a specific card's Leitner status in Firestore and updates the deck's overall masteryPercent
  Future<void> updateCardStatus(
    String uid,
    String deckId,
    String cardId,
    int status,
  ) async {
    final docRef = _firestore
        .collection('flashcard_decks')
        .doc(uid)
        .collection('decks')
        .doc(deckId);

    try {
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) return;

        final deck = DeckModel.fromFirestore(snapshot);
        final List<FlashcardModel> updatedCards = deck.cards.map((card) {
          if (card.id == cardId) {
            return FlashcardModel(
              id: card.id,
              front: card.front,
              back: card.back,
              reviewStatus: status,
            );
          }
          return card;
        }).toList();

        final masteredCount = updatedCards.where((c) => c.reviewStatus == 2).length;
        final double masteryPercent = updatedCards.isEmpty
            ? 0.0
            : (masteredCount / updatedCards.length);

        transaction.update(docRef, {
          'cards': updatedCards.map((c) => c.toMap()).toList(),
          'masteryPercent': masteryPercent,
        });
      });
    } on FirebaseException catch (e, stack) {
      debugPrint('FirebaseException in updateCardStatus: ${e.message}\n$stack');
      rethrow;
    } catch (e, stack) {
      debugPrint('Unknown error in updateCardStatus: $e\n$stack');
      rethrow;
    }
  }

  /// Optional utility to delete a deck from Firestore
  Future<void> deleteDeck(String uid, String deckId) async {
    try {
      await _firestore
          .collection('flashcard_decks')
          .doc(uid)
          .collection('decks')
          .doc(deckId)
          .delete();
    } catch (e) {
      debugPrint('Error deleting deck: $e');
    }
  }
}
