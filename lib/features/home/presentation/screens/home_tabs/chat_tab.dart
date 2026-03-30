import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/constants/app_routes.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../shared/mixins/stagger_animation_mixin.dart';
import '../../../../../shared/widgets/confirmation_dialog.dart';
import '../../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../../chat/domain/entities/message.dart';
import '../../../../chat/presentation/bloc/chat_bloc.dart';
import '../../../../chat/presentation/widgets/chat_tile.dart';
import '../../../../friends/presentation/bloc/friend_bloc.dart';
import '../../../../friends/presentation/bloc/friend_event.dart';
import '../../widgets/skeletons/chat_skeleton.dart';

/// Chat tab embedded in HomeScreen following the tab widget pattern.
///
/// Uses [ChatBloc] directly for chat state management. Only dispatches
/// [ChatRoomsLoadRequested] when status is [ChatStatus.initial] to avoid
/// reloading on every tab switch.
class ChatTab extends StatefulWidget {
  final VoidCallback onNewChat;
  final Function(Map<String, dynamic>)? onDeepLink;

  const ChatTab({
    super.key,
    required this.onNewChat,
    this.onDeepLink,
  });

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> with StaggerAnimationMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late final ChatBloc _chatBloc;

  @override
  int get staggerCount => 3;

  @override
  void initState() {
    super.initState();
    startStaggerAnimation();
    _chatBloc = context.read<ChatBloc>();
    final userId = context.read<AuthBloc>().state.user?.id ?? '';
    final friendBloc = context.read<FriendBloc>();
    if (userId.isNotEmpty && friendBloc.state.friends.isEmpty) {
      friendBloc.add(FriendsLoadRequested(userId));
    }
    // Always start watching when tab initializes - ensures live updates
    _chatBloc.add(ChatRoomsWatchRequested());
  }

  @override
  void dispose() {
    // Don't stop watching - keep real-time updates active in background
    // Chat apps prioritize instant updates over battery/cost optimization
    _searchController.dispose();
    super.dispose();
  }

  Map<String, String> _buildMemberNames(
    BuildContext context,
    ChatRoom chatRoom,
  ) {
    if (chatRoom.memberNames.isNotEmpty) return chatRoom.memberNames;
    // Legacy fallback: build from FriendBloc for rooms without memberNames
    final currentUser = context.read<AuthBloc>().state.user;
    final friends = context.read<FriendBloc>().state.friends;
    final nameMap = <String, String>{};

    for (final id in chatRoom.members) {
      if (id == currentUser?.id) {
        nameMap[id] = currentUser?.displayName ?? 'You';
      } else {
        final friend = friends.where((f) => f.friendId == id).firstOrNull;
        nameMap[id] = friend?.friendDisplayName ?? id;
      }
    }
    return nameMap;
  }

  Map<String, String> _buildMemberPhones(
    BuildContext context,
    List<String> memberIds,
  ) {
    final currentUser = context.read<AuthBloc>().state.user;
    final friends = context.read<FriendBloc>().state.friends;
    final phoneMap = <String, String>{};

    for (final id in memberIds) {
      if (id == currentUser?.id) {
        phoneMap[id] = currentUser?.phone ?? '';
      } else {
        final friend = friends.where((f) => f.friendId == id).firstOrNull;
        phoneMap[id] = friend?.friendPhone ?? '';
      }
    }
    return phoneMap;
  }

  Map<String, String> _buildMemberPhotoUrls(
    BuildContext context,
    List<String> memberIds,
  ) {
    final currentUser = context.read<AuthBloc>().state.user;
    final friends = context.read<FriendBloc>().state.friends;
    final photoMap = <String, String>{};

    for (final id in memberIds) {
      if (id == currentUser?.id) {
        photoMap[id] = currentUser?.photoUrl ?? '';
      } else {
        final friend = friends.where((f) => f.friendId == id).firstOrNull;
        photoMap[id] = friend?.friendPhotoUrl ?? '';
      }
    }
    return photoMap;
  }

  String _getChatDisplayName(BuildContext context, ChatRoom chatRoom) {
    if (chatRoom.isGroup) return chatRoom.name;
    final currentUserId = context.read<AuthBloc>().state.user?.id ?? '';

    // Primary: use memberNames (populated for new rooms + enriched legacy rooms)
    if (chatRoom.memberNames.isNotEmpty) {
      return chatRoom.displayNameFor(currentUserId);
    }

    // Safety net: FriendBloc lookup for edge cases (offline/cached data)
    final otherUserId = chatRoom.members.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
    if (otherUserId.isEmpty) return chatRoom.name;
    final friends = context.read<FriendBloc>().state.friends;
    final friend = friends.where((f) => f.friendId == otherUserId).firstOrNull;
    return friend?.friendDisplayName ?? chatRoom.name;
  }

  String? _getChatAvatarUrl(BuildContext context, ChatRoom chatRoom) {
    if (chatRoom.isGroup) {
      return chatRoom.imageUrl;
    }
    final currentUserId = context.read<AuthBloc>().state.user?.id ?? '';
    final otherUserId = chatRoom.members.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
    if (otherUserId.isEmpty) return null;
    final friends = context.read<FriendBloc>().state.friends;
    final friend = friends.where((f) => f.friendId == otherUserId).firstOrNull;
    return friend?.friendPhotoUrl;
  }

  int _computeUnreadCount(List<ChatRoom> chatRooms, String currentUserId) {
    return chatRooms.where((c) {
      final lm = c.lastMessage;
      if (lm == null) return false;
      if (lm.senderId == currentUserId) return false;
      final myLastRead = c.lastReadAt[currentUserId];
      return myLastRead == null || myLastRead.isBefore(lm.timestamp);
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    context.select((FriendBloc bloc) => bloc.state.friends.length);

    return BlocConsumer<ChatBloc, ChatState>(
      listener: (context, state) {
        if (state.status == ChatStatus.error && state.errorMessage != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        }
      },
      builder: (context, state) {
        return SafeArea(
          child: Column(
            children: [
              staggerIn(index: 0, child: _buildHeader(theme, state)),
              staggerIn(index: 1, child: _buildSearchBar(theme)),
              Expanded(
                child: staggerIn(index: 2, child: _buildContent(theme, state)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(ThemeData theme, ChatState state) {
    final currentUserId = context.read<AuthBloc>().state.user?.id ?? '';

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.spacingLg,
        AppDimensions.spacingMd,
        AppDimensions.spacingLg,
        AppDimensions.spacingSm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.messages,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              BlocSelector<ChatBloc, ChatState, int>(
                selector: (state) =>
                    _computeUnreadCount(state.chatRooms, currentUserId),
                builder: (context, unreadCount) {
                  return Text(
                    '$unreadCount ${AppStrings.unreadConversations}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  );
                },
              ),
            ],
          ),
          _buildHeaderButton(theme, Icons.person_search, () {
            Navigator.pushNamed(context, AppRoutes.addFriend);
          }),
        ],
      ),
    );
  }

  Widget _buildHeaderButton(
    ThemeData theme,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Semantics(
      button: true,
      label: 'Find friends',
      child: GestureDetector(
        onTap: onTap,
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.getGlassBackground(0.05),
                border: Border.all(
                  color: AppColors.getGlassBorder(0.4),
                  width: 1.5,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: AppColors.textPrimary),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.spacingLg,
        AppDimensions.spacingMd,
        AppDimensions.spacingLg,
        AppDimensions.spacingSm,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.getGlassBackground(0.05),
              borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
              border: Border.all(
                color: AppColors.getGlassBorder(0.4),
                width: 1.5,
              ),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: AppStrings.searchMessages,
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.textSecondary,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme, ChatState state) {
    if (state.status == ChatStatus.loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: AppDimensions.spacingLg),
        child: ChatSkeleton(),
      );
    }

    if (state.status == ChatStatus.error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: AppDimensions.spacingMd),
            const Text(AppStrings.failedToLoadMessages),
            const SizedBox(height: AppDimensions.spacingSm),
            ElevatedButton(
              onPressed: () {
                context.read<ChatBloc>().add(ChatRoomsLoadRequested());
              },
              child: const Text(AppStrings.retry),
            ),
          ],
        ),
      );
    }

    if (state.chatRooms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: AppDimensions.spacingMd),
            Text(
              AppStrings.noConversations,
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingSm),
            Text(
              AppStrings.startNewChat,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: widget.onNewChat,
              icon: const Icon(Icons.add),
              label: const Text('Start a conversation'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final filteredRooms = _searchQuery.isEmpty
        ? state.chatRooms
        : state.chatRooms
              .where(
                (room) => _getChatDisplayName(
                  context,
                  room,
                ).toLowerCase().contains(_searchQuery),
              )
              .toList();

    return RefreshIndicator(
      onRefresh: () {
        context.read<ChatBloc>().add(ChatRoomsLoadRequested());
        return context.read<ChatBloc>().stream.firstWhere(
          (s) => s.status != ChatStatus.loading,
        );
      },
      child: ListView.separated(
        padding: const EdgeInsets.only(top: AppDimensions.spacingSm),
        itemCount: filteredRooms.length,
        separatorBuilder: (_, __) =>
            const SizedBox(height: AppDimensions.spacingSm),
        itemBuilder: (context, index) {
          final chatRoom = filteredRooms[index];
          return RepaintBoundary(
            child: _buildChatTile(context, theme, chatRoom),
          );
        },
      ),
    );
  }

  Widget _buildChatTile(
    BuildContext context,
    ThemeData theme,
    ChatRoom chatRoom,
  ) {
    final currentUserId = context.read<AuthBloc>().state.user?.id ?? '';
    final lastMessage = chatRoom.lastMessage;
    final myLastRead = chatRoom.lastReadAt[currentUserId];
    final hasUnread =
        lastMessage != null &&
        lastMessage.senderId != currentUserId &&
        (myLastRead == null || myLastRead.isBefore(lastMessage.timestamp));
    final displayName = _getChatDisplayName(context, chatRoom);
    final avatarUrl = _getChatAvatarUrl(context, chatRoom);

    return ChatTile(
      chatRoom: chatRoom,
      currentUserId: currentUserId,
      hasUnread: hasUnread,
      displayName: displayName,
      avatarUrl: avatarUrl,
      onTap: () async {
        final memberNames = _buildMemberNames(context, chatRoom);
        final memberPhones = _buildMemberPhones(context, chatRoom.members);
        final memberPhotoUrls = _buildMemberPhotoUrls(
          context,
          chatRoom.members,
        );
        final result = await Navigator.pushNamed(
          context,
          AppRoutes.groupChat,
          arguments: {
            'id': chatRoom.id,
            'name': displayName,
            'avatar': chatRoom.isGroup
                ? '👥'
                : (displayName.isNotEmpty
                      ? displayName.characters.first.toUpperCase()
                      : '👤'),
            'avatarUrl': avatarUrl,
            'isGroup': chatRoom.isGroup,
            'members': chatRoom.members,
            'memberNames': memberNames,
            'memberPhones': memberPhones,
            'memberPhotoUrls': memberPhotoUrls,
            'admins': chatRoom.admins,
          },
        );

        // If the chat screen returned deep link arguments (e.g., location view)
        if (result != null && result is Map<String, dynamic>) {
          widget.onDeepLink?.call(result);
        }
      },
      onDismissed: () {
        context.read<ChatBloc>().add(
          ChatRoomDeleteRequested(chatRoomId: chatRoom.id),
        );
      },
      onConfirmDismiss: (dialogContext) async {
        bool? result = false;
        await ConfirmationDialog.show(
          dialogContext,
          title: AppStrings.deleteConversation,
          message: '${AppStrings.deleteConversationConfirm} $displayName?',
          confirmText: AppStrings.delete,
          isDestructive: true,
          onConfirm: () {
            result = true;
          },
        );
        return result ?? false;
      },
    );
  }
}
