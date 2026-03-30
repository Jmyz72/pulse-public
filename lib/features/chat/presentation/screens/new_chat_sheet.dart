import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../friends/domain/entities/friendship.dart';
import '../../../friends/presentation/bloc/friend_bloc.dart';
import '../../../friends/presentation/bloc/friend_event.dart';
import '../../../friends/presentation/bloc/friend_state.dart';
import '../../domain/entities/message.dart';
import '../bloc/chat_bloc.dart';

class NewChatSheet extends StatefulWidget {
  const NewChatSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<FriendBloc>()),
          BlocProvider.value(value: context.read<ChatBloc>()),
          BlocProvider.value(value: context.read<AuthBloc>()),
        ],
        child: const NewChatSheet(),
      ),
    );
  }

  @override
  State<NewChatSheet> createState() => _NewChatSheetState();
}

class _NewChatSheetState extends State<NewChatSheet> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _groupNameController = TextEditingController();
  final Set<String> _selectedFriendIds = {};
  String _searchQuery = '';
  bool _isCreating = false;
  String? _pendingChatName;
  String? _pendingAvatarUrl;
  bool _pendingIsGroup = false;
  List<String> _pendingMembers = [];
  Map<String, String> _pendingMemberNames = {};
  Map<String, String> _pendingMemberPhotoUrls = {};

  @override
  void initState() {
    super.initState();
    final userId = context.read<AuthBloc>().state.user?.id ?? '';
    if (userId.isNotEmpty) {
      context.read<FriendBloc>().add(FriendsLoadRequested(userId));
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _groupNameController.dispose();
    super.dispose();
  }

  void _onConfirm() {
    if (_selectedFriendIds.isEmpty || _isCreating) return;

    final currentUser = context.read<AuthBloc>().state.user;
    final currentUserId = currentUser?.id ?? '';
    final friends = context.read<FriendBloc>().state.friends;

    if (_selectedFriendIds.length == 1) {
      final friendId = _selectedFriendIds.first;
      final friend = friends.where((f) => f.friendId == friendId).firstOrNull;
      if (friend == null) return;
      final memberIds = [currentUserId, friendId];

      setState(() {
        _isCreating = true;
        _pendingChatName = friend.friendDisplayName;
        _pendingAvatarUrl = friend.friendPhotoUrl;
        _pendingIsGroup = false;
        _pendingMembers = memberIds;
        _pendingMemberNames = {
          currentUserId: currentUser?.displayName ?? 'You',
          friendId: friend.friendDisplayName,
        };
        _pendingMemberPhotoUrls = {
          currentUserId: currentUser?.photoUrl ?? '',
          friendId: friend.friendPhotoUrl ?? '',
        };
      });

      final chatRoom = ChatRoom(
        id: '',
        name: friend.friendDisplayName,
        members: memberIds,
        createdAt: DateTime.now(),
        isGroup: false,
        memberNames: {
          currentUserId: currentUser?.displayName ?? 'You',
          friendId: friend.friendDisplayName,
        },
      );

      context.read<ChatBloc>().add(ChatRoomCreateRequested(chatRoom: chatRoom));
    } else {
      final groupName = _groupNameController.text.trim();
      if (groupName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.errorEmptyField)),
        );
        return;
      }

      final memberIds = [currentUserId, ..._selectedFriendIds];

      final nameMap = <String, String>{
        currentUserId: currentUser?.displayName ?? 'You',
      };
      for (final fid in _selectedFriendIds) {
        final f = friends.where((fr) => fr.friendId == fid).firstOrNull;
        if (f != null) nameMap[fid] = f.friendDisplayName;
      }

      setState(() {
        _isCreating = true;
        _pendingChatName = groupName;
        _pendingAvatarUrl = null;
        _pendingIsGroup = true;
        _pendingMembers = memberIds;
        _pendingMemberNames = nameMap;
        _pendingMemberPhotoUrls = {currentUserId: currentUser?.photoUrl ?? ''};
        for (final fid in _selectedFriendIds) {
          final f = friends.where((fr) => fr.friendId == fid).firstOrNull;
          if (f != null) {
            _pendingMemberPhotoUrls[fid] = f.friendPhotoUrl ?? '';
          }
        }
      });

      final chatRoom = ChatRoom(
        id: '',
        name: groupName,
        members: memberIds,
        createdAt: DateTime.now(),
        isGroup: true,
        createdBy: currentUserId,
        admins: [currentUserId],
        memberNames: nameMap,
      );

      context.read<ChatBloc>().add(ChatRoomCreateRequested(chatRoom: chatRoom));
    }
  }

  void _onChatCreated(ChatRoom createdRoom) {
    Navigator.pop(context);
    Navigator.pushNamed(
      context,
      AppRoutes.groupChat,
      arguments: {
        'id': createdRoom.id,
        'name': _pendingChatName,
        'avatarUrl': _pendingAvatarUrl,
        'isGroup': _pendingIsGroup,
        'members': _pendingMembers,
        'memberNames': _pendingMemberNames,
        'memberPhotoUrls': _pendingMemberPhotoUrls,
        'admins': createdRoom.admins,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<ChatBloc, ChatState>(
      listenWhen: (previous, current) =>
          _isCreating &&
          (current.status == ChatStatus.error ||
              (current.createdChatRoom != null &&
                  current.createdChatRoom != previous.createdChatRoom)),
      listener: (context, state) {
        if (_isCreating && state.status == ChatStatus.error) {
          setState(() => _isCreating = false);
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
          }
          return;
        }
        if (_isCreating && state.createdChatRoom != null) {
          _onChatCreated(state.createdChatRoom!);
        }
      },
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppStrings.newChat,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.getGlassBackground(0.05),
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusXl,
                      ),
                      border: Border.all(
                        color: AppColors.getGlassBorder(0.4),
                        width: 1.5,
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) =>
                          setState(() => _searchQuery = value.toLowerCase()),
                      decoration: InputDecoration(
                        hintText: AppStrings.searchFriends,
                        hintStyle: const TextStyle(
                          color: AppColors.textSecondary,
                        ),
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
            ),
            // Selected chips
            if (_selectedFriendIds.isNotEmpty)
              _SelectedFriendsChips(
                selectedFriendIds: _selectedFriendIds,
                onRemoveFriend: (friendId) =>
                    setState(() => _selectedFriendIds.remove(friendId)),
              ),
            // Friends list
            Expanded(
              child: _FriendsList(
                selectedFriendIds: _selectedFriendIds,
                searchQuery: _searchQuery,
                onFriendSelected: (friendId) {
                  setState(() {
                    if (_selectedFriendIds.contains(friendId)) {
                      _selectedFriendIds.remove(friendId);
                    } else {
                      _selectedFriendIds.add(friendId);
                    }
                  });
                },
              ),
            ),
            // Bottom bar
            _CreateChatBottomBar(
              selectedFriendIds: _selectedFriendIds,
              isCreating: _isCreating,
              groupNameController: _groupNameController,
              onConfirm: _onConfirm,
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedFriendsChips extends StatelessWidget {
  final Set<String> selectedFriendIds;
  final ValueChanged<String> onRemoveFriend;

  const _SelectedFriendsChips({
    required this.selectedFriendIds,
    required this.onRemoveFriend,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<FriendBloc, FriendState>(
      builder: (context, state) {
        final selectedFriends = state.friends
            .where((f) => selectedFriendIds.contains(f.friendId))
            .toList();
        return Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: selectedFriends.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final friend = selectedFriends[index];
              return Chip(
                label: Text(friend.friendDisplayName),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () => onRemoveFriend(friend.friendId),
                backgroundColor: theme.colorScheme.primaryContainer,
              );
            },
          ),
        );
      },
    );
  }
}

class _FriendsList extends StatelessWidget {
  final Set<String> selectedFriendIds;
  final String searchQuery;
  final ValueChanged<String> onFriendSelected;

  const _FriendsList({
    required this.selectedFriendIds,
    required this.searchQuery,
    required this.onFriendSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<FriendBloc, FriendState>(
      builder: (context, state) {
        if (state.friendsStatus == FriendLoadStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        final friends = state.friends.where((f) {
          if (searchQuery.isEmpty) return true;
          return f.friendDisplayName.toLowerCase().contains(searchQuery);
        }).toList();

        if (friends.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 64,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  searchQuery.isNotEmpty
                      ? AppStrings.noFriendsFound
                      : AppStrings.addFriendsFirst,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: friends.length,
          itemBuilder: (context, index) {
            final friend = friends[index];
            return _buildFriendTile(theme, friend);
          },
        );
      },
    );
  }

  Widget _buildFriendTile(ThemeData theme, Friendship friend) {
    final isSelected = selectedFriendIds.contains(friend.friendId);

    return InkWell(
      onTap: () => onFriendSelected(friend.friendId),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: isSelected
                  ? theme.colorScheme.primary.withValues(alpha: 0.15)
                  : theme.colorScheme.surfaceContainerHighest,
              child: Text(
                friend.friendDisplayName.isNotEmpty
                    ? friend.friendDisplayName[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    friend.friendDisplayName,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    friend.friendEmail,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                  width: 2,
                ),
                shape: BoxShape.circle,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateChatBottomBar extends StatelessWidget {
  final Set<String> selectedFriendIds;
  final bool isCreating;
  final TextEditingController groupNameController;
  final VoidCallback onConfirm;

  const _CreateChatBottomBar({
    required this.selectedFriendIds,
    required this.isCreating,
    required this.groupNameController,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedFriendIds.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isGroup = selectedFriendIds.length >= 2;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isGroup) ...[
            TextField(
              controller: groupNameController,
              decoration: InputDecoration(
                hintText: AppStrings.groupName,
                prefixIcon: const Icon(Icons.group),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: isCreating ? null : onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: isCreating
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      isGroup ? AppStrings.createGroup : AppStrings.message,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
