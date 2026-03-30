import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/image_lightbox.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../chat/domain/entities/message.dart';
import '../../../chat/presentation/bloc/chat_bloc.dart';
import '../../domain/entities/grocery_item.dart';
import '../bloc/grocery_bloc.dart';
import '../widgets/grocery_item_card.dart';
import '../widgets/grocery_item_form_dialog.dart';
import '../widgets/grocery_skeleton.dart';
import '../widgets/grocery_summary_card.dart';

enum _GroceryFilter { all, needed, purchased }

class _PendingGroceryMessage {
  final String tempItemId;
  final String senderId;
  final String senderName;
  final DateTime timestamp;

  const _PendingGroceryMessage({
    required this.tempItemId,
    required this.senderId,
    required this.senderName,
    required this.timestamp,
  });
}

/// Group grocery shopping list screen
class GroceryScreen extends StatefulWidget {
  const GroceryScreen({super.key});

  @override
  State<GroceryScreen> createState() => _GroceryScreenState();
}

class _GroceryScreenState extends State<GroceryScreen> {
  _GroceryFilter _activeFilter = _GroceryFilter.needed;
  String? _preselectedChatRoomId;
  List<ChatRoom>? _routeChatRooms;
  bool _hasLoadedRouteArgs = false;
  final Map<String, _PendingGroceryMessage> _pendingGroceryMessages = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoadedRouteArgs) {
      _hasLoadedRouteArgs = true;
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _routeChatRooms = args['chatRooms'] as List<ChatRoom>?;
        _preselectedChatRoomId = args['preselectedChatRoomId'] as String?;
      }
      _startWatching();
    }
  }

  @override
  void dispose() {
    context.read<GroceryBloc>().add(GroceryWatchStopRequested());
    super.dispose();
  }

  void _startWatching() {
    if (_preselectedChatRoomId != null) {
      context.read<GroceryBloc>().add(
        GroceryWatchRequested(chatRoomIds: [_preselectedChatRoomId!]),
      );
    } else {
      final chatState = context.read<ChatBloc>().state;
      final chatRoomIds = chatState.chatRooms.map((r) => r.id).toList();
      context.read<GroceryBloc>().add(
        GroceryWatchRequested(chatRoomIds: chatRoomIds),
      );
    }
  }

  List<GroceryItem> _getFilteredItems(GroceryState state) {
    switch (_activeFilter) {
      case _GroceryFilter.all:
        return state.items;
      case _GroceryFilter.needed:
        return state.pendingItems;
      case _GroceryFilter.purchased:
        return state.purchasedItems;
    }
  }

  String? _getCurrentUserId() {
    final authState = context.read<AuthBloc>().state;
    return authState.user?.id;
  }

  bool _canEditItem(GroceryItem item) {
    final currentUserId = _getCurrentUserId();
    return currentUserId != null && item.addedBy == currentUserId;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GroceryBloc, GroceryState>(
      listener: (context, state) {
        if (state.status == GroceryStatus.error && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.error.withValues(alpha: 0.9),
            ),
          );
        }
        _flushPendingGroceryMessages(state);
      },
      builder: (context, state) {
        return Scaffold(
          appBar: GlassAppBar(
            title: 'Shopping List',
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: _buildBody(state),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddItemDialog(context),
            backgroundColor: AppColors.grocery,
            foregroundColor: AppColors.background,
            child: const Icon(Icons.add_shopping_cart),
          ),
        );
      },
    );
  }

  Widget _buildBody(GroceryState state) {
    if (state.status == GroceryStatus.loading) {
      return const GrocerySkeleton();
    }

    if (state.status == GroceryStatus.error && state.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: AppDimensions.spacingMd),
            const Text('Failed to load grocery items'),
            const SizedBox(height: AppDimensions.spacingSm),
            GlassButton(text: 'Retry', onPressed: _startWatching),
          ],
        ),
      );
    }

    final filteredItems = _getFilteredItems(state);

    return Column(
      children: [
        GrocerySummaryCard(
          totalItems: state.items.length,
          neededCount: state.pendingItems.length,
          purchasedCount: state.purchasedItems.length,
        ),
        _buildFilterChips(state),
        Expanded(
          child: filteredItems.isEmpty
              ? _buildEmptyState()
              : _preselectedChatRoomId != null
              ? _buildFlatList(filteredItems)
              : _buildGroupedList(state, filteredItems),
        ),
      ],
    );
  }

  // ─── Filter Chips ───────────────────────────────────────────────

  Widget _buildFilterChips(GroceryState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingMd,
        vertical: AppDimensions.spacingSm,
      ),
      child: Row(
        children: [
          _buildTabChip(
            label: 'All',
            count: state.items.length,
            color: AppColors.primary,
            filter: _GroceryFilter.all,
          ),
          const SizedBox(width: 8),
          _buildTabChip(
            label: 'Needed',
            count: state.pendingItems.length,
            color: AppColors.warning,
            filter: _GroceryFilter.needed,
          ),
          const SizedBox(width: 8),
          _buildTabChip(
            label: 'Purchased',
            count: state.purchasedItems.length,
            color: AppColors.success,
            filter: _GroceryFilter.purchased,
          ),
        ],
      ),
    );
  }

  Widget _buildTabChip({
    required String label,
    required int count,
    required Color color,
    required _GroceryFilter filter,
  }) {
    final isSelected = _activeFilter == filter;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeFilter = filter),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? color : Colors.grey.withValues(alpha: 0.2),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$label ($count)',
                style: TextStyle(
                  color: isSelected ? color : Colors.grey[600],
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Flat List (single room) ────────────────────────────────────

  Widget _buildFlatList(List<GroceryItem> filteredItems) {
    return RefreshIndicator(
      onRefresh: () async => _startWatching(),
      child: ListView.builder(
        padding: const EdgeInsets.all(AppDimensions.spacingMd),
        itemCount: filteredItems.length,
        itemBuilder: (context, index) {
          return _buildDismissibleCard(filteredItems[index]);
        },
      ),
    );
  }

  // ─── Grouped List (multi-room) ──────────────────────────────────

  Widget _buildGroupedList(
    GroceryState state,
    List<GroceryItem> filteredItems,
  ) {
    final chatState = context.watch<ChatBloc>().state;
    final grouped = state.itemsByChatRoomFiltered(filteredItems);
    final chatRoomIds = grouped.keys.toList();

    return RefreshIndicator(
      onRefresh: () async => _startWatching(),
      child: ListView.builder(
        padding: const EdgeInsets.all(AppDimensions.spacingMd),
        itemCount: chatRoomIds.length,
        itemBuilder: (context, index) {
          final chatRoomId = chatRoomIds[index];
          final items = grouped[chatRoomId]!;

          final chatRoomIndex = chatState.chatRooms.indexWhere(
            (r) => r.id == chatRoomId,
          );
          if (chatRoomIndex == -1) return const SizedBox.shrink();
          final chatRoom = chatState.chatRooms[chatRoomIndex];
          final theme = Theme.of(context);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section header
              Padding(
                padding: const EdgeInsets.only(bottom: 8, top: 8),
                child: Row(
                  children: [
                    Icon(
                      chatRoom.members.length > 2 ? Icons.groups : Icons.people,
                      size: 18,
                      color: AppColors.grocery,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        chatRoom.name.isNotEmpty ? chatRoom.name : 'Chat',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.grocery,
                        ),
                      ),
                    ),
                    Text(
                      '${items.length} ${items.length == 1 ? 'item' : 'items'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Items in this chat room
              ...items.map(_buildDismissibleCard),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  // ─── Dismissible Card ───────────────────────────────────────────

  Widget _buildDismissibleCard(GroceryItem item) {
    final isOwner = _canEditItem(item);

    final authState = context.read<AuthBloc>().state;
    final currentUserId = authState.user?.id ?? '';
    final currentUserName = authState.user?.displayName;

    // Disable uncheck for non-purchasers; anyone can purchase
    final canToggle = !item.isPurchased || item.purchasedBy == currentUserId;

    final card = GroceryItemCard(
      item: item,
      isOwner: isOwner,
      currentUserId: currentUserId,
      onImageTap: item.imageUrl != null && item.imageUrl!.isNotEmpty
          ? () => ImageLightbox.show(context, item.imageUrl!, item.id)
          : null,
      onToggle: canToggle
          ? () {
              context.read<GroceryBloc>().add(
                GroceryItemToggleRequested(
                  itemId: item.id,
                  userId: currentUserId,
                  userName: currentUserName,
                ),
              );
              // Send system message for purchase/unpurchase
              final action = item.isPurchased ? 'unpurchased' : 'purchased';
              context.read<ChatBloc>().add(
                MessageSendRequested(
                  message: Message(
                    id: const Uuid().v4(),
                    senderId: currentUserId,
                    senderName: currentUserName ?? 'Someone',
                    content:
                        '${currentUserName ?? 'Someone'} $action ${item.name}',
                    chatRoomId: item.chatRoomId,
                    timestamp: DateTime.now(),
                    type: MessageType.system,
                    sendStatus: MessageSendStatus.sending,
                  ),
                ),
              );
            }
          : null,
      onEdit: isOwner ? () => _showEditItemDialog(context, item) : null,
    );

    if (!isOwner) return card;

    return Dismissible(
      key: Key('grocery_${item.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: AppColors.backgroundLight,
                title: const Text(
                  'Delete Item',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                content: Text(
                  'Are you sure you want to delete "${item.name}"?',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                    ),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) {
        context.read<GroceryBloc>().add(
          GroceryItemDeleteRequested(itemId: item.id),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.name} deleted'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                context.read<GroceryBloc>().add(
                  GroceryItemRestoreRequested(item: item),
                );
              },
            ),
          ),
        );
      },
      child: card,
    );
  }

  // ─── Empty States ───────────────────────────────────────────────

  Widget _buildEmptyState() {
    final theme = Theme.of(context);

    late final IconData icon;
    late final String title;
    late final String subtitle;

    switch (_activeFilter) {
      case _GroceryFilter.all:
        icon = Icons.shopping_basket_outlined;
        title = 'No grocery items yet';
        subtitle = 'Tap + to add items';
      case _GroceryFilter.needed:
        icon = Icons.check_circle_outline;
        title = 'All items purchased!';
        subtitle = 'Great job! List is complete';
      case _GroceryFilter.purchased:
        icon = Icons.shopping_cart_outlined;
        title = 'No purchased items';
        subtitle = 'Items you mark will appear here';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.grocery.withValues(alpha: 0.12),
            ),
            child: Icon(
              icon,
              size: 40,
              color: AppColors.grocery.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingSm),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Dialogs (preserved) ────────────────────────────────────────

  void _showAddItemDialog(BuildContext context) {
    final chatRooms =
        _routeChatRooms ?? this.context.read<ChatBloc>().state.chatRooms;
    final authState = this.context.read<AuthBloc>().state;
    final currentUser = authState.user;
    final userId = currentUser?.id ?? '';
    final userName = currentUser?.displayName;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GroceryItemFormDialog(
        chatRooms: chatRooms,
        preselectedChatRoomId: _preselectedChatRoomId,
        onSubmit: (submission) {
          final item = submission.item;
          final tempItemId = const Uuid().v4();
          final newItem = GroceryItem(
            id: tempItemId,
            name: item.name,
            brand: item.brand,
            size: item.size,
            variant: item.variant,
            quantity: item.quantity,
            note: item.note,
            imageUrl: item.imageUrl,
            category: item.category,
            chatRoomId: item.chatRoomId,
            addedBy: userId,
            addedByName: userName,
            createdAt: DateTime.now(),
          );
          _pendingGroceryMessages[tempItemId] = _PendingGroceryMessage(
            tempItemId: tempItemId,
            senderId: userId,
            senderName: userName ?? 'Unknown',
            timestamp: DateTime.now(),
          );
          this.context.read<GroceryBloc>().add(
            GroceryItemAddRequested(
              item: newItem,
              imagePath: submission.imagePath,
            ),
          );

          ScaffoldMessenger.of(this.context).showSnackBar(
            SnackBar(content: Text('${newItem.name} added to list')),
          );
        },
      ),
    );
  }

  void _showEditItemDialog(BuildContext context, GroceryItem item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GroceryItemFormDialog(
        existingItem: item,
        onSubmit: (submission) {
          this.context.read<GroceryBloc>().add(
            GroceryItemUpdateRequested(
              item: submission.item,
              imagePath: submission.imagePath,
              clearImage: submission.clearImage,
            ),
          );
          ScaffoldMessenger.of(this.context).showSnackBar(
            SnackBar(content: Text('${submission.item.name} updated')),
          );
        },
      ),
    );
  }

  Map<String, dynamic> _buildGroceryMessageItem(GroceryItem item) {
    return {
      'name': item.name,
      'quantity': item.quantity,
      'brand': item.brand,
      'size': item.size,
      'variant': item.variant,
      'category': item.category,
      'note': item.note,
      'imageUrl': item.imageUrl,
    };
  }

  void _flushPendingGroceryMessages(GroceryState state) {
    if (_pendingGroceryMessages.isEmpty) return;

    final resolvedIds = <String>[];
    for (final entry in _pendingGroceryMessages.entries) {
      final pending = entry.value;
      GroceryItem? item;
      for (final candidate in state.items) {
        if (candidate.id == pending.tempItemId) {
          item = candidate;
          break;
        }
      }
      if (item != null && state.status == GroceryStatus.loaded) {
        context.read<ChatBloc>().add(
          MessageSendRequested(
            message: Message(
              id: const Uuid().v4(),
              senderId: pending.senderId,
              senderName: pending.senderName,
              content: 'Added to shopping list: ${item.name}',
              chatRoomId: item.chatRoomId,
              timestamp: pending.timestamp,
              type: MessageType.grocery,
              sendStatus: MessageSendStatus.sending,
              eventData: {
                'items': [_buildGroceryMessageItem(item)],
              },
            ),
          ),
        );
        resolvedIds.add(entry.key);
      } else if (state.status == GroceryStatus.error &&
          state.items.every(
            (candidate) => candidate.id != pending.tempItemId,
          )) {
        resolvedIds.add(entry.key);
      }
    }

    for (final id in resolvedIds) {
      _pendingGroceryMessages.remove(id);
    }
  }
}
