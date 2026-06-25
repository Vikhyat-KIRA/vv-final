import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/colors.dart';

class AchievementModel {
  final String id;
  final String name;
  final String description;
  final String icon;
  final int xpReward;

  const AchievementModel({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.xpReward,
  });
}

const List<AchievementModel> allAchievements = [
  AchievementModel(
    id: 'first_chapter',
    name: 'First Chapter',
    description: 'Completed your first study chapter',
    icon: '📚',
    xpReward: 50,
  ),
  AchievementModel(
    id: 'first_ai_message',
    name: 'AI Tutor Used',
    description: 'Sent your first message to the AI Tutor',
    icon: '🧠',
    xpReward: 30,
  ),
  AchievementModel(
    id: 'streak_7_days',
    name: '7-Day Streak',
    description: 'Logged activity 7 days in a row',
    icon: '🔥',
    xpReward: 100,
  ),
];

class AchievementToast {
  static void show(BuildContext context, AchievementModel achievement, Color accentColor) {
    final overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _AchievementToastWidget(
        achievement: achievement,
        accentColor: accentColor,
        onDismiss: () {
          if (overlayEntry.mounted) {
            overlayEntry.remove();
          }
        },
      ),
    );

    overlayState.insert(overlayEntry);

    // Auto-remove after 3.2 seconds (gives time for reverse animation)
    Timer(const Duration(milliseconds: 3200), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }
}

class _AchievementToastWidget extends StatefulWidget {
  final AchievementModel achievement;
  final Color accentColor;
  final VoidCallback onDismiss;

  const _AchievementToastWidget({
    required this.achievement,
    required this.accentColor,
    required this.onDismiss,
  });

  @override
  State<_AchievementToastWidget> createState() => _AchievementToastWidgetState();
}

class _AchievementToastWidgetState extends State<_AchievementToastWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 450),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, 2.0), // Start offscreen
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _controller.forward();

    // Trigger slide down and dismiss
    Timer(const Duration(milliseconds: 2700), () {
      if (mounted) {
        _controller.reverse().then((_) => widget.onDismiss());
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: SlideTransition(
          position: _offsetAnimation,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Material(
              color: Colors.transparent,
              child: Card(
                color: const Color(0xFF161B22), // Premium dark theme color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: AppColors.border),
                ),
                elevation: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(color: widget.accentColor, width: 4), // Accent left border
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.achievement.icon,
                        style: const TextStyle(fontSize: 28),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ACHIEVEMENT UNLOCKED!',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: widget.accentColor,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.achievement.name,
                            style: const TextStyle(
                              fontFamily: 'Playfair Display',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFF0F0F5),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 24),
                      Text(
                        '+${widget.achievement.xpReward} XP',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: widget.accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
