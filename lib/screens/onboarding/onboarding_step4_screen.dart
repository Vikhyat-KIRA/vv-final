import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in_all_platforms/google_sign_in_all_platforms.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import '../../theme/colors.dart';
import '../../widgets/step_indicator.dart';
import '../../providers/theme_provider.dart';
import '../../providers/sync_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';

import 'package:confetti/confetti.dart';
import '../../services/gamification_service.dart';

class OnboardingStep4Screen extends ConsumerStatefulWidget {
  const OnboardingStep4Screen({super.key});

  @override
  ConsumerState<OnboardingStep4Screen> createState() => _OnboardingStep4ScreenState();
}

class _OnboardingStep4ScreenState extends ConsumerState<OnboardingStep4Screen> {
  String _selectedStorage = 'drive'; // 'drive' or 'local'
  bool _isLoading = false;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _handleComplete() async {
    setState(() => _isLoading = true);

    if (_selectedStorage == 'drive') {
      try {
        final googleSignIn = GoogleSignIn(
          params: GoogleSignInParams(
            clientId: '773443742576-rab15ntpgmeeffg9isalt55pamcqstc3.apps.googleusercontent.com',
            clientSecret: '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',
            redirectPort: 3000,
            scopes: [drive.DriveApi.driveFileScope],
          ),
        );
        
        final credentials = await googleSignIn.signIn();
        
        if (credentials == null) {
          // User canceled sign in, let them try again or switch to local
          setState(() => _isLoading = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Google Drive access is required for Cloud Sync. Please sign in or choose Local Storage.'),
                backgroundColor: AppColors.error,
              ),
            );
          }
          return;
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to connect to Google Drive: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }
    }


    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('storage_preference', _selectedStorage);
    await prefs.setBool('onboarding_complete', true);

    // Sync to Firebase
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      ref.read(syncStatusProvider.notifier).setSyncing();
      try {
        final displayName = prefs.getString('user_name') ?? '';
        final username = await FirestoreService().generateUniqueUsername(displayName);

        final profileData = {
          'name': displayName,
          'grade': prefs.getString('user_grade') ?? '',
          'board': prefs.getString('user_board') ?? '',
          'username': username,
          'usernameUpdatedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        final currentPercent = prefs.getDouble('user_percentage') ?? 0.0;
        final metricsData = {
          'currentPercentage': currentPercent,
          'statusBadge': prefs.getString('user_status_badge') ?? '',
          'updatedAt': FieldValue.serverTimestamp(),
        };

        final targetsData = {
          'goal': prefs.getString('user_goal') ?? '',
          'targetPercentage': prefs.getDouble('user_target_percentage') ?? 90.0,
          'tutorMode': prefs.getString('user_tutor_mode') ?? 'general',
          'urgency': prefs.getString('user_urgency') ?? 'calm',
          'updatedAt': FieldValue.serverTimestamp(),
        };

        await FirestoreService().saveUserProfile(user.uid, profileData);
        ref.read(authProvider.notifier).refreshUsername(username);
        await FirestoreService().saveUserMetrics(user.uid, metricsData);
        await FirestoreService().saveUserTargets(user.uid, targetsData);

        ref.read(syncStatusProvider.notifier).setSynced();
      } catch (e) {
        ref.read(syncStatusProvider.notifier).setError();
      }
    }

    if (mounted) {
      _confettiController.play();
      GamificationService().playSuccessSound();
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        context.go('/dashboard');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = ref.watch(themeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SafeArea(
            child: _isLoading 
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: accent),
                SizedBox(height: 16),
                Text('Finalizing Setup...', style: TextStyle(color: AppColors.textPrimary, fontFamily: 'Playfair Display')),
              ],
            ),
          )
        : SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Expanded(
                      child: StepIndicator(totalSteps: 4, currentIndex: 3),
                    ),
                    SizedBox(width: 48),
                  ],
                ),
                SizedBox(height: 24),
                
                Text(
                  'Vault Storage Setup',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontFamily: 'Playfair Display',
                        fontSize: 26,
                        color: AppColors.textPrimary,
                      ),
                ),
                SizedBox(height: 8),
                Text(
                  'Where should we store your study materials, PDFs, and generated notes?',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
                SizedBox(height: 32),

                // Cloud Sync Card
                GestureDetector(
                  onTap: () => setState(() => _selectedStorage = 'drive'),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _selectedStorage == 'drive' ? accent.withAlpha(30) : AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _selectedStorage == 'drive' ? accent : AppColors.surface2,
                        width: _selectedStorage == 'drive' ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.cloud_sync, color: _selectedStorage == 'drive' ? accent : AppColors.textSecondary),
                            SizedBox(width: 12),
                            Text(
                              'Cloud Sync (Recommended)',
                              style: TextStyle(
                                fontFamily: 'Playfair Display',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Securely store your files in a hidden "VidyaVerse Vault" folder in your personal Google Drive. Access your study materials from any device for free, using your 15 GB quota.',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ),
                
                SizedBox(height: 16),

                // Local Only Card
                GestureDetector(
                  onTap: () => setState(() => _selectedStorage = 'local'),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _selectedStorage == 'local' ? accent.withAlpha(30) : AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _selectedStorage == 'local' ? accent : AppColors.surface2,
                        width: _selectedStorage == 'local' ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.phone_android, color: _selectedStorage == 'local' ? accent : AppColors.textSecondary),
                            SizedBox(width: 12),
                            Text(
                              'Local Storage Only',
                              style: TextStyle(
                                fontFamily: 'Playfair Display',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Save files directly to this device\'s internal storage. Fast and private, but files cannot be accessed on other devices and will be permanently lost if you uninstall the app.',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                        ),
                        if (_selectedStorage == 'local') ...[
                          SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.error.withAlpha(20),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.error.withAlpha(50)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Warning: Data cannot be recovered if the app is deleted.',
                                    style: TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 48),

                // Complete Button
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _handleComplete,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: AppColors.background,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Complete Setup',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 24),
              ],
            ),
          ),
        ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
            ),
          ),
        ],
      ),
    );
  }
}
