import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/timetable_entry.dart';

class TimetableConstants {
  TimetableConstants._();

  static const List<Color> colorOptions = [
    Color(0xFFEF4444),
    Color(0xFFF97316),
    Color(0xFFF59E0B),
    Color(0xFF22C55E),
    Color(0xFF3B82F6),
    Color(0xFF0EA5E9),
    Color(0xFF8B5CF6),
    Color(0xFFE91E63),
  ];

  static const Map<int, String> colorNames = {
    0xFFEF4444: 'Red',
    0xFFF97316: 'Orange',
    0xFFF59E0B: 'Amber',
    0xFF22C55E: 'Green',
    0xFF3B82F6: 'Blue',
    0xFF0EA5E9: 'Sky Blue',
    0xFF8B5CF6: 'Purple',
    0xFFE91E63: 'Magenta',
  };

  static String getColorName(Color color) {
    return colorNames[color.toARGB32()] ?? 'Custom';
  }

  static DateTime startOfDay(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static DateTime startOfWeek(DateTime value) {
    final normalized = startOfDay(value);
    return normalized.subtract(Duration(days: normalized.weekday - 1));
  }

  static bool isSameDate(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }

  static String formatShortDay(DateTime date) {
    return DateFormat('EEE').format(date);
  }

  static String formatDayNumber(DateTime date) {
    return DateFormat('d').format(date);
  }

  static String formatHeaderDate(DateTime date) {
    return DateFormat('EEE, d MMM yyyy').format(date);
  }

  static String formatMonthLabel(DateTime date) {
    return DateFormat('MMMM yyyy').format(date);
  }

  static String formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  static String formatTimeRange(TimetableEntry entry) {
    return '${formatTime(entry.startAt)} - ${formatTime(entry.endAt)}';
  }

  static String recurrenceSummary(TimetableEntry entry) {
    if (!entry.isRecurring) {
      return 'One-time';
    }

    final interval = entry.recurrenceInterval;
    final intervalLabel = interval == 1 ? '' : 'Every $interval ';

    switch (entry.recurrenceFrequency) {
      case TimetableRecurrenceFrequency.daily:
        return interval == 1 ? 'Daily' : '${intervalLabel}days';
      case TimetableRecurrenceFrequency.weekly:
        return interval == 1 ? 'Weekly' : '${intervalLabel}weeks';
      case TimetableRecurrenceFrequency.monthly:
        return interval == 1 ? 'Monthly' : '${intervalLabel}months';
      case TimetableRecurrenceFrequency.none:
        return 'One-time';
    }
  }
}

Color? parseColor(String? colorHex) {
  if (colorHex == null || colorHex.isEmpty) return null;
  try {
    final hex = colorHex.replaceFirst('#', '');
    if (hex.length == 6) {
      return Color(int.parse('FF$hex', radix: 16));
    }
    if (hex.length == 8) {
      return Color(int.parse(hex, radix: 16));
    }
  } catch (_) {}
  return null;
}
