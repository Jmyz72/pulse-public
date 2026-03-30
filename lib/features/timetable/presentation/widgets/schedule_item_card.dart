import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../domain/entities/timetable_entry.dart';
import 'timetable_constants.dart';

class ScheduleItemCard extends StatelessWidget {
  final TimetableEntry entry;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool showVisibility;

  const ScheduleItemCard({
    super.key,
    required this.entry,
    this.onTap,
    this.onLongPress,
    this.showVisibility = false,
  });

  @override
  Widget build(BuildContext context) {
    final entryColor = parseColor(entry.color) ?? AppColors.schedule;

    return Semantics(
      label: '${entry.title}, ${TimetableConstants.formatTimeRange(entry)}',
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppDimensions.spacingMd - 4),
        child: GlassCard(
          borderColor: entryColor,
          borderRadius: AppDimensions.radiusXl,
          padding: EdgeInsets.zero,
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.spacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.spacingSm + 2,
                          vertical: AppDimensions.spacingXs,
                        ),
                        decoration: BoxDecoration(
                          color: entryColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusSm,
                          ),
                        ),
                        child: Text(
                          TimetableConstants.formatTimeRange(entry),
                          style: TextStyle(
                            fontSize: 12,
                            color: entryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (showVisibility) _buildVisibilityBadge(),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spacingMd - 4),
                  Text(
                    entry.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingXs),
                  Row(
                    children: [
                      const Icon(
                        Icons.event_repeat,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: AppDimensions.spacingXs),
                      Expanded(
                        child: Text(
                          TimetableConstants.recurrenceSummary(entry),
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (entry.description != null &&
                      entry.description!.isNotEmpty) ...[
                    const SizedBox(height: AppDimensions.spacingXs),
                    Text(
                      entry.description!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVisibilityBadge() {
    IconData icon;
    String label;
    Color color;

    switch (entry.visibility) {
      case 'public':
        icon = Icons.public;
        label = 'Public';
        color = AppColors.success;
        break;
      case 'friends':
        icon = Icons.people;
        label = 'Friends';
        color = AppColors.info;
        break;
      default:
        icon = Icons.lock;
        label = 'Private';
        color = AppColors.grey500;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingSm,
        vertical: AppDimensions.spacingXs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: AppDimensions.spacingXs),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
