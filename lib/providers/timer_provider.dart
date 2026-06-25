import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_service.dart';

enum TimerPhase { work, shortBreak, longBreak }

class TimerState {
  final TimerPhase phase;
  final int secondsRemaining;
  final bool isRunning;
  final int sessionsCompleted;

  TimerState({
    required this.phase,
    required this.secondsRemaining,
    required this.isRunning,
    required this.sessionsCompleted,
  });

  TimerState copyWith({
    TimerPhase? phase,
    int? secondsRemaining,
    bool? isRunning,
    int? sessionsCompleted,
  }) {
    return TimerState(
      phase: phase ?? this.phase,
      secondsRemaining: secondsRemaining ?? this.secondsRemaining,
      isRunning: isRunning ?? this.isRunning,
      sessionsCompleted: sessionsCompleted ?? this.sessionsCompleted,
    );
  }
}

class TimerNotifier extends Notifier<TimerState> {
  Timer? _timer;

  static const int workDuration = 1500;       // 25 mins
  static const int shortBreakDuration = 300;  // 5 mins
  static const int longBreakDuration = 900;   // 15 mins

  @override
  TimerState build() {
    ref.onDispose(() {
      _timer?.cancel();
    });
    return TimerState(
      phase: TimerPhase.work,
      secondsRemaining: workDuration,
      isRunning: false,
      sessionsCompleted: 0,
    );
  }

  void start() {
    if (state.isRunning) return;

    state = state.copyWith(isRunning: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _tick();
    });
  }

  void pause() {
    _timer?.cancel();
    state = state.copyWith(isRunning: false);
  }

  void reset() {
    _timer?.cancel();
    int duration = workDuration;
    if (state.phase == TimerPhase.shortBreak) {
      duration = shortBreakDuration;
    } else if (state.phase == TimerPhase.longBreak) {
      duration = longBreakDuration;
    }

    state = state.copyWith(
      secondsRemaining: duration,
      isRunning: false,
    );
  }

  void skip() {
    _timer?.cancel();
    _transitionNextPhase();
  }

  void _tick() {
    if (state.secondsRemaining > 0) {
      state = state.copyWith(secondsRemaining: state.secondsRemaining - 1);
    } else {
      _timer?.cancel();
      NotificationService.showTimerComplete(state.phase);
      _transitionNextPhase();
    }
  }

  void _transitionNextPhase() {
    TimerPhase nextPhase;
    int nextSeconds;
    int nextSessions = state.sessionsCompleted;

    if (state.phase == TimerPhase.work) {
      nextSessions++;
      if (nextSessions % 4 == 0) {
        nextPhase = TimerPhase.longBreak;
        nextSeconds = longBreakDuration;
      } else {
        nextPhase = TimerPhase.shortBreak;
        nextSeconds = shortBreakDuration;
      }
    } else {
      nextPhase = TimerPhase.work;
      nextSeconds = workDuration;
    }

    state = TimerState(
      phase: nextPhase,
      secondsRemaining: nextSeconds,
      isRunning: false,
      sessionsCompleted: nextSessions,
    );
  }

}

final timerProvider = NotifierProvider<TimerNotifier, TimerState>(() {
  return TimerNotifier();
});
