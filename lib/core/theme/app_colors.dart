import 'package:flutter/material.dart';

class AppColors {
  // main brand colors
  static const Color primary = Color(0xFF6C63FF); // Purple (accent)
  static const Color secondary = Color(0xFF03DAC6); // Mint (success/etc)

  // bg and surfaces
  static const Color background = Color(0xFF0F0F12); // very dark blue/black
  static const Color surface = Color(0xFF1D1D23); // cards color
  static const Color surfaceLight = Color(0xFF2C2C34); // To highlight elements

  // text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9EA3AE);

  // functional colors
  static const Color error = Color(0xFFFF5252);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);

  // colors for categories
  static const List<Color> categoryPalette = [
    Color(0xFF6C63FF), // Work
    Color(0xFFFF6B6B), // Personal
    Color(0xFF4ECDC4), // Study
    Color(0xFFFFE66D), // Health
    Color(0xFFA29BFE), // Hobby
  ];
}
