import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../shared/widgets/glass_card.dart';

/// Skeleton shimmer placeholder that mimics the chat room list
class ChatSkeleton extends StatelessWidget {
  final int count;

  const ChatSkeleton({super.key, this.count = 6});

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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  // Avatar circle
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: AppColors.grey50,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Text lines
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Name placeholder
                            Container(
                              width: 120,
                              height: 14,
                              decoration: BoxDecoration(
                                color: AppColors.grey50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            // Timestamp placeholder
                            Container(
                              width: 40,
                              height: 12,
                              decoration: BoxDecoration(
                                color: AppColors.grey50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Message preview placeholder
                        Container(
                          width: double.infinity,
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
