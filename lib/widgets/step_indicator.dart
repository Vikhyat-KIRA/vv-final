import 'package:flutter/material.dart';
import '../theme/colors.dart';

class StepIndicator extends StatelessWidget {
  final int totalSteps;
  final int currentIndex;

  const StepIndicator({
    super.key,
    required this.totalSteps,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSteps, (index) {
        final isActive = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: isActive ? 12 : 6,
          height: isActive ? 12 : 6,
          decoration: BoxDecoration(
            color: isActive ? AppColors.accentDefault : AppColors.textSecondary.withAlpha(100),
            shape: BoxShape.circle,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.accentDefault.withAlpha(150),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }
}
