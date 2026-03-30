import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../shared/widgets/glass_card.dart';

/// Tile sizes for the bento grid layout
enum BentoTileSize {
  /// 1 column, 80px height - compact info display
  small,

  /// 1 column, 120px height - standard feature tile
  medium,

  /// 2 columns, 180px height - hero/overview tile
  large,
}

/// A flexible tile widget for the bento grid layout
///
/// Uses GlassContainer with Cyber-Teal design system:
/// - Feature-colored borders
/// - Glass background (white at 5% opacity)
/// - 16px border radius
/// - Badge support for counts
class BentoGridTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final String? badgeCount;
  final String? subtitle;
  final VoidCallback onTap;
  final BentoTileSize size;
  final Widget? customContent;

  const BentoGridTile({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    this.badgeCount,
    this.subtitle,
    required this.onTap,
    this.size = BentoTileSize.medium,
    this.customContent,
  });

  double get _height {
    switch (size) {
      case BentoTileSize.small:
        return 80;
      case BentoTileSize.medium:
        return 120;
      case BentoTileSize.large:
        return 180;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final semanticLabel = [
      label,
      if (subtitle != null) subtitle,
      if (_hasBadge) '$badgeCount pending',
    ].join(', ');

    return RepaintBoundary(
      child: Semantics(
      label: semanticLabel,
      button: true,
      child: SizedBox(
        height: _height,
        child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
          child: GlassContainer(
            borderRadius: AppDimensions.radiusXl,
            backgroundOpacity: 0.05,
            borderOpacity: 0.4,
            borderColor: color,
            padding: EdgeInsets.all(
              size == BentoTileSize.large
                  ? AppDimensions.spacingMd + 4
                  : AppDimensions.spacingMd,
            ),
            child: customContent ?? _buildDefaultContent(theme),
          ),
        ),
      ),
      ),
    ),
    );
  }

  Widget _buildDefaultContent(ThemeData theme) {
    switch (size) {
      case BentoTileSize.large:
        return _buildLargeContent(theme);
      case BentoTileSize.medium:
        return _buildMediumContent(theme);
      case BentoTileSize.small:
        return _buildSmallContent(theme);
    }
  }

  /// Large tile: icon + label top-left, subtitle below, badge top-right
  Widget _buildLargeContent(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                  child: Icon(icon, color: color, size: AppDimensions.iconMd),
                ),
                const SizedBox(width: AppDimensions.spacingMd),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            if (_hasBadge)
              _buildBadge(theme),
          ],
        ),
        const Spacer(),
        if (subtitle != null)
          Icon(
            Icons.chevron_right,
            color: color.withValues(alpha: 0.6),
            size: 20,
          ),
      ],
    );
  }

  /// Medium tile: centered icon + label, badge top-right
  Widget _buildMediumContent(ThemeData theme) {
    return Stack(
      children: [
        // Badge
        if (_hasBadge)
          Positioned(
            right: 0,
            top: 0,
            child: _buildBadge(theme),
          ),
        // Content
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: AppDimensions.spacingSm),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    color: AppColors.textTertiary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Small tile: horizontal icon + label, badge right
  Widget _buildSmallContent(ThemeData theme) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: AppDimensions.spacingSm),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (_hasBadge)
          _buildBadge(theme),
      ],
    );
  }

  bool get _hasBadge =>
      badgeCount != null && badgeCount!.isNotEmpty && badgeCount != '0';

  Widget _buildBadge(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        badgeCount!,
        style: theme.textTheme.bodySmall?.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
