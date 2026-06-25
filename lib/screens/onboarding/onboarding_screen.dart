import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/local_storage_service.dart';
import '../../theme/colors.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<Map<String, String>> _onboardingSteps = [
    {
      'title': 'AI Study Tutor',
      'description': 'Chat with our AI Tutor trained on your syllabus to ask questions and generate flashcards instantly.',
      'icon': '🤖',
    },
    {
      'title': 'Spaced Repetition',
      'description': 'Master complex theories with our built-in flashcard system based on the Leitner methodology.',
      'icon': '🎴',
    },
    {
      'title': 'Knowledge Vault',
      'description': 'Upload your textbooks, PDFs, and notes to compile them into interactive learning materials.',
      'icon': '📦',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: () => _completeOnboarding(context),
                  child: Text('Skip', style: TextStyle(color: AppColors.textSecondary)),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  itemCount: _onboardingSteps.length,
                  itemBuilder: (context, index) {
                    final step = _onboardingSteps[index];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          step['icon']!,
                          style: TextStyle(fontSize: 80),
                        ),
                        SizedBox(height: 32),
                        Text(
                          step['title']!,
                          style: Theme.of(context).textTheme.displaySmall,
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16),
                        Text(
                          step['description']!,
                          style: Theme.of(context).textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _onboardingSteps.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentIndex == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentIndex == index ? AppColors.accentDefault : AppColors.surface2,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  if (_currentIndex < _onboardingSteps.length - 1) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  } else {
                    _completeOnboarding(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentDefault,
                  foregroundColor: AppColors.background,
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  _currentIndex == _onboardingSteps.length - 1 ? 'Start Learning' : 'Next',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _completeOnboarding(BuildContext context) async {
    await LocalStorageService().setOnboardingComplete(true);
    if (context.mounted) {
      context.go('/dashboard');
    }
  }
}
