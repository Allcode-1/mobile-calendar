import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class DescriptionTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;

  const DescriptionTextField({
    super.key,
    required this.controller,
    this.hint = "Add description...",
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: null,
      keyboardType: TextInputType.multiline,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        fillColor: Colors.transparent,
        contentPadding: EdgeInsets.zero,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
      ),
    );
  }
}
