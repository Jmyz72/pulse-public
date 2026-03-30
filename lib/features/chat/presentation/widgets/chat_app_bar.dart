import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../shared/widgets/initials_avatar.dart';

class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String chatName;
  final String avatar;
  final String? avatarUrl;
  final bool isGroup;
  final List<dynamic> members;
  final Map<String, String> memberNames;
  final Map<String, String> memberPhones;
  final Map<String, String> memberPhotoUrls;
  final bool isOnline;
  final String chatRoomId;
  final List<String> typingUserIds;
  final VoidCallback? onSearchPressed;
  final bool isSearching;
  final List<dynamic> admins;

  const ChatAppBar({
    super.key,
    required this.chatName,
    required this.avatar,
    this.avatarUrl,
    required this.isGroup,
    required this.members,
    this.memberNames = const {},
    this.memberPhones = const {},
    this.memberPhotoUrls = const {},
    required this.isOnline,
    required this.chatRoomId,
    this.typingUserIds = const [],
    this.onSearchPressed,
    this.isSearching = false,
    this.admins = const [],
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  String _fallbackAvatarText() {
    if (avatar.isNotEmpty) return avatar;
    final trimmedName = chatName.trim();
    if (trimmedName.isNotEmpty) {
      return trimmedName.characters.first.toUpperCase();
    }
    return '👤';
  }

  String _buildSubtitle() {
    if (typingUserIds.isNotEmpty) {
      if (isGroup) {
        final names = typingUserIds
            .map((id) => memberNames[id] ?? 'Someone')
            .toList();
        if (names.length == 1) {
          return '${names.first} is typing...';
        }
        return '${names.join(", ")} are typing...';
      }
      return 'typing...';
    }

    if (isGroup) {
      return '${members.length} members';
    }
    return isOnline ? 'Online' : 'Offline';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = _buildSubtitle();
    final isTyping = typingUserIds.isNotEmpty;

    return AppBar(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leadingWidth: 40,
      leading: IconButton(
        tooltip: 'Back',
        icon: const Icon(
          Icons.arrow_back_ios_new,
          size: 22,
          color: AppColors.textPrimary,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: GestureDetector(
        onTap: () => _navigateToInfo(context),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: avatarUrl != null && avatarUrl!.isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            avatarUrl!,
                            width: 42,
                            height: 42,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                InitialsAvatar(name: chatName, size: 42),
                          ),
                        )
                      : Center(
                          child: Text(
                            _fallbackAvatarText(),
                            style: const TextStyle(fontSize: 22),
                          ),
                        ),
                ),
                if (isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.colorScheme.surface,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chatName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isTyping
                          ? theme.colorScheme.primary
                          : isOnline
                          ? AppColors.success
                          : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontStyle: isTyping ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (onSearchPressed != null)
          IconButton(
            tooltip: isSearching ? 'Close search' : 'Search',
            icon: Icon(
              isSearching ? Icons.search_off : Icons.search,
              size: 22,
              color: AppColors.textPrimary,
            ),
            onPressed: onSearchPressed,
          ),
        IconButton(
          tooltip: 'More options',
          onPressed: () => _navigateToInfo(context),
          icon: ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.getGlassBackground(0.05),
                  border: Border.all(
                    color: AppColors.getGlassBorder(0.4),
                    width: 1.5,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.more_vert,
                  size: 22,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  void _navigateToInfo(BuildContext context) {
    Navigator.pushNamed(
      context,
      AppRoutes.groupInfo,
      arguments: {
        'id': chatRoomId,
        'name': chatName,
        'avatar': avatar,
        'members': members,
        'memberNames': memberNames,
        'memberPhones': memberPhones,
        'memberPhotoUrls': memberPhotoUrls,
        'isGroup': isGroup,
        'avatarUrl': avatarUrl,
        'admins': admins,
      },
    );
  }
}
