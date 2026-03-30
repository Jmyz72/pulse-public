import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_dimensions.dart';
import '../../features/chat/domain/entities/message.dart';
import '../../features/chat/presentation/bloc/chat_bloc.dart';

class ChatPicker extends StatelessWidget {
  final String? selectedChatRoomId;
  final ValueChanged<ChatRoom> onSelected;
  final String? errorText;
  final String label;
  final String hint;

  const ChatPicker({
    super.key,
    this.selectedChatRoomId,
    required this.onSelected,
    this.errorText,
    this.label = 'Share to Chat',
    this.hint = 'Select a chat to share this item',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<ChatBloc, ChatState>(
      builder: (context, state) {
        final chatRooms = state.chatRooms;
        final selectedRoom = selectedChatRoomId != null
            ? chatRooms.where((r) => r.id == selectedChatRoomId).firstOrNull
            : null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingSm),
            InkWell(
              onTap: () => _showChatPickerSheet(context, chatRooms),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              child: Container(
                padding: const EdgeInsets.all(AppDimensions.spacingMd),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: errorText != null
                        ? theme.colorScheme.error
                        : theme.colorScheme.outline,
                  ),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: selectedRoom != null
                            ? theme.colorScheme.primaryContainer
                            : theme.colorScheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        selectedRoom?.isGroup == true
                            ? Icons.group
                            : selectedRoom != null
                                ? Icons.person
                                : Icons.chat_bubble_outline,
                        color: selectedRoom != null
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spacingMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedRoom?.name ?? hint,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: selectedRoom != null
                                  ? theme.colorScheme.onSurface
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (selectedRoom != null)
                            Text(
                              selectedRoom.isGroup
                                  ? '${selectedRoom.members.length} members'
                                  : 'Private chat',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
            if (errorText != null) ...[
              const SizedBox(height: AppDimensions.spacingXs),
              Text(
                errorText!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  void _showChatPickerSheet(BuildContext context, List<ChatRoom> chatRooms) {
    final theme = Theme.of(context);

    // Separate group chats and private chats
    final groupChats = chatRooms.where((r) => r.isGroup).toList();
    final privateChats = chatRooms.where((r) => !r.isGroup).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusLg),
        ),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Title
                Padding(
                  padding: const EdgeInsets.all(AppDimensions.spacingMd),
                  child: Row(
                    children: [
                      Text(
                        'Select Chat',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Chat list
                Expanded(
                  child: chatRooms.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 64,
                                color: theme.colorScheme.outline,
                              ),
                              const SizedBox(height: AppDimensions.spacingMd),
                              Text(
                                'No chats available',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: AppDimensions.spacingSm),
                              Text(
                                'Start a conversation to share items',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView(
                          controller: scrollController,
                          children: [
                            if (groupChats.isNotEmpty) ...[
                              _buildSectionHeader(context, 'Group Chats'),
                              ...groupChats.map((room) => _buildChatTile(
                                    context,
                                    room,
                                    () {
                                      onSelected(room);
                                      Navigator.pop(context);
                                    },
                                  )),
                            ],
                            if (privateChats.isNotEmpty) ...[
                              _buildSectionHeader(context, 'Private Chats'),
                              ...privateChats.map((room) => _buildChatTile(
                                    context,
                                    room,
                                    () {
                                      onSelected(room);
                                      Navigator.pop(context);
                                    },
                                  )),
                            ],
                          ],
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.spacingMd,
        AppDimensions.spacingMd,
        AppDimensions.spacingMd,
        AppDimensions.spacingSm,
      ),
      child: Text(
        title,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildChatTile(
    BuildContext context,
    ChatRoom room,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    final isSelected = room.id == selectedChatRoomId;

    return ListTile(
      onTap: onTap,
      selected: isSelected,
      selectedTileColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          shape: BoxShape.circle,
        ),
        child: Icon(
          room.isGroup ? Icons.group : Icons.person,
          color: isSelected
              ? theme.colorScheme.onPrimary
              : theme.colorScheme.onSurfaceVariant,
        ),
      ),
      title: Text(
        room.name,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        room.isGroup ? '${room.members.length} members' : 'Private chat',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: isSelected
          ? Icon(
              Icons.check_circle,
              color: theme.colorScheme.primary,
            )
          : null,
    );
  }
}
