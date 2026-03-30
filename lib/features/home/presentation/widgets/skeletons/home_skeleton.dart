import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../shared/widgets/glass_card.dart';
import 'activity_card_skeleton.dart';

/// Full home dashboard skeleton that mimics the redesigned HomeTab layout.
class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // App bar with shimmer greeting
        SliverAppBar(
          floating: true,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          title: Shimmer.fromColors(
            baseColor: AppColors.grey50,
            highlightColor: AppColors.grey100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 180,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.grey50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 140,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.grey50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.all(AppDimensions.spacingLg),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildShimmerTile(height: 244),
              const SizedBox(height: AppDimensions.spacingLg),

              _buildSectionHeaderSkeleton(),
              const SizedBox(height: AppDimensions.spacingSm),
              _buildAttentionListSkeleton(),
              const SizedBox(height: AppDimensions.spacingMd),

              _buildSectionHeaderSkeleton(),
              const SizedBox(height: AppDimensions.spacingSm),
              _buildMembersRowSkeleton(),
              const SizedBox(height: AppDimensions.spacingLg),

              _buildSectionHeaderSkeleton(),
              const SizedBox(height: AppDimensions.spacingSm),
              _buildStoryCardsSkeleton(),
              const SizedBox(height: AppDimensions.spacingLg),

              _buildSectionHeaderSkeleton(),
              const SizedBox(height: AppDimensions.spacingSm),
              _buildQuickActionsSkeleton(),
              const SizedBox(height: AppDimensions.spacingLg),

              _buildSectionHeaderSkeleton(withTrailing: true),
              const SizedBox(height: AppDimensions.spacingSm),
              const ActivityCardSkeleton(count: 3),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildMembersRowSkeleton() {
    return Shimmer.fromColors(
      baseColor: AppColors.grey50,
      highlightColor: AppColors.grey100,
      child: GlassContainer(
        borderRadius: AppDimensions.radiusXl,
        backgroundOpacity: 0.03,
        padding: const EdgeInsets.all(AppDimensions.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 100,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.grey50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Container(
                  width: 60,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.grey50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingMd),
            // 5 avatar circles
            Row(
              children: List.generate(
                5,
                (_) => Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: AppColors.grey50,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 36,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppColors.grey50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttentionListSkeleton() {
    return Shimmer.fromColors(
      baseColor: AppColors.grey50,
      highlightColor: AppColors.grey100,
      child: Column(
        children: [
          _buildShimmerTileInner(height: 92),
          const SizedBox(height: AppDimensions.spacingSm),
          _buildShimmerTileInner(height: 92),
          const SizedBox(height: AppDimensions.spacingSm),
          _buildShimmerTileInner(height: 92),
        ],
      ),
    );
  }

  Widget _buildStoryCardsSkeleton() {
    return Shimmer.fromColors(
      baseColor: AppColors.grey50,
      highlightColor: AppColors.grey100,
      child: Column(
        children: List.generate(
          3,
          (rowIndex) => Padding(
            padding: EdgeInsets.only(
              bottom: rowIndex < 2 ? AppDimensions.spacingMd : 0,
            ),
            child: Row(
              children: List.generate(
                2,
                (columnIndex) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: columnIndex == 0 ? AppDimensions.spacingMd : 0,
                    ),
                    child: _buildShimmerTileInner(height: 172),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerTile({required double height}) {
    return Shimmer.fromColors(
      baseColor: AppColors.grey50,
      highlightColor: AppColors.grey100,
      child: _buildShimmerTileInner(height: height),
    );
  }

  Widget _buildSectionHeaderSkeleton({bool withTrailing = false}) {
    return Shimmer.fromColors(
      baseColor: AppColors.grey50,
      highlightColor: AppColors.grey100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 92,
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.grey50,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 200,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.grey50,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          if (withTrailing)
            Container(
              width: 60,
              height: 14,
              decoration: BoxDecoration(
                color: AppColors.grey50,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildShimmerTileInner({required double height}) {
    return GlassContainer(
      height: height,
      borderRadius: AppDimensions.radiusXl,
      backgroundOpacity: 0.03,
      padding: EdgeInsets.zero,
      child: const SizedBox.expand(),
    );
  }

  Widget _buildQuickActionsSkeleton() {
    return Shimmer.fromColors(
      baseColor: AppColors.grey50,
      highlightColor: AppColors.grey100,
      child: Row(
        children: List.generate(
          4,
          (i) => Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: i < 3 ? AppDimensions.spacingSm : 0,
              ),
              child: const GlassContainer(
                height: 56,
                borderRadius: AppDimensions.radiusLg,
                backgroundOpacity: 0.03,
                padding: EdgeInsets.zero,
                child: SizedBox.expand(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
