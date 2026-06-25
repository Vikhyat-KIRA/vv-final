import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PomodoroState {
  final int durationSeconds;
  final bool isRunning;
  final bool isBreak;
  final int completedSessions;

  PomodoroState({
    required this.durationSeconds,
    required this.isRunning,
    required this.isBreak,
    required this.completedSessions,
  });

  PomodoroState copyWith({
    int? durationSeconds,
    bool? isRunning,
    bool? isBreak,
    int? completedSessions,
  }) {
    return PomodoroState(
      durationSeconds: durationSeconds ?? this.durationSeconds,
      isRunning: isRunning ?? this.isRunning,
      isBreak: isBreak ?? this.isBreak,
      completedSessions: completedSessions ?? this.completedSessions,
    );
  }
}

class PomodoroNotifier extends StateNotifier<PomodoroState> {
  Timer? _timer;

  PomodoroNotifier()
      : super(PomodoroState(
          durationSeconds: 25 * 60,
          isRunning: false,
          isBreak: false,
          completedSessions: 0,
        ));

  void startTimer() {
    if (state.isRunning) return;

    state = state.copyWith(isRunning: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.durationSeconds > 0) {
        state = state.copyWith(durationSeconds: state.durationSeconds - 1);
      } else {
        _timer?.cancel();
        final newIsBreak = !state.isBreak;
        state = state.copyWith(
          isRunning: false,
          isBreak: newIsBreak,
          durationSeconds: newIsBreak ? 5 * 60 : 25 * 60,
          completedSessions: newIsBreak ? state.completedSessions + 1 : state.completedSessions,
        );
      }
    });
  }

  void pauseTimer() {
    _timer?.cancel();
    state = state.copyWith(isRunning: false);
  }

  void resetTimer() {
    _timer?.cancel();
    state = PomodoroState(
      durationSeconds: state.isBreak ? 5 * 60 : 25 * 60,
      isRunning: false,
      isBreak: state.isBreak,
      completedSessions: state.completedSessions,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final pomodoroProvider = StateNotifierProvider<PomodoroNotifier, PomodoroState>((ref) {
  return PomodoroNotifier();
});
