import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

class DateDivider extends StatelessWidget {
  final String date;

  const DateDivider({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: AppColors.getGlassBorder(0.2))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.getGlassBackground(0.05),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
                    border: Border.all(
                      color: AppColors.getGlassBorder(0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    date,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(child: Divider(color: AppColors.getGlassBorder(0.2))),
        ],
      ),
    );
  }
}
