import 'package:flutter/material.dart';
import '../theme/colors.dart';

class EmptyState extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? ctaLabel;
  final VoidCallback? onCta;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.ctaLabel,
    this.onCta,
  });

  @override
  State<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<EmptyState> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _auraScale;
  late Animation<double> _auraOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _auraScale = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _auraOpacity = Tween<double>(begin: 0.05, end: 0.18).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Breathing Mystical Aura behind the icon
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scale: _auraScale.value,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.accentDefault.withValues(alpha: _auraOpacity.value),
                          AppColors.accentDefault.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            // Floating Sparkles / Celestial dots
            Positioned(
              top: 20,
              left: 40,
              child: _buildSparkle(0.4, 6.0),
            ),
            Positioned(
              bottom: 30,
              right: 50,
              child: _buildSparkle(0.6, 8.0),
            ),
            Positioned(
              top: 80,
              right: 30,
              child: _buildSparkle(0.3, 5.0),
            ),

            // Content Column
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  size: 64,
                  color: AppColors.textPrimary.withValues(alpha: 0.85),
                ),
                const SizedBox(height: 20),
                Text(
                  widget.title,
                  style: TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.subtitle,
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (widget.ctaLabel != null && widget.onCta != null) ...[
                  const SizedBox(height: 28),
                  OutlinedButton(
                    onPressed: widget.onCta,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: BorderSide(color: AppColors.accentDefault.withValues(alpha: 0.4)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      backgroundColor: AppColors.surface,
                    ),
                    child: Text(
                      widget.ctaLabel!,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSparkle(double baseOpacity, double size) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final opacity = (baseOpacity + (0.2 * _auraScale.value - 1.0)).clamp(0.1, 0.9);
        return Opacity(
          opacity: opacity,
          child: Icon(
            Icons.auto_awesome_sharp,
            size: size,
            color: AppColors.accentDefault.withValues(alpha: opacity),
          ),
        );
      },
    );
  }
}
