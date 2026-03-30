import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

/// A reusable chip widget for quick actions in chat
///
/// Used for actions like:
/// - Split Expense
/// - Shopping List
/// - New Event
/// - Task Items
/// - Grocery Items
class QuickActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const QuickActionChip({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chipColor = color ?? theme.colorScheme.primary;

    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.getGlassBackground(0.05),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(
                color: chipColor.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon with colored background
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: chipColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: chipColor,
                  ),
                ),
                const SizedBox(width: 8),
                // Label
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}
