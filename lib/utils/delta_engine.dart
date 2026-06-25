// Pure local utility for computing academic delta.
// No network calls. Reads only from passed-in values.

/// Computes percentage gap between current and target.
/// Returns a non-negative double clamped to [0, 100].
double computeDelta(double currentPercent, double targetPercent) {
  return (targetPercent - currentPercent).clamp(0.0, 100.0);
}

/// Returns a human-friendly delta label.
String deltaLabel(double currentPercent, double targetPercent) {
  final gap = computeDelta(currentPercent, targetPercent);
  if (gap <= 0) return 'Goal reached! 🎉';
  if (gap <= 5) return 'Almost there — ${gap.toInt()}% to go';
  return 'Close ${gap.toInt()}% more to reach your goal';
}
