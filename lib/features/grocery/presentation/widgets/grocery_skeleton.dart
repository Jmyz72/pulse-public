import 'package:flutter/material.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../shared/widgets/shimmer_loading.dart';

class GrocerySkeleton extends StatelessWidget {
  const GrocerySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      child: Column(
        children: [
          // Summary card shimmer
          const ShimmerBox(
            width: double.infinity,
            height: 90,
            borderRadius: 24,
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          // Filter chip shimmers
          Row(
            children: List.generate(3, (index) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  left: index == 0 ? 0 : 6,
                  right: index == 2 ? 0 : 6,
                ),
                child: const ShimmerBox(
                  width: double.infinity,
                  height: 44,
                  borderRadius: 14,
                ),
              ),
            )),
          ),
          const SizedBox(height: AppDimensions.spacingLg),
          // Section header shimmer
          const Row(
            children: [
              ShimmerCircle(size: 18),
              SizedBox(width: 8),
              ShimmerBox(width: 120, height: 16, borderRadius: 8),
              Spacer(),
              ShimmerBox(width: 60, height: 14, borderRadius: 8),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          // Card skeletons
          ...List.generate(4, (index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ShimmerBox(
              width: double.infinity,
              height: _cardHeight(index),
              borderRadius: 24,
            ),
          )),
        ],
      ),
    );
  }

  // Vary heights slightly for a more natural look
  double _cardHeight(int index) {
    const heights = [110.0, 130.0, 110.0, 120.0];
    return heights[index % heights.length];
  }
}
