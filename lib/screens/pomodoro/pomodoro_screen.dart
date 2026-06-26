import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../providers/timer_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/circular_timer_painter.dart';
import '../../theme/colors.dart';

class PomodoroScreen extends ConsumerStatefulWidget {
  const PomodoroScreen({super.key});

  @override
  ConsumerState<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends ConsumerState<PomodoroScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _playAmbient = false;

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _toggleAmbientSound(bool play) async {
    setState(() {
      _playAmbient = play;
    });

    try {
      if (play) {
        await _audioPlayer.setReleaseMode(ReleaseMode.loop);
        // Safely play white noise asset. White noise WAV should be added to assets.
        await _audioPlayer.play(AssetSource('audio/white_noise.wav'));
      } else {
        await _audioPlayer.stop();
      }
    } catch (_) {
      // Catch silently if audio asset is missing in development
    }
  }

  void _triggerFocusLockOverlay() {
    final overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => FocusLockOverlay(
        onDismiss: () {
          overlayEntry.remove();
        },
      ),
    );

    overlayState.insert(overlayEntry);
  }

  String _formatTime(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Color _getPhaseColor(TimerPhase phase, Color accentColor) {
    switch (phase) {
      case TimerPhase.shortBreak:
        return const Color(0xFF60A5FA); // Blue
      case TimerPhase.longBreak:
        return const Color(0xFFA855F7); // Purple
      case TimerPhase.work:
        return accentColor;
    }
  }

  String _getPhaseLabel(TimerPhase phase) {
    switch (phase) {
      case TimerPhase.shortBreak:
        return 'SHORT BREAK';
      case TimerPhase.longBreak:
        return 'LONG BREAK';
      case TimerPhase.work:
        return 'FOCUS SESSION';
    }
  }

  int _getPhaseTotalSeconds(TimerPhase phase) {
    switch (phase) {
      case TimerPhase.shortBreak:
        return TimerNotifier.shortBreakDuration;
      case TimerPhase.longBreak:
        return TimerNotifier.longBreakDuration;
      case TimerPhase.work:
        return TimerNotifier.workDuration;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = ref.watch(themeProvider);
    final timerState = ref.watch(timerProvider);

    // Listen to work session start to trigger overlay
    ref.listen<TimerState>(timerProvider, (previous, next) {
      final wasRunning = previous?.isRunning ?? false;
      if (next.isRunning && next.phase == TimerPhase.work && !wasRunning) {
        _triggerFocusLockOverlay();
      }
    });

    final phaseColor = _getPhaseColor(timerState.phase, accent);
    final totalSeconds = _getPhaseTotalSeconds(timerState.phase);
    final double progress = totalSeconds > 0 
        ? timerState.secondsRemaining / totalSeconds 
        : 1.0;

    // session tracker completed count
    int activeSessions = timerState.sessionsCompleted % 4;
    if (activeSessions == 0 && timerState.sessionsCompleted > 0 && timerState.phase != TimerPhase.work) {
      activeSessions = 4;
    }

    // focus hours calculation
    final totalMinutesFocused = timerState.sessionsCompleted * 25;
    final hrs = totalMinutesFocused ~/ 60;
    final mins = totalMinutesFocused % 60;
    final focusTodayText = '${hrs}hr ${mins}min';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Focus Timer', style: TextStyle(fontFamily: 'Space Grotesk', fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Spacer(),

            // 1. Phase label (with animated switcher transition)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                _getPhaseLabel(timerState.phase),
                key: ValueKey<TimerPhase>(timerState.phase),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: phaseColor,
                  letterSpacing: 1.4,
                ),
              ),
            ),
            SizedBox(height: 32),

            // 2. CustomPaint circular timer
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(260, 260),
                    painter: CircularTimerPainter(
                      progress: progress,
                      progressColor: phaseColor,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(timerState.secondsRemaining),
                        style: TextStyle(
                          fontFamily: 'Space Grotesk',
                          fontSize: 56,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        timerState.isRunning ? 'KEEP FOCUSING' : 'PAUSED',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 32),

            // 3. Session tracker row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final isFilled = index < activeSessions;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6.0),
                  child: Icon(
                    Icons.local_pizza,
                    size: 24,
                    color: isFilled ? accent : AppColors.surface2,
                  ),
                );
              }),
            ),
            SizedBox(height: 40),

            // 4. Controls Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  iconSize: 28,
                  icon: Icon(Icons.refresh, color: AppColors.textPrimary),
                  onPressed: () => ref.read(timerProvider.notifier).reset(),
                ),
                SizedBox(width: 24),
                // Play / Pause FAB
                SizedBox(
                  width: 64,
                  height: 64,
                  child: FloatingActionButton(
                    backgroundColor: accent,
                    foregroundColor: AppColors.background,
                    shape: const CircleBorder(),
                    onPressed: () {
                      if (timerState.isRunning) {
                        ref.read(timerProvider.notifier).pause();
                      } else {
                        ref.read(timerProvider.notifier).start();
                      }
                    },
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        timerState.isRunning ? Icons.pause : Icons.play_arrow,
                        key: ValueKey<bool>(timerState.isRunning),
                        size: 32,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 24),
                IconButton(
                  iconSize: 28,
                  icon: Icon(Icons.skip_next, color: AppColors.textPrimary),
                  onPressed: () => ref.read(timerProvider.notifier).skip(),
                ),
              ],
            ),
            SizedBox(height: 40),

            // 5. Ambient sound row
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.surface2),
              ),
              child: Row(
                children: [
                  Icon(Icons.headphones, color: AppColors.textSecondary),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Ambient Sound',
                      style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                  ),
                  Switch(
                    value: _playAmbient,
                    activeThumbColor: phaseColor,
                    onChanged: _toggleAmbientSound,
                  ),
                ],
              ),
            ),
            const Spacer(),

            // 6. Stats card at bottom
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.symmetric(vertical: 16),
              color: AppColors.surface,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    'Focus today: $focusTodayText',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                  ),
                  Container(width: 1, height: 20, color: AppColors.surface2),
                  Text(
                    'Sessions: ${timerState.sessionsCompleted}',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FocusLockOverlay extends StatefulWidget {
  final VoidCallback onDismiss;

  const FocusLockOverlay({super.key, required this.onDismiss});

  @override
  State<FocusLockOverlay> createState() => _FocusLockOverlayState();
}

class _FocusLockOverlayState extends State<FocusLockOverlay> {
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      setState(() {
        _opacity = 1.0;
      });
    });
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _opacity = 0.0;
        });
      }
    });
    Future.delayed(const Duration(milliseconds: 2000), () {
      widget.onDismiss();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 400),
        opacity: _opacity,
        child: Container(
          color: Colors.black87,
          alignment: Alignment.center,
          child: Text(
            'FOCUS LOCKED',
            style: TextStyle(
              fontFamily: 'Space Grotesk',
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
            ),
          ),
        ),
      ),
    );
  }
}
