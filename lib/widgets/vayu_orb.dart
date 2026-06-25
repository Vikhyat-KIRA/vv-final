import 'dart:math';
import 'package:flutter/material.dart';

class VayuOrb extends StatefulWidget {
  final Color color;
  final bool isActive;
  final VoidCallback onTap;

  const VayuOrb({
    super.key,
    required this.color,
    this.isActive = false,
    required this.onTap,
  });

  @override
  State<VayuOrb> createState() => _VayuOrbState();
}

class _VayuOrbState extends State<VayuOrb> with TickerProviderStateMixin {
  late final AnimationController _rotationController;
  late final AnimationController _pulseController;
  late final AnimationController _tapController;
  late final Animation<double> _tapScale;

  @override
  void initState() {
    super.initState();

    // Slow continuous rotation for sparkle particles
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    // Subtle breathing pulse
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    // Tap scale animation
    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _tapScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.18), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.18, end: 0.95), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _tapController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _tapController.dispose();
    super.dispose();
  }

  void _handleTap() {
    _tapController.forward(from: 0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_rotationController, _pulseController, _tapController]),
        builder: (context, child) {
          final pulse = 0.92 + (_pulseController.value * 0.08);
          final scale = _tapController.isAnimating ? _tapScale.value : pulse;

          return SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Sparkle particles
                CustomPaint(
                  size: const Size(80, 80),
                  painter: _SparklePainter(
                    color: widget.color,
                    rotation: _rotationController.value * 2 * pi,
                    opacity: widget.isActive ? 1.0 : 0.6,
                  ),
                ),
                // Outer glow
                Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: widget.color.withOpacity(widget.isActive ? 0.5 : 0.3),
                          blurRadius: widget.isActive ? 24 : 16,
                          spreadRadius: widget.isActive ? 4 : 1,
                        ),
                      ],
                    ),
                    // Glass body
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            widget.color.withOpacity(0.9),
                            widget.color,
                            widget.color.withOpacity(0.7),
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white,
                              Colors.white.withOpacity(0.7),
                            ],
                          ).createShader(bounds),
                          child: const Icon(
                            Icons.auto_awesome,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SparklePainter extends CustomPainter {
  final Color color;
  final double rotation;
  final double opacity;

  _SparklePainter({
    required this.color,
    required this.rotation,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;
    const particleCount = 6;

    for (int i = 0; i < particleCount; i++) {
      final angle = rotation + (i * 2 * pi / particleCount);
      final particleRadius = radius * (0.85 + 0.15 * sin(rotation * 2 + i));
      final x = center.dx + particleRadius * cos(angle);
      final y = center.dy + particleRadius * sin(angle);
      final particleSize = 2.0 + 1.0 * sin(rotation * 3 + i * 1.5);

      final paint = Paint()
        ..color = color.withOpacity(opacity * (0.4 + 0.4 * sin(rotation * 2 + i * 0.8)))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      canvas.drawCircle(Offset(x, y), particleSize, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) => true;
}
