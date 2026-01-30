import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';

class QuickTaskField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmitted;

  const QuickTaskField({
    super.key,
    required this.controller,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.elementSpacing,
      ),
      child: TextField(
        controller: controller,
        onSubmitted: (_) => onSubmitted(),
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: "Quick task...",
          hintStyle: const TextStyle(color: AppColors.textSecondary),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          suffixIcon: IconButton(
            icon: const Icon(Icons.add_circle, color: AppColors.primary),
            onPressed: onSubmitted,
          ),
        ),
      ),
    );
  }
}
