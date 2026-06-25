import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/guild_model.dart';

class GuildService {
  static final GuildService _instance = GuildService._internal();
  factory GuildService() => _instance;
  GuildService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _generateCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = math.Random();
    return List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
  }

  Future<String> _getUniqueInviteCode() async {
    while (true) {
      final code = _generateCode();
      final query = await _firestore
          .collection('guilds')
          .where('inviteCode', isEqualTo: code)
          .limit(1)
          .get();
      if (query.docs.isEmpty) {
        return code;
      }
    }
  }

  /// Creates a new guild, attaches a unique invite code, joins the creator, and updates the user's doc
  Future<GuildModel> createGuild({
    required String name,
    required String description,
    required String subjectFocus,
    required bool isOpen,
    required String uid,
  }) async {
    try {
      final inviteCode = await _getUniqueInviteCode();
      final guildDocRef = _firestore.collection('guilds').doc();
      final guildId = guildDocRef.id;

      final data = {
        'name': name,
        'description': description,
        'inviteCode': inviteCode,
        'createdBy': uid,
        'subjectFocus': subjectFocus,
        'memberIds': [uid],
        'isOpen': isOpen,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // 1. Save guild document
      await guildDocRef.set(data);

      // 2. Add guildId to users/$uid/guilds array
      await _firestore.collection('users').doc(uid).set({
        'guilds': FieldValue.arrayUnion([guildId]),
      }, SetOptions(merge: true));

      // Fetch the created document to return a complete GuildModel
      final doc = await guildDocRef.get();
      return GuildModel.fromFirestore(doc);
    } catch (e, stack) {
      debugPrint('Error in createGuild: $e\n$stack');
      rethrow;
    }
  }

  /// Searches for a guild using its 6-character invite code
  Future<GuildModel?> findByCode(String code) async {
    try {
      final cleanCode = code.trim().toUpperCase();
      final query = await _firestore
          .collection('guilds')
          .where('inviteCode', isEqualTo: cleanCode)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return null;
      return GuildModel.fromFirestore(query.docs.first);
    } catch (e, stack) {
      debugPrint('Error in findByCode: $e\n$stack');
      return null;
    }
  }

  /// Joins a user to a guild by updating both the memberIds array and the user's document
  Future<void> joinGuild(String guildId, String uid) async {
    try {
      final batch = _firestore.batch();
      final guildRef = _firestore.collection('guilds').doc(guildId);
      final userRef = _firestore.collection('users').doc(uid);

      batch.update(guildRef, {
        'memberIds': FieldValue.arrayUnion([uid]),
      });

      batch.set(userRef, {
        'guilds': FieldValue.arrayUnion([guildId]),
      }, SetOptions(merge: true));

      await batch.commit();
    } catch (e, stack) {
      debugPrint('Error in joinGuild: $e\n$stack');
      rethrow;
    }
  }

  /// Streams the list of guilds the user is currently a member of
  Stream<List<GuildModel>> getMyGuilds(String uid) {
    return _firestore
        .collection('guilds')
        .where('memberIds', arrayContains: uid)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => GuildModel.fromFirestore(doc)).toList();
    });
  }

  /// Sends a text message inside the guild chat room subcollection
  Future<void> sendGuildMessage(
    String guildId,
    String senderId,
    String text,
    String senderUsername,
  ) async {
    try {
      await _firestore
          .collection('guilds')
          .doc(guildId)
          .collection('messages')
          .add({
        'senderId': senderId,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
        'senderUsername': senderUsername,
      });
    } catch (e, stack) {
      debugPrint('Error in sendGuildMessage: $e\n$stack');
      rethrow;
    }
  }

  /// Streams the chat messages of a specific guild room sorted by time ascending
  Stream<QuerySnapshot> getGuildMessages(String guildId) {
    return _firestore
        .collection('guilds')
        .doc(guildId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}
