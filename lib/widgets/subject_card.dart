import 'package:flutter/material.dart';
import '../models/subject_model.dart';
import '../screens/syllabus/subject_detail_screen.dart';
import '../theme/colors.dart';

class SubjectCard extends StatelessWidget {
  final SubjectModel subject;
  final Color accentColor;

  const SubjectCard({
    super.key,
    required this.subject,
    required this.accentColor,
  });

  Color _getTintByCompletion(double completion) {
    if (completion <= 30.0) {
      return const Color(0xFFEF4444); // Red
    } else if (completion <= 70.0) {
      return const Color(0xFFF59E0B); // Amber
    } else {
      return const Color(0xFF22C55E); // Green
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = _getTintByCompletion(subject.completionPercent);
    final completedChapters = subject.chapters.where((c) => c.status == 2).length;

    return Hero(
      tag: 'subject_${subject.id}',
      child: Card(
        color: Colors.transparent, // Let Container handle styling
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.surface2, width: 1),
        ),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SubjectDetailScreen(subject: subject),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: themeColor.withAlpha(20),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: themeColor.withAlpha(50), width: 1),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  subject.emoji,
                  style: TextStyle(fontSize: 28),
                ),
                SizedBox(height: 8),
                Text(
                  subject.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Playfair Display',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 16),
                SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    value: subject.completionPercent / 100.0,
                    strokeWidth: 4,
                    valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                    backgroundColor: AppColors.surface2,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  '$completedChapters/${subject.chapters.length} chapters',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
