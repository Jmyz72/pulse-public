import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/date_formatter.dart';
import 'package:pulse/features/living_tools/presentation/bloc/living_tools_bloc.dart';
import 'package:pulse/features/living_tools/presentation/widgets/add_bill_form.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../location/presentation/bloc/event_bloc.dart';
import '../../../location/presentation/widgets/create_event_bottom_sheet.dart';
import '../../domain/entities/message.dart';
import '../bloc/chat_bloc.dart';
import '../widgets/chat_app_bar.dart';
import '../widgets/date_divider.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input_bar.dart';
import '../widgets/quick_action_chip.dart';

const _uuid = Uuid();

class GroupChatScreen extends StatefulWidget {
  const GroupChatScreen({super.key});

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _showQuickActions = false;
  bool _isSearching = false;
  bool _showScrollToBottom = false;
  late final ChatBloc _chatBloc;
  late final String _currentUserId;
  late final String _currentUserName;

  Map<String, dynamic>? _chatData;

  // Quick Actions Configuration
  static final List<Map<String, dynamic>> _quickActionsConfig = [
    {
      'icon': Icons.attach_money,
      'label': 'Split',
      'color': AppColors.expense,
      'action': 'expense',
    },
    {
      'icon': Icons.shopping_cart,
      'label': 'Grocery',
      'color': AppColors.grocery,
      'action': 'grocery',
    },
    {
      'icon': Icons.receipt_long,
      'label': 'Bill',
      'color': AppColors.bill,
      'action': 'bill',
    },
    {
      'icon': Icons.location_on,
      'label': 'Location',
      'color': AppColors.location,
      'action': 'location',
    },
    {
      'icon': Icons.event,
      'label': 'Event',
      'color': AppColors.event,
      'action': 'event',
    },
  ];

  Map<String, String> _asStringMap(dynamic value) {
    if (value is! Map) return const {};
    return value.map(
      (key, mapValue) => MapEntry(key.toString(), mapValue?.toString() ?? ''),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_chatData == null) {
      _chatBloc = context.read<ChatBloc>();
      final authState = context.read<AuthBloc>().state;
      _currentUserId = authState.user?.id ?? '';
      _currentUserName = authState.user?.displayName ?? 'Me';
      _chatData =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final chatRoomId = _chatData?['id'] as String?;
      if (chatRoomId != null && chatRoomId.isNotEmpty) {
        _chatBloc.add(ChatMessagesWatchRequested(chatRoomId: chatRoomId));
        _chatBloc.add(
          MarkAsReadRequested(chatRoomId: chatRoomId, userId: _currentUserId),
        );
        _chatBloc.add(
          ChatTypingWatchRequested(
            chatRoomId: chatRoomId,
            currentUserId: _currentUserId,
          ),
        );

        // If opened via deep link without full room data, fetch it
        final hasName = (_chatData?['name'] as String?)?.isNotEmpty ?? false;
        final hasMembers =
            (_chatData?['members'] as List?)?.isNotEmpty ?? false;
        if (!hasName || !hasMembers) {
          _chatBloc.add(ChatRoomFetchRequested(chatRoomId: chatRoomId));
        }

        // Watch presence for other members in 1-on-1 chats
        final membersList = _chatData?['members'] as List<dynamic>? ?? [];
        final otherMembers = membersList
            .map((e) => e.toString())
            .where((id) => id != _currentUserId)
            .toList();
        if (otherMembers.isNotEmpty) {
          _chatBloc.add(PresenceWatchRequested(userIds: otherMembers));
        }

        // Watch events so we can detect when a new one is created for sharing
        if (_currentUserId.isNotEmpty) {
          context.read<EventBloc>().add(
            EventWatchRequested(userId: _currentUserId),
          );
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    // Check if near bottom (reversed list, so position 0 = bottom)
    final isAtBottom =
        _scrollController.hasClients &&
        _scrollController.position.pixels <= 100;
    if (isAtBottom != !_showScrollToBottom) {
      setState(() => _showScrollToBottom = !isAtBottom);
    }

    // Load more messages when near top (older messages)
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 50) {
      final chatRoomId = _chatData?['id'] as String? ?? '';
      if (chatRoomId.isNotEmpty) {
        _chatBloc.add(ChatMoreMessagesLoadRequested(chatRoomId: chatRoomId));
      }
    }
  }

  @override
  void dispose() {
    _chatBloc.add(ChatMessagesWatchStopRequested());
    // Stop typing when leaving
    final chatRoomId = _chatData?['id'] as String? ?? '';
    if (chatRoomId.isNotEmpty) {
      _chatBloc.add(
        ChatTypingStatusChangeRequested(
          chatRoomId: chatRoomId,
          userId: _currentUserId,
          isTyping: false,
        ),
      );
    }
    _messageController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    HapticFeedback.lightImpact();

    final chatRoomId = _chatData?['id'] as String? ?? '';
    final message = Message(
      id: _uuid.v4(),
      senderId: _currentUserId,
      senderName: _currentUserName,
      content: _messageController.text.trim(),
      chatRoomId: chatRoomId,
      timestamp: DateTime.now(),
      sendStatus: MessageSendStatus.sending,
    );

    context.read<ChatBloc>().add(MessageSendRequested(message: message));
    _messageController.clear();
  }

  void _onTypingChanged(bool isTyping) {
    final chatRoomId = _chatData?['id'] as String? ?? '';
    if (chatRoomId.isNotEmpty) {
      context.read<ChatBloc>().add(
        ChatTypingStatusChangeRequested(
          chatRoomId: chatRoomId,
          userId: _currentUserId,
          isTyping: isTyping,
        ),
      );
    }
  }

  Future<void> _pickAndSendImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    if (!mounted) return;

    final chatRoomId = _chatData?['id'] as String? ?? '';
    if (chatRoomId.isEmpty) return;

    context.read<ChatBloc>().add(
      MediaMessageSendRequested(
        chatRoomId: chatRoomId,
        senderId: _currentUserId,
        senderName: _currentUserName,
        filePath: picked.path,
        fileName: picked.name,
      ),
    );
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        context.read<ChatBloc>().add(MessageSearchClearRequested());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatData = _chatData;

    final String chatName = chatData?['name'] ?? 'Chat';
    final bool isGroup = chatData?['isGroup'] ?? false;
    final List<dynamic> members = chatData?['members'] ?? [];
    final List<String> memberIds = members.map((e) => e.toString()).toList();
    final Map<String, String> memberNames = _asStringMap(
      chatData?['memberNames'],
    );
    final Map<String, String> memberPhones = _asStringMap(
      chatData?['memberPhones'],
    );
    final Map<String, String> memberPhotoUrls = _asStringMap(
      chatData?['memberPhotoUrls'],
    );
    final String avatar = chatData?['avatar'] ?? '';
    final String? avatarUrl = (chatData?['avatarUrl'] as String?)?.trim();
    final bool isOnline = chatData?['isOnline'] ?? false;
    final String chatRoomId = chatData?['id'] ?? '';
    final List<dynamic> admins = chatData?['admins'] ?? [];

    return MultiBlocListener(
      listeners: [
        BlocListener<ChatBloc, ChatState>(
          listenWhen: (prev, curr) =>
              prev.fetchedChatRoom != curr.fetchedChatRoom &&
              curr.fetchedChatRoom != null,
          listener: (context, state) {
            final room = state.fetchedChatRoom;
            if (room != null && room.id == chatRoomId) {
              final existingAvatarUrl = (_chatData?['avatarUrl'] as String?)
                  ?.trim();
              setState(() {
                _chatData = {
                  ..._chatData ?? {},
                  'name': room.name,
                  'members': room.members,
                  'isGroup': room.isGroup,
                  'admins': room.admins,
                  'memberNames': room.memberNames,
                  'avatarUrl':
                      (existingAvatarUrl != null &&
                          existingAvatarUrl.isNotEmpty)
                      ? existingAvatarUrl
                      : room.imageUrl,
                };
              });
              // Start presence watching now that we have members
              final otherMembers = room.members
                  .where((id) => id != _currentUserId)
                  .toList();
              if (otherMembers.isNotEmpty) {
                _chatBloc.add(PresenceWatchRequested(userIds: otherMembers));
              }
              // Clear fetchedChatRoom from state
              _chatBloc.add(ChatRoomsLoadRequested());
            }
          },
        ),
        BlocListener<EventBloc, EventState>(
          listenWhen: (prev, curr) =>
              prev.createStatus != curr.createStatus &&
              curr.createStatus == EventCreateStatus.created,
          listener: (context, state) {
            if (state.events.isNotEmpty) {
              // Get all events by current user
              final userEvents = state.events
                  .where((e) => e.creatorId == _currentUserId)
                  .toList();

              if (userEvents.isNotEmpty) {
                // Sort by creation time to get the absolute newest
                userEvents.sort((a, b) => b.createdAt.compareTo(a.createdAt));
                final newEvent = userEvents.first;

                // Safety: only share if it was created in the last 10 seconds to avoid accidental reshares
                final age = DateTime.now()
                    .difference(newEvent.createdAt)
                    .inSeconds;
                if (age > 10) return;

                final message = Message(
                  id: _uuid.v4(),
                  senderId: _currentUserId,
                  senderName: _currentUserName,
                  content: 'New Event: ${newEvent.title}',
                  chatRoomId: chatRoomId,
                  timestamp: DateTime.now(),
                  type: MessageType.event,
                  eventData: {
                    'eventId': newEvent
                        .id, // Ensure this matches MessageBubble extraction
                    'title': newEvent.title,
                    'description': newEvent.description,
                    'category': newEvent.category,
                    'latitude': newEvent.latitude,
                    'longitude': newEvent.longitude,
                    'eventDate': newEvent.eventDate.toIso8601String(),
                    'eventTime': newEvent.eventTime,
                    'creatorName': newEvent.creatorName,
                    'attendeeNames': newEvent.attendeeNames,
                    'attendeeIds': newEvent.attendeeIds,
                    'maxCapacity': newEvent.maxCapacity,
                  },
                );

                context.read<ChatBloc>().add(
                  MessageSendRequested(message: message),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Event "${newEvent.title}" shared to chat!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: AppColors.background,
        floatingActionButton: _showScrollToBottom
            ? FloatingActionButton.small(
                onPressed: () {
                  _scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                },
                backgroundColor: AppColors.primary,
                child: const Icon(Icons.arrow_downward, color: Colors.white),
              )
            : null,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: BlocBuilder<ChatBloc, ChatState>(
            buildWhen: (prev, curr) =>
                prev.typingUserIds != curr.typingUserIds ||
                prev.onlineStatus != curr.onlineStatus,
            builder: (context, chatState) {
              final bool resolvedOnline = isGroup
                  ? isOnline
                  : (chatState.onlineStatus.isNotEmpty
                        ? chatState.onlineStatus.values.any((v) => v)
                        : isOnline);
              return ChatAppBar(
                chatName: chatName,
                avatar: avatar,
                avatarUrl: avatarUrl,
                isGroup: isGroup,
                members: members,
                memberNames: memberNames,
                memberPhones: memberPhones,
                memberPhotoUrls: memberPhotoUrls,
                isOnline: resolvedOnline,
                chatRoomId: chatRoomId,
                typingUserIds: chatState.typingUserIds,
                onSearchPressed: _toggleSearch,
                isSearching: _isSearching,
                admins: admins,
              );
            },
          ),
        ),
        body: Column(
          children: [
            if (_isSearching)
              _MessageSearchBar(
                searchController: _searchController,
                onToggleSearch: _toggleSearch,
              ),
            const _UploadProgressIndicator(),
            Expanded(
              child: _ChatMessagesView(
                chatRoomId: chatRoomId,
                currentUserId: _currentUserId,
                isSearching: _isSearching,
                scrollController: _scrollController,
                isGroup: isGroup,
                members: memberIds,
                memberNames: memberNames,
                memberPhotoUrls: memberPhotoUrls,
              ),
            ),
            MessageInputBar(
              controller: _messageController,
              onSend: _sendMessage,
              showQuickActions: _showQuickActions,
              onToggleQuickActions: () =>
                  setState(() => _showQuickActions = !_showQuickActions),
              onTypingChanged: _onTypingChanged,
              onAttachmentPressed: _pickAndSendImage,
              quickActionChips: _quickActionsConfig
                  .expand(
                    (config) => [
                      QuickActionChip(
                        icon: config['icon'] as IconData,
                        label: config['label'] as String,
                        color: config['color'] as Color,
                        onTap: () {
                          setState(() => _showQuickActions = false);
                          if (config['action'] == 'expense') {
                            _handleExpenseTap();
                          } else {
                            _handleQuickAction(config['action'] as String);
                          }
                        },
                        onLongPress: config['action'] == 'expense'
                            ? () {
                                setState(() => _showQuickActions = false);
                                _handleQuickAction('expense');
                              }
                            : null,
                      ),
                      if (config != _quickActionsConfig.last)
                        const SizedBox(width: 8),
                    ],
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _handleExpenseTap() {
    final chatRoomId = _chatData?['id'] as String? ?? '';
    if (chatRoomId.isEmpty) return;
    final chatRooms = _chatBloc.state.chatRooms;
    final matchIndex = chatRooms.indexWhere((r) => r.id == chatRoomId);
    if (matchIndex == -1) return;
    final currentRoom = chatRooms[matchIndex];
    Navigator.pushNamed(
      context,
      AppRoutes.expense,
      arguments: {
        'chatRooms': [currentRoom],
        'preselectedChatRoomId': chatRoomId,
      },
    );
  }

  void _handleQuickAction(String action) {
    if (action == 'expense') {
      final chatRoomId = _chatData?['id'] as String? ?? '';
      if (chatRoomId.isEmpty) return;
      final chatRooms = _chatBloc.state.chatRooms;
      final matchIndex = chatRooms.indexWhere((r) => r.id == chatRoomId);
      if (matchIndex == -1) return;
      final currentRoom = chatRooms[matchIndex];
      Navigator.pushNamed(
        context,
        AppRoutes.addExpense,
        arguments: {
          'chatRooms': [currentRoom],
          'preselectedChatRoomId': chatRoomId,
        },
      );
      return;
    }
    if (action == 'grocery') {
      final chatRoomId = _chatData?['id'] as String? ?? '';
      if (chatRoomId.isEmpty) return;
      final chatRooms = _chatBloc.state.chatRooms;
      final matchIndex = chatRooms.indexWhere((r) => r.id == chatRoomId);
      if (matchIndex == -1) return;
      final currentRoom = chatRooms[matchIndex];
      Navigator.pushNamed(
        context,
        AppRoutes.grocery,
        arguments: {
          'chatRooms': [currentRoom],
          'preselectedChatRoomId': chatRoomId,
        },
      );
      return;
    }
    if (action == 'event') {
      _handleEventAction();
      return;
    }
    if (action == 'location') {
      _handleLocationAction();
      return;
    }
    if (action == 'bill') {
      _handleBillAction();
      return;
    }
    _showComingSoon(context);
  }

  void _handleBillAction() {
    final chatRoomId = _chatData?['id'] as String? ?? '';
    final roomName = _chatData?['name'] as String? ?? 'Chat';
    final memberIds = _chatData?['members'] as List<dynamic>? ?? [];
    final memberNames = _chatData?['memberNames'] as Map<String, String>? ?? {};

    if (chatRoomId.isEmpty || memberIds.isEmpty) return;

    final List<Map<String, String>> members = memberIds.map((id) {
      final name = memberNames[id] ?? 'Unknown';
      return {
        'id': id.toString(),
        'name': name,
        'avatar': name.isNotEmpty ? name[0].toUpperCase() : '?',
      };
    }).toList();

    final livingToolsBloc = context.read<LivingToolsBloc>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => AddBillForm(
        currentUserId: _currentUserId,
        currentUserName: _currentUserName,
        chatRoomId: chatRoomId,
        chatRoomName: roomName,
        members: members,
        onSubmit: (bill) {
          // 1. Create the bill in Firestore
          livingToolsBloc.add(LivingToolsBillCreated(bill: bill));

          // 2. Automatically share it to this chat
          final yourShare = bill.getShareForUser(_currentUserId);
          final message = Message(
            id: _uuid.v4(),
            senderId: _currentUserId,
            senderName: _currentUserName,
            content: 'Created a shared bill: ${bill.title}',
            chatRoomId: chatRoomId,
            timestamp: DateTime.now(),
            type: MessageType.bill,
            eventData: {
              'billId': bill
                  .id, // This will be updated by the bloc when Firestore assigns an ID, but for the optimistic UI we send the local one
              'title': bill.title,
              'amount': bill.amount,
              'dueDate': bill.dueDate.toIso8601String(),
              'type': bill.type.name,
              'yourShare': yourShare,
            },
          );

          _chatBloc.add(MessageSendRequested(message: message));

          Navigator.pop(sheetContext);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Bill "${bill.title}" created and shared!'),
              backgroundColor: AppColors.success,
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleLocationAction() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 12),
            Text('Getting current location...'),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      if (!mounted) return;

      final chatRoomId = _chatData?['id'] as String? ?? '';
      if (chatRoomId.isEmpty) return;

      final message = Message(
        id: _uuid.v4(),
        senderId: _currentUserId,
        senderName: _currentUserName,
        content: 'Shared a location',
        chatRoomId: chatRoomId,
        timestamp: DateTime.now(),
        type: MessageType.location,
        eventData: {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'address': 'Current Location', // Could use geocoding here if desired
        },
      );

      _chatBloc.add(MessageSendRequested(message: message));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to get location: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleEventAction() async {
    // Default coordinates (KL area)
    double lat = 3.1390;
    double lng = 101.6869;

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );
      lat = position.latitude;
      lng = position.longitude;
    } catch (e) {
      debugPrint('Error getting location for event: $e');
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          CreateEventBottomSheet(latitude: lat, longitude: lng),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text(AppStrings.comingSoon)));
  }
}

class _MessageSearchBar extends StatelessWidget {
  final TextEditingController searchController;
  final VoidCallback onToggleSearch;

  const _MessageSearchBar({
    required this.searchController,
    required this.onToggleSearch,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  controller: searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: AppStrings.searchMessages,
                    hintStyle: const TextStyle(color: AppColors.textSecondary),
                    prefixIcon: const Icon(
                      Icons.search,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(
                        Icons.close,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: onToggleSearch,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  onChanged: (query) {
                    if (query.isNotEmpty) {
                      context.read<ChatBloc>().add(
                        MessageSearchRequested(query: query),
                      );
                    } else {
                      context.read<ChatBloc>().add(
                        MessageSearchClearRequested(),
                      );
                    }
                  },
                ),
              ),
            ),
          ),
        ),
        BlocBuilder<ChatBloc, ChatState>(
          buildWhen: (prev, curr) => prev.searchResults != curr.searchResults,
          builder: (context, state) {
            if (state.searchResults.isEmpty &&
                state.searchQuery != null &&
                state.searchQuery!.isNotEmpty) {
              return Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                child: Text(
                  'No results found',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              );
            }
            if (state.searchResults.isNotEmpty) {
              return Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                child: Text(
                  '${state.searchResults.length} ${state.searchResults.length == 1 ? 'result' : 'results'}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }
}

class _UploadProgressIndicator extends StatelessWidget {
  const _UploadProgressIndicator();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocSelector<ChatBloc, ChatState, double?>(
      selector: (state) => state.uploadProgress,
      builder: (context, progress) {
        if (progress == null) return const SizedBox.shrink();
        return Column(
          children: [
            LinearProgressIndicator(
              value: progress > 0 ? progress : null,
              backgroundColor: AppColors.grey100,
              color: AppColors.primary,
            ),
            if (progress > 0)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  'Uploading: ${(progress * 100).toInt()}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ChatMessagesView extends StatelessWidget {
  final String chatRoomId;
  final String currentUserId;
  final bool isSearching;
  final ScrollController scrollController;
  final bool isGroup;
  final List<String> members;
  final Map<String, String> memberNames;
  final Map<String, String> memberPhotoUrls;

  const _ChatMessagesView({
    required this.chatRoomId,
    required this.currentUserId,
    required this.isSearching,
    required this.scrollController,
    required this.isGroup,
    this.members = const [],
    this.memberNames = const {},
    this.memberPhotoUrls = const {},
  });

  bool _shouldGroupMessage(Message current, Message? adjacent) {
    if (adjacent == null) return false;
    if (current.senderId != adjacent.senderId) return false;

    final timeDiffMinutes = current.timestamp
        .difference(adjacent.timestamp)
        .inMinutes
        .abs();
    return timeDiffMinutes < 5;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<ChatBloc, ChatState>(
      listenWhen: (prev, curr) =>
          prev.status != curr.status ||
          prev.messages.length != curr.messages.length,
      buildWhen: (prev, curr) =>
          prev.status != curr.status ||
          prev.messages != curr.messages ||
          prev.isLoadingMore != curr.isLoadingMore ||
          prev.uploadProgress != curr.uploadProgress ||
          prev.searchQuery != curr.searchQuery ||
          prev.searchResults != curr.searchResults ||
          prev.currentChatRoom != curr.currentChatRoom,
      listener: (context, state) {
        if (state.status == ChatStatus.loaded &&
            state.messages.isNotEmpty &&
            chatRoomId.isNotEmpty) {
          context.read<ChatBloc>().add(
            MarkAsReadRequested(chatRoomId: chatRoomId, userId: currentUserId),
          );

          if (scrollController.hasClients &&
              scrollController.position.pixels <= 200) {
            Future.delayed(const Duration(milliseconds: 100), () {
              if (scrollController.hasClients) {
                scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              }
            });
          }
        }
      },
      builder: (context, state) {
        if (state.status == ChatStatus.loading && state.messages.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 64,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  AppStrings.noMessagesYet,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.sendMessageToStart,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          );
        }

        final displayMessages =
            ((isSearching &&
                      state.searchQuery != null &&
                      state.searchQuery!.isNotEmpty)
                  ? List<Message>.from(state.searchResults)
                  : List<Message>.from(state.messages))
              ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

        final effectiveMemberNames =
            state.currentChatRoom?.memberNames.isNotEmpty == true
            ? {...memberNames, ...state.currentChatRoom!.memberNames}
            : memberNames;

        return Column(
          children: [
            if (state.isLoadingMore)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                reverse: true,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                itemCount: displayMessages.length,
                itemBuilder: (context, index) {
                  final message =
                      displayMessages[displayMessages.length - 1 - index];
                  final isMe = message.senderId == currentUserId;

                  Widget? dateDivider;
                  final bool showDivider;
                  if (index == displayMessages.length - 1) {
                    showDivider = true;
                  } else {
                    final prevMessage =
                        displayMessages[displayMessages.length -
                            1 -
                            (index + 1)];
                    final msgDate = DateTime(
                      message.timestamp.year,
                      message.timestamp.month,
                      message.timestamp.day,
                    );
                    final prevDate = DateTime(
                      prevMessage.timestamp.year,
                      prevMessage.timestamp.month,
                      prevMessage.timestamp.day,
                    );
                    showDivider = msgDate != prevDate;
                  }
                  if (showDivider) {
                    final now = DateTime.now();
                    final today = DateTime(now.year, now.month, now.day);
                    final msgDate = DateTime(
                      message.timestamp.year,
                      message.timestamp.month,
                      message.timestamp.day,
                    );
                    final String label;
                    if (msgDate == today) {
                      label = AppStrings.today;
                    } else if (msgDate ==
                        today.subtract(const Duration(days: 1))) {
                      label = AppStrings.yesterday;
                    } else {
                      label = DateFormatter.formatDate(message.timestamp);
                    }
                    dateDivider = DateDivider(date: label);
                  }

                  final newerMessage = index > 0
                      ? displayMessages[displayMessages.length -
                            1 -
                            (index - 1)]
                      : null;
                  final olderMessage = index < displayMessages.length - 1
                      ? displayMessages[displayMessages.length -
                            1 -
                            (index + 1)]
                      : null;
                  final isGrouped = _shouldGroupMessage(message, olderMessage);
                  final isLastInGroup =
                      newerMessage == null ||
                      !_shouldGroupMessage(newerMessage, message);

                  return Column(
                    children: [
                      ?dateDivider,
                      MessageBubble(
                        message: message,
                        isMe: isMe,
                        isGroup: isGroup,
                        currentUserId: currentUserId,
                        lastReadAt:
                            state.currentChatRoom?.lastReadAt ?? const {},
                        members: state.currentChatRoom?.members ?? members,
                        memberNames: effectiveMemberNames,
                        memberPhotoUrls: memberPhotoUrls,
                        isGrouped: isGrouped,
                        isLastInGroup: isLastInGroup,
                        searchQuery: state.searchQuery,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
