import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/flashcard_model.dart';
import '../theme/colors.dart';

class FlashCardWidget extends StatefulWidget {
  final FlashcardModel card;
  final Color accentColor;

  const FlashCardWidget({
    super.key,
    required this.card,
    required this.accentColor,
  });

  @override
  State<FlashCardWidget> createState() => _FlashCardWidgetState();
}

class _FlashCardWidgetState extends State<FlashCardWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(covariant FlashCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.card.id != widget.card.id) {
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleFlip() {
    if (_controller.isDismissed) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleFlip,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final isBack = _animation.value > 0.5;
          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.001) // perspective
            ..rotateY(_animation.value * math.pi);

          return Transform(
            transform: transform,
            alignment: Alignment.center,
            child: isBack
                ? Transform(
                    // Counter-rotate the back child so text isn't mirrored
                    transform: Matrix4.rotationY(math.pi),
                    alignment: Alignment.center,
                    child: _buildCardSide(
                      content: widget.card.back,
                      label: 'ANSWER',
                      hint: 'Tap to see question',
                      isBack: true,
                    ),
                  )
                : _buildCardSide(
                    content: widget.card.front,
                    label: 'QUESTION',
                    hint: 'Tap to reveal answer',
                    isBack: false,
                  ),
          );
        },
      ),
    );
  }

  Widget _buildCardSide({
    required String content,
    required String label,
    required String hint,
    required bool isBack,
  }) {
    return Container(
      width: double.infinity,
      height: 320,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isBack ? widget.accentColor.withValues(alpha: 0.08) : AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isBack ? widget.accentColor.withValues(alpha: 0.3) : AppColors.surface2,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Header Label
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isBack ? widget.accentColor : AppColors.textSecondary,
              letterSpacing: 1.5,
              fontFamily: 'Playfair Display',
            ),
          ),

          // Content
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Text(
                  content,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontFamily: 'Playfair Display',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),

          // Bottom Hint
          Text(
            hint,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
