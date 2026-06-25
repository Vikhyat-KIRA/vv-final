import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/syllabus_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/subject_card.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/shimmer_loading.dart';
import '../../theme/colors.dart';

class SyllabusScreen extends ConsumerStatefulWidget {
  const SyllabusScreen({super.key});

  @override
  ConsumerState<SyllabusScreen> createState() => _SyllabusScreenState();
}

class _SyllabusScreenState extends ConsumerState<SyllabusScreen> {
  void _showAddSubjectDialog(Color accent) {
    final nameController = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: GlassCard(
            borderRadius: 24,
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.surface2,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  'Add New Subject',
                  style: TextStyle(
                    fontFamily: 'Playfair Display',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter a subject name to add it to your syllabus',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: nameController,
                  autofocus: true,
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'e.g., Computer Science',
                    hintStyle: TextStyle(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.surface2,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: accent, width: 2),
                    ),
                    prefixIcon: Icon(Icons.menu_book, color: accent),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      final name = nameController.text.trim();
                      if (name.isNotEmpty) {
                        // TODO: Add subject to the syllabus provider
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('$name added to your syllabus!'),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: accent,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Add Subject',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _navigateToAiTutor(String subjectName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_subject', subjectName);
    if (mounted) {
      context.go('/tutor');
    }
  }

  @override
  Widget build(BuildContext context, ) {
    final subjects = ref.watch(syllabusProvider);
    final accent = ref.watch(themeProvider);

    // Calculate total average completion percent
    double totalPercentSum = 0.0;
    for (final subject in subjects) {
      totalPercentSum += subject.completionPercent;
    }
    final double overallCompletion = subjects.isNotEmpty 
        ? totalPercentSum / subjects.length 
        : 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Syllabus',
          style: TextStyle(fontFamily: 'Playfair Display', fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.background,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: Center(
              child: Text(
                '${overallCompletion.toInt()}% done',
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
      body: subjects.isEmpty
          ? GridView.builder(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 100.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.9,
              ),
              itemCount: 4,
              itemBuilder: (context, index) => const ShimmerSubjectCard(),
            )
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 100.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),
              itemCount: subjects.length,
              itemBuilder: (context, index) {
                final subject = subjects[index];
                return _SubjectCardWithAi(
                  subject: subject,
                  accentColor: accent,
                  onLearnWithAi: () => _navigateToAiTutor(subject.name),
                ).animate().fadeIn(delay: (index * 80).ms, duration: 400.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSubjectDialog(accent),
        backgroundColor: accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Add Subject',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _SubjectCardWithAi extends StatelessWidget {
  final dynamic subject;
  final Color accentColor;
  final VoidCallback onLearnWithAi;

  const _SubjectCardWithAi({
    required this.subject,
    required this.accentColor,
    required this.onLearnWithAi,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SubjectCard(
            subject: subject,
            accentColor: accentColor,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          height: 32,
          child: OutlinedButton.icon(
            onPressed: onLearnWithAi,
            icon: Icon(Icons.auto_awesome, size: 14, color: accentColor),
            label: Text(
              'Learn with AI',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              side: BorderSide(color: accentColor.withAlpha(80)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              backgroundColor: accentColor.withAlpha(15),
            ),
          ),
        ),
      ],
    );
  }
}
