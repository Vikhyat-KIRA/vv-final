import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/colors.dart';
import '../../providers/theme_provider.dart';
import '../../providers/sync_provider.dart';
import '../../providers/syllabus_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/unread_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';
import '../../utils/delta_engine.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/stats_engine.dart';
import '../../widgets/exam_countdown_card.dart';
import '../../widgets/glass_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String _userName = 'Learner';
  double _currentPercent = 65.0;
  double _targetPercent = 90.0;
  String _lastSubject = 'Quantum Physics';
  String _lastChapter = 'Wave Mechanics intro';
  Timer? _countdownTimer;
  String _countdownStr = '';

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _updateCountdown();
    // Update countdown once per minute — not per frame
    _countdownTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _updateCountdown(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initNotificationsAndStreak();
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _updateCountdown() {
    SharedPreferences.getInstance().then((prefs) {
      final examDateStr = prefs.getString('exam_date');
      if (!mounted) return;
      if (examDateStr == null) {
        setState(() => _countdownStr = '');
        return;
      }
      try {
        final examDate = DateTime.parse(examDateStr);
        final now = DateTime.now();
        final diff = examDate.difference(now);
        if (diff.isNegative) {
          setState(() => _countdownStr = 'Exam passed');
        } else {
          final days = diff.inDays;
          final hours = diff.inHours % 24;
          setState(() => _countdownStr = '$days d $hours h left');
        }
      } catch (_) {
        setState(() => _countdownStr = '');
      }
    });
  }

  Future<void> _initNotificationsAndStreak() async {
    await NotificationService.requestPermission();
    final prefs = await SharedPreferences.getInstance();

    final lastActiveStr = prefs.getString('user_last_active');
    final now = DateTime.now();
    int streak = prefs.getInt('user_streak') ?? 1;

    if (lastActiveStr != null) {
      final lastActive = DateTime.parse(lastActiveStr);
      final lastDay =
          DateTime(lastActive.year, lastActive.month, lastActive.day);
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));

      if (lastDay == today) {
        // Already logged in today — do nothing
      } else if (lastDay == yesterday) {
        // Consecutive day
        streak++;
        await prefs.setInt('user_streak', streak);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🔥 $streak-day streak! Keep it up!'),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Streak broken
        streak = 1;
        await prefs.setInt('user_streak', streak);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Streak reset 😔 — start fresh today!'),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } else {
      // First time
      await prefs.setInt('user_streak', 1);
    }

    // Mark today as active
    await prefs.setString('user_last_active', now.toIso8601String());

    final streakRemindersEnabled =
        prefs.getBool('pref_streak_reminders') ?? true;
    if (streakRemindersEnabled) {
      await NotificationService.checkStreakAndNotify(
          streak, DateTime.parse(
              prefs.getString('user_last_active') ?? now.toIso8601String()));
    }
  }

  Future<void> _loadDashboardData() async {
    // Load from local SharedPreferences only — zero Firestore reads here
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _userName = prefs.getString('user_name') ?? 'Learner';
      _currentPercent = prefs.getDouble('user_percentage') ?? 65.0;
      _targetPercent = prefs.getDouble('user_target_percentage') ?? 90.0;
      _lastSubject = prefs.getString('last_subject') ?? 'Quantum Physics';
      _lastChapter =
          prefs.getString('last_chapter') ?? 'Wave Mechanics intro';
    });
    // Background sync (non-blocking)
    _pullAndMergeFirestoreData();
  }

  Future<void> _pullAndMergeFirestoreData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    ref.read(syncStatusProvider.notifier).setSyncing();
    try {
      final docSnapshot = await FirestoreService().getUserData(user.uid);
      final prefs = await SharedPreferences.getInstance();

      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        if (data != null) {
          final profile = data['profile'] as Map<String, dynamic>?;
          if (profile != null) {
            if (profile.containsKey('name')) {
              await prefs.setString('user_name', profile['name']);
            }
            if (profile.containsKey('grade')) {
              await prefs.setString('user_grade', profile['grade']);
            }
            if (profile.containsKey('board')) {
              await prefs.setString('user_board', profile['board']);
            }
            final username = profile['username'] as String?;
            if (username == null || username.trim().isEmpty) {
              final displayName =
                  profile['name'] ?? user.displayName ?? 'Learner';
              final generated = await FirestoreService()
                  .generateUniqueUsername(displayName);
              await FirestoreService().saveUserProfile(user.uid, {
                'username': generated,
                'usernameUpdatedAt': FieldValue.serverTimestamp(),
              });
              ref.read(authProvider.notifier).refreshUsername(generated);
            }
          } else {
            final displayName = user.displayName ?? 'Learner';
            final generated =
                await FirestoreService().generateUniqueUsername(displayName);
            await FirestoreService().saveUserProfile(user.uid, {
              'username': generated,
              'usernameUpdatedAt': FieldValue.serverTimestamp(),
            });
            ref.read(authProvider.notifier).refreshUsername(generated);
          }

          final metrics = data['metrics'] as Map<String, dynamic>?;
          if (metrics != null) {
            if (metrics.containsKey('currentPercentage')) {
              await prefs.setDouble('user_percentage',
                  (metrics['currentPercentage'] as num).toDouble());
            }
            if (metrics.containsKey('statusBadge')) {
              await prefs.setString(
                  'user_status_badge', metrics['statusBadge']);
            }
          }

          final targets = data['targets'] as Map<String, dynamic>?;
          if (targets != null) {
            if (targets.containsKey('goal')) {
              await prefs.setString('user_goal', targets['goal']);
            }
            if (targets.containsKey('targetPercentage')) {
              await prefs.setDouble('user_target_percentage',
                  (targets['targetPercentage'] as num).toDouble());
            }
            if (targets.containsKey('tutorMode')) {
              await prefs.setString(
                  'user_tutor_mode', targets['tutorMode']);
            }
            if (targets.containsKey('urgency')) {
              final urgency = targets['urgency'] as String;
              await prefs.setString('user_urgency', urgency);
              ref.read(themeProvider.notifier).updateUrgency(urgency);
            }
          }
        }
      }

      final progressSnap = await FirebaseFirestore.instance
          .collection('user_progress')
          .doc(user.uid)
          .collection('subjects')
          .get();

      for (final doc in progressSnap.docs) {
        final subjectData = doc.data();
        final chapters = subjectData['chapters'] as List<dynamic>?;
        if (chapters != null) {
          for (final chapter in chapters) {
            final cId = chapter['id'] as String;
            final cStatus = chapter['status'] as int;
            await prefs.setInt('chapter_status_$cId', cStatus);
          }
        }
      }

      await ref.read(syllabusProvider.notifier).initializeSyllabus();

      if (mounted) {
        setState(() {
          _userName = prefs.getString('user_name') ?? _userName;
          _currentPercent =
              prefs.getDouble('user_percentage') ?? _currentPercent;
          _targetPercent =
              prefs.getDouble('user_target_percentage') ?? _targetPercent;
          _lastSubject = prefs.getString('last_subject') ?? _lastSubject;
          _lastChapter = prefs.getString('last_chapter') ?? _lastChapter;
        });
      }
      ref.read(syncStatusProvider.notifier).setSynced();
    } catch (e) {
      ref.read(syncStatusProvider.notifier).setError();
    }
  }

  Widget _buildSyncIcon() {
    final syncStatus = ref.watch(syncStatusProvider);
    switch (syncStatus) {
      case SyncStatus.syncing:
        return Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor:
                  AlwaysStoppedAnimation<Color>(AppColors.textSecondary),
            ),
          ),
        );
      case SyncStatus.synced:
        return Icon(Icons.cloud_done, color: AppColors.accentDefault, size: 24);
      case SyncStatus.error:
        return
            Icon(Icons.cloud_off, color: Colors.redAccent, size: 24);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = ref.watch(themeProvider);
    final accent = themeColor;
    final themeState = themeColor as ThemeColor;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent, // Background handled by App container (mesh)
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(24.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // -- Header --
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Good morning,',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            _userName,
                            style: textTheme.displaySmall,
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          _buildSyncIcon(),
                          const SizedBox(width: 8),
                          Consumer(
                            builder: (context, ref, child) {
                              final unreadCount =
                                  ref.watch(unreadConversationsProvider).value ?? 0;
                              return Stack(
                                clipBehavior: Clip.none,
                                alignment: Alignment.center,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.forum_outlined,
                                        color: colorScheme.onSurface),
                                    onPressed: () => context.push('/dms'),
                                  ),
                                  if (unreadCount > 0)
                                    Positioned(
                                      right: 8,
                                      top: 8,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: Colors.redAccent,
                                          shape: BoxShape.circle,
                                        ),
                                        constraints: const BoxConstraints(
                                            minWidth: 8, minHeight: 8),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.15, end: 0, curve: Curves.easeOutQuad),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: themeState.urgencyBadgeColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        themeState.urgencyLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 50.ms, duration: 400.ms).slideY(begin: 0.15, end: 0, curve: Curves.easeOutQuad),

                  if (_countdownStr.isNotEmpty) ...
                    [const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.alarm, color: accent, size: 16),
                          const SizedBox(width: 8),
                          Text(_countdownStr,
                              style: textTheme.labelLarge?.copyWith(
                                  color: colorScheme.onSurface)),
                        ],
                      ),
                    ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideY(begin: 0.12, end: 0, curve: Curves.easeOutQuad)],
                  
                  const SizedBox(height: 24),
                  
                  ExamCountdownCard(accentColor: accent)
                      .animate()
                      .fadeIn(delay: 150.ms, duration: 500.ms)
                      .slideY(begin: 0.12, end: 0, curve: Curves.easeOutQuad),
                  
                  const SizedBox(height: 24),
                  
                  // -- XP Ring --
                  Center(
                    child: SizedBox(
                      width: 220,
                      height: 220,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: const Size(220, 220),
                            painter: _DonutChartPainter(
                              percent: _currentPercent,
                              targetPercent: _targetPercent,
                              accentColor: accent,
                              backgroundColor: colorScheme.surfaceVariant,
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${_currentPercent.toInt()}%',
                                style: textTheme.displayMedium?.copyWith(
                                  fontSize: 48,
                                ),
                              ),
                              Text(
                                'Syllabus Mastered',
                                style: textTheme.labelMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 200.ms, duration: 500.ms).scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutQuad),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      deltaLabel(_currentPercent, _targetPercent),
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
                  const SizedBox(height: 32),
                  
                  // -- Continue Where You Left Off --
                  GlassCard(
                    elevation: CardElevation.recessed,
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                          Text(
                            'Continue Where You Left Off',
                            style: textTheme.labelMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(_lastSubject,
                                        style: textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        )),
                                    const SizedBox(height: 4),
                                    Text(_lastChapter,
                                        style: textTheme.bodySmall?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () => context.go('/syllabus'),
                                style: TextButton.styleFrom(
                                  foregroundColor: accent,
                                ),
                                child: const Text('Continue →'),
                              ),
                            ],
                          ),
                        ],
                      ),
                  ).animate().fadeIn(delay: 250.ms, duration: 500.ms).slideY(begin: 0.12, end: 0, curve: Curves.easeOutQuad),
                  
                  const SizedBox(height: 32),
                  
                  // -- Action Buttons --
                  Row(
                    children: [
                      Expanded(
                        child: GlassCard(
                          elevation: CardElevation.standard,
                          padding: EdgeInsets.zero,
                          child: InkWell(
                            onTap: () => context.push('/pomodoro'),
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Column(
                                children: [
                                  Icon(Icons.timer_outlined, color: accent, size: 32),
                                  const SizedBox(height: 8),
                                  Text('Focus', style: textTheme.labelLarge),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GlassCard(
                          elevation: CardElevation.standard,
                          padding: EdgeInsets.zero,
                          child: InkWell(
                            onTap: () => context.push('/tutor'),
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Column(
                                children: [
                                  Icon(Icons.psychology_outlined, color: accent, size: 32),
                                  const SizedBox(height: 8),
                                  Text('AI Tutor', style: textTheme.labelLarge),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GlassCard(
                          elevation: CardElevation.standard,
                          padding: EdgeInsets.zero,
                          child: InkWell(
                            onTap: () => context.push('/leaderboard'),
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Column(
                                children: [
                                  Icon(Icons.leaderboard_outlined, color: accent, size: 32),
                                  const SizedBox(height: 8),
                                  Text('Guilds', style: textTheme.labelLarge),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 300.ms, duration: 500.ms).slideY(begin: 0.12, end: 0, curve: Curves.easeOutQuad),
                  
                  const SizedBox(height: 48),
                  const SizedBox(height: 32),
                  Text(
                    'Recent Activity',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ).animate().fadeIn(delay: 500.ms, duration: 400.ms),
                  const SizedBox(height: 8),
                  FutureBuilder<List<Map<String, String>>>(
                    future: StatsEngine.getRecentActivity(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      }
                      final activities = snapshot.data ?? [];
                      if (activities.isEmpty) {
                        return GlassCard(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.all(24),
                          child: Center(
                              child: Text(
                                'No recent activity yet',
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ),
                        );
                      }
                      return Column(
                        children: activities.map((entry) {
                          final subject = entry['subject'] ?? '';
                          final action = entry['action'] ?? '';
                          final timestamp = entry['timestamp'] ?? '';
                          final timeAgo = _relativeTime(timestamp);
                          final dotColor = _dotColorForSubject(subject);
                          return _buildActivityTile(
                              subject, action, timeAgo, dotColor);
                        }).toList(),
                      );
                    },
                  ).animate().fadeIn(delay: 550.ms, duration: 500.ms).slideY(begin: 0.08, end: 0, curve: Curves.easeOutQuad),
                  const SizedBox(height: 100),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityTile(
      String subject, String chapter, String timeAgo, Color dotColor) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return GlassCard(
      elevation: CardElevation.recessed,
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: EdgeInsets.zero,
      child: ListTile(
        leading: Icon(Icons.circle, size: 12, color: dotColor),
        title: Text(chapter,
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text(subject, style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
        trailing: Text(timeAgo,
            style: textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant)),
      ),
    );
  }

  String _relativeTime(String isoTimestamp) {
    if (isoTimestamp.isEmpty) return '';
    try {
      final dt = DateTime.parse(isoTimestamp);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
      if (diff.inHours < 24) {
        return '${diff.inHours} ${diff.inHours == 1 ? 'hour' : 'hours'} ago';
      }
      final days = diff.inDays;
      if (days < 30) return '$days ${days == 1 ? 'day' : 'days'} ago';
      return DateFormat.yMMMd().format(dt);
    } catch (_) {
      return '';
    }
  }

  Color _dotColorForSubject(String subject) {
    final lower = subject.toLowerCase();
    if (lower.contains('physics')) return Colors.blue;
    if (lower.contains('math') || lower.contains('algebra')) {
      return Colors.purple;
    }
    if (lower.contains('chemistry')) return Colors.teal;
    if (lower.contains('biology')) return Colors.green;
    if (lower.contains('focus') || lower.contains('timer')) {
      return Colors.orange;
    }
    if (lower.contains('flash')) return Colors.amber;
    if (lower.contains('tutor') || lower.contains('ai')) return Colors.cyan;
    // Deterministic fallback based on subject hash.
    final colors = [
      Colors.indigo,
      Colors.pink,
      Colors.deepOrange,
      Colors.lightBlue,
      Colors.lime,
    ];
    return colors[subject.hashCode.abs() % colors.length];
  }
}

class _DonutChartPainter extends CustomPainter {
  final double percent;
  final double targetPercent;
  final Color accentColor;
  final Color backgroundColor;

  const _DonutChartPainter({
    required this.percent,
    required this.targetPercent,
    required this.accentColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 24) / 2;
    
    // Background track
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16;
    canvas.drawCircle(center, radius, backgroundPaint);

    // Gradient Sweep for progress
    final sweepAngle = (percent / 100) * 2 * math.pi;
    final gradient = SweepGradient(
      colors: [accentColor.withOpacity(0.2), accentColor],
      stops: const [0.0, 1.0],
      startAngle: -math.pi / 2,
      endAngle: -math.pi / 2 + sweepAngle,
      tileMode: TileMode.clamp,
    );
    
    final progressPaint = Paint()
      ..shader = gradient.createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;
      
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );

    // Target marker
    final targetAngle = -math.pi / 2 + (targetPercent / 100) * 2 * math.pi;
    final markerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final markerOuterRadius = radius + 12;
    final markerInnerRadius = radius - 12;
    
    final p1 = Offset(
      center.dx + markerInnerRadius * math.cos(targetAngle),
      center.dy + markerInnerRadius * math.sin(targetAngle),
    );
    final p2 = Offset(
      center.dx + markerOuterRadius * math.cos(targetAngle),
      center.dy + markerOuterRadius * math.sin(targetAngle),
    );
    
    canvas.drawLine(p1, p2, markerPaint);
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) =>
      oldDelegate.percent != percent ||
      oldDelegate.targetPercent != targetPercent ||
      oldDelegate.accentColor != accentColor ||
      oldDelegate.backgroundColor != backgroundColor;
}
