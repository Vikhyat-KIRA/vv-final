import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/conversation_model.dart';

class DmService {
  static final DmService _instance = DmService._internal();
  factory DmService() => _instance;
  DmService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const int _pageSize = 20;

  String getDmId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return sorted.join('_');
  }

  Future<void> createOrGetDm(String myUid, String otherUid) async {
    try {
      final dmId = getDmId(myUid, otherUid);
      final docRef = _firestore.collection('dms').doc(dmId);
      final doc = await docRef.get();
      if (doc.exists) return;

      String myUsername = 'Learner';
      String otherUsername = 'Other Learner';

      final myDoc = await _firestore.collection('users').doc(myUid).get();
      if (myDoc.exists) {
        myUsername = myDoc.data()?['profile']?['username'] ?? 'Learner';
      }
      final otherDoc = await _firestore.collection('users').doc(otherUid).get();
      if (otherDoc.exists) {
        otherUsername = otherDoc.data()?['profile']?['username'] ?? 'Other Learner';
      }

      await docRef.set({
        'participants': [myUid, otherUid],
        'createdAt': FieldValue.serverTimestamp(),
        'usernames': {myUid: myUsername, otherUid: otherUsername},
        'lastMessage': '',
        'lastTimestamp': FieldValue.serverTimestamp(),
        'unreadCount_$myUid': 0,
        'unreadCount_$otherUid': 0,
      }, SetOptions(merge: true));
    } catch (e, stack) {
      debugPrint('Error in createOrGetDm: $e\n$stack');
      rethrow;
    }
  }

  /// Returns the first [_pageSize] messages, newest first.
  /// Returns a tuple: (messages, lastDocument for cursor pagination)
  Future<(List<DocumentSnapshot>, DocumentSnapshot?)> getMessages(
      String dmId) async {
    final snap = await _firestore
        .collection('dms')
        .doc(dmId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(_pageSize)
        .get();
    return (snap.docs, snap.docs.isNotEmpty ? snap.docs.last : null);
  }

  /// Loads the next page of messages older than [afterDoc].
  Future<(List<DocumentSnapshot>, DocumentSnapshot?)> getOlderMessages(
      String dmId, DocumentSnapshot afterDoc) async {
    final snap = await _firestore
        .collection('dms')
        .doc(dmId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .startAfterDocument(afterDoc)
        .limit(_pageSize)
        .get();
    return (snap.docs, snap.docs.isNotEmpty ? snap.docs.last : null);
  }

  /// Real-time stream of the latest [_pageSize] messages (for live updates only)
  Stream<QuerySnapshot> messagesStream(String dmId) {
    return _firestore
        .collection('dms')
        .doc(dmId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(_pageSize)
        .snapshots();
  }

  Future<void> sendMessage(String dmId, String senderId, String text) async {
    try {
      final participants = dmId.split('_');
      final otherUserId =
          participants.firstWhere((id) => id != senderId, orElse: () => '');

      final batch = _firestore.batch();
      final messageRef = _firestore
          .collection('dms')
          .doc(dmId)
          .collection('messages')
          .doc();
      final conversationRef = _firestore.collection('dms').doc(dmId);

      batch.set(messageRef, {
        'senderId': senderId,
        'text': text,
        'messageType': 'text',
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });
      batch.update(conversationRef, {
        'lastMessage': text,
        'lastTimestamp': FieldValue.serverTimestamp(),
        'lastSenderId': senderId,
        'unreadCount_$otherUserId': FieldValue.increment(1),
      });
      await batch.commit();
    } catch (e, stack) {
      debugPrint('Error in sendMessage: $e\n$stack');
      rethrow;
    }
  }

  // ────────────────────────────────────────────────────────────────
  //  NOTE: Image-message and voice-message features have been removed
  //  to keep the app fully functional on the free Firebase Spark plan.
  //  All other DM functionality (text messages, pagination,
  //  real-time streams, read receipts) remains unchanged.
  // ────────────────────────────────────────────────────────────────

  Stream<List<ConversationModel>> getConversations(String uid) {
    return _firestore
        .collection('dms')
        .where('participants', arrayContains: uid)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ConversationModel.fromFirestore(doc, uid))
          .toList();
      list.sort((a, b) => b.lastTimestamp.compareTo(a.lastTimestamp));
      return list;
    });
  }

  Future<void> markAsRead(String dmId, String myUid) async {
    try {
      await _firestore.collection('dms').doc(dmId).update({
        'unreadCount_$myUid': 0,
      });
      final unreadQuery = await _firestore
          .collection('dms')
          .doc(dmId)
          .collection('messages')
          .where('senderId', isNotEqualTo: myUid)
          .where('read', isEqualTo: false)
          .get();
      if (unreadQuery.docs.isEmpty) return;
      final batch = _firestore.batch();
      for (final doc in unreadQuery.docs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();
    } catch (e, stack) {
      debugPrint('Error in markAsRead: $e\n$stack');
    }
  }
}
