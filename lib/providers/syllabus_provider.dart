import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/subject_model.dart';
import '../models/chapter_model.dart';
import '../data/subjects_data.dart';
import '../services/firestore_service.dart';
import 'sync_provider.dart';

class SyllabusNotifier extends StateNotifier<List<SubjectModel>> {
  final Ref ref;
  Timer? _debounceTimer;

  SyllabusNotifier(this.ref) : super([]) {
    initializeSyllabus();
  }

  Future<void> initializeSyllabus() async {
    final prefs = await SharedPreferences.getInstance();
    // Default to 'CBSE Class 8' if not set during onboarding
    final board = prefs.getString('user_board') ?? 'CBSE';
    final grade = prefs.getString('user_grade') ?? 'Class 8';
    
    // Construct the lookup key e.g. "CBSE Class 8" or "ICSE Class 8"
    String lookupKey = '$board $grade';
    if (!boardSubjects.containsKey(lookupKey)) {
      lookupKey = 'CBSE Class 8';
    }

    final templateSubjects = boardSubjects[lookupKey] ?? [];
    List<SubjectModel> loadedSubjects = [];

    for (final subject in templateSubjects) {
      List<ChapterModel> updatedChapters = [];
      int completedWeight = 0;
      int totalWeight = 0;

      for (final chapter in subject.chapters) {
        final savedStatus = prefs.getInt('chapter_status_${chapter.id}') ?? 0;
        updatedChapters.add(chapter.copyWith(status: savedStatus));
        totalWeight += chapter.weightage;
        if (savedStatus == 2) {
          completedWeight += chapter.weightage;
        }
      }

      final double completionPercent = totalWeight > 0 
          ? (completedWeight / totalWeight) * 100.0 
          : 0.0;

      loadedSubjects.add(subject.copyWith(
        chapters: updatedChapters,
        completionPercent: completionPercent,
      ));
    }

    state = loadedSubjects;
    _saveOverallProgress();
  }

  Future<void> cycleChapterStatus(String subjectId, String chapterId) async {
    final prefs = await SharedPreferences.getInstance();
    
    state = [
      for (final subject in state)
        if (subject.id == subjectId)
          _updateSubjectChapterStatus(subject, chapterId, prefs)
        else
          subject
    ];

    _saveOverallProgress();
    _triggerDebouncedSync(subjectId);
  }

  SubjectModel _updateSubjectChapterStatus(
    SubjectModel subject,
    String chapterId,
    SharedPreferences prefs,
  ) {
    List<ChapterModel> updatedChapters = [];
    int completedWeight = 0;
    int totalWeight = 0;
    int newStatusValue = 0;

    for (final chapter in subject.chapters) {
      int status = chapter.status;
      if (chapter.id == chapterId) {
        status = (status + 1) % 3;
        newStatusValue = status;
        prefs.setInt('chapter_status_${chapter.id}', status);
      }
      
      updatedChapters.add(chapter.copyWith(status: status));
      totalWeight += chapter.weightage;
      if (status == 2) {
        completedWeight += chapter.weightage;
      }
    }

    final double completionPercent = totalWeight > 0 
        ? (completedWeight / totalWeight) * 100.0 
        : 0.0;

    // Check if the chapter just transitioned to completed (status 2) to log
    if (newStatusValue == 2) {
      prefs.setString('last_subject', subject.name);
      final compChapter = subject.chapters.firstWhere((c) => c.id == chapterId);
      prefs.setString('last_chapter', compChapter.title);
    }

    return subject.copyWith(
      chapters: updatedChapters,
      completionPercent: completionPercent,
    );
  }

  Future<void> _saveOverallProgress() async {
    final prefs = await SharedPreferences.getInstance();
    if (state.isEmpty) return;

    double totalPercentSum = 0.0;
    for (final subject in state) {
      totalPercentSum += subject.completionPercent;
    }
    final averagePercent = totalPercentSum / state.length;
    await prefs.setDouble('user_percentage', averagePercent);
  }

  void _triggerDebouncedSync(String subjectId) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final subject = state.firstWhere((s) => s.id == subjectId);
        final data = {
          'subjectId': subject.id,
          'completionPercent': subject.completionPercent,
          'chapters': subject.chapters.map((c) => {
            'id': c.id,
            'status': c.status,
          }).toList(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        ref.read(syncStatusProvider.notifier).setSyncing();
        try {
          await FirestoreService().saveChapterProgress(uid, subjectId, data);
          ref.read(syncStatusProvider.notifier).setSynced();
        } catch (e) {
          ref.read(syncStatusProvider.notifier).setError();
        }
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

final syllabusProvider = StateNotifierProvider<SyllabusNotifier, List<SubjectModel>>((ref) {
  return SyllabusNotifier(ref);
});
