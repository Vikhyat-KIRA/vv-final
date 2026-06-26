import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_mode_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/syllabus_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/stats_engine.dart';
import '../../theme/colors.dart';
import '../../widgets/custom_text_field.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final String? uid;
  const ProfileScreen({super.key, this.uid});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  UserModel? _profileUser;
  bool _isLoading = true;
  int _chaptersCompleted = 0;
  double _focusHours = 12.5;
  int _dayStreak = 4;
  int _localXp = 0;
  String _tutorMode = 'general';
  Map<String, double> _publicSubjectProgress = {};

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  @override
  void didUpdateWidget(ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uid != widget.uid) {
      _loadProfileData();
    }
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
    });

    final currentUser = ref.read(authProvider);
    final isPrivate = widget.uid == null || widget.uid == currentUser?.uid;

    final prefs = await SharedPreferences.getInstance();
    _tutorMode = prefs.getString('user_tutor_mode') ?? 'general';
    _dayStreak = prefs.getInt('user_streak') ?? 1;

    if (isPrivate) {
      _profileUser = currentUser;
      if (currentUser != null) {
        // Fetch local dynamic stats from StatsEngine
        final stats = await StatsEngine.getStats();
        _chaptersCompleted = stats['chaptersCompleted'] ?? 0;
        final int focusMins = stats['focusMinutes'] ?? 0;
        _focusHours = focusMins / 60.0;
        _localXp = stats['totalXp'] ?? 0;
      }
    } else {
      // Public profile mode
      try {
        final doc = await FirestoreService().getUserData(widget.uid!);
        if (doc.exists) {
          final data = doc.data();
          final profile = data?['profile'] as Map<String, dynamic>?;
          final metrics = data?['metrics'] as Map<String, dynamic>?;

          if (profile != null) {
            _profileUser = UserModel(
              uid: widget.uid!,
              email: '', // Hide email publicly
              displayName: profile['name'] ?? 'Learner',
              photoUrl: profile['photoUrl'] ?? 'https://api.dicebear.com/7.x/bottts/svg?seed=${widget.uid}',
              level: metrics?['level'] ?? 1,
              xp: metrics?['xp'] ?? 0,
              enrolledSubjects: List<String>.from(profile['enrolledSubjects'] ?? []),
              username: profile['username'] ?? '',
              grade: profile['grade'] ?? '',
              board: profile['board'] ?? '',
            );

            _chaptersCompleted = await FirestoreService().getChaptersCompletedCount(widget.uid!);
            _focusHours = (metrics?['focusHours'] ?? 8.0) as double;
            _dayStreak = (metrics?['dayStreak'] ?? 2) as int;

            // Fetch subject progress for public user
            final progressSnap = await FirebaseFirestore.instance
                .collection('user_progress')
                .doc(widget.uid)
                .collection('subjects')
                .get();

            final Map<String, double> progressMap = {};
            for (final doc in progressSnap.docs) {
              final sData = doc.data();
              final sId = sData['subjectId'] as String?;
              final sPercent = (sData['completionPercent'] as num?)?.toDouble() ?? 0.0;
              if (sId != null) {
                progressMap[sId] = sPercent;
              }
            }
            _publicSubjectProgress = progressMap;
          }
        }
      } catch (e) {
        debugPrint('Error loading public profile data: $e');
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = ref.watch(themeProvider);
    final currentUser = ref.watch(authProvider);
    final isPrivate = widget.uid == null || widget.uid == currentUser?.uid;

    // If private, sync to the latest state from authProvider
    final user = isPrivate ? currentUser : _profileUser;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(accent),
          ),
        ),
      );
    }

    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Profile'),
          backgroundColor: AppColors.background,
        ),
        body: const Center(
          child: Text('User details could not be found.'),
        ),
      );
    }

    final initial = user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : 'L';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          isPrivate ? 'My Profile' : 'Public Profile',
          style: const TextStyle(
            fontFamily: 'Space Grotesk',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: !isPrivate
            ? IconButton(
                icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
                onPressed: () => context.pop(),
              )
            : null,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.only(left: 24.0, right: 24.0, top: 16.0, bottom: 16.0 + MediaQuery.of(context).padding.bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Profile Header
            Center(
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: accent.withAlpha(50),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 54,
                      backgroundColor: accent,
                      child: CircleAvatar(
                        radius: 51,
                        backgroundColor: AppColors.surface,
                        child: Text(
                          initial,
                          style: TextStyle(
                            fontFamily: 'Space Grotesk',
                            fontWeight: FontWeight.bold,
                            fontSize: 40,
                            color: accent,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.displayName,
                    style: TextStyle(
                      fontFamily: 'Space Grotesk',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.username.isNotEmpty ? '@${user.username}' : 'No username set',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (user.grade.isNotEmpty || user.board.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (user.grade.isNotEmpty)
                          _buildHeaderChip(user.grade),
                        if (user.grade.isNotEmpty && user.board.isNotEmpty)
                          const SizedBox(width: 8),
                        if (user.board.isNotEmpty)
                          _buildHeaderChip(user.board),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 2. XP & Rank Progress Bar
            Text(
              '${user.rank} Tier',
              style: TextStyle(
                fontFamily: 'Space Grotesk',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: accent,
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: user.levelProgress,
                backgroundColor: AppColors.surface2,
                valueColor: AlwaysStoppedAnimation<Color>(accent),
                minHeight: 12,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'XP: ${isPrivate ? _localXp : user.xp}',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  'Next Tier: ${user.nextLevelXp} XP',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // 3. Stats Grid
            Text(
              'Academic Stats',
              style: TextStyle(
                fontFamily: 'Space Grotesk',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.4,
              children: [
                _buildStatCard(
                  Icons.stars_rounded,
                  '${isPrivate ? _localXp : user.xp}',
                  'Total XP',
                  accent,
                ),
                _buildStatCard(
                  Icons.menu_book_rounded,
                  '$_chaptersCompleted',
                  'Chapters Done',
                  accent,
                ),
                _buildStatCard(
                  Icons.timer_rounded,
                  '${_focusHours.toStringAsFixed(1)}h',
                  'Focus Hours',
                  accent,
                ),
                _buildStatCard(
                  Icons.local_fire_department_rounded,
                  '$_dayStreak d',
                  'Day Streak',
                  accent,
                ),
              ],
            ),
            const SizedBox(height: 32),

            // 4. Subject Completion Bars
            Text(
              'Subject Progress',
              style: TextStyle(
                fontFamily: 'Space Grotesk',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildSubjectProgressList(isPrivate, user, accent),
            const SizedBox(height: 32),

            // 5. Achievements Grid
            Text(
              'Unlocked Achievements',
              style: TextStyle(
                fontFamily: 'Space Grotesk',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildAchievementsGrid(user, isPrivate),
            const SizedBox(height: 32),

            // 6. Settings Card (Private Mode Only)
            if (isPrivate) ...[
              Text(
                'Settings & Preferences',
                style: TextStyle(
                  fontFamily: 'Space Grotesk',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _buildSettingsCard(context, user, accent),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          fontSize: 11,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label, Color accent) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: accent, size: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Space Grotesk',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectProgressList(bool isPrivate, UserModel user, Color accent) {
    if (isPrivate) {
      final localSubjects = ref.watch(syllabusProvider);
      if (localSubjects.isEmpty) {
        return _buildNoSubjectsWidget();
      }
      return Column(
        children: localSubjects.map((subject) {
          return _buildSubjectProgressItem(
            subject.name,
            subject.completionPercent,
            accent,
          );
        }).toList(),
      );
    } else {
      if (user.enrolledSubjects.isEmpty) {
        return _buildNoSubjectsWidget();
      }
      return Column(
        children: user.enrolledSubjects.map((subName) {
          // Check public subjects map by matching name or ID
          final cleanKey = subName.replaceAll(' ', '').toLowerCase();
          double percent = 0.0;
          _publicSubjectProgress.forEach((key, val) {
            if (key.replaceAll(' ', '').toLowerCase() == cleanKey) {
              percent = val;
            }
          });
          return _buildSubjectProgressItem(subName, percent, accent);
        }).toList(),
      );
    }
  }

  Widget _buildNoSubjectsWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: Text(
          'No enrolled subjects found.',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectProgressItem(String name, double percent, Color accent) {
    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.border),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${percent.toInt()}%',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percent / 100.0,
                backgroundColor: AppColors.surface2,
                valueColor: AlwaysStoppedAnimation<Color>(accent),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementsGrid(UserModel user, bool isPrivate) {
    final achievements = [
      _Achievement(
        '🚀',
        'Quantum Cadet',
        'Profile Setup Complete',
        true,
      ),
      _Achievement(
        '📚',
        'First Milestone',
        'Completed first chapter',
        _chaptersCompleted >= 1,
      ),
      _Achievement(
        '🔥',
        '7-Day Streak',
        'Study 7 days in a row',
        _dayStreak >= 7,
      ),
      _Achievement(
        '🧠',
        'Scholar Tier',
        'Reach 500+ total XP',
        (isPrivate ? _localXp : user.xp) >= 500,
      ),
      _Achievement(
        '👑',
        'Mastery Mindset',
        'Reach 5000+ total XP',
        (isPrivate ? _localXp : user.xp) >= 5000,
      ),
      _Achievement(
        '⚡',
        'Deep Focus',
        'Log 20+ Focus Hours',
        _focusHours >= 20.0,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.82,
      ),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        final ach = achievements[index];
        return Opacity(
          opacity: ach.unlocked ? 1.0 : 0.35,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: ach.unlocked ? AppColors.accentDefault : AppColors.border,
                width: ach.unlocked ? 1.2 : 1.0,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  ach.icon,
                  style: const TextStyle(fontSize: 28),
                ),
                const SizedBox(height: 8),
                Text(
                  ach.title,
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  ach.description,
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 9,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingsCard(BuildContext context, UserModel user, Color accent) {
    return Card(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.border),
      ),
      elevation: 0,
      child: Column(
        children: [
          // Edit Profile
          ListTile(
            leading: Icon(Icons.edit_rounded, color: accent),
            title: Text(
              'Edit Profile',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: Text(
              'Update display name and unique username',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary),
            onTap: () => _showEditProfileBottomSheet(context, user),
          ),
          Divider(color: AppColors.border, height: 1),
          // Tutor Mode Toggle
          ListTile(
            leading: Icon(Icons.psychology_rounded, color: accent),
            title: Text(
              'Tutor Mode',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: Text(
              _tutorMode == 'general' ? 'General Coach Mode active' : 'Strict Syllabus Mode active',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            trailing: Text(
              _tutorMode == 'general' ? 'General' : 'Strict',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.bold,
                color: accent,
              ),
            ),
            onTap: () => _showTutorModeDialog(context, user),
          ),
          Divider(color: AppColors.border, height: 1),
          // Dark Mode Toggle Switch
          Consumer(
            builder: (context, ref, child) {
              final themeMode = ref.watch(themeModeProvider);
              final isDark = themeMode == ThemeMode.dark ||
                  (themeMode == ThemeMode.system && Theme.of(context).brightness == Brightness.dark);
              return SwitchListTile(
                title: Text(
                  'Dark Mode',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  themeMode == ThemeMode.system ? 'System Default' : 'Manual Toggle',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                secondary: Icon(
                  isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  color: accent,
                ),
                value: isDark,
                activeThumbColor: accent,
                onChanged: (val) {
                  ref.read(themeModeProvider.notifier).toggleThemeMode(val);
                },
              );
            },
          ),
          Divider(color: AppColors.border, height: 1),
          // Accent Choice List Tile
          Consumer(
            builder: (context, ref, child) {
              final themeMode = ref.watch(themeModeProvider);
              final isDark = themeMode == ThemeMode.dark ||
                  (themeMode == ThemeMode.system && Theme.of(context).brightness == Brightness.dark);
              final accentChoice = ref.watch(accentChoiceProvider);
              return ListTile(
                leading: Icon(Icons.palette_rounded, color: accent),
                title: Text(
                  'Accent Palette',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  accentChoice == 'emerald' ? 'Emerald Green' : 'Sapphire Blue',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => ref.read(accentChoiceProvider.notifier).setAccentChoice('emerald'),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: accentChoice == 'emerald' ? AppColors.textPrimary : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => ref.read(accentChoiceProvider.notifier).setAccentChoice('sapphire'),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: accentChoice == 'sapphire' ? AppColors.textPrimary : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Divider(color: AppColors.border, height: 1),
          ListTile(
            leading: Icon(Icons.notifications_active_rounded, color: accent),
            title: Text(
              'Notification Settings',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: Text(
              'Configure reminders, countdown alerts, and messages',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary),
            onTap: () => context.push('/settings'),
          ),
          Divider(color: AppColors.border, height: 1),
          // Sign Out
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            title: const Text(
              'Sign Out',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.bold,
                color: Colors.redAccent,
              ),
            ),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.redAccent),
            onTap: () {
              ref.read(authProvider.notifier).logout();
              context.go('/auth');
            },
          ),
        ],
      ),
    );
  }

  void _showEditProfileBottomSheet(BuildContext context, UserModel user) {
    final nameController = TextEditingController(text: user.displayName);
    final usernameController = TextEditingController(text: user.username);
    bool isSaving = false;
    String errorMessage = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final accent = ref.watch(themeProvider);

            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Edit Profile',
                        style: TextStyle(
                          fontFamily: 'Space Grotesk',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: AppColors.textSecondary),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    controller: nameController,
                    labelText: 'Display Name',
                    hintText: 'Enter display name',
                    prefixIcon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: usernameController,
                    labelText: 'Username',
                    hintText: 'Enter unique username',
                    prefixIcon: Icons.alternate_email_rounded,
                  ),
                  if (errorMessage.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      errorMessage,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        color: Colors.redAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            final newName = nameController.text.trim();
                            final newUsername = usernameController.text.trim().toLowerCase();

                            if (newName.isEmpty || newUsername.isEmpty) {
                              setSheetState(() {
                                errorMessage = 'All fields are required.';
                              });
                              return;
                            }

                            setSheetState(() {
                              isSaving = true;
                              errorMessage = '';
                            });

                            try {
                              // 1. Update Display Name if changed
                              if (newName != user.displayName) {
                                await FirestoreService().saveUserProfile(user.uid, {'name': newName});
                              }

                              // 2. Update Username if changed (updateUsername enforces 30-day cooldown and uniqueness)
                              if (newUsername != user.username) {
                                await FirestoreService().updateUsername(user.uid, newUsername);
                              }

                              // Refresh authentication state
                              await ref.read(authProvider.notifier).refresh();

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Profile updated successfully!'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                Navigator.of(context).pop();
                              }
                            } catch (e) {
                              setSheetState(() {
                                isSaving = false;
                                errorMessage = e.toString().replaceFirst('Exception: ', '');
                              });
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: AppColors.background,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showTutorModeDialog(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (ctx) {
        final accent = ref.watch(themeProvider);

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: AppColors.border),
              ),
              title: Text(
                'AI Tutor Mode',
                style: TextStyle(
                  fontFamily: 'Space Grotesk',
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      setDialogState(() {
                        _tutorMode = 'general';
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: _tutorMode == 'general' ? accent.withAlpha(20) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _tutorMode == 'general' ? accent : AppColors.border,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _tutorMode == 'general' ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                            color: _tutorMode == 'general' ? accent : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '🧭 General Coach',
                                  style: TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Compassionate, comprehensive study help.',
                                  style: TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {
                      setDialogState(() {
                        _tutorMode = 'strict';
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: _tutorMode == 'strict' ? accent.withAlpha(20) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _tutorMode == 'strict' ? accent : AppColors.border,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _tutorMode == 'strict' ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                            color: _tutorMode == 'strict' ? accent : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '📚 Strict Syllabus',
                                  style: TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Locked to your board/curriculum boundaries only.',
                                  style: TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('user_tutor_mode', _tutorMode);
                    await FirestoreService().saveUserTargets(user.uid, {'tutorMode': _tutorMode});

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('AI Tutor mode updated to ${_tutorMode == 'general' ? 'General Coach' : 'Strict Syllabus'}!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      Navigator.of(context).pop();
                      setState(() {});
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: AppColors.background,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _Achievement {
  final String icon;
  final String title;
  final String description;
  final bool unlocked;

  _Achievement(this.icon, this.title, this.description, this.unlocked);
}
