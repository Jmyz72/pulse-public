import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ===== PULSE CYBER-TEAL DESIGN SYSTEM =====

  // Background (The Void)
  static const Color background = Color(0xFF0C171C); // Deep petrol slate
  static const Color backgroundLight = Color(0xFF16272F); // Elevated surface
  static const Color backgroundElevated = Color(0xFF20353E); // Soft slate

  // Atmospheric backdrop
  static const Color backdropTop = Color(0xFF10242B);
  static const Color backdropBottom = Color(0xFF1B313A);
  static const Color backdropGlowA = Color(0xFF2C7A88);
  static const Color backdropGlowB = Color(0xFF6A4D7C);
  static const Color backdropGlowC = Color(0xFF2A8B6D);
  static const Color backdropLine = Color(0x22D7F6FF);

  // Primary Accent (The Energy) - USE SPARINGLY
  static const Color primary = Color(0xFF00E5FF); // Neon Cyan
  static const Color primaryLight = Color(0xFF1AEAFF);
  static const Color primaryDark = Color(0xFF00C4D4);

  // Secondary Accent (The Depth)
  static const Color secondary = Color(0xFF008B9D); // Electric Teal
  static const Color secondaryLight = Color(0xFF00A3B8);
  static const Color secondaryDark = Color(0xFF007382);

  // Supporting Neons
  static const Color neonMagenta = Color(0xFFE91E63); // Magenta/Purple
  static const Color neonPurple = Color(0xFFAB47BC); // Purple variant
  static const Color neonGreen = Color(0xFF00E676); // Acid Green
  static const Color neonYellow = Color(0xFFFFC107); // Yellow/Amber

  // Glassmorphism
  static const Color glassBackground = Color(0x14F3FCFF);
  static const Color glassBackgroundLight = Color(0x0CF3FCFF);
  static const Color glassBorder = Color(0x664CB2C2);

  // Typography
  static const Color textPrimary = Color(0xFFFFFFFF); // White
  static const Color textSecondary = Color(0x99FFFFFF); // white.withOpacity(0.6)
  static const Color textTertiary = Color(0x66FFFFFF); // white.withOpacity(0.4)
  static const Color textCyan = Color(0xFF00E5FF); // For labels
  static const Color textTeal = Color(0xFF008B9D); // For secondary labels

  // Status Colors (Updated for Cyber-Teal)
  static const Color success = Color(0xFF00E676); // Neon Green
  static const Color warning = Color(0xFFFFC107); // Amber
  static const Color error = Color(0xFFFF1744); // Neon Red
  static const Color info = Color(0xFF00E5FF); // Neon Cyan

  // Status Indicators
  static const Color statusOnline = Color(0xFF00E676); // Green
  static const Color statusAway = Color(0xFFFFC107); // Yellow
  static const Color statusOffline = Color(0xFF78909C); // Gray

  // Feature Colors (Updated with Cyber Theme)
  static const Color expense = Color(0xFF00E5FF); // Neon Cyan
  static const Color grocery = Color(0xFF00E676); // Neon Green
  static const Color bill = Color(0xFFE91E63); // Magenta
  static const Color billDark = Color(0xFFC2185B);
  static const Color event = Color(0xFFAB47BC); // Purple
  static const Color eventDark = Color(0xFF8E24AA);
  static const Color camera = Color(0xFF00E5FF); // Cyan
  static const Color location = Color(0xFFFF1744); // Neon Red
  static const Color file = Color(0xFFAB47BC); // Purple

  // Task & Schedule Colors
  static const Color task = Color(0xFF10B981); // Emerald Green
  static const Color taskDark = Color(0xFF059669);
  static const Color schedule = Color(0xFF0EA5E9); // Sky Blue
  static const Color scheduleDark = Color(0xFF0284C7);

  // Chart & Visualization
  static const Color chartPrimary = Color(0xFF00E5FF); // Brightest (neon cyan)
  static const Color chartSecondary = Color(0xFF008B9D); // Mid (electric teal)
  static const Color chartTertiary = Color(0xFF005662); // Darkest (deep teal)

  // Progress Bars
  static const Color progressTrack = Color(0x33008B9D); // Teal at 20%
  static List<Color> progressGradient1 = const [
    Color(0xFFE91E63), // Magenta
    Color(0xFF00E5FF), // Cyan
  ];
  static List<Color> progressGradient2 = const [
    Color(0xFF008B9D), // Teal
    Color(0xFF00E5FF), // Cyan
  ];

  // Neutral Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  // Gray Scale (for rare use)
  static const Color grey50 = Color(0xFF0D1418);
  static const Color grey100 = Color(0xFF1A2630);
  static const Color grey200 = Color(0xFF273645);
  static const Color grey300 = Color(0xFF34465A);
  static const Color grey400 = Color(0xFF4A5F73);
  static const Color grey500 = Color(0xFF78909C);
  static const Color grey600 = Color(0xFF90A4AE);
  static const Color grey700 = Color(0xFFB0BEC5);
  static const Color grey800 = Color(0xFFCFD8DC);
  static const Color grey900 = Color(0xFFECEFF1);

  // ===== DEPRECATED COLORS (Material Design 3) =====
  // Keep for reference during migration, remove after all screens updated

  // @deprecated Use AppColors.primary (neon cyan) instead
  static const Color oldPrimary = Color(0xFF6366F1); // Old Indigo

  // @deprecated Use AppColors.secondary (electric teal) instead
  static const Color oldSecondary = Color(0xFFEC4899); // Old Pink

  // @deprecated Use specific feature colors instead
  static const Color oldTeal = Color(0xFF14B8A6);
  static const Color oldIndigo = Color(0xFF6366F1);
  static const Color oldPink = Color(0xFFEC4899);

  // ===== HELPER METHODS =====

  /// Get a color with custom opacity
  static Color withOpacity(Color color, double opacity) {
    return color.withValues(alpha: opacity);
  }

  /// Get glass background color (for cards)
  static Color getGlassBackground([double opacity = 0.05]) {
    return Colors.white.withValues(alpha: opacity);
  }

  /// Get glass border color
  static Color getGlassBorder([double opacity = 0.4]) {
    return secondary.withValues(alpha: opacity);
  }

  /// Get gradient for progress bars
  static LinearGradient getProgressGradient({bool useMagenta = false}) {
    return LinearGradient(
      colors: useMagenta ? progressGradient1 : progressGradient2,
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );
  }

  /// Get chart color based on index (for bar charts)
  static Color getChartColor(int index, int total) {
    // Gradient from dark teal to bright cyan
    final ratio = index / (total - 1);
    return Color.lerp(chartTertiary, chartPrimary, ratio) ?? chartPrimary;
  }
}
