import 'package:flutter/material.dart';

/// App-wide constants used across the staff-app.
class Constants {
  Constants._();

  /// Primary brand color (green to match the staff app theme).
  static const Color primaryColor = Color(0xFF4CAF50);

  /// Secondary brand color (dark teal).
  static const Color secondaryColor = Color(0xFF00838F);

  /// Accent / tertiary brand color.
  static const Color accentColor = Color(0xFFFF9800);

  /// Error / danger color.
  static const Color errorColor = Color(0xFFD32F2F);

  /// Success color.
  static const Color successColor = Color(0xFF388E3C);

  /// Card border radius.
  static const double defaultBorderRadius = 12.0;

  /// Default page padding.
  static const EdgeInsets pagePadding = EdgeInsets.all(16.0);

  /// Default gap between form fields.
  static const double fieldSpacing = 16.0;

  /// Maximum characters for text fields.
  static const int maxTextFieldLength = 200;
}