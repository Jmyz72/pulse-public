import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/widgets/initials_avatar.dart';
import '../../../../shared/widgets/confirmation_dialog.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../friends/presentation/bloc/friend_bloc.dart';
import '../../../friends/presentation/bloc/friend_state.dart';
import '../bloc/chat_bloc.dart';
import '../widgets/member_list_tile.dart';

/// Group info screen showing members and group settings
class GroupInfoScreen extends StatelessWidget {
  const GroupInfoScreen({super.key});

  Map<String, String> _asStringMap(dynamic value) {
    if (value is! Map) return const {};
    return value.map(
      (key, mapValue) => MapEntry(key.toString(), mapValue?.toString() ?? ''),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Ensure user is authenticated
    final currentUser = context.read<AuthBloc>().state.user;
    if (currentUser == null) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pop();
      });
      return const SizedBox.shrink();
    }
    final currentUserId = currentUser.id;

    // Get group data from navigation arguments (extracted once for efficiency)
    final Map<String, dynamic>? groupData =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final String chatRoomId = groupData?['id'] as String? ?? '';
    final String groupName = groupData?['name'] ?? 'Group';
    final String? avatarUrl = (groupData?['avatarUrl'] as String?)?.trim();
    final List<dynamic> rawMembers = groupData?['members'] ?? [];
    final List<dynamic> rawAdmins = groupData?['admins'] ?? [];
    final Map<String, String> memberNames = _asStringMap(
      groupData?['memberNames'],
    );
    final Map<String, String> memberPhones = _asStringMap(
      groupData?['memberPhones'],
    );
    final Map<String, String> memberPhotoUrls = _asStringMap(
      groupData?['memberPhotoUrls'],
    );

    // Parse admins list with backward compatibility
    final List<String> adminIds = rawAdmins.isNotEmpty
        ? rawAdmins.map((e) => e.toString()).toList()
        : (rawMembers.isNotEmpty ? [rawMembers.first.toString()] : []);

    final bool currentUserIsAdmin = adminIds.contains(currentUserId);
    final bool isProcessingAdminAction = context.select(
      (ChatBloc bloc) => bloc.state.isProcessingAdminAction,
    );

    final List<Map<String, dynamic>> members = rawMembers.asMap().entries.map((
      entry,
    ) {
      final id = entry.value.toString();
      final name = memberNames[id] ?? id;
      final phone = memberPhones[id] ?? '';
      final photoUrl = memberPhotoUrls[id];
      final isMe = id == currentUserId;
      final isAdmin = adminIds.contains(id);
      return {
        'id': id,
        'name': name,
        'phone': phone,
        'photoUrl': photoUrl,
        'isMe': isMe,
        'isAdmin': isAdmin,
      };
    }).toList();

    return BlocListener<ChatBloc, ChatState>(
      listenWhen: (prev, curr) =>
          prev.successMessage != curr.successMessage ||
          prev.errorMessage != curr.errorMessage ||
          prev.lastAction != curr.lastAction,
      listener: (context, state) {
        if (state.successMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.successMessage!)));

          // Use post-frame callback to prevent duplicate navigation
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            if (state.lastAction == ChatAction.leftGroup) {
              Navigator.of(context).popUntil((route) => route.isFirst);
            } else if ([
              ChatAction.memberAdded,
              ChatAction.memberRemoved,
              ChatAction.madeAdmin,
              ChatAction.removedAdmin,
            ].contains(state.lastAction)) {
              Navigator.of(context).pop();
            }
          });
        }
        if (state.errorMessage != null && state.status == ChatStatus.error) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        }
      },
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            // App Bar with group avatar
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              backgroundColor: AppColors.background,
              flexibleSpace: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primary.withValues(alpha: 0.2),
                            AppColors.secondary.withValues(alpha: 0.2),
                          ],
                        ),
                        border: const Border(
                          bottom: BorderSide(
                            color: AppColors.glassBorder,
                            width: 1.5,
                          ),
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 40),
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: AppColors.getGlassBackground(0.2),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.6,
                                  ),
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: InitialsAvatar(
                                  name: groupName,
                                  imageUrl: avatarUrl,
                                  size: 100,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              groupName,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${members.length} members',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Group actions
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Members section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${members.length} Members',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (currentUserIsAdmin)
                          BlocBuilder<ChatBloc, ChatState>(
                            buildWhen: (prev, curr) =>
                                prev.isProcessingAdminAction !=
                                curr.isProcessingAdminAction,
                            builder: (context, state) {
                              return IconButton(
                                icon: state.isProcessingAdminAction
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Icon(
                                        Icons.person_add,
                                        color: theme.colorScheme.primary,
                                      ),
                                onPressed: state.isProcessingAdminAction
                                    ? null
                                    : () => _showAddMemberDialog(
                                        context,
                                        chatRoomId,
                                        rawMembers,
                                      ),
                              );
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            // Members list
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final member = members[index];
                final isMe = member['isMe'] == true;
                final memberIsAdmin = member['isAdmin'] == true;
                final memberName = member['name']?.toString() ?? '';
                final memberId = member['id']?.toString() ?? '';
                final memberPhone = member['phone']?.toString() ?? '';
                final memberPhotoUrl = member['photoUrl']?.toString();

                return MemberListTile(
                  memberId: memberId,
                  memberName: memberName,
                  memberPhone: memberPhone,
                  memberImageUrl: memberPhotoUrl,
                  isAdmin: memberIsAdmin,
                  isCurrentUser: isMe,
                  isCurrentUserAdmin: currentUserIsAdmin,
                  showActions: !isProcessingAdminAction,
                  onRemoveMember: () => _showRemoveMemberDialog(
                    context,
                    memberName,
                    memberId,
                    chatRoomId,
                  ),
                  onMakeAdmin: memberIsAdmin
                      ? null
                      : () => _showMakeAdminDialog(
                          context,
                          memberName,
                          memberId,
                          chatRoomId,
                        ),
                  onRemoveAdmin: memberIsAdmin
                      ? () => _showRemoveAdminDialog(
                          context,
                          memberName,
                          memberId,
                          adminIds.length,
                          chatRoomId,
                        )
                      : null,
                );
              }, childCount: members.length),
            ),

            // Exit group button
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: BlocBuilder<ChatBloc, ChatState>(
                  buildWhen: (prev, curr) =>
                      prev.isProcessingAdminAction !=
                      curr.isProcessingAdminAction,
                  builder: (context, state) {
                    return ElevatedButton(
                      onPressed: state.isProcessingAdminAction
                          ? null
                          : () => _showExitGroupDialog(
                              context,
                              chatRoomId,
                              currentUserId,
                            ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        disabledBackgroundColor: AppColors.error.withValues(
                          alpha: 0.5,
                        ),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: state.isProcessingAdminAction
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.exit_to_app, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  'Exit Group',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                    );
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  void _showAddMemberDialog(
    BuildContext context,
    String chatRoomId,
    List<dynamic> rawMembers,
  ) {
    final existingMembers = rawMembers.map((e) => e.toString()).toSet();

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.getGlassBackground(0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
                border: Border.all(
                  color: AppColors.getGlassBorder(0.4),
                  width: 1.5,
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.person_add, color: AppColors.primary),
                      SizedBox(width: 12),
                      Text(
                        'Add Member',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.maxFinite,
                    height: 300,
                    child: BlocBuilder<FriendBloc, FriendState>(
                      builder: (context, friendState) {
                        final available = friendState.friends
                            .where((f) => !existingMembers.contains(f.friendId))
                            .toList();
                        if (available.isEmpty) {
                          return const Center(
                            child: Text(
                              AppStrings.noFriendsAvailable,
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          );
                        }
                        return ListView.builder(
                          shrinkWrap: true,
                          itemCount: available.length,
                          itemBuilder: (context, index) {
                            final friend = available[index];
                            return ListTile(
                              leading: InitialsAvatar(
                                name: friend.friendDisplayName,
                                imageUrl: friend.friendPhotoUrl,
                                size: 36,
                              ),
                              title: Text(
                                friend.friendDisplayName,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.add_circle,
                                  color: AppColors.success,
                                ),
                                onPressed: () {
                                  Navigator.pop(dialogContext);
                                  context.read<ChatBloc>().add(
                                    AddChatMemberRequested(
                                      chatRoomId: chatRoomId,
                                      userId: friend.friendId,
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Common confirmation dialog builder using ConfirmationDialog
  void _showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String message,
    required VoidCallback onConfirm,
    required Color buttonColor,
    required String confirmText,
    Widget? titleIcon,
  }) {
    ConfirmationDialog.show(
      context,
      title: title,
      message: message,
      confirmText: confirmText,
      isDestructive: buttonColor == AppColors.error,
      titleIcon: titleIcon,
      onConfirm: onConfirm,
    );
  }

  void _showRemoveMemberDialog(
    BuildContext context,
    String memberName,
    String memberId,
    String chatRoomId,
  ) {
    _showConfirmationDialog(
      context: context,
      title: 'Remove Member',
      message: 'Are you sure you want to remove $memberName from the group?',
      buttonColor: AppColors.error,
      confirmText: 'Remove',
      onConfirm: () => context.read<ChatBloc>().add(
        RemoveChatMemberRequested(chatRoomId: chatRoomId, userId: memberId),
      ),
    );
  }

  void _showMakeAdminDialog(
    BuildContext context,
    String memberName,
    String memberId,
    String chatRoomId,
  ) {
    _showConfirmationDialog(
      context: context,
      title: AppStrings.makeAdmin,
      message: 'Are you sure you want to make $memberName an admin?',
      buttonColor: AppColors.primary,
      confirmText: AppStrings.makeAdmin,
      onConfirm: () => context.read<ChatBloc>().add(
        MakeAdminRequested(chatRoomId: chatRoomId, userId: memberId),
      ),
    );
  }

  void _showRemoveAdminDialog(
    BuildContext context,
    String memberName,
    String memberId,
    int adminCount,
    String chatRoomId,
  ) {
    // Client-side check for UX; server-side transaction is source of truth
    if (adminCount <= 1) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Cannot remove the last admin')),
        );
      return;
    }

    _showConfirmationDialog(
      context: context,
      title: AppStrings.removeAdmin,
      message: 'Are you sure you want to remove admin role from $memberName?',
      buttonColor: AppColors.warning,
      confirmText: AppStrings.removeAdmin,
      onConfirm: () => context.read<ChatBloc>().add(
        RemoveAdminRequested(chatRoomId: chatRoomId, userId: memberId),
      ),
    );
  }

  void _showExitGroupDialog(
    BuildContext context,
    String chatRoomId,
    String currentUserId,
  ) {
    _showConfirmationDialog(
      context: context,
      title: 'Exit Group',
      message:
          'Are you sure you want to exit this group? You will no longer receive messages from this group.',
      buttonColor: AppColors.error,
      confirmText: 'Exit',
      titleIcon: const Icon(Icons.warning, color: AppColors.error),
      onConfirm: () => context.read<ChatBloc>().add(
        LeaveGroupRequested(chatRoomId: chatRoomId, userId: currentUserId),
      ),
    );
  }
}
