import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

/// A reusable menu option widget with icon badge, title, and chevron
///
/// Commonly used for navigation lists in settings, profile, and option screens.
/// Features a tappable InkWell with rounded corners, icon badge, and trailing chevron.
///
/// Example usage:
/// ```dart
/// MenuOption(
///   title: 'Edit Profile',
///   icon: Icons.edit_outlined,
///   onTap: () => Navigator.pushNamed(context, '/settings'),
/// )
/// ```
class MenuOption extends StatelessWidget {
  /// The title text to display
  final String title;

  /// The icon to display in the leading badge
  final IconData icon;

  /// Callback when the option is tapped
  final VoidCallback onTap;

  /// Custom color for the icon (defaults to theme primary)
  final Color? iconColor;

  /// Custom background color for the icon badge (defaults to primaryContainer with 50% opacity)
  final Color? backgroundColor;

  const MenuOption({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.iconColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: title,
      button: true,
      child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.spacingMd),
        child: Row(
          children: [
            // Icon badge
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: backgroundColor ?? AppColors.secondary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: Icon(
                icon,
                color: iconColor ?? AppColors.primary,
              ),
            ),
            const SizedBox(width: AppDimensions.spacingMd),

            // Title
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            // Chevron
            const Icon(
              Icons.chevron_right,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    ),
    );
  }
}
