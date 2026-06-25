import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/colors.dart';
import '../../widgets/step_indicator.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/delta_display.dart';
import '../../providers/theme_provider.dart';
import '../../providers/sync_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';

class OnboardingStep3Screen extends ConsumerStatefulWidget {
  const OnboardingStep3Screen({super.key});

  @override
  ConsumerState<OnboardingStep3Screen> createState() => _OnboardingStep3ScreenState();
}

class _OnboardingStep3ScreenState extends ConsumerState<OnboardingStep3Screen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _goalController = TextEditingController();
  double _targetPercent = 90.0;
  String _tutorMode = 'general'; // 'general' or 'strict'

  late AnimationController _pulseController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(_pulseController);
  }

  @override
  void dispose() {
    _goalController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleLaunch() async {
    final goalText = _goalController.text.trim();
    if (goalText.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final currentPercent = prefs.getDouble('user_percentage') ?? 0.0;
    final delta = _targetPercent - currentPercent;

    String urgency;
    if (delta > 30) {
      urgency = 'critical';
    } else if (delta >= 15) {
      urgency = 'high';
    } else {
      urgency = 'calm';
    }

    // Save configuration variables locally
    await prefs.setString('user_goal', goalText);
    await prefs.setDouble('user_target_percentage', _targetPercent);
    await prefs.setString('user_tutor_mode', _tutorMode);
    await prefs.setString('user_urgency', urgency);

    // Update global AccentColorProvider (themeProvider)
    ref.read(themeProvider.notifier).updateUrgency(urgency);

    if (mounted) {
      context.push('/onboarding/step4');
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = ref.watch(themeProvider);

    final goalFilled = _goalController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header with Back and StepIndicator
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    const Expanded(
                      child: StepIndicator(totalSteps: 4, currentIndex: 2),
                    ),
                    SizedBox(width: 48),
                  ],
                ),
                SizedBox(height: 24),
                
                // Title
                Text(
                  'Set Your Endgame',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontFamily: 'Playfair Display',
                        fontSize: 26,
                      ),
                ),
                SizedBox(height: 24),

                // Core Goal Input
                CustomTextField(
                  controller: _goalController,
                  labelText: 'Your Core Goal',
                  hintText: 'e.g., Rank 1, Crack JEE, Master Physics',
                  prefixIcon: Icons.outlined_flag,
                  onChanged: (_) => setState(() {}),
                ),
                SizedBox(height: 24),

                // Target Percentage Slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Target Overall Percentage',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: accent.withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: accent.withAlpha(80)),
                      ),
                      child: Text(
                        '${_targetPercent.toInt()}%',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: accent,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Slider(
                  value: _targetPercent,
                  min: 0,
                  max: 100,
                  divisions: 100,
                  label: '${_targetPercent.toInt()}%',
                  activeColor: accent,
                  thumbColor: accent,
                  inactiveColor: AppColors.surface2,
                  onChanged: (val) {
                    setState(() {
                      _targetPercent = val;
                    });
                  },
                ),
                SizedBox(height: 4),
                // Live Delta Widget
                DeltaDisplay(targetPercentage: _targetPercent),
                SizedBox(height: 32),

                // Tutor Mode Selector
                Text(
                  'Choose Your AI Tutor Mode',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    // General Coach Card
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _tutorMode = 'general';
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                          padding: const EdgeInsets.all(16),
                          transform: Matrix4.diagonal3Values(
                            _tutorMode == 'general' ? 1.02 : 1.0,
                            _tutorMode == 'general' ? 1.02 : 1.0,
                            1.0,
                          ),
                          decoration: BoxDecoration(
                            color: _tutorMode == 'general'
                                ? accent.withAlpha(30)
                                : AppColors.surface2,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _tutorMode == 'general' ? accent : AppColors.surface2,
                              width: _tutorMode == 'general' ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '🧭 General Coach',
                                style: TextStyle(
                                  fontFamily: 'Playfair Display',
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Ask anything. Wide academic companion.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    // Strict Syllabus Card
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _tutorMode = 'strict';
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                          padding: const EdgeInsets.all(16),
                          transform: Matrix4.diagonal3Values(
                            _tutorMode == 'strict' ? 1.02 : 1.0,
                            _tutorMode == 'strict' ? 1.02 : 1.0,
                            1.0,
                          ),
                          decoration: BoxDecoration(
                            color: _tutorMode == 'strict'
                                ? accent.withAlpha(30)
                                : AppColors.surface2,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _tutorMode == 'strict' ? accent : AppColors.surface2,
                              width: _tutorMode == 'strict' ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '📚 Strict Syllabus',
                                style: TextStyle(
                                  fontFamily: 'Playfair Display',
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Locked to your board and chapters only.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 48),

                // Pulsing Launch Button
                AnimatedBuilder(
                  animation: _glowAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: goalFilled ? 1.0 : 0.4,
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: goalFilled
                              ? [
                                  BoxShadow(
                                    color: accent.withAlpha((0.4 * _glowAnimation.value * 255).round()),
                                    blurRadius: 16,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: ElevatedButton(
                          onPressed: goalFilled ? _handleLaunch : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accent,
                            foregroundColor: AppColors.background,
                            disabledBackgroundColor: AppColors.surface2,
                            disabledForegroundColor: AppColors.textSecondary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Launch VidyaVerse →',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
