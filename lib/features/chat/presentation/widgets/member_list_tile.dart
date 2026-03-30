import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/initials_avatar.dart';

/// A reusable member list tile for group info screens
///
/// Features:
/// - Avatar with initials fallback
/// - Member name with "You" label for current user
/// - Admin badge
/// - Action menu (make admin, remove admin, remove member)
class MemberListTile extends StatelessWidget {
  final String memberId;
  final String memberName;
  final String? memberPhone;
  final String? memberImageUrl;
  final bool isAdmin;
  final bool isCurrentUser;
  final bool isCurrentUserAdmin;
  final bool showActions;
  final VoidCallback? onMakeAdmin;
  final VoidCallback? onRemoveAdmin;
  final VoidCallback? onRemoveMember;

  const MemberListTile({
    super.key,
    required this.memberId,
    required this.memberName,
    this.memberPhone,
    this.memberImageUrl,
    this.isAdmin = false,
    this.isCurrentUser = false,
    this.isCurrentUserAdmin = false,
    this.showActions = true,
    this.onMakeAdmin,
    this.onRemoveAdmin,
    this.onRemoveMember,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName = isCurrentUser ? 'You' : memberName;

    return ListTile(
      leading: InitialsAvatar(
        name: memberName,
        imageUrl: memberImageUrl,
        size: 40,
      ),
      title: Row(
        children: [
          Text(
            displayName,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (isAdmin) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Admin',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: memberPhone != null && memberPhone!.isNotEmpty
          ? Text(
              memberPhone!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            )
          : null,
      trailing: (isCurrentUserAdmin && showActions && !isCurrentUser)
          ? PopupMenuButton(
              icon: const Icon(Icons.more_vert),
              itemBuilder: (context) => [
                if (!isAdmin)
                  const PopupMenuItem(
                    value: 'make_admin',
                    child: Row(
                      children: [
                        Icon(Icons.admin_panel_settings, size: 20, color: AppColors.primary),
                        SizedBox(width: 12),
                        Text('Make Admin', style: TextStyle(color: AppColors.primary)),
                      ],
                    ),
                  ),
                if (isAdmin)
                  const PopupMenuItem(
                    value: 'remove_admin',
                    child: Row(
                      children: [
                        Icon(Icons.remove_moderator, size: 20, color: AppColors.warning),
                        SizedBox(width: 12),
                        Text('Remove Admin', style: TextStyle(color: AppColors.warning)),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'remove',
                  child: Row(
                    children: [
                      Icon(Icons.person_remove, size: 20, color: AppColors.error),
                      SizedBox(width: 12),
                      Text('Remove', style: TextStyle(color: AppColors.error)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'make_admin' && onMakeAdmin != null) {
                  onMakeAdmin!();
                } else if (value == 'remove_admin' && onRemoveAdmin != null) {
                  onRemoveAdmin!();
                } else if (value == 'remove' && onRemoveMember != null) {
                  onRemoveMember!();
                }
              },
            )
          : null,
    );
  }
}
