import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class LeaderboardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<UserModel>> getTopUsers() async {
    final querySnapshot = await _firestore
        .collection('users')
        .orderBy('metrics.xp', descending: true)
        .limit(50)
        .get();

    return querySnapshot.docs.map((doc) {
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
  }
}
