import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';

/// A reusable confirmation dialog with glassmorphism styling
///
/// Features:
/// - Title and message
/// - Confirm and cancel actions
/// - Destructive action styling (red confirm button)
/// - Glassmorphism background
/// - Returns true if confirmed, false if cancelled, null if dismissed
class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final VoidCallback onConfirm;
  final bool isDestructive;
  final Widget? titleIcon;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    required this.onConfirm,
    this.confirmText = 'Confirm',
    this.cancelText = 'Cancel',
    this.isDestructive = false,
    this.titleIcon,
  });

  /// Static method to show the dialog and return the result
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onConfirm,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDestructive = false,
    Widget? titleIcon,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: title,
        message: message,
        onConfirm: onConfirm,
        confirmText: confirmText,
        cancelText: cancelText,
        isDestructive: isDestructive,
        titleIcon: titleIcon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.getGlassBackground(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
              border: Border.all(
                color: AppColors.getGlassBorder(0.4),
                width: 1.5,
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title with optional icon
                Row(
                  children: [
                    if (titleIcon != null) ...[
                      titleIcon!,
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Message
                Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 24),
                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Cancel button
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(
                        cancelText,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Confirm button
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(true);
                        onConfirm();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDestructive
                            ? AppColors.error
                            : theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                        ),
                      ),
                      child: Text(confirmText),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
