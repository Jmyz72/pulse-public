import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// A member avatar card with online status indicator
///
/// Displays a circular avatar with gradient background, online/offline status border,
/// status indicator dot, member name, and status text. Reusable across location,
/// friends, groups, and chat features.
///
/// Example usage:
/// ```dart
/// MemberAvatarCard(
///   name: 'John Doe',
///   avatarInitial: 'J',
///   isOnline: true,
///   size: 70,
/// )
/// ```
class MemberAvatarCard extends StatelessWidget {
  /// The member's full name
  final String name;

  /// The initial letter(s) to display in the avatar
  final String avatarInitial;

  /// Optional profile photo URL. Falls back to [avatarInitial] when missing/invalid.
  final String? imageUrl;

  /// Whether the member is currently online
  final bool isOnline;

  /// The size of the avatar circle (default: 70)
  final double size;

  /// Whether to show the online status indicator dot (default: true)
  final bool showStatus;

  /// Whether to show the member's name below the avatar (default: true)
  final bool showName;

  /// Optional callback when the avatar is tapped
  final VoidCallback? onTap;

  /// Compact mode: smaller avatar (44px), narrower (64px), no status text
  final bool compact;

  const MemberAvatarCard({
    super.key,
    required this.name,
    required this.avatarInitial,
    this.imageUrl,
    required this.isOnline,
    this.size = 70,
    this.showStatus = true,
    this.showName = true,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveSize = compact ? 44.0 : size;
    final containerWidth = showName ? (compact ? 64.0 : 100.0) : effectiveSize;
    final indicatorSize = compact ? 14.0 : 20.0;
    final borderWidth = compact ? 2.0 : 3.0;
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;

    return RepaintBoundary(
      child: Semantics(
        label: '$name, ${isOnline ? "online" : "offline"}',
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: containerWidth,
            margin: EdgeInsets.only(right: showName ? 12 : 0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Avatar with online status
                Stack(
                  children: [
                    Container(
                      width: effectiveSize,
                      height: effectiveSize,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.secondary],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isOnline
                              ? AppColors.success
                              : AppColors.grey500,
                          width: borderWidth,
                        ),
                      ),
                      child: ClipOval(
                        child: hasImage
                            ? Image.network(
                                imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _buildInitialContent(theme),
                              )
                            : _buildInitialContent(theme),
                      ),
                    ),
                    if (showStatus && isOnline)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: indicatorSize,
                          height: indicatorSize,
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.background,
                              width: borderWidth,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                if (showName) ...[
                  const SizedBox(height: 4),
                  Text(
                    name.split(' ')[0],
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: compact ? 11 : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  if (!compact) ...[
                    const SizedBox(height: 2),
                    Text(
                      isOnline ? 'Online' : 'Offline',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isOnline
                            ? AppColors.success
                            : AppColors.textTertiary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInitialContent(ThemeData theme) {
    return Center(
      child: Text(
        avatarInitial,
        style:
            (compact
                    ? theme.textTheme.titleMedium
                    : theme.textTheme.headlineMedium)
                ?.copyWith(color: AppColors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}
