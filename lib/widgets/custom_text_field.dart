import 'package:flutter/material.dart';
import '../theme/colors.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final IconData prefixIcon;
  final String? hintText;
  final ValueChanged<String>? onChanged;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.prefixIcon,
    this.hintText,
    this.onChanged,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasText = widget.controller.text.isNotEmpty;
    final isLabelFloating = _isFocused || hasText;

    return Container(
      height: 68,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isFocused ? AppColors.accentDefault : AppColors.surface2,
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          // Animated Label
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            left: 48,
            top: isLabelFloating ? 8 : 20,
            child: Text(
              widget.labelText,
              style: TextStyle(
                color: isLabelFloating 
                    ? (_isFocused ? AppColors.accentDefault : AppColors.textSecondary)
                    : AppColors.textSecondary,
                fontSize: isLabelFloating ? 11 : 14,
                fontWeight: isLabelFloating ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          // Input Field
          Positioned.fill(
            child: Row(
              children: [
                SizedBox(width: 12),
                Icon(widget.prefixIcon, color: _isFocused ? AppColors.accentDefault : AppColors.textSecondary),
                SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(top: isLabelFloating ? 18.0 : 4.0),
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _focusNode,
                      onChanged: widget.onChanged,
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
                      decoration: InputDecoration(
                        hintText: isLabelFloating ? null : widget.hintText,
                        hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        filled: false,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
