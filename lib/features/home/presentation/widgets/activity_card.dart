import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../shared/widgets/glass_card.dart';

enum ActivityCardVariant { preview, feed }

/// Activity card widget for home dashboard and activity feed
///
/// Supports two variants:
/// - Preview: For short dashboard previews
/// - Feed: For the full activity timeline
class ActivityCard extends StatelessWidget {
  final String title;
  final String description;
  final String timeAgo;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final ActivityCardVariant variant;

  const ActivityCard({
    super.key,
    required this.title,
    required this.description,
    required this.timeAgo,
    required this.icon,
    required this.color,
    this.onTap,
    this.variant = ActivityCardVariant.feed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPreview = variant == ActivityCardVariant.preview;

    return Semantics(
      label: '$title, $description, $timeAgo',
      button: true,
      child: RepaintBoundary(
        child: Container(
          margin: EdgeInsets.only(bottom: isPreview ? 8 : 12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
            child: GlassContainer(
              borderRadius: AppDimensions.radiusXl,
              backgroundOpacity: 0.03,
              borderOpacity: 0.4,
              padding: EdgeInsets.all(isPreview ? 12 : 16),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isPreview ? 10 : 12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: isPreview ? 20 : 24),
                  ),
                  SizedBox(width: isPreview ? 12 : 16),
                  Expanded(
                    child: isPreview
                        ? _buildCompactContent(theme)
                        : _buildExpandedContent(theme),
                  ),
                  if (isPreview)
                    Text(
                      timeAgo,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    )
                  else
                    const Icon(
                      Icons.chevron_right,
                      color: AppColors.textTertiary,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactContent(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          description,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedContent(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          timeAgo,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textTertiary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
