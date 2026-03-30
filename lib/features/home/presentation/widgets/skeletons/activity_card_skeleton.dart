import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../shared/widgets/glass_card.dart';

/// Skeleton shimmer placeholder that mimics the ActivityCard list
class ActivityCardSkeleton extends StatelessWidget {
  final int count;

  const ActivityCardSkeleton({super.key, this.count = 3});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.grey50,
      highlightColor: AppColors.grey100,
      child: Column(
        children: List.generate(count, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GlassContainer(
              borderRadius: AppDimensions.radiusXl,
              backgroundOpacity: 0.03,
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Icon circle
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.grey50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Text lines
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 14,
                          decoration: BoxDecoration(
                            color: AppColors.grey50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 120,
                          height: 12,
                          decoration: BoxDecoration(
                            color: AppColors.grey50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
