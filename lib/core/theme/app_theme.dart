import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

class AppTheme {
  AppTheme._();

  /// Pulse Cyber-Teal Theme (Default)
  /// Dark theme with neon accents and glassmorphism
  static ThemeData get cyberTealTheme {
    return ThemeData(
      // Color Scheme (Cyber-Teal)
      colorScheme: const ColorScheme.dark(
        brightness: Brightness.dark,
        primary: AppColors.primary, // Neon Cyan
        onPrimary: AppColors.white,
        secondary: AppColors.secondary, // Electric Teal
        onSecondary: AppColors.white,
        error: AppColors.error,
        onError: AppColors.white,
        surface: AppColors.background, // Deep Obsidian
        onSurface: AppColors.textPrimary,
      ),

      // Scaffold
      scaffoldBackgroundColor: Colors.transparent,

      // Material 3
      useMaterial3: true,

      // Typography
      textTheme: const TextTheme(
        // Hero numbers (e.g., "$2,450.00")
        displayLarge: TextStyle(
          fontSize: 64,
          fontWeight: FontWeight.w900,
          color: AppColors.textPrimary,
          letterSpacing: -1,
        ),
        displayMedium: TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),

        // Section headers (e.g., "TOTAL POT")
        headlineMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          letterSpacing: 1.5,
        ),
        headlineSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          letterSpacing: 1.2,
        ),

        // Card titles (e.g., "Rent", "Groceries")
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        titleSmall: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),

        // Body text
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary, // 60% opacity
        ),

        // Labels (e.g., "+12.5%", "75%")
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textCyan, // Cyan labels
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textTeal, // Teal labels
        ),
        labelSmall: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),
      ),

      // AppBar (Glassmorphism)
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(
          color: AppColors.textPrimary,
        ),
      ),

      // Cards (Glassmorphism - but use GlassCard widget instead)
      cardTheme: CardThemeData(
        elevation: 0, // No shadows in Cyber-Teal
        color: Colors.white.withValues(alpha:0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24), // 24px radius
          side: BorderSide(
            color: AppColors.secondary.withValues(alpha:0.4),
            width: 1.5,
          ),
        ),
        margin: const EdgeInsets.all(0),
      ),

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.grey500,
          disabledForegroundColor: AppColors.grey700,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: BorderSide(
            color: AppColors.secondary.withValues(alpha:0.4),
            width: 1.5,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // FAB (Center elevated button)
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary, // Bright cyan
        foregroundColor: AppColors.white,
        elevation: 0,
        shape: CircleBorder(),
        sizeConstraints: BoxConstraints.tightFor(
          width: 64,
          height: 64,
        ),
      ),

      // Input Fields (Glassmorphism)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha:0.03),
        hintStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
        labelStyle: const TextStyle(
          color: AppColors.textTeal,
          fontSize: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.secondary.withValues(alpha:0.4),
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.secondary.withValues(alpha:0.4),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.primary, // Neon cyan when focused
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),

      // Bottom Navigation (Glassmorphism)
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white.withValues(alpha:0.03),
        selectedItemColor: AppColors.primary, // Neon cyan when active
        unselectedItemColor: AppColors.grey500, // Gray when inactive
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: AppColors.secondary.withValues(alpha:0.2),
        thickness: 1,
        space: 1,
      ),

      // Progress Indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.progressTrack,
        circularTrackColor: AppColors.progressTrack,
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white.withValues(alpha:0.05),
        selectedColor: AppColors.primary.withValues(alpha:0.2),
        labelStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        side: BorderSide(
          color: AppColors.secondary.withValues(alpha:0.4),
          width: 1,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),

      // Dialog
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
          side: BorderSide(
            color: AppColors.glassBorder,
            width: 1.5,
          ),
        ),
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Colors.white.withValues(alpha:0.1),
        contentTextStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: AppColors.secondary.withValues(alpha:0.4),
            width: 1,
          ),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Legacy Light Theme (Deprecated)
  /// @deprecated Use cyberTealTheme instead
  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.oldPrimary,
        secondary: AppColors.oldSecondary,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        ),
      ),
    );
  }

  /// Legacy Dark Theme (Deprecated)
  /// @deprecated Use cyberTealTheme instead
  static ThemeData get darkTheme => cyberTealTheme;
}
