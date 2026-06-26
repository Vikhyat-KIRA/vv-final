import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import '../../theme/colors.dart';
import '../../widgets/step_indicator.dart';
import '../../widgets/percentage_dial.dart';
import '../../widgets/glow_button.dart';

class OnboardingStep2Screen extends StatefulWidget {
  const OnboardingStep2Screen({super.key});

  @override
  State<OnboardingStep2Screen> createState() => _OnboardingStep2ScreenState();
}

class _OnboardingStep2ScreenState extends State<OnboardingStep2Screen> {
  final ValueNotifier<double> _percentageNotifier = ValueNotifier<double>(65.0);
  int? _selectedStatusIndex;

  final List<Map<String, dynamic>> _statusOptions = [
    {
      'label': 'Lagging Behind',
      'emoji': '🔴',
      'color': const Color(0xFFEF4444),
    },
    {
      'label': 'Average',
      'emoji': '🟡',
      'color': const Color(0xFFF59E0B),
    },
    {
      'label': 'On Track',
      'emoji': '🟢',
      'color': const Color(0xFF22C55E),
    },
    {
      'label': 'Excellence Mode',
      'emoji': '🔵',
      'color': const Color(0xFF60A5FA),
    },
  ];

  @override
  void dispose() {
    _percentageNotifier.dispose();
    super.dispose();
  }

  Future<void> _handleContinue() async {
    if (_selectedStatusIndex == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('user_percentage', _percentageNotifier.value);
    await prefs.setString(
      'user_status',
      _statusOptions[_selectedStatusIndex!]['label'] as String,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Academic level: ${_percentageNotifier.value.toInt()}% (${_statusOptions[_selectedStatusIndex!]['label']}). Saving & pushing to Step 3...',
          ),
          backgroundColor: AppColors.accentDefault,
        ),
      );
      context.push('/onboarding/step3');
    }
  }

  @override
  Widget build(BuildContext context) {
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
                      child: StepIndicator(totalSteps: 4, currentIndex: 1),
                    ),
                    SizedBox(width: 48), // Balancing spacer matching the BackButton width
                  ],
                ),
                SizedBox(height: 24),
                
                // Title
                Text(
                  'Where are you right now?',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontFamily: 'Space Grotesk',
                        fontSize: 26,
                      ),
                  textAlign: TextAlign.left,
                ),
                SizedBox(height: 6),
                
                // Subtitle
                Text(
                  'Be honest. This powers your experience.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 32),

                // Animated Percentage Dial
                Center(
                  child: PercentageDial(percentageNotifier: _percentageNotifier),
                ),
                SizedBox(height: 24),

                // Slider Section
                Text(
                  'Current Overall Percentage',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                ValueListenableBuilder<double>(
                  valueListenable: _percentageNotifier,
                  builder: (context, value, _) {
                    return Slider(
                      value: value,
                      min: 0,
                      max: 100,
                      divisions: 100,
                      activeColor: AppColors.accentDefault,
                      thumbColor: AppColors.accentDefault,
                      inactiveColor: AppColors.surface2,
                      onChanged: (newValue) {
                        _percentageNotifier.value = newValue;
                      },
                    );
                  },
                ),
                SizedBox(height: 28),

                // Grid View of Status Badge Cards
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 2.2,
                  ),
                  itemCount: _statusOptions.length,
                  itemBuilder: (context, index) {
                    final status = _statusOptions[index];
                    final isSelected = _selectedStatusIndex == index;
                    final cardColor = status['color'] as Color;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedStatusIndex = index;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                        transform: Matrix4.diagonal3Values(
                          isSelected ? 1.04 : 1.0,
                          isSelected ? 1.04 : 1.0,
                          1.0,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? cardColor.withAlpha((0.12 * 255).round())
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? cardColor : AppColors.surface2,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                status['emoji']!,
                                style: TextStyle(fontSize: 20),
                              ),
                              SizedBox(width: 8),
                              Text(
                                status['label']!,
                                style: TextStyle(
                                  fontFamily: 'Space Grotesk',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                
                SizedBox(height: 40),

                // Navigation Row (Back + Continue)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: BorderSide(color: AppColors.surface2),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text('Back'),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: GlowButton(
                        text: 'Continue',
                        isEnabled: _selectedStatusIndex != null,
                        onPressed: _handleContinue,
                      ),
                    ),
                  ],
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
