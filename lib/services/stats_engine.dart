import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StatsEngine {
  static const String _keyTotalMessages = 'stats_total_ai_messages';
  static const String _keyTotalFocusMinutes = 'stats_total_focus_minutes';
  static const String _keyTotalFlashcardsReviewed =
      'stats_total_flashcards_reviewed';
  static const String _keyTotalChaptersCompleted =
      'stats_total_chapters_completed';
  static const String _keyRecentActivity = 'stats_recent_activity';
  static const String _keyXp = 'stats_total_xp';

  /// Log an AI chat message (+5 XP per message).
  static Future<void> logAiMessage() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_keyTotalMessages) ?? 0;
    await prefs.setInt(_keyTotalMessages, current + 1);
    await _addXp(5);
    await logActivity('AI Tutor', 'Sent a message');
  }

  /// Log completed Pomodoro session (+15 XP per session, adds minutes).
  static Future<void> logFocusSession(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_keyTotalFocusMinutes) ?? 0;
    await prefs.setInt(_keyTotalFocusMinutes, current + minutes);
    await _addXp(15);
    await logActivity('Focus Timer', 'Completed $minutes min session');
  }

  /// Log flashcard review (+2 XP per card).
  static Future<void> logFlashcardReview(int cardsReviewed) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_keyTotalFlashcardsReviewed) ?? 0;
    await prefs.setInt(_keyTotalFlashcardsReviewed, current + cardsReviewed);
    await _addXp(2 * cardsReviewed);
    await logActivity('Flashcards', 'Reviewed $cardsReviewed cards');
  }

  /// Log chapter completion (+25 XP per chapter).
  static Future<void> logChapterCompleted(
      String subjectName, String chapterName) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_keyTotalChaptersCompleted) ?? 0;
    await prefs.setInt(_keyTotalChaptersCompleted, current + 1);
    await _addXp(25);
    await logActivity(subjectName, 'Completed "$chapterName"');
  }

  /// Log any activity to the recent activity list.
  ///
  /// Stores entries as a JSON-encoded list of maps with keys:
  /// `subject`, `action`, `timestamp` (ISO 8601).
  /// The list is capped at 20 items (newest first).
  static Future<void> logActivity(String subject, String action) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_keyRecentActivity) ?? [];

    final entry = jsonEncode({
      'subject': subject,
      'action': action,
      'timestamp': DateTime.now().toIso8601String(),
    });

    raw.insert(0, entry);

    // Keep at most 20 entries.
    if (raw.length > 20) {
      raw.removeRange(20, raw.length);
    }

    await prefs.setStringList(_keyRecentActivity, raw);
  }

  /// Get all stats as a map.
  static Future<Map<String, dynamic>> getStats() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'totalMessages': prefs.getInt(_keyTotalMessages) ?? 0,
      'totalFocusMinutes': prefs.getInt(_keyTotalFocusMinutes) ?? 0,
      'totalFlashcardsReviewed':
          prefs.getInt(_keyTotalFlashcardsReviewed) ?? 0,
      'totalChaptersCompleted':
          prefs.getInt(_keyTotalChaptersCompleted) ?? 0,
      'totalXp': prefs.getInt(_keyXp) ?? 0,
    };
  }

  /// Get recent activity list as `List<Map<String, String>>`.
  static Future<List<Map<String, String>>> getRecentActivity() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_keyRecentActivity) ?? [];

    return raw.map((entry) {
      final decoded = jsonDecode(entry) as Map<String, dynamic>;
      return {
        'subject': decoded['subject'] as String,
        'action': decoded['action'] as String,
        'timestamp': decoded['timestamp'] as String,
      };
    }).toList();
  }

  /// Get total XP.
  static Future<int> getTotalXp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyXp) ?? 0;
  }

  // ── Private helpers ──────────────────────────────────────────────────

  static Future<void> _addXp(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_keyXp) ?? 0;
    await prefs.setInt(_keyXp, current + amount);
  }
}
