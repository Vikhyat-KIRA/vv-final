import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/colors.dart';

class PercentageDial extends StatelessWidget {
  final ValueNotifier<double> percentageNotifier;

  const PercentageDial({
    super.key,
    required this.percentageNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: percentageNotifier,
      builder: (context, percentage, _) {
        return SizedBox(
          width: 200,
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(200, 200),
                painter: _DialPainter(percentage: percentage),
              ),
              // Center text
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${percentage.toInt()}%',
                    style: TextStyle(
                      fontFamily: 'Space Grotesk',
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'OVERALL',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DialPainter extends CustomPainter {
  final double percentage;

  _DialPainter({required this.percentage});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 14) / 2;

    // Background track paint (surface2, full 360 degrees)
    final trackPaint = Paint()
      ..color = AppColors.surface2
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Active progress arc paint (accentDefault)
    final progressPaint = Paint()
      ..color = AppColors.accentDefault
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    // Sweep angle based on percentage (starts from top i.e. -pi/2)
    const startAngle = -math.pi / 2;
    final sweepAngle = (percentage / 100) * 2 * math.pi;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _DialPainter oldDelegate) {
    return oldDelegate.percentage != percentage;
  }
}
