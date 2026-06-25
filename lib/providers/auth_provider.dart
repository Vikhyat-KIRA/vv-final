import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../models/user_model.dart';
import '../services/firestore_service.dart';

class AuthNotifier extends StateNotifier<UserModel?> {
  AuthNotifier() : super(null) {
    _initFromFirebase();
  }

  Future<void> _initFromFirebase() async {
    final user = fb.FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _loadUserData(user);
    }
  }

  Future<void> _loadUserData(fb.User user) async {
    try {
      final doc = await FirestoreService().getUserData(user.uid);
      if (doc.exists) {
        final data = doc.data();
        final profile = data?['profile'] as Map<String, dynamic>?;
        final metrics = data?['metrics'] as Map<String, dynamic>?;

        state = UserModel(
          uid: user.uid,
          email: user.email ?? '',
          displayName: profile?['name'] ?? user.displayName ?? 'Learner',
          photoUrl: user.photoURL ?? 'https://api.dicebear.com/7.x/bottts/svg?seed=vidyaverse',
          level: metrics?['level'] ?? 1,
          xp: metrics?['xp'] ?? 120,
          enrolledSubjects: List<String>.from(profile?['enrolledSubjects'] ?? ['Quantum Physics', 'Machine Learning', 'Linear Algebra']),
          username: profile?['username'] ?? '',
          grade: profile?['grade'] ?? '',
          board: profile?['board'] ?? '',
        );
      } else {
        state = UserModel(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName ?? 'Learner',
          photoUrl: user.photoURL ?? 'https://api.dicebear.com/7.x/bottts/svg?seed=vidyaverse',
          level: 1,
          xp: 120,
          enrolledSubjects: ['Quantum Physics', 'Machine Learning', 'Linear Algebra'],
          username: '',
        );
      }
    } catch (_) {
      state = UserModel(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? 'Learner',
        photoUrl: user.photoURL ?? 'https://api.dicebear.com/7.x/bottts/svg?seed=vidyaverse',
        level: 1,
        xp: 120,
        enrolledSubjects: ['Quantum Physics', 'Machine Learning', 'Linear Algebra'],
        username: '',
      );
    }
  }

  Future<void> loginWithFirebaseUser(fb.User user) async {
    await _loadUserData(user);
  }

  void login(String email, String displayName) {
    state = UserModel(
      uid: 'user_123',
      email: email,
      displayName: displayName,
      photoUrl: 'https://api.dicebear.com/7.x/bottts/svg?seed=vidyaverse',
      level: 1,
      xp: 120,
      enrolledSubjects: ['Quantum Physics', 'Machine Learning', 'Linear Algebra'],
      username: 'learner123',
      grade: 'Class 12',
      board: 'CBSE',
    );
  }

  void refreshUsername(String newUsername) {
    if (state != null) {
      state = UserModel(
        uid: state!.uid,
        email: state!.email,
        displayName: state!.displayName,
        photoUrl: state!.photoUrl,
        level: state!.level,
        xp: state!.xp,
        enrolledSubjects: state!.enrolledSubjects,
        username: newUsername,
        grade: state!.grade,
        board: state!.board,
      );
    }
  }

  Future<void> refresh() async {
    final user = fb.FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _loadUserData(user);
    }
  }

  void addXp(int amount) {
    if (state != null) {
      final currentXp = state!.xp + amount;
      final currentLevel = state!.level;
      // Simple leveling formula: level up every 200 XP
      final nextLevel = (currentXp / 200).floor() + 1;
      
      final updatedUser = UserModel(
        uid: state!.uid,
        email: state!.email,
        displayName: state!.displayName,
        photoUrl: state!.photoUrl,
        level: nextLevel > currentLevel ? nextLevel : currentLevel,
        xp: currentXp,
        enrolledSubjects: state!.enrolledSubjects,
        username: state!.username,
        grade: state!.grade,
        board: state!.board,
      );
      
      state = updatedUser;
      
      // Persist in Firestore metrics
      FirestoreService().saveUserMetrics(updatedUser.uid, {
        'xp': currentXp,
        'level': updatedUser.level,
      });
    }
  }

  void syncXpAndLevel(int newXp, int newLevel) {
    if (state != null) {
      state = UserModel(
        uid: state!.uid,
        email: state!.email,
        displayName: state!.displayName,
        photoUrl: state!.photoUrl,
        level: newLevel,
        xp: newXp,
        enrolledSubjects: state!.enrolledSubjects,
        username: state!.username,
        grade: state!.grade,
        board: state!.board,
      );
    }
  }

  void logout() {
    state = null;
    fb.FirebaseAuth.instance.signOut();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, UserModel?>((ref) {
  return AuthNotifier();
});
