import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/notification_service.dart';
import '../../theme/colors.dart';
import '../../providers/theme_provider.dart';
import '../../providers/theme_mode_provider.dart';
import '../../providers/theme_style_provider.dart';
import '../../widgets/glass_card.dart';
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _dailyReminder = true;
  String _dailyReminderTime = '19:00';
  bool _examAlerts = true;
  bool _streakReminders = true;
  bool _xpNotifications = true;
  bool _guildMessages = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _dailyReminder = prefs.getBool('pref_daily_reminder') ?? true;
      _dailyReminderTime = prefs.getString('pref_daily_reminder_time') ?? '19:00';
      _examAlerts = prefs.getBool('pref_exam_alerts') ?? true;
      _streakReminders = prefs.getBool('pref_streak_reminders') ?? true;
      _xpNotifications = prefs.getBool('pref_xp_notifications') ?? true;
      _guildMessages = prefs.getBool('pref_guild_messages') ?? true;
      _isLoading = false;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    _updateNotificationScheduling();
  }

  Future<void> _updateNotificationScheduling() async {
    final prefs = await SharedPreferences.getInstance();
    final dailyEnabled = prefs.getBool('pref_daily_reminder') ?? true;
    final timeStr = prefs.getString('pref_daily_reminder_time') ?? '19:00';
    final examEnabled = prefs.getBool('pref_exam_alerts') ?? true;

    final name = prefs.getString('user_name') ?? 'Learner';
    
    if (dailyEnabled) {
      final parts = timeStr.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      await NotificationService.scheduleDailyReminder(
        name,
        'Physics Board Exam',
        15,
        customTime: TimeOfDay(hour: hour, minute: minute),
      );
    } else {
      await NotificationService.cancelDailyReminder();
    }

    if (examEnabled) {
      final examDate = DateTime.now().add(const Duration(days: 15));
      await NotificationService.scheduleExamAlerts(examDate, 'Physics Board Exam');
    } else {
      await NotificationService.cancelExamAlerts();
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final parts = _dailyReminderTime.split(':');
    final initialTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        final accent = ref.read(themeProvider);
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: accent,
              primary: accent,
              onPrimary: AppColors.background,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
            timePickerTheme: TimePickerThemeData(
              dialHandColor: accent,
              hourMinuteTextColor: AppColors.textPrimary,
              dayPeriodTextColor: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formattedTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pref_daily_reminder_time', formattedTime);
      setState(() {
        _dailyReminderTime = formattedTime;
      });
      _updateNotificationScheduling();
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = ref.watch(themeProvider);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text(
            'Settings',
            style: TextStyle(fontFamily: 'Playfair Display', fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppColors.background,
        ),
        body: Center(
          child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(accent)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontFamily: 'Playfair Display', fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        children: [
          // ── Appearance Section ──
          Text(
            'Appearance',
            style: TextStyle(
              fontFamily: 'Playfair Display',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Customize the look and feel of VidyaVerse.',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          GlassCard(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Theme Style',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Builder(
                  builder: (context) {
                    final currentStyle = ref.watch(themeStyleProvider);
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ThemeStyle.values.map((style) {
                          final isSelected = currentStyle == style;
                          final accent = ref.watch(themeProvider);
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(style.name),
                              selected: isSelected,
                              selectedColor: accent.withOpacity(0.2),
                              onSelected: (selected) {
                                if (selected) {
                                  ref.read(themeStyleProvider.notifier).setThemeStyle(style);
                                }
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Divider(color: AppColors.border, height: 1),
                const SizedBox(height: 16),
                Text(
                  'Accent Palette',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Builder(
                    builder: (context) {
                      final currentAccent = ref.watch(accentChoiceProvider);
                      const palettes = <String, Color>{
                        'emerald': Color(0xFF10B981),
                        'sapphire': Color(0xFF3B82F6),
                        'ruby': Color(0xFFEF4444),
                        'amethyst': Color(0xFF8B5CF6),
                        'amber': Color(0xFFF59E0B),
                      };
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: palettes.entries.map((entry) {
                          final isSelected = currentAccent == entry.key;
                          return GestureDetector(
                            onTap: () {
                              ref.read(accentChoiceProvider.notifier).setAccentChoice(entry.key);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: entry.value,
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(color: Colors.white, width: 2.5)
                                    : null,
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: entry.value.withOpacity(0.5),
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                                  : null,
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Divider(color: AppColors.border, height: 1),
                  Builder(
                    builder: (context) {
                      final themeMode = ref.watch(themeModeProvider);
                      final isDark = themeMode == ThemeMode.dark;
                      return SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Dark Mode',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          isDark ? 'Dark theme is active' : 'Light theme is active',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                        value: isDark,
                        activeThumbColor: accent,
                        onChanged: (val) {
                          ref.read(themeModeProvider.notifier).toggleThemeMode(val);
                        },
                      );
                    },
                  ),
                ],
              ),
          ),
          const SizedBox(height: 32),

          // ── Notifications & Alerts Section ──
          Text(
            'Notifications & Alerts',
            style: TextStyle(
              fontFamily: 'Playfair Display',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Control how and when Vidyaverse reminds you to study.',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          GlassCard(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                  SwitchListTile(
                    title: const Text(
                      'Daily Study Reminder',
                      style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Reminds you to grind daily at $_dailyReminderTime',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                    value: _dailyReminder,
                    activeThumbColor: accent,
                    onChanged: (val) {
                      setState(() {
                        _dailyReminder = val;
                      });
                      _saveSetting('pref_daily_reminder', val);
                    },
                  ),
                  if (_dailyReminder) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0, bottom: 12.0, right: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Reminder Time',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _selectTime(context),
                            icon: Icon(Icons.access_time_rounded, size: 16, color: accent),
                            label: Text(
                              _dailyReminderTime,
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AppColors.border),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  Divider(color: AppColors.border, height: 1),
                  SwitchListTile(
                    title: const Text(
                      'Exam Countdown Alerts',
                      style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Alerts 7 days, 3 days, and 1 day before exams',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                    value: _examAlerts,
                    activeThumbColor: accent,
                    onChanged: (val) {
                      setState(() {
                        _examAlerts = val;
                      });
                      _saveSetting('pref_exam_alerts', val);
                    },
                  ),
                  Divider(color: AppColors.border, height: 1),
                  SwitchListTile(
                    title: const Text(
                      'Streak Reminders',
                      style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Warns you if your streak is about to break',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                    value: _streakReminders,
                    activeThumbColor: accent,
                    onChanged: (val) {
                      setState(() {
                        _streakReminders = val;
                      });
                      _saveSetting('pref_streak_reminders', val);
                    },
                  ),
                  Divider(color: AppColors.border, height: 1),
                  SwitchListTile(
                    title: const Text(
                      'XP & Milestone Alerts',
                      style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Get notified when you earn XP and reach milestones',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                    value: _xpNotifications,
                    activeThumbColor: accent,
                    onChanged: (val) {
                      setState(() {
                        _xpNotifications = val;
                      });
                      _saveSetting('pref_xp_notifications', val);
                    },
                  ),
                  Divider(color: AppColors.border, height: 1),
                  SwitchListTile(
                    title: const Text(
                      'Guild Messages',
                      style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Notifications for new messages in joined guilds',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                    value: _guildMessages,
                    activeThumbColor: accent,
                    onChanged: (val) {
                      setState(() {
                        _guildMessages = val;
                      });
                      _saveSetting('pref_guild_messages', val);
                    },
                  ),
                ],
              ),
          ),
        ],
      ),
    );
  }
}
