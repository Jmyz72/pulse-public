import 'package:flutter/material.dart';
import '../../domain/entities/dashboard_data.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../shared/widgets/glass_card.dart';
import 'member_avatar_card.dart';

/// Full-width row showing members with online status.
///
/// Displays an online count on the left and an optional "See All" action
/// on the right,
/// followed by a horizontally scrollable list of compact member avatars
/// sorted with online members first.
class OnlineMembersRow extends StatelessWidget {
  final List<MemberSummary> members;
  final VoidCallback? onSeeAll;
  final VoidCallback? onAddFriends;

  const OnlineMembersRow({
    super.key,
    required this.members,
    this.onSeeAll,
    this.onAddFriends,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onlineCount = members.where((m) => m.isOnline).length;

    // Sort: online first
    final sorted = List<MemberSummary>.from(members)
      ..sort((a, b) {
        if (a.isOnline == b.isOnline) return 0;
        return a.isOnline ? -1 : 1;
      });

    return GlassContainer(
      borderRadius: AppDimensions.radiusXl,
      backgroundOpacity: 0.05,
      borderOpacity: 0.4,
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.spacingMd,
        AppDimensions.spacingMd,
        AppDimensions.spacingMd,
        AppDimensions.spacingSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: onlineCount > 0
                      ? AppColors.success.withValues(alpha: 0.15)
                      : AppColors.glassBackground,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: onlineCount > 0
                            ? AppColors.success
                            : AppColors.textTertiary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$onlineCount online now',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: onlineCount > 0
                            ? AppColors.success
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (onSeeAll != null)
                TextButton(
                  onPressed: onSeeAll,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'See All',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          // Members scroll
          if (sorted.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppDimensions.spacingSm,
              ),
              child: Center(
                child: Column(
                  children: [
                    Text(
                      'No people yet',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (onAddFriends != null) ...[
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: onAddFriends,
                        icon: const Icon(Icons.person_add, size: 16),
                        label: const Text('Invite people'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusFull,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 68,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: sorted
                      .map(
                        (member) => MemberAvatarCard(
                          name: member.name,
                          avatarInitial: member.avatarInitial,
                          imageUrl: member.photoUrl,
                          isOnline: member.isOnline,
                          compact: true,
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
