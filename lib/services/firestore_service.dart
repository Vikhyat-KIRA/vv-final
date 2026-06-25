import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import 'either.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Either<Failure, T>> runSafe<T>(Future<T> Function() call) async {
    try {
      final result = await call();
      return Right(result);
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.message ?? 'Firebase error'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  /// Writes to `users/$uid` with profile map
  Future<void> saveUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'profile': data,
      }, SetOptions(merge: true));
    } on FirebaseException catch (e, stack) {
      debugPrint('FirebaseException in saveUserProfile: ${e.message}\n$stack');
      rethrow;
    } catch (e, stack) {
      debugPrint('Unknown error in saveUserProfile: $e\n$stack');
      rethrow;
    }
  }

  /// Updates users/$uid/metrics map field
  Future<void> saveUserMetrics(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'metrics': data,
      }, SetOptions(merge: true));
    } on FirebaseException catch (e, stack) {
      debugPrint('FirebaseException in saveUserMetrics: ${e.message}\n$stack');
      rethrow;
    } catch (e, stack) {
      debugPrint('Unknown error in saveUserMetrics: $e\n$stack');
      rethrow;
    }
  }

  /// Updates users/$uid/targets map field
  Future<void> saveUserTargets(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'targets': data,
      }, SetOptions(merge: true));
    } on FirebaseException catch (e, stack) {
      debugPrint('FirebaseException in saveUserTargets: ${e.message}\n$stack');
      rethrow;
    } catch (e, stack) {
      debugPrint('Unknown error in saveUserTargets: $e\n$stack');
      rethrow;
    }
  }

  /// Writes user_progress/$uid/$subjectKey
  Future<void> saveChapterProgress(String uid, String subjectKey, Map<String, dynamic> data) async {
    try {
      await _firestore
          .collection('user_progress')
          .doc(uid)
          .collection('subjects')
          .doc(subjectKey)
          .set(data, SetOptions(merge: true));
    } on FirebaseException catch (e, stack) {
      debugPrint('FirebaseException in saveChapterProgress: ${e.message}\n$stack');
      rethrow;
    } catch (e, stack) {
      debugPrint('Unknown error in saveChapterProgress: $e\n$stack');
      rethrow;
    }
  }

  /// Reads users/$uid
  Future<DocumentSnapshot<Map<String, dynamic>>> getUserData(String uid) async {
    try {
      return await _firestore.collection('users').doc(uid).get();
    } on FirebaseException catch (e, stack) {
      debugPrint('FirebaseException in getUserData: ${e.message}\n$stack');
      rethrow;
    } catch (e, stack) {
      debugPrint('Unknown error in getUserData: $e\n$stack');
      rethrow;
    }
  }

  /// Checks if a username is already taken in the database
  Future<bool> isUsernameTaken(String username) async {
    try {
      final lowercase = username.trim().toLowerCase();
      final query = await _firestore
          .collection('users')
          .where('profile.username', isEqualTo: lowercase)
          .limit(1)
          .get();
      return query.docs.isNotEmpty;
    } catch (e, stack) {
      debugPrint('Error in isUsernameTaken: $e\n$stack');
      return false;
    }
  }

  /// Auto-generates a unique username: @[firstname][random3digits]
  Future<String> generateUniqueUsername(String displayName) async {
    String firstName = displayName.split(' ').first.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
    if (firstName.isEmpty) {
      firstName = 'learner';
    }

    final random = math.Random();
    while (true) {
      final digits = random.nextInt(900) + 100; // 100 to 999
      final candidate = '$firstName$digits';
      final taken = await isUsernameTaken(candidate);
      if (!taken) {
        return candidate;
      }
    }
  }

  /// Updates the username in Firestore, enforcing uniqueness and a 30-day rate limit
  Future<void> updateUsername(String uid, String newUsername) async {
    try {
      final cleanUsername = newUsername.trim().toLowerCase();
      if (cleanUsername.isEmpty) {
        throw Exception('Username cannot be empty');
      }

      // Check if taken
      final taken = await isUsernameTaken(cleanUsername);
      if (taken) {
        throw Exception('Username is already taken');
      }

      final doc = await getUserData(uid);
      if (doc.exists) {
        final data = doc.data();
        final profile = data?['profile'] as Map<String, dynamic>?;
        if (profile != null) {
          final lastChange = profile['usernameUpdatedAt'] as Timestamp?;
          if (lastChange != null) {
            final difference = DateTime.now().difference(lastChange.toDate());
            if (difference.inDays < 30) {
              final remainingDays = 30 - difference.inDays;
              throw Exception('You can only change your username once every 30 days. Please wait $remainingDays more days.');
            }
          }
        }
      }

      // Save username and timestamp
      await saveUserProfile(uid, {
        'username': cleanUsername,
        'usernameUpdatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e, stack) {
      debugPrint('FirebaseException in updateUsername: ${e.message}\n$stack');
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  /// Dynamically queries syllabus progress for completed chapters count
  Future<int> getChaptersCompletedCount(String uid) async {
    try {
      final subjectsQuery = await _firestore
          .collection('user_progress')
          .doc(uid)
          .collection('subjects')
          .get();

      int completedCount = 0;
      for (final doc in subjectsQuery.docs) {
        final data = doc.data();
        final chapters = data['chapters'] as List<dynamic>?;
        if (chapters != null) {
          for (final chapter in chapters) {
            if (chapter is Map<String, dynamic> && chapter['status'] == 2) {
              completedCount++;
            }
          }
        }
      }
      return completedCount;
    } catch (e, stack) {
      debugPrint('Error getting completed chapters: $e\n$stack');
      return 0;
    }
  }

  /// Searches users in Firestore by username prefix (case-insensitive prefix search)
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      final clean = query.trim().toLowerCase();
      if (clean.isEmpty) return [];

      final snapshot = await _firestore
          .collection('users')
          .where('profile.username', isGreaterThanOrEqualTo: clean)
          .where('profile.username', isLessThanOrEqualTo: '$clean\uf8ff')
          .limit(15)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        final profile = data['profile'] as Map<String, dynamic>? ?? {};
        final metrics = data['metrics'] as Map<String, dynamic>? ?? {};

        return UserModel(
          uid: doc.id,
          email: data['email'] ?? '',
          displayName: profile['name'] ?? 'Learner',
          photoUrl: profile['photoUrl'] ?? 'https://api.dicebear.com/7.x/bottts/svg?seed=${doc.id}',
          level: metrics['level'] ?? 1,
          xp: metrics['xp'] ?? 0,
          enrolledSubjects: List<String>.from(profile['enrolledSubjects'] ?? []),
          username: profile['username'] ?? '',
          grade: profile['grade'] ?? '',
          board: profile['board'] ?? '',
        );
      }).toList();
    } catch (e, stack) {
      debugPrint('Error in searchUsers: $e\n$stack');
      return [];
    }
  }
}
