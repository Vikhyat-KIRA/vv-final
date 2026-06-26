import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import '../../theme/colors.dart';
import '../../widgets/step_indicator.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_dropdown.dart';
import '../../widgets/glow_button.dart';

class OnboardingStep1Screen extends StatefulWidget {
  const OnboardingStep1Screen({super.key});

  @override
  State<OnboardingStep1Screen> createState() => _OnboardingStep1ScreenState();
}

class _OnboardingStep1ScreenState extends State<OnboardingStep1Screen> {
  final TextEditingController _nameController = TextEditingController();
  String? _selectedGrade;
  String? _selectedBoard;
  bool _formIsValid = false;

  final List<String> _gradeOptions = [
    'Class 6',
    'Class 7',
    'Class 8',
    'Class 9',
    'Class 10',
    'Class 11 PCM',
    'Class 11 PCB',
    'Class 12 PCM',
    'Class 12 PCB',
    'University Y1',
    'University Y2',
    'University Y3',
  ];

  final List<String> _boardOptions = [
    'CBSE',
    'ICSE',
    'ISC',
    'State Board',
    'A-Levels',
    'IB',
    'Custom',
  ];

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _validateForm() {
    final nameValid = _nameController.text.trim().isNotEmpty;
    final gradeValid = _selectedGrade != null;
    final boardValid = _selectedBoard != null;
    setState(() {
      _formIsValid = nameValid && gradeValid && boardValid;
    });
  }

  Future<void> _handleContinue() async {
    if (!_formIsValid) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', _nameController.text.trim());
    await prefs.setString('user_grade', _selectedGrade!);
    await prefs.setString('user_board', _selectedBoard!);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Character "${_nameController.text}" initialized! Pushing to Step 2...'),
          backgroundColor: AppColors.accentDefault,
        ),
      );
      context.push('/onboarding/step2');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 24),
                // 1. Logo & Tagline (Space Grotesk, Animated)
                Text(
                  'VidyaVerse',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontFamily: 'Space Grotesk',
                        fontSize: 32,
                        color: AppColors.textPrimary,
                      ),
                )
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: 0.5, end: 0.0, curve: Curves.easeOutQuad),
                
                SizedBox(height: 4),
                
                Text(
                  'Your Academic Simulator',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 500.ms)
                    .slideY(begin: 0.5, end: 0.0, curve: Curves.easeOutQuad),

                SizedBox(height: 32),
                
                // 2. Step Indicator
                const StepIndicator(totalSteps: 4, currentIndex: 0),
                
                SizedBox(height: 40),

                // Character creation title
                Text(
                  'CHARACTER CREATION',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.accentDefault,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                  ),
                ),
                SizedBox(height: 24),

                // 3. Custom Name Input
                CustomTextField(
                  controller: _nameController,
                  labelText: 'Hero Full Name',
                  prefixIcon: Icons.person_outline,
                  onChanged: (_) => _validateForm(),
                ),
                
                SizedBox(height: 20),

                // 4. Custom Grade Dropdown
                CustomDropdown(
                  labelText: 'Grade Level',
                  value: _selectedGrade,
                  options: _gradeOptions,
                  prefixIcon: Icons.workspace_premium_outlined,
                  onChanged: (val) {
                    setState(() {
                      _selectedGrade = val;
                    });
                    _validateForm();
                  },
                ),
                
                SizedBox(height: 20),

                // 5. Custom Board Dropdown
                CustomDropdown(
                  labelText: 'Educational Board',
                  value: _selectedBoard,
                  options: _boardOptions,
                  prefixIcon: Icons.menu_book_outlined,
                  onChanged: (val) {
                    setState(() {
                      _selectedBoard = val;
                    });
                    _validateForm();
                  },
                ),
                
                SizedBox(height: 48),

                // 6. Glow Button
                GlowButton(
                  text: 'Continue →',
                  isEnabled: _formIsValid,
                  onPressed: _handleContinue,
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
