import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../shared/widgets/glass_card.dart';

/// Skeleton shimmer placeholder that mimics the BentoGrid layout
class BentoGridSkeleton extends StatelessWidget {
  const BentoGridSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.grey50,
      highlightColor: AppColors.grey100,
      child: Column(
        children: [
          // Hero tile (2 columns, 180px)
          _buildShimmerTile(height: 180),
          const SizedBox(height: AppDimensions.spacingMd),
          // 4 rows of 2 tiles (120px each)
          for (int i = 0; i < 4; i++) ...[
            Row(
              children: [
                Expanded(child: _buildShimmerTile(height: 120)),
                const SizedBox(width: AppDimensions.spacingMd),
                Expanded(child: _buildShimmerTile(height: 120)),
              ],
            ),
            if (i < 3) const SizedBox(height: AppDimensions.spacingMd),
          ],
        ],
      ),
    );
  }

  Widget _buildShimmerTile({required double height}) {
    return GlassContainer(
      height: height,
      borderRadius: AppDimensions.radiusXl,
      backgroundOpacity: 0.03,
      padding: EdgeInsets.zero,
      child: const SizedBox.expand(),
    );
  }
}
