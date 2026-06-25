import 'package:flutter/material.dart';
import '../theme/colors.dart';

class CustomDropdown extends StatelessWidget {
  final String labelText;
  final String? value;
  final List<String> options;
  final IconData prefixIcon;
  final ValueChanged<String?> onChanged;

  const CustomDropdown({
    super.key,
    required this.labelText,
    required this.value,
    required this.options,
    required this.prefixIcon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.surface2,
          width: 1,
        ),
      ),
      child: Center(
        child: DropdownButtonFormField<String>(
          initialValue: value,
          onChanged: onChanged,
          dropdownColor: AppColors.surface2,
          style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
          iconEnabledColor: AppColors.textSecondary,
          decoration: InputDecoration(
            labelText: labelText,
            labelStyle: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            prefixIcon: Icon(prefixIcon, color: AppColors.textSecondary),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            contentPadding: const EdgeInsets.only(bottom: 8),
          ),
          items: options.map((option) {
            return DropdownMenuItem<String>(
              value: option,
              child: Text(option),
            );
          }).toList(),
        ),
      ),
    );
  }
}
