import 'dart:async';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/services.dart';
import '../theme/colors.dart';

class LevelUpOverlay {
  static void show(BuildContext context, int newLevel, Color accentColor) {
    final overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;

    // Trigger haptic feedback: heavy impact 3 times with 100ms gaps
    _triggerLevelUpHaptics();

    overlayEntry = OverlayEntry(
      builder: (context) => _LevelUpWidget(
        newLevel: newLevel,
        accentColor: accentColor,
        onDismiss: () {
          if (overlayEntry.mounted) {
            overlayEntry.remove();
          }
        },
      ),
    );

    overlayState.insert(overlayEntry);

    // Auto-remove after 3.5 seconds
    Timer(const Duration(milliseconds: 3500), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  static void _triggerLevelUpHaptics() async {
    for (int i = 0; i < 3; i++) {
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }
}

class _LevelUpWidget extends StatefulWidget {
  final int newLevel;
  final Color accentColor;
  final VoidCallback onDismiss;

  const _LevelUpWidget({
    required this.newLevel,
    required this.accentColor,
    required this.onDismiss,
  });

  @override
  State<_LevelUpWidget> createState() => _LevelUpWidgetState();
}

class _LevelUpWidgetState extends State<_LevelUpWidget> {
  late ConfettiController _confettiController;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    
    // Start animation and confetti
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _visible = true;
        });
        _confettiController.play();
      }
    });

    // Start fade out after 3 seconds
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _visible = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onDismiss,
      behavior: HitTestBehavior.opaque,
      child: Material(
        color: Colors.black54, // Semi-transparent overlay
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Confetti burst from top center
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: [widget.accentColor, Colors.white],
                maxBlastForce: 25,
                minBlastForce: 10,
                emissionFrequency: 0.06,
                numberOfParticles: 40,
                gravity: 0.18,
              ),
            ),
            
            // Fading and bouncing content
            AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _visible ? 1.0 : 0.0,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'LEVEL UP!',
                      style: TextStyle(
                        fontFamily: 'Space Grotesk', // Headers font
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black87,
                            offset: Offset(0, 4),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.elasticOut,
                      builder: (context, scale, child) {
                        return Transform.scale(
                          scale: scale,
                          child: child,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: widget.accentColor, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: widget.accentColor.withValues(alpha: 0.35),
                              blurRadius: 24,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              'LEVEL',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textSecondary,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${widget.newLevel}',
                              style: TextStyle(
                                fontFamily: 'Space Grotesk',
                                fontSize: 72,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
