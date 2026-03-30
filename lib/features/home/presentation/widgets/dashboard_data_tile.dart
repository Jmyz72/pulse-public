import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../shared/widgets/glass_card.dart';

/// An informative dashboard tile that displays a big number with icon and label.
///
/// Used for Tasks, Bills, and Events tiles on the home dashboard.
/// Features a colored circle icon, prominent count, and descriptive subtitle.
class DashboardDataTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final int count;
  final String subtitle;
  final double height;
  final VoidCallback onTap;

  const DashboardDataTile({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.count,
    required this.subtitle,
    required this.height,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RepaintBoundary(
      child: Semantics(
        label: '$label, $count $subtitle',
        button: true,
        child: SizedBox(
          height: height,
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
                padding: const EdgeInsets.all(AppDimensions.spacingMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: label + count badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          label.toUpperCase(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            fontSize: 11,
                          ),
                        ),
                        if (count > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusFull,
                              ),
                            ),
                            child: Text(
                              '$count',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const Spacer(),
                    // Icon + big number
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusMd,
                            ),
                          ),
                          child: Icon(icon, color: color, size: 20),
                        ),
                        const SizedBox(width: AppDimensions.spacingSm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$count',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                subtitle,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
