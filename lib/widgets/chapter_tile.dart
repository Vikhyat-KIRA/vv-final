import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/chapter_model.dart';
import '../providers/syllabus_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/colors.dart';

class ChapterTile extends ConsumerWidget {
  final String subjectId;
  final int index;
  final ChapterModel chapter;

  const ChapterTile({
    super.key,
    required this.subjectId,
    required this.index,
    required this.chapter,
  });

  void _showXpToast(BuildContext context) {
    final overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 120,
        left: MediaQuery.of(context).size.width * 0.35,
        right: MediaQuery.of(context).size.width * 0.35,
        child: Material(
          color: Colors.transparent,
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF22C55E).withAlpha(100),
                  blurRadius: 12,
                  spreadRadius: 2,
                )
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bolt, color: Colors.white, size: 20),
                SizedBox(width: 6),
                Text(
                  '+10 XP',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 200.ms)
              .slideY(begin: 0.5, end: 0.0, curve: Curves.easeOut)
              .then(delay: 1100.ms)
              .fadeOut(duration: 200.ms),
        ),
      ),
    );

    overlayState.insert(overlayEntry);

    Future.delayed(const Duration(milliseconds: 1500), () {
      overlayEntry.remove();
    });
  }

  Widget _buildStatusChip(BuildContext context, int status) {
    Widget chip;
    switch (status) {
      case 1:
        chip = Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF59E0B).withAlpha(30),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFF59E0B), width: 1),
          ),
          child: Text(
            'In Progress',
            style: TextStyle(color: Color(0xFFF59E0B), fontSize: 12, fontWeight: FontWeight.w600),
          ),
        );
        break;
      case 2:
        chip = Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF22C55E).withAlpha(30),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF22C55E), width: 1),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check, size: 14, color: Color(0xFF22C55E)),
              SizedBox(width: 4),
              Text(
                '✓ Done',
                style: TextStyle(color: Color(0xFF22C55E), fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        );
        break;
      case 0:
      default:
        chip = Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.textSecondary.withAlpha(100), width: 1),
          ),
          child: Text(
            'Not Started',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        );
        break;
    }

    if (status == 2) {
      return chip.animate().scaleXY(
            begin: 0.8,
            end: 1.0,
            curve: Curves.bounceOut,
            duration: const Duration(milliseconds: 450),
          );
    }
    return chip;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: ListTile(
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.surface2,
          child: Text(
            '${index + 1}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        title: Text(
          chapter.title,
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        subtitle: Text(
          'Weightage: ${chapter.weightage}%',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: GestureDetector(
          onTap: () {
            final nextStatus = (chapter.status + 1) % 3;
            ref.read(syllabusProvider.notifier).cycleChapterStatus(subjectId, chapter.id);
            
            if (nextStatus == 2) {
              _showXpToast(context);
              ref.read(authProvider.notifier).addXp(10);
            }
          },
          child: _buildStatusChip(context, chapter.status),
        ),
      ),
    );
  }
}
