import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../shared/widgets/glass_card.dart';

class TodaySummaryCard extends StatelessWidget {
  final int pendingTasksCount;
  final int pendingBillsCount;
  final int upcomingEventsCount;
  final int groceryItemsCount;

  const TodaySummaryCard({
    super.key,
    required this.pendingTasksCount,
    required this.pendingBillsCount,
    required this.upcomingEventsCount,
    required this.groceryItemsCount,
  });

  int get _attentionCount =>
      pendingTasksCount +
      pendingBillsCount +
      upcomingEventsCount +
      groceryItemsCount;

  String get _statusLine {
    if (_attentionCount == 0) {
      return 'Nothing urgent today';
    }
    if (_attentionCount == 1) {
      return '1 thing needs attention';
    }
    return '$_attentionCount things need attention';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassContainer(
      borderRadius: AppDimensions.radiusXl,
      backgroundOpacity: 0.07,
      borderOpacity: 0.5,
      borderColor: AppColors.primary,
      padding: const EdgeInsets.all(AppDimensions.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TODAY',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingSm),
          Text(
            _statusLine,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingXs),
          Text(
            'Open tasks, unpaid bills, upcoming events, and grocery items at a glance.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingLg),
          Row(
            children: [
              Expanded(
                child: _MetricPill(
                  label: 'Tasks',
                  value: pendingTasksCount,
                  color: AppColors.task,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingSm),
              Expanded(
                child: _MetricPill(
                  label: 'Bills',
                  value: pendingBillsCount,
                  color: AppColors.bill,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingSm),
          Row(
            children: [
              Expanded(
                child: _MetricPill(
                  label: 'Events',
                  value: upcomingEventsCount,
                  color: AppColors.event,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingSm),
              Expanded(
                child: _MetricPill(
                  label: 'Grocery',
                  value: groceryItemsCount,
                  color: AppColors.grocery,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _MetricPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingMd,
        vertical: AppDimensions.spacingSm + 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$value',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
