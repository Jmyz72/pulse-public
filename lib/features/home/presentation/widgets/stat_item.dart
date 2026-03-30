import 'package:flutter/material.dart';

/// Display variant for StatItem widget
enum StatItemVariant {
  /// Horizontal layout: Icon + label above, value below (for gradient backgrounds)
  horizontal,

  /// Vertical layout: Value above, label below (for plain backgrounds)
  vertical,
}

/// A flexible widget for displaying statistics with icon support
///
/// Supports two layout variants:
/// - **Horizontal**: Icon + label on top, value below (for cards with gradient backgrounds)
/// - **Vertical**: Value on top, label below (for profile stats)
///
/// Example usage:
/// ```dart
/// StatItem(
///   variant: StatItemVariant.horizontal,
///   label: 'Total',
///   value: 'RM 1,234.56',
///   icon: Icons.account_balance_wallet,
///   valueColor: Colors.white,
/// )
/// ```
class StatItem extends StatelessWidget {
  /// The value to display (e.g., "RM 123.45", "5")
  final String value;

  /// The label describing the value (e.g., "Total", "Members")
  final String label;

  /// Optional icon to display (only shown in horizontal variant)
  final IconData? icon;

  /// Layout variant (horizontal or vertical)
  final StatItemVariant variant;

  /// Color for the value text (defaults to theme color)
  final Color? valueColor;

  /// Color for the icon (defaults to onPrimary with 90% opacity)
  final Color? iconColor;

  /// Color for the label text (defaults to theme color)
  final Color? labelColor;

  const StatItem({
    super.key,
    required this.value,
    required this.label,
    this.icon,
    this.variant = StatItemVariant.horizontal,
    this.valueColor,
    this.iconColor,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: '$label, $value',
      child: variant == StatItemVariant.horizontal
          ? _buildHorizontalLayout(theme)
          : _buildVerticalLayout(theme),
    );
  }

  /// Horizontal layout: Icon + label above, value below
  /// Used on gradient backgrounds (home card)
  Widget _buildHorizontalLayout(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: iconColor ?? theme.colorScheme.onPrimary.withValues(alpha: 0.9),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: labelColor ?? theme.colorScheme.onPrimary.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            color: valueColor ?? theme.colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Vertical layout: Value above, label below
  /// Used on plain backgrounds (profile tab)
  Widget _buildVerticalLayout(ThemeData theme) {
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor ?? theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: labelColor ?? theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
