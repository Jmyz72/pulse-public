import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/widgets/initials_avatar.dart';
import '../../domain/entities/message.dart';

/// A reusable chat room tile for the chat list
///
/// Features:
/// - Avatar (group icon or user initials)
/// - Room name with unread indicator
/// - Last message preview
/// - Timestamp
/// - Unread badge
/// - Swipe to delete (Dismissible)
/// - Glassmorphism styling
class ChatTile extends StatelessWidget {
  final ChatRoom chatRoom;
  final String currentUserId;
  final bool hasUnread;
  final VoidCallback onTap;
  final VoidCallback onDismissed;
  final Future<bool?> Function(BuildContext) onConfirmDismiss;
  final String? displayName; // Optional override for 1:1 chat display names
  final String? avatarUrl; // Optional override for avatar URL

  const ChatTile({
    super.key,
    required this.chatRoom,
    required this.currentUserId,
    required this.hasUnread,
    required this.onTap,
    required this.onDismissed,
    required this.onConfirmDismiss,
    this.displayName,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lastMessage = chatRoom.lastMessage;

    return Dismissible(
      key: Key(chatRoom.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => onConfirmDismiss(context),
      onDismissed: (_) {
        HapticFeedback.heavyImpact();
        onDismissed();
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: hasUnread
                    ? AppColors.getGlassBackground(0.1)
                    : AppColors.getGlassBackground(0.05),
                borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
                border: Border.all(
                  color: hasUnread
                      ? AppColors.primary.withValues(alpha: 0.4)
                      : AppColors.getGlassBorder(0.2),
                  width: hasUnread ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  // Avatar
                  _buildAvatar(theme),
                  const SizedBox(width: 14),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name and timestamp row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  if (chatRoom.isGroup)
                                    const Padding(
                                      padding: EdgeInsets.only(right: 4),
                                      child: Icon(
                                        Icons.group,
                                        size: 16,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  Expanded(
                                    child: Text(
                                      displayName ?? chatRoom.name,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: hasUnread
                                                ? FontWeight.bold
                                                : FontWeight.w600,
                                          ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (lastMessage != null)
                              Text(
                                DateFormatter.formatRelativeTime(
                                  lastMessage.timestamp,
                                ),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: hasUnread
                                      ? AppColors.primary
                                      : theme.colorScheme.onSurface.withValues(
                                          alpha: 0.5,
                                        ),
                                  fontWeight: hasUnread
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Last message and unread badge row
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _getLastMessageText(lastMessage),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: hasUnread
                                      ? theme.colorScheme.onSurface.withValues(
                                          alpha: 0.9,
                                        )
                                      : theme.colorScheme.onSurface.withValues(
                                          alpha: 0.6,
                                        ),
                                  fontWeight: hasUnread
                                      ? FontWeight.w500
                                      : FontWeight.normal,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (hasUnread) ...[
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppColors.primary,
                                      AppColors.secondary,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  AppStrings.newLabel,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(ThemeData theme) {
    final resolvedAvatarUrl = (avatarUrl != null && avatarUrl!.isNotEmpty)
        ? avatarUrl
        : chatRoom.imageUrl;

    if (chatRoom.isGroup) {
      // Group avatar with icon
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: hasUnread
                ? [AppColors.primary, AppColors.secondary]
                : [
                    theme.colorScheme.surfaceContainerHighest,
                    theme.colorScheme.surfaceContainerHigh,
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: resolvedAvatarUrl != null
              ? ClipOval(
                  child: Image.network(
                    resolvedAvatarUrl,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Text('👥', style: TextStyle(fontSize: 26)),
                  ),
                )
              : const Text('👥', style: TextStyle(fontSize: 26)),
        ),
      );
    } else {
      // 1-on-1 chat with InitialsAvatar
      return InitialsAvatar(
        name: displayName ?? chatRoom.name,
        imageUrl: resolvedAvatarUrl,
        size: 56,
      );
    }
  }

  String _getLastMessageText(Message? lastMessage) {
    if (lastMessage == null) {
      return AppStrings.noMessagesYet;
    }
    if (lastMessage.type == MessageType.system) {
      return lastMessage.content;
    }
    return '${lastMessage.senderName}: ${lastMessage.content}';
  }
}
