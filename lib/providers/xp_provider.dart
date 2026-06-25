import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firestore_service.dart';
import '../services/achievement_service.dart';
import '../models/user_model.dart';
import 'auth_provider.dart';

class XpState {
  final int totalXP;
  final int level;
  final int streakDays;
  final List<String> earnedAchievements;

  XpState({
    required this.totalXP,
    required this.level,
    required this.streakDays,
    required this.earnedAchievements,
  });

  XpState copyWith({
    int? totalXP,
    int? level,
    int? streakDays,
    List<String>? earnedAchievements,
  }) {
    return XpState(
      totalXP: totalXP ?? this.totalXP,
      level: level ?? this.level,
      streakDays: streakDays ?? this.streakDays,
      earnedAchievements: earnedAchievements ?? this.earnedAchievements,
    );
  }
}

class XpNotifier extends Notifier<XpState> {
  @override
  XpState build() {
    // Listen to auth state transitions to reload user XP on login
    ref.listen<UserModel?>(authProvider, (previous, next) {
      if (next != null && previous?.uid != next.uid) {
        initializeXpState();
      }
    });
    
    // Asynchronously initialize from preferences and user profile
    Future.microtask(() => initializeXpState());
    
    return XpState(
      totalXP: 0,
      level: 1,
      streakDays: 1,
      earnedAchievements: [],
    );
  }

  Future<void> initializeXpState() async {
    final prefs = await SharedPreferences.getInstance();
    final user = ref.read(authProvider);

    int xp = 0;
    int level = 1;
    int streak = prefs.getInt('user_streak') ?? 1;
    List<String> achievements = prefs.getStringList('earned_achievements') ?? [];

    if (user != null) {
      xp = user.xp;
      level = user.level;
    } else {
      xp = prefs.getInt('user_xp') ?? 0;
      level = prefs.getInt('user_level') ?? 1;
    }

    state = XpState(
      totalXP: xp,
      level: level,
      streakDays: streak,
      earnedAchievements: achievements,
    );
  }

  int calculateLevel(int xp) {
    if (xp < 500) return 1;
    if (xp < 2000) return 2;
    if (xp < 5000) return 3;
    if (xp < 10000) return 4;
    return 5;
  }

  Future<void> addXP(int amount, String source) async {
    final prefs = await SharedPreferences.getInstance();
    final newXp = state.totalXP + amount;
    final newLevel = calculateLevel(newXp);

    state = state.copyWith(
      totalXP: newXp,
      level: newLevel,
    );

    // Save to SharedPreferences
    await prefs.setInt('user_xp', newXp);
    await prefs.setInt('user_level', newLevel);

    // Save to Firestore
    final user = ref.read(authProvider);
    if (user != null) {
      await FirestoreService().saveUserMetrics(user.uid, {
        'xp': newXp,
        'level': newLevel,
        'streak': state.streakDays,
      });

      // Synchronize back to authProvider model
      ref.read(authProvider.notifier).syncXpAndLevel(newXp, newLevel);
    }

    checkAchievements();
  }

  Future<void> setStreak(int streak) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_streak', streak);
    state = state.copyWith(streakDays: streak);

    final user = ref.read(authProvider);
    if (user != null) {
      await FirestoreService().saveUserMetrics(user.uid, {
        'streak': streak,
      });
    }

    checkAchievements();
  }

  Future<void> earnAchievement(String id) async {
    if (state.earnedAchievements.contains(id)) return;

    final achievement = allAchievements.firstWhere((a) => a.id == id, orElse: () => allAchievements.first);
    if (achievement.id != id) return; // safeguard

    final prefs = await SharedPreferences.getInstance();
    final updatedAchievements = List<String>.from(state.earnedAchievements)..add(id);

    state = state.copyWith(earnedAchievements: updatedAchievements);

    // Save to SharedPreferences
    await prefs.setStringList('earned_achievements', updatedAchievements);

    // Save to Firestore profile
    final user = ref.read(authProvider);
    if (user != null) {
      await FirestoreService().saveUserProfile(user.uid, {
        'earnedAchievements': updatedAchievements,
      });
    }

    // Award XP reward
    await addXP(achievement.xpReward, id);
  }

  void checkAchievements() {
    // Check 7-day streak achievement
    if (state.streakDays >= 7 && !state.earnedAchievements.contains('streak_7_days')) {
      earnAchievement('streak_7_days');
    }
  }
}

final xpProvider = NotifierProvider<XpNotifier, XpState>(() {
  return XpNotifier();
});
