import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/widgets/image_lightbox.dart';
import '../../../../shared/widgets/initials_avatar.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../location/presentation/bloc/event_bloc.dart';
import '../../../living_tools/presentation/bloc/living_tools_bloc.dart';
import '../../domain/entities/message.dart';
import '../bloc/chat_bloc.dart';
import 'special_message_cards.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final bool isGroup;
  final String? currentUserId;
  final Map<String, DateTime> lastReadAt;
  final List<String> members;
  final Map<String, String> memberNames;
  final Map<String, String> memberPhotoUrls;
  final bool isGrouped;
  final bool isLastInGroup;
  final String? searchQuery;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.isGroup,
    this.currentUserId,
    this.lastReadAt = const {},
    this.members = const [],
    this.memberNames = const {},
    this.memberPhotoUrls = const {},
    this.isGrouped = false,
    this.isLastInGroup = true,
    this.searchQuery,
  });

  bool get _isSpecialCard =>
      message.type == MessageType.expense ||
      message.type == MessageType.event ||
      message.type == MessageType.grocery;

  void _showMessageActions(BuildContext context) {
    if (!isMe) return;
    if (message.isDeleted) return;

    final chatRoomId = message.chatRoomId;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text(AppStrings.edit),
              onTap: () {
                Navigator.pop(ctx);
                _showEditDialog(context, chatRoomId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppColors.error),
              title: const Text(
                AppStrings.delete,
                style: TextStyle(color: AppColors.error),
              ),
              onTap: () {
                Navigator.pop(ctx);
                context.read<ChatBloc>().add(
                  MessageDeleteRequested(
                    chatRoomId: chatRoomId,
                    messageId: message.id,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, String chatRoomId) {
    final controller = TextEditingController(text: message.content);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    AppStrings.editMessage,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    maxLines: 3,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: AppStrings.editMessageHint,
                      hintStyle: const TextStyle(
                        color: AppColors.textSecondary,
                      ),
                      filled: true,
                      fillColor: AppColors.getGlassBackground(0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusMd,
                        ),
                        borderSide: BorderSide(
                          color: AppColors.getGlassBorder(0.4),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusMd,
                        ),
                        borderSide: BorderSide(
                          color: AppColors.getGlassBorder(0.4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text(
                          AppStrings.cancel,
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          final newContent = controller.text.trim();
                          if (newContent.isNotEmpty &&
                              newContent != message.content) {
                            context.read<ChatBloc>().add(
                              MessageEditRequested(
                                chatRoomId: chatRoomId,
                                messageId: message.id,
                                newContent: newContent,
                              ),
                            );
                          }
                          Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusMd,
                            ),
                          ),
                        ),
                        child: const Text(AppStrings.save),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).then((_) => controller.dispose());
  }

  void _showReadReceipts(BuildContext context) {
    final otherMembers = members.where((id) => id != currentUserId).toList();
    if (otherMembers.isEmpty) return;

    final readBy = <String, DateTime>{};
    final notSeenBy = <String>[];

    for (final memberId in otherMembers) {
      final readAt = lastReadAt[memberId];
      if (readAt != null && !readAt.isBefore(message.timestamp)) {
        readBy[memberId] = readAt;
      } else {
        notSeenBy.add(memberId);
      }
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXl),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.getGlassBackground(0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppDimensions.radiusXl),
              ),
              border: Border.all(
                color: AppColors.getGlassBorder(0.4),
                width: 1.5,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textTertiary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (readBy.isNotEmpty) ...[
                  const Row(
                    children: [
                      Icon(
                        Icons.done_all,
                        size: 16,
                        color: Colors.lightBlueAccent,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Read by',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...readBy.entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          InitialsAvatar(
                            name: memberNames[entry.key] ?? entry.key,
                            imageUrl: memberPhotoUrls[entry.key],
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              memberNames[entry.key] ?? entry.key,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          Text(
                            DateFormatter.formatTime(entry.value),
                            style: const TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (notSeenBy.isNotEmpty) ...[
                  if (readBy.isNotEmpty) const SizedBox(height: 16),
                  const Row(
                    children: [
                      Icon(
                        Icons.done_all,
                        size: 16,
                        color: AppColors.textTertiary,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Not seen yet',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...notSeenBy.map(
                    (memberId) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          InitialsAvatar(
                            name: memberNames[memberId] ?? memberId,
                            imageUrl: memberPhotoUrls[memberId],
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            memberNames[memberId] ?? memberId,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContentText(ThemeData theme) {
    final textColor = isMe
        ? AppColors.textPrimary
        : theme.colorScheme.onSurface;
    final baseStyle = theme.textTheme.bodyMedium?.copyWith(color: textColor);

    if (searchQuery != null && searchQuery!.isNotEmpty) {
      return _buildHighlightedText(baseStyle);
    }

    return Text(message.content, style: baseStyle);
  }

  Widget _buildHighlightedText(TextStyle? baseStyle) {
    final query = searchQuery!;
    final text = message.content;
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();

    final spans = <TextSpan>[];
    var start = 0;

    while (start < text.length) {
      final matchIndex = lowerText.indexOf(lowerQuery, start);
      if (matchIndex == -1) {
        spans.add(TextSpan(text: text.substring(start), style: baseStyle));
        break;
      }

      if (matchIndex > start) {
        spans.add(
          TextSpan(text: text.substring(start, matchIndex), style: baseStyle),
        );
      }

      spans.add(
        TextSpan(
          text: text.substring(matchIndex, matchIndex + query.length),
          style: baseStyle?.copyWith(
            backgroundColor: AppColors.primary.withValues(alpha: 0.3),
            fontWeight: FontWeight.bold,
          ),
        ),
      );

      start = matchIndex + query.length;
    }

    return RichText(text: TextSpan(children: spans));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (message.type == MessageType.system) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            message.content,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (message.isDeleted) {
      return Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHigh.withValues(
              alpha: 0.5,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            AppStrings.messageDeleted,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ),
      );
    }

    // Determine read status via chatRoom-level lastReadAt
    // Blue double-tick only when ALL other members have read the message
    final bool hasBeenRead;
    if (isMe && currentUserId != null) {
      final otherMembers = members.where((id) => id != currentUserId).toList();
      if (otherMembers.isEmpty) {
        hasBeenRead = false;
      } else {
        hasBeenRead = otherMembers.every((memberId) {
          final readAt = lastReadAt[memberId];
          return readAt != null && !readAt.isBefore(message.timestamp);
        });
      }
    } else {
      hasBeenRead = false;
    }

    final maxBubbleWidth = MediaQuery.of(context).size.width * 0.75;
    final showGroupSenderHeader = !isMe && isGroup && !isGrouped;
    final showSenderInSpecialCard = !(isGroup && !isMe);

    return GestureDetector(
      onLongPress: () {
        HapticFeedback.mediumImpact();
        _showMessageActions(context);
      },
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showGroupSenderHeader)
              Padding(
                padding: const EdgeInsets.only(bottom: 4, left: 2),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxBubbleWidth),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InitialsAvatar(
                        name: message.senderName,
                        imageUrl: memberPhotoUrls[message.senderId],
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          message.senderName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Container(
              margin: _isSpecialCard
                  ? EdgeInsets.zero
                  : EdgeInsets.symmetric(vertical: isGrouped ? 2 : 4),
              padding: _isSpecialCard
                  ? EdgeInsets.zero
                  : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: _isSpecialCard
                  ? null
                  : BoxDecoration(
                      color: isMe
                          ? AppColors.getGlassBackground(0.1)
                          : AppColors.getGlassBackground(0.05),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(
                          AppDimensions.chatBubbleRadius,
                        ),
                        topRight: const Radius.circular(
                          AppDimensions.chatBubbleRadius,
                        ),
                        bottomLeft: Radius.circular(
                          isMe ? AppDimensions.chatBubbleRadius : 6,
                        ),
                        bottomRight: Radius.circular(
                          isMe ? 6 : AppDimensions.chatBubbleRadius,
                        ),
                      ),
                      border: Border.all(
                        color: isMe
                            ? AppColors.primary.withValues(alpha: 0.6)
                            : AppColors.getGlassBorder(0.4),
                        width: 1.5,
                      ),
                    ),
              constraints: _isSpecialCard
                  ? null
                  : BoxConstraints(maxWidth: maxBubbleWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.type == MessageType.event &&
                      message.eventData != null)
                    EventMessageCard(
                      message: {
                        'senderName': message.senderName,
                        'timestamp': message.timestamp,
                        'event': {
                          'eventId': message.eventData!['eventId'] ?? '',
                          'title': message.eventData!['title'] ?? '',
                          'category': message.eventData!['category'] ?? 'other',
                          'creatorName':
                              message.eventData!['creatorName'] ?? '',
                          'latitude': message.eventData!['latitude'] ?? 0.0,
                          'longitude': message.eventData!['longitude'] ?? 0.0,
                          'date': message.eventData!['eventDate'] != null
                              ? DateTime.tryParse(
                                      message.eventData!['eventDate'],
                                    ) ??
                                    DateTime.now()
                              : DateTime.now(),
                          'time': message.eventData!['eventTime'] ?? '',
                          'location':
                              '${(message.eventData!['latitude'] as num?)?.toStringAsFixed(4) ?? '0'}, ${(message.eventData!['longitude'] as num?)?.toStringAsFixed(4) ?? '0'}',
                          'attendees': List<String>.from(
                            message.eventData!['attendeeNames'] ?? [],
                          ),
                          'attendeeIds': List<String>.from(
                            message.eventData!['attendeeIds'] ?? [],
                          ),
                          'maxCapacity': message.eventData!['maxCapacity'],
                        },
                      },
                      isMe: isMe,
                      showSenderInCard: showSenderInSpecialCard,
                      onJoinTap: () {
                        final authState = context.read<AuthBloc>().state;
                        final userId = authState.user?.id;
                        final userName = authState.user?.displayName;
                        final eventId = message.eventData?['eventId'];

                        if (userId != null &&
                            userName != null &&
                            eventId != null) {
                          context.read<EventBloc>().add(
                            EventJoinRequested(
                              eventId: eventId,
                              userId: userId,
                              userName: userName,
                            ),
                          );
                        }
                      },
                      onLeaveTap: () {
                        final authState = context.read<AuthBloc>().state;
                        final userId = authState.user?.id;
                        final eventId = message.eventData?['eventId'];

                        if (userId != null && eventId != null) {
                          context.read<EventBloc>().add(
                            EventLeaveRequested(
                              eventId: eventId,
                              userId: userId,
                            ),
                          );
                        }
                      },
                      onViewDetails: () {
                        final eventId = message.eventData?['eventId'];
                        if (eventId != null) {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.events,
                            arguments: {'eventId': eventId},
                          );
                        }
                      },
                      hasBeenRead: hasBeenRead,
                      isFailed: message.sendStatus == MessageSendStatus.failed,
                      onReadReceiptsTap: () => _showReadReceipts(context),
                      onRetry: () => context.read<ChatBloc>().add(
                        MessageRetryRequested(message: message),
                      ),
                    ),
                  if (message.type == MessageType.location &&
                      message.eventData != null)
                    LocationMessageCard(
                      message: {
                        'senderName': message.senderName,
                        'timestamp': message.timestamp,
                        'location': {
                          'latitude': message.eventData!['latitude'] ?? 0.0,
                          'longitude': message.eventData!['longitude'] ?? 0.0,
                          'address': message.eventData!['address'],
                        },
                      },
                      isMe: isMe,
                      showSenderInCard: showSenderInSpecialCard,
                      hasBeenRead: hasBeenRead,
                      isFailed: message.sendStatus == MessageSendStatus.failed,
                      onReadReceiptsTap: () => _showReadReceipts(context),
                      onRetry: () => context.read<ChatBloc>().add(
                        MessageRetryRequested(message: message),
                      ),
                      onViewInPulse: () {
                        final lat = message.eventData!['latitude'];
                        final lng = message.eventData!['longitude'];
                        if (lat != null && lng != null) {
                          // Return to HomeScreen with deep link data
                          Navigator.pop(context, {
                            'initialTab': 0, // Map tab
                            'targetLat': lat,
                            'targetLng': lng,
                          });
                        }
                      },
                    ),
                  if (message.type == MessageType.paymentRequest &&
                      message.eventData != null)
                    PaymentRequestMessageCard(
                      message: {
                        'senderName': message.senderName,
                        'timestamp': message.timestamp,
                        'paymentRequest': {
                          'billId': message.eventData!['billId'] ?? '',
                          'billTitle': message.eventData!['billTitle'] ?? '',
                          'memberId': message.eventData!['memberId'] ?? '',
                          'memberName': message.eventData!['memberName'] ?? '',
                          'amount':
                              (message.eventData!['amount'] as num?)
                                  ?.toDouble() ??
                              0.0,
                        },
                      },
                      isMe: isMe,
                      onConfirmTap: () {
                        context.read<LivingToolsBloc>().add(
                          LivingToolsBillMarkedAsPaid(
                            billId: message.eventData!['billId'],
                            memberId: message.eventData!['memberId'],
                          ),
                        );
                      },
                      hasBeenRead: hasBeenRead,
                    ),
                  if (message.type == MessageType.bill &&
                      message.eventData != null)
                    BillMessageCard(
                      message: {
                        'senderName': message.senderName,
                        'timestamp': message.timestamp,
                        'bill': {
                          'billId': message.eventData!['billId'] ?? '',
                          'title': message.eventData!['title'] ?? '',
                          'amount':
                              (message.eventData!['amount'] as num?)
                                  ?.toDouble() ??
                              0.0,
                          'dueDate': message.eventData!['dueDate'] != null
                              ? DateTime.tryParse(
                                      message.eventData!['dueDate'],
                                    ) ??
                                    DateTime.now()
                              : DateTime.now(),
                          'type': message.eventData!['type'] ?? 'other',
                          'yourShare':
                              (message.eventData!['yourShare'] as num?)
                                  ?.toDouble() ??
                              0.0,
                          'createdBy': message
                              .senderId, // Correctly track who created it
                        },
                      },
                      isMe: isMe,
                      showSenderInCard: showSenderInSpecialCard,
                      onPayTap: () {
                        final authState = context.read<AuthBloc>().state;
                        if (authState.user != null) {
                          context.read<LivingToolsBloc>().add(
                            LivingToolsBillMarkedAsPaid(
                              billId: message.eventData!['billId'],
                              memberId: authState.user!.id,
                            ),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Payment confirmed!'),
                              backgroundColor: AppColors.success,
                              duration: Duration(seconds: 1),
                            ),
                          );
                        }
                      },
                      hasBeenRead: hasBeenRead,
                      isFailed: message.sendStatus == MessageSendStatus.failed,
                      onReadReceiptsTap: () => _showReadReceipts(context),
                      onRetry: () => context.read<ChatBloc>().add(
                        MessageRetryRequested(message: message),
                      ),
                    ),
                  if (message.type == MessageType.expense &&
                      message.eventData != null)
                    ExpenseMessageCard(
                      message: {
                        'senderName': message.senderName,
                        'timestamp': message.timestamp,
                        'expense': {
                          'amount':
                              (message.eventData!['amount'] as num?)
                                  ?.toDouble() ??
                              0,
                          'description': message.eventData!['title'] ?? '',
                          'members': List<String>.from(
                            message.eventData!['memberNames'] ?? [],
                          ),
                          'perPerson':
                              (message.eventData!['perPerson'] as num?)
                                  ?.toDouble() ??
                              0,
                          'requiresItemSelection':
                              message.eventData!['requiresItemSelection'] ==
                              true,
                        },
                      },
                      isMe: isMe,
                      showSenderInCard: showSenderInSpecialCard,
                      onViewDetails: () {
                        final chatRoomId = message.chatRoomId;
                        final chatRooms = context
                            .read<ChatBloc>()
                            .state
                            .chatRooms;
                        final matchIndex = chatRooms.indexWhere(
                          (r) => r.id == chatRoomId,
                        );
                        if (matchIndex != -1) {
                          final currentRoom = chatRooms[matchIndex];
                          Navigator.of(context).pushNamed(
                            AppRoutes.expense,
                            arguments: {
                              'chatRooms': [currentRoom],
                              'preselectedChatRoomId': chatRoomId,
                            },
                          );
                        } else {
                          Navigator.of(context).pushNamed(AppRoutes.expense);
                        }
                      },
                      hasBeenRead: hasBeenRead,
                      isFailed: message.sendStatus == MessageSendStatus.failed,
                      onReadReceiptsTap: () => _showReadReceipts(context),
                      onRetry: () => context.read<ChatBloc>().add(
                        MessageRetryRequested(message: message),
                      ),
                    ),
                  if (message.type == MessageType.grocery &&
                      message.eventData != null)
                    GroceryMessageCard(
                      message: {
                        'senderName': message.senderName,
                        'timestamp': message.timestamp,
                        'grocery': {
                          'items': List<Map<String, dynamic>>.from(
                            message.eventData!['items'] ?? [],
                          ),
                        },
                      },
                      isMe: isMe,
                      showSenderInCard: showSenderInSpecialCard,
                      onViewList: () {
                        final chatRoomId = message.chatRoomId;
                        final chatRooms = context
                            .read<ChatBloc>()
                            .state
                            .chatRooms;
                        final matchIndex = chatRooms.indexWhere(
                          (r) => r.id == chatRoomId,
                        );
                        if (matchIndex != -1) {
                          final currentRoom = chatRooms[matchIndex];
                          Navigator.of(context).pushNamed(
                            AppRoutes.grocery,
                            arguments: {
                              'chatRooms': [currentRoom],
                              'preselectedChatRoomId': chatRoomId,
                            },
                          );
                        } else {
                          Navigator.of(context).pushNamed(AppRoutes.grocery);
                        }
                      },
                      hasBeenRead: hasBeenRead,
                      isFailed: message.sendStatus == MessageSendStatus.failed,
                      onReadReceiptsTap: () => _showReadReceipts(context),
                      onRetry: () => context.read<ChatBloc>().add(
                        MessageRetryRequested(message: message),
                      ),
                    ),
                  if (message.type != MessageType.event &&
                      message.imageUrl != null &&
                      message.type == MessageType.image)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GestureDetector(
                        onTap: () => ImageLightbox.show(
                          context,
                          message.imageUrl!,
                          message.id,
                        ),
                        child: Hero(
                          tag: message.id,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              message.imageUrl!,
                              width: 200,
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return SizedBox(
                                      width: 200,
                                      height: 150,
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          value:
                                              loadingProgress
                                                      .expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                        .cumulativeBytesLoaded /
                                                    loadingProgress
                                                        .expectedTotalBytes!
                                              : null,
                                        ),
                                      ),
                                    );
                                  },
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.broken_image, size: 48),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (message.content.isNotEmpty &&
                      message.type != MessageType.expense &&
                      message.type != MessageType.event &&
                      message.type != MessageType.grocery)
                    _buildContentText(theme),
                  if (!_isSpecialCard) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (message.editedAt != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Text(
                              AppStrings.edited,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: isMe
                                    ? Colors.white.withValues(alpha: 0.6)
                                    : theme.colorScheme.onSurface.withValues(
                                        alpha: 0.6,
                                      ),
                                fontStyle: FontStyle.italic,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        Text(
                          DateFormatter.formatTime(message.timestamp),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isMe
                                ? Colors.white.withValues(alpha: 0.7)
                                : theme.colorScheme.onSurface.withValues(
                                    alpha: 0.5,
                                  ),
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 4),
                          if (message.sendStatus == MessageSendStatus.failed)
                            Icon(
                              Icons.error_outline,
                              size: 14,
                              color: AppColors.error.withValues(alpha: 0.7),
                            )
                          else
                            GestureDetector(
                              onTap: () => _showReadReceipts(context),
                              child: Icon(
                                Icons.done_all,
                                size: 14,
                                color: hasBeenRead
                                    ? Colors.lightBlueAccent
                                    : Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                        ],
                        if (message.sendStatus == MessageSendStatus.failed &&
                            isMe) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              context.read<ChatBloc>().add(
                                MessageRetryRequested(message: message),
                              );
                            },
                            child: Icon(
                              Icons.refresh,
                              size: 16,
                              color: AppColors.error.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
