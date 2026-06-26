import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';
import '../providers/theme_style_provider.dart';
import '../theme/colors.dart';

class AnimatedMeshBackground extends ConsumerStatefulWidget {
  const AnimatedMeshBackground({super.key});

  @override
  ConsumerState<AnimatedMeshBackground> createState() => _AnimatedMeshBackgroundState();
}

class _AnimatedMeshBackgroundState extends ConsumerState<AnimatedMeshBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Very slow, soothing drift (25 seconds)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getComplementary(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withHue((hsl.hue + 120) % 360).toColor();
  }

  Color _getTriadic(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withHue((hsl.hue + 240) % 360).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final themeStyle = ref.watch(themeStyleProvider);
    final accentColor = ref.watch(themeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Fall back to solid styling only for brutalist
    if (themeStyle == ThemeStyle.brutalist) {
      return Container(
        color: AppColors.background,
      );
    }

    // Determine the base solid color underneath the mesh blobs
    Color baseColor;
    if (themeStyle == ThemeStyle.darkGold) {
      baseColor = const Color(0xFF0A0E1A);
    } else if (isDark) {
      baseColor = const Color(0xFF0F172A); // slate-900
    } else {
      baseColor = themeStyle == ThemeStyle.gradient
          ? const Color(0xFFF0FDFA) // teal-50
          : const Color(0xFFF8FAFC); // slate-50
    }

    final compColor = _getComplementary(accentColor);
    final triadColor = _getTriadic(accentColor);

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: MeshBackgroundPainter(
              animationValue: _controller.value,
              baseColor: baseColor,
              accentColor: accentColor,
              compColor: compColor,
              triadColor: triadColor,
              isDark: isDark,
            ),
          );
        },
      ),
    );
  }
}

class MeshBackgroundPainter extends CustomPainter {
  final double animationValue;
  final Color baseColor;
  final Color accentColor;
  final Color compColor;
  final Color triadColor;
  final bool isDark;

  MeshBackgroundPainter({
    required this.animationValue,
    required this.baseColor,
    required this.accentColor,
    required this.compColor,
    required this.triadColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final basePaint = Paint()..color = baseColor;
    canvas.drawRect(Offset.zero & size, basePaint);

    final double t = animationValue;
    final double w = size.width;
    final double h = size.height;

    // Avoid running computations if screen hasn't loaded size
    if (w == 0 || h == 0) return;

    // Blob 1: Accent Color (Slow circular drift)
    final x1 = w * (0.3 + 0.18 * math.sin(t * 2 * math.pi));
    final y1 = h * (0.35 + 0.12 * math.cos(t * 2 * math.pi));
    final r1 = w * (isDark ? 0.75 : 0.65);
    final paint1 = Paint()
      ..shader = RadialGradient(
        colors: [
          accentColor.withOpacity(isDark ? 0.18 : 0.14),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(x1, y1), radius: r1));
    canvas.drawCircle(Offset(x1, y1), r1, paint1);

    // Blob 2: Complementary Color (Slow figure-8 drift)
    final x2 = w * (0.7 + 0.15 * math.cos(t * 2 * math.pi + 1.0));
    final y2 = h * (0.55 + 0.18 * math.sin(t * 2 * math.pi * 2 + 0.5));
    final r2 = w * (isDark ? 0.8 : 0.7);
    final paint2 = Paint()
      ..shader = RadialGradient(
        colors: [
          compColor.withOpacity(isDark ? 0.14 : 0.11),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(x2, y2), radius: r2));
    canvas.drawCircle(Offset(x2, y2), r2, paint2);

    // Blob 3: Triadic Color (Slow elliptical drift)
    final x3 = w * (0.45 + 0.22 * math.sin(t * 2 * math.pi + 2.0));
    final y3 = h * (0.75 + 0.1 * math.cos(t * 2 * math.pi + 1.5));
    final r3 = w * (isDark ? 0.7 : 0.6);
    final paint3 = Paint()
      ..shader = RadialGradient(
        colors: [
          triadColor.withOpacity(isDark ? 0.12 : 0.09),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(x3, y3), radius: r3));
    canvas.drawCircle(Offset(x3, y3), r3, paint3);
  }

  @override
  bool shouldRepaint(covariant MeshBackgroundPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.baseColor != baseColor ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.isDark != isDark;
  }
}
