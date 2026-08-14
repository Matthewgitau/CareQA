import 'package:flutter/material.dart';

class AppColors {
  // Primary Brand Colors
  static const Color primary = Color(0xFF00BF6D);
  static const Color primaryLight = Color(0xFF66D99A);
  static const Color primaryDark = Color(0xFF009955);
  static const Color primarySurface = Color(0xFFF0FDF5);

  // Secondary Colors
  static const Color secondary = Color(0xFF1A73E8);
  static const Color secondaryLight = Color(0xFF4A9CF5);
  static const Color secondaryDark = Color(0xFF0D47A1);

  // Status Colors
  static const Color success = Color(0xFF00BF6D);
  static const Color warning = Color(0xFFFFB800);
  static const Color error = Color(0xFFE74C3C);
  static const Color info = Color(0xFF1A73E8);

  // Neutral Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF8FAFB);
  static const Color background = Color(0xFFF5F6FA);
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color border = Color(0xFFE5E7EB);

  // Dark Mode
  static const Color darkSurface = Color(0xFF1F2937);
  static const Color darkBackground = Color(0xFF111827);
  static const Color darkTextPrimary = Color(0xFFF9FAFB);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);
  static const Color darkBorder = Color(0xFF374151);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );
}
</arg_value></tool_call>