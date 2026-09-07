import 'package:intl/intl.dart';

/// Date formatting helpers used across the app.
///
/// NOTE: Screens import this alongside `package:flutter/material.dart`,
/// which also exports a `DateUtils`. Affected screens use
/// `import 'package:flutter/material.dart' hide DateUtils;` to resolve
/// the ambiguity in favour of this class.
class DateUtils {
  DateUtils._();

  /// Formats a [DateTime] as `dd/MM/yyyy`.
  static String formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  /// Formats a [DateTime] as `HH:mm`.
  static String formatTime(DateTime? date) {
    if (date == null) return '';
    return DateFormat('HH:mm').format(date);
  }

  /// Formats a [DateTime] as `dd/MM/yyyy HH:mm`.
  static String formatDateTime(DateTime? date) {
    if (date == null) return '';
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  /// Parses a string in `dd/MM/yyyy` format to a [DateTime].
  static DateTime? parseDate(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateFormat('dd/MM/yyyy').tryParse(value);
  }

  /// Returns a `yyyy-MM-dd` date string (for API payloads).
  static String toApiDate(DateTime date) {
    return date.toIso8601String().split('T').first;
  }

  /// Returns `true` if both dates are on the same calendar day.
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Returns `true` if the given date is today.
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return isSameDay(date, now);
  }
}
