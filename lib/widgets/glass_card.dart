import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/colors.dart';

enum CardElevation { standard, elevated, recessed }

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double? blurSigma;
  final Color? backgroundColor;
  final Color? borderColor;
  final CardElevation elevation;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 20,
    this.blurSigma,
    this.backgroundColor,
    this.borderColor,
    this.elevation = CardElevation.standard,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    Color defaultBg;
    Color defaultBorder;
    
    switch (elevation) {
      case CardElevation.elevated:
        defaultBg = AppColors.surfaceElevated;
        defaultBorder = AppColors.borderEmphasis;
        break;
      case CardElevation.recessed:
        defaultBg = AppColors.surfaceRecessed;
        defaultBorder = AppColors.border;
        break;
      case CardElevation.standard:
        defaultBg = AppColors.surface;
        defaultBorder = AppColors.border;
        break;
    }

    final bg = backgroundColor ?? defaultBg;
    final border = borderColor ?? defaultBorder;
    final sigma = blurSigma ?? AppColors.glassBlurSigma;

    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          child: Container(
            padding: padding ?? const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(color: border, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.35)
                      : const Color(0xFF0F172A).withOpacity(0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                  spreadRadius: isDark ? 2 : -2,
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
