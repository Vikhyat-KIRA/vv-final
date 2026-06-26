import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/subject_model.dart';
import '../../providers/syllabus_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/chapter_tile.dart';
import '../../theme/colors.dart';

class SubjectDetailScreen extends ConsumerWidget {
  final SubjectModel subject;

  const SubjectDetailScreen({
    super.key,
    required this.subject,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjects = ref.watch(syllabusProvider);
    final accent = ref.watch(themeProvider);

    // Look up the latest progress state of this subject from Riverpod
    final activeSubject = subjects.firstWhere(
      (s) => s.id == subject.id,
      orElse: () => subject,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Hero(
          tag: 'subject_${subject.id}',
          flightShuttleBuilder: (
            flightContext,
            animation,
            flightDirection,
            fromHeroContext,
            toHeroContext,
          ) {
            return DefaultTextStyle(
              style: Theme.of(flightContext).textTheme.titleLarge!,
              child: toHeroContext.widget,
            );
          },
          child: Text(
            '${activeSubject.emoji} ${activeSubject.name}',
            style: TextStyle(
              fontFamily: 'Space Grotesk',
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: LinearProgressIndicator(
            value: activeSubject.completionPercent / 100.0,
            backgroundColor: AppColors.surface2,
            valueColor: AlwaysStoppedAnimation<Color>(accent),
            minHeight: 6,
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.only(top: 12, bottom: 24),
        itemCount: activeSubject.chapters.length,
        itemBuilder: (context, index) {
          final chapter = activeSubject.chapters[index];
          return ChapterTile(
            subjectId: activeSubject.id,
            index: index,
            chapter: chapter,
          );
        },
      ),
    );
  }
}
