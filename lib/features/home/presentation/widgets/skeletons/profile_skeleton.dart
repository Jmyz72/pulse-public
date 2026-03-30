import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../shared/widgets/glass_card.dart';

/// Skeleton shimmer placeholder that mimics the ProfileTab layout
class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.grey50,
      highlightColor: AppColors.grey100,
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacingLg),
        child: Column(
          children: [
            // Avatar circle
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: AppColors.grey50,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 16),
            // Name
            Container(
              width: 150,
              height: 20,
              decoration: BoxDecoration(
                color: AppColors.grey50,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            // Email
            Container(
              width: 200,
              height: 14,
              decoration: BoxDecoration(
                color: AppColors.grey50,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 24),
            // Stats row
            GlassContainer(
              borderRadius: AppDimensions.radiusXl,
              backgroundOpacity: 0.03,
              padding: const EdgeInsets.symmetric(
                vertical: AppDimensions.spacingMd,
                horizontal: AppDimensions.spacingSm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(3, (_) {
                  return Column(
                    children: [
                      Container(
                        width: 40,
                        height: 18,
                        decoration: BoxDecoration(
                          color: AppColors.grey50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 60,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppColors.grey50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
            const SizedBox(height: 32),
            // Menu group 1
            _buildMenuGroupSkeleton(5),
            const SizedBox(height: 16),
            // Menu group 2
            _buildMenuGroupSkeleton(2),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuGroupSkeleton(int count) {
    return GlassContainer(
      borderRadius: AppDimensions.radiusXl,
      backgroundOpacity: 0.03,
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingSm),
      child: Column(
        children: List.generate(count, (index) {
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingMd,
              vertical: 12,
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: AppColors.grey50,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 120,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.grey50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
