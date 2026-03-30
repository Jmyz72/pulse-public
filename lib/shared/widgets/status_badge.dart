import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';

enum BadgeStatus {
  pending,
  inProgress,
  completed,
  cancelled,
  overdue,
  paid,
  unpaid,
}

class StatusBadge extends StatelessWidget {
  final BadgeStatus status;
  final String? customLabel;
  final bool isSmall;

  const StatusBadge({
    super.key,
    required this.status,
    this.customLabel,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getConfig();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? AppDimensions.spacingSm : AppDimensions.spacingMd,
        vertical: isSmall ? AppDimensions.spacingXs : AppDimensions.spacingSm,
      ),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Text(
        customLabel ?? config.label,
        style: TextStyle(
          color: config.textColor,
          fontSize: isSmall ? 10 : 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  _BadgeConfig _getConfig() {
    switch (status) {
      case BadgeStatus.pending:
        return _BadgeConfig(
          label: 'Pending',
          backgroundColor: AppColors.warning.withValues(alpha: 0.1),
          textColor: AppColors.warning,
        );
      case BadgeStatus.inProgress:
        return _BadgeConfig(
          label: 'In Progress',
          backgroundColor: AppColors.info.withValues(alpha: 0.1),
          textColor: AppColors.info,
        );
      case BadgeStatus.completed:
        return _BadgeConfig(
          label: 'Completed',
          backgroundColor: AppColors.success.withValues(alpha: 0.1),
          textColor: AppColors.success,
        );
      case BadgeStatus.cancelled:
        return _BadgeConfig(
          label: 'Cancelled',
          backgroundColor: AppColors.grey300.withValues(alpha: 0.3),
          textColor: AppColors.grey500,
        );
      case BadgeStatus.overdue:
        return _BadgeConfig(
          label: 'Overdue',
          backgroundColor: AppColors.error.withValues(alpha: 0.1),
          textColor: AppColors.error,
        );
      case BadgeStatus.paid:
        return _BadgeConfig(
          label: 'Paid',
          backgroundColor: AppColors.success.withValues(alpha: 0.1),
          textColor: AppColors.success,
        );
      case BadgeStatus.unpaid:
        return _BadgeConfig(
          label: 'Unpaid',
          backgroundColor: AppColors.error.withValues(alpha: 0.1),
          textColor: AppColors.error,
        );
    }
  }
}

class _BadgeConfig {
  final String label;
  final Color backgroundColor;
  final Color textColor;

  const _BadgeConfig({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });
}
