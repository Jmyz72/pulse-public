import 'dart:async';
import 'dart:math';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/usecases/usecase.dart';
import '../../core/chat_constants.dart';
import '../../domain/entities/message.dart';
import '../../domain/usecases/add_chat_member.dart';
import '../../domain/usecases/create_chat_room.dart';
import '../../domain/usecases/delete_chat_room.dart';
import '../../domain/usecases/delete_message.dart';
import '../../domain/usecases/edit_message.dart';
import '../../domain/usecases/get_chat_room_by_id.dart';
import '../../domain/usecases/get_chat_rooms.dart';
import '../../domain/usecases/get_failed_messages.dart';
import '../../domain/usecases/get_merged_messages.dart';
import '../../domain/usecases/leave_chat_group.dart';
import '../../domain/usecases/get_messages.dart';
import '../../domain/usecases/make_admin.dart';
import '../../domain/usecases/mark_as_read.dart';
import '../../domain/usecases/remove_admin.dart';
import '../../domain/usecases/remove_chat_member.dart';
import '../../domain/usecases/remove_failed_message.dart';
import '../../domain/usecases/save_failed_message.dart';
import '../../domain/usecases/search_messages.dart';
import '../../domain/usecases/send_message.dart';
import '../../domain/usecases/set_typing_status.dart';
import '../../domain/usecases/update_presence.dart';
import '../../domain/usecases/upload_chat_media.dart';
import '../../domain/usecases/watch_chat_room.dart';
import '../../domain/usecases/watch_chat_rooms.dart';
import '../../domain/usecases/watch_messages.dart';
import '../../domain/usecases/watch_typing_users.dart';
import '../../domain/usecases/watch_user_presence.dart';

part 'chat_event.dart';
part 'chat_state.dart';

const _uuid = Uuid();

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final GetChatRooms getChatRooms;
  final WatchChatRooms watchChatRooms;
  final WatchChatRoom watchChatRoom;
  final GetMessages getMessages;
  final SendMessage sendMessage;
  final WatchMessages watchMessages;
  final CreateChatRoom createChatRoom;
  final DeleteChatRoom deleteChatRoom;
  final MarkAsRead markAsRead;
  final EditMessage editMessage;
  final DeleteMessage deleteMessage;
  final SetTypingStatus setTypingStatus;
  final WatchTypingUsers watchTypingUsers;
  final UploadChatMedia uploadChatMedia;
  final SaveFailedMessage? saveFailedMessage;
  final GetFailedMessages? getFailedMessages;
  final GetMergedMessages getMergedMessages;
  final RemoveFailedMessage? removeFailedMessage;
  final UpdatePresence? updatePresence;
  final WatchUserPresence? watchUserPresence;
  final AddChatMember? addChatMember;
  final RemoveChatMember? removeChatMember;
  final LeaveChatGroup? leaveChatGroup;
  final MakeAdmin makeAdmin;
  final RemoveAdmin removeAdmin;
  final GetChatRoomById getChatRoomById;
  final SearchMessages searchMessages;

  StreamSubscription<List<Message>>? _messagesSubscription;
  StreamSubscription<List<String>>? _typingSubscription;
  StreamSubscription<Map<String, bool>>? _presenceSubscription;
  StreamSubscription<List<ChatRoom>>? _chatRoomsSubscription;
  StreamSubscription<ChatRoom>? _currentChatRoomSubscription;
  int _reconnectAttempts = 0;

  ChatBloc({
    required this.getChatRooms,
    required this.watchChatRooms,
    required this.watchChatRoom,
    required this.getMessages,
    required this.sendMessage,
    required this.watchMessages,
    required this.createChatRoom,
    required this.deleteChatRoom,
    required this.markAsRead,
    required this.editMessage,
    required this.deleteMessage,
    required this.setTypingStatus,
    required this.watchTypingUsers,
    required this.uploadChatMedia,
    this.saveFailedMessage,
    this.getFailedMessages,
    required this.getMergedMessages,
    this.removeFailedMessage,
    this.updatePresence,
    this.watchUserPresence,
    this.addChatMember,
    this.removeChatMember,
    this.leaveChatGroup,
    required this.makeAdmin,
    required this.removeAdmin,
    required this.getChatRoomById,
    required this.searchMessages,
  }) : super(const ChatState()) {
    on<ChatRoomsLoadRequested>(
      _onChatRoomsLoadRequested,
      transformer: droppable(),
    );
    on<ChatRoomsWatchRequested>(_onChatRoomsWatchRequested);
    on<ChatRoomsWatchStopRequested>(_onChatRoomsWatchStopRequested);
    on<ChatClearedRequested>(_onChatClearedRequested);
    on<_ChatRoomsUpdated>(_onChatRoomsUpdated);
    on<_CurrentChatRoomUpdated>(_onCurrentChatRoomUpdated);
    on<ChatMessagesLoadRequested>(
      _onChatMessagesLoadRequested,
      transformer: droppable(),
    );
    on<MessageSendRequested>(_onMessageSendRequested, transformer: droppable());
    on<ChatMessagesWatchRequested>(_onChatMessagesWatchRequested);
    on<ChatMessagesWatchStopRequested>(_onChatMessagesWatchStopRequested);
    on<_ChatMessagesUpdated>(_onChatMessagesUpdated);
    on<_ChatMessagesWatchError>(_onChatMessagesWatchError);
    on<ChatRoomDeleteRequested>(
      _onChatRoomDeleteRequested,
      transformer: droppable(),
    );
    on<ChatRoomCreateRequested>(
      _onChatRoomCreateRequested,
      transformer: droppable(),
    );
    on<MarkAsReadRequested>(
      _onMarkAsReadRequested,
      transformer: (events, mapper) =>
          events.debounce(const Duration(seconds: 1)).switchMap(mapper),
    );
    on<ChatMoreMessagesLoadRequested>(
      _onChatMoreMessagesLoadRequested,
      transformer: droppable(),
    );
    on<MessageEditRequested>(_onMessageEditRequested, transformer: droppable());
    on<MessageDeleteRequested>(
      _onMessageDeleteRequested,
      transformer: droppable(),
    );
    on<MessageRetryRequested>(_onMessageRetryRequested);
    on<ChatTypingStatusChangeRequested>(_onChatTypingStatusChangeRequested);
    on<ChatTypingWatchRequested>(_onChatTypingWatchRequested);
    on<_ChatTypingUsersUpdated>(_onChatTypingUsersUpdated);
    on<MediaMessageSendRequested>(
      _onMediaMessageSendRequested,
      transformer: droppable(),
    );
    on<MessageSearchRequested>(
      _onMessageSearchRequested,
      transformer: (events, mapper) =>
          events.debounce(const Duration(milliseconds: 300)).switchMap(mapper),
    );
    on<MessageSearchClearRequested>(_onMessageSearchClearRequested);
    on<PresenceWatchRequested>(_onPresenceWatchRequested);
    on<_ChatPresenceUpdated>(_onChatPresenceUpdated);
    on<AddChatMemberRequested>(
      _onAddChatMemberRequested,
      transformer: droppable(),
    );
    on<RemoveChatMemberRequested>(
      _onRemoveChatMemberRequested,
      transformer: droppable(),
    );
    on<LeaveGroupRequested>(_onLeaveGroupRequested, transformer: droppable());
    on<MakeAdminRequested>(_onMakeAdminRequested, transformer: droppable());
    on<RemoveAdminRequested>(_onRemoveAdminRequested, transformer: droppable());
    on<ChatRoomFetchRequested>(
      _onChatRoomFetchRequested,
      transformer: droppable(),
    );
  }

  Future<void> _onChatRoomsLoadRequested(
    ChatRoomsLoadRequested event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(status: ChatStatus.loading));

    final result = await getChatRooms(const NoParams());

    result.fold(
      (failure) => emit(
        state.copyWith(status: ChatStatus.error, errorMessage: failure.message),
      ),
      (chatRooms) =>
          emit(state.copyWith(status: ChatStatus.loaded, chatRooms: chatRooms)),
    );
  }

  void _onChatRoomsWatchRequested(
    ChatRoomsWatchRequested event,
    Emitter<ChatState> emit,
  ) {
    _chatRoomsSubscription?.cancel();
    var hasEmitted = false;
    _chatRoomsSubscription = watchChatRooms().listen(
      (chatRooms) {
        hasEmitted = true;
        add(_ChatRoomsUpdated(chatRooms));
      },
      onError: (error) {
        add(
          ChatRoomsLoadRequested(),
        ); // Fallback to one-time fetch on stream error
      },
    );
    // Only show loading if we don't have data yet
    if (state.chatRooms.isEmpty) {
      emit(state.copyWith(status: ChatStatus.loading));
    }

    // Fallback: if stream hasn't emitted within 5 seconds, fetch once
    Future.delayed(const Duration(seconds: 5), () {
      if (!hasEmitted && !isClosed && state.status == ChatStatus.loading) {
        add(ChatRoomsLoadRequested());
      }
    });
  }

  void _onChatRoomsWatchStopRequested(
    ChatRoomsWatchStopRequested event,
    Emitter<ChatState> emit,
  ) {
    _chatRoomsSubscription?.cancel();
    _chatRoomsSubscription = null;
  }

  void _onChatClearedRequested(
    ChatClearedRequested event,
    Emitter<ChatState> emit,
  ) {
    _messagesSubscription?.cancel();
    _messagesSubscription = null;
    _typingSubscription?.cancel();
    _typingSubscription = null;
    _presenceSubscription?.cancel();
    _presenceSubscription = null;
    _chatRoomsSubscription?.cancel();
    _chatRoomsSubscription = null;
    _currentChatRoomSubscription?.cancel();
    _currentChatRoomSubscription = null;
    _reconnectAttempts = 0;

    emit(const ChatState());
  }

  void _onChatRoomsUpdated(_ChatRoomsUpdated event, Emitter<ChatState> emit) {
    emit(state.copyWith(status: ChatStatus.loaded, chatRooms: event.chatRooms));
  }

  Future<void> _onChatMessagesLoadRequested(
    ChatMessagesLoadRequested event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(status: ChatStatus.loading));

    final result = await getMessages(
      GetMessagesParams(chatRoomId: event.chatRoomId),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(status: ChatStatus.error, errorMessage: failure.message),
      ),
      (messages) => emit(
        state.copyWith(
          status: ChatStatus.loaded,
          messages: messages,
          currentChatRoomId: event.chatRoomId,
          hasMoreMessages:
              messages.length >= ChatConstants.messagePaginationLimit,
        ),
      ),
    );
  }

  Future<void> _onMessageSendRequested(
    MessageSendRequested event,
    Emitter<ChatState> emit,
  ) async {
    // Optimistic update: add message to state immediately
    final optimisticMessages = [...state.messages, event.message];
    emit(
      state.copyWith(
        messages: optimisticMessages,
        sendingStatus: SendStatus.sending,
      ),
    );

    final result = await sendMessage(SendMessageParams(message: event.message));

    result.fold(
      (failure) {
        // Mark message as failed instead of removing
        final failedMessage = event.message.copyWith(
          sendStatus: MessageSendStatus.failed,
        );
        final updatedMessages = state.messages
            .map((m) => m.id == event.message.id ? failedMessage : m)
            .toList();
        emit(
          state.copyWith(
            messages: updatedMessages,
            sendingStatus: SendStatus.error,
            errorMessage: failure.message,
          ),
        );
        // Persist failed message for offline retry
        saveFailedMessage?.call(
          SaveFailedMessageParams(message: event.message),
        );
      },
      (message) {
        emit(state.copyWith(sendingStatus: SendStatus.sent));
      },
    );
  }

  Future<void> _onChatMessagesWatchRequested(
    ChatMessagesWatchRequested event,
    Emitter<ChatState> emit,
  ) async {
    _reconnectAttempts = 0;
    _subscribeToMessages(event.chatRoomId);
    _subscribeToChatRoom(
      event.chatRoomId,
    ); // Watch chat room for lastReadAt updates
    emit(
      state.copyWith(
        status: ChatStatus.loading,
        currentChatRoomId: event.chatRoomId,
        messages: [], // Clear messages from previous chat room
      ),
    );
  }

  void _subscribeToMessages(String chatRoomId) {
    _messagesSubscription?.cancel();
    _messagesSubscription =
        watchMessages(WatchMessagesParams(chatRoomId: chatRoomId)).listen(
          (messages) {
            _reconnectAttempts = 0;
            add(_ChatMessagesUpdated(messages));
          },
          onError: (error) {
            if (_reconnectAttempts < ChatConstants.streamReconnectMaxAttempts) {
              _reconnectAttempts++;
              // Cap exponent to prevent overflow (max 2^10 = 1024 seconds)
              final exponent = min(_reconnectAttempts - 1, 10);
              final delay =
                  ChatConstants.streamReconnectBaseDelay *
                  pow(2, exponent).toInt();
              Future.delayed(delay, () {
                if (!isClosed && state.currentChatRoomId == chatRoomId) {
                  _subscribeToMessages(chatRoomId);
                }
              });
            } else {
              add(_ChatMessagesWatchError(error.toString()));
            }
          },
        );
  }

  void _subscribeToChatRoom(String chatRoomId) {
    _currentChatRoomSubscription?.cancel();
    _currentChatRoomSubscription =
        watchChatRoom(WatchChatRoomParams(chatRoomId: chatRoomId)).listen(
          (chatRoom) => add(_CurrentChatRoomUpdated(chatRoom)),
          onError: (_) {}, // Silently handle errors
        );
  }

  void _onCurrentChatRoomUpdated(
    _CurrentChatRoomUpdated event,
    Emitter<ChatState> emit,
  ) {
    // Update the current chat room in state to get latest lastReadAt
    emit(state.copyWith(currentChatRoom: event.chatRoom));
  }

  void _onChatMessagesWatchStopRequested(
    ChatMessagesWatchStopRequested event,
    Emitter<ChatState> emit,
  ) {
    _messagesSubscription?.cancel();
    _messagesSubscription = null;
    _typingSubscription?.cancel();
    _typingSubscription = null;
    _currentChatRoomSubscription?.cancel();
    _currentChatRoomSubscription = null;
  }

  Future<void> _onChatMessagesUpdated(
    _ChatMessagesUpdated event,
    Emitter<ChatState> emit,
  ) async {
    final currentChatRoomId = state.currentChatRoomId;

    // Safety check: only merge messages for the current chat room
    if (currentChatRoomId == null || currentChatRoomId.isEmpty) {
      return;
    }

    // Extract failed messages from current state
    final failedMessages = state.messages
        .where((m) => m.sendStatus == MessageSendStatus.failed)
        .toList();

    // Use GetMergedMessages use case to merge all message sources
    final result = await getMergedMessages(
      GetMergedMessagesParams(
        streamMessages: event.messages,
        paginatedMessages: state.messages,
        failedMessages: failedMessages,
        chatRoomId: currentChatRoomId,
      ),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(status: ChatStatus.error, errorMessage: failure.message),
      ),
      (merged) =>
          emit(state.copyWith(status: ChatStatus.loaded, messages: merged)),
    );
  }

  void _onChatMessagesWatchError(
    _ChatMessagesWatchError event,
    Emitter<ChatState> emit,
  ) {
    emit(
      state.copyWith(
        status: ChatStatus.error,
        errorMessage: 'Connection lost. Pull to refresh.',
      ),
    );
  }

  Future<void> _onChatRoomDeleteRequested(
    ChatRoomDeleteRequested event,
    Emitter<ChatState> emit,
  ) async {
    final result = await deleteChatRoom(
      DeleteChatRoomParams(chatRoomId: event.chatRoomId),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(status: ChatStatus.error, errorMessage: failure.message),
      ),
      (_) {
        final updatedRooms = state.chatRooms
            .where((r) => r.id != event.chatRoomId)
            .toList();
        emit(
          state.copyWith(status: ChatStatus.loaded, chatRooms: updatedRooms),
        );
      },
    );
  }

  Future<void> _onChatRoomCreateRequested(
    ChatRoomCreateRequested event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(status: ChatStatus.loading));

    final result = await createChatRoom(
      CreateChatRoomParams(chatRoom: event.chatRoom),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(status: ChatStatus.error, errorMessage: failure.message),
      ),
      (chatRoom) {
        final updatedRooms = [
          chatRoom,
          ...state.chatRooms.where((r) => r.id != chatRoom.id),
        ];
        emit(
          state.copyWith(
            status: ChatStatus.loaded,
            chatRooms: updatedRooms,
            createdChatRoom: chatRoom,
          ),
        );
      },
    );
  }

  Future<void> _onMarkAsReadRequested(
    MarkAsReadRequested event,
    Emitter<ChatState> emit,
  ) async {
    final result = await markAsRead(
      MarkAsReadParams(chatRoomId: event.chatRoomId, userId: event.userId),
    );
    result.fold((failure) {
      // Non-critical: log but don't emit error state
      // debugPrint would be stripped in release builds
    }, (_) {});
  }

  Future<void> _onChatMoreMessagesLoadRequested(
    ChatMoreMessagesLoadRequested event,
    Emitter<ChatState> emit,
  ) async {
    if (state.isLoadingMore ||
        !state.hasMoreMessages ||
        state.messages.isEmpty) {
      return;
    }

    emit(state.copyWith(isLoadingMore: true));

    final oldestMessageId = state.messages.first.id;
    final result = await getMessages(
      GetMessagesParams(
        chatRoomId: event.chatRoomId,
        startAfterMessageId: oldestMessageId,
      ),
    );

    result.fold((failure) => emit(state.copyWith(isLoadingMore: false)), (
      olderMessages,
    ) {
      final allMessages = [...olderMessages, ...state.messages];
      emit(
        state.copyWith(
          messages: allMessages,
          isLoadingMore: false,
          hasMoreMessages:
              olderMessages.length >= ChatConstants.messagePaginationLimit,
        ),
      );
    });
  }

  Future<void> _onMessageEditRequested(
    MessageEditRequested event,
    Emitter<ChatState> emit,
  ) async {
    final result = await editMessage(
      EditMessageParams(
        chatRoomId: event.chatRoomId,
        messageId: event.messageId,
        newContent: event.newContent,
      ),
    );

    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) {
        // The stream update will handle refreshing
      },
    );
  }

  Future<void> _onMessageDeleteRequested(
    MessageDeleteRequested event,
    Emitter<ChatState> emit,
  ) async {
    final result = await deleteMessage(
      DeleteMessageParams(
        chatRoomId: event.chatRoomId,
        messageId: event.messageId,
      ),
    );

    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) {
        // The stream update will handle refreshing
      },
    );
  }

  Future<void> _onMessageRetryRequested(
    MessageRetryRequested event,
    Emitter<ChatState> emit,
  ) async {
    // Update message status to sending
    final retryMessage = event.message.copyWith(
      sendStatus: MessageSendStatus.sending,
    );
    final updatedMessages = state.messages
        .map((m) => m.id == event.message.id ? retryMessage : m)
        .toList();
    emit(
      state.copyWith(
        messages: updatedMessages,
        sendingStatus: SendStatus.sending,
      ),
    );

    final result = await sendMessage(SendMessageParams(message: event.message));

    result.fold(
      (failure) {
        final failedMessage = event.message.copyWith(
          sendStatus: MessageSendStatus.failed,
        );
        final msgs = state.messages
            .map((m) => m.id == event.message.id ? failedMessage : m)
            .toList();
        emit(
          state.copyWith(
            messages: msgs,
            sendingStatus: SendStatus.error,
            errorMessage: failure.message,
          ),
        );
      },
      (message) {
        // Remove the failed message; the stream will bring in the real one
        final msgs = state.messages
            .where((m) => m.id != event.message.id)
            .toList();
        emit(state.copyWith(messages: msgs, sendingStatus: SendStatus.sent));
        removeFailedMessage?.call(
          RemoveFailedMessageParams(
            chatRoomId: event.message.chatRoomId,
            messageId: event.message.id,
          ),
        );
      },
    );
  }

  Future<void> _onChatTypingStatusChangeRequested(
    ChatTypingStatusChangeRequested event,
    Emitter<ChatState> emit,
  ) async {
    await setTypingStatus(
      SetTypingStatusParams(
        chatRoomId: event.chatRoomId,
        userId: event.userId,
        isTyping: event.isTyping,
      ),
    );
  }

  void _onChatTypingWatchRequested(
    ChatTypingWatchRequested event,
    Emitter<ChatState> emit,
  ) {
    _typingSubscription?.cancel();
    _typingSubscription =
        watchTypingUsers(
          WatchTypingUsersParams(
            chatRoomId: event.chatRoomId,
            currentUserId: event.currentUserId,
          ),
        ).listen(
          (userIds) => add(_ChatTypingUsersUpdated(userIds)),
          onError: (_) {},
        );
  }

  void _onChatTypingUsersUpdated(
    _ChatTypingUsersUpdated event,
    Emitter<ChatState> emit,
  ) {
    emit(state.copyWith(typingUserIds: event.typingUserIds));
  }

  Future<void> _onMediaMessageSendRequested(
    MediaMessageSendRequested event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(uploadProgress: 0.0));

    final uploadResult = await uploadChatMedia(
      UploadChatMediaParams(
        chatRoomId: event.chatRoomId,
        filePath: event.filePath,
        fileName: event.fileName,
      ),
    );

    await uploadResult.fold(
      (failure) async {
        emit(
          state.copyWith(
            clearUploadProgress: true,
            errorMessage: failure.message,
          ),
        );
      },
      (url) async {
        emit(state.copyWith(clearUploadProgress: true));

        final message = Message(
          id: _uuid.v4(),
          senderId: event.senderId,
          senderName: event.senderName,
          content: event.fileName,
          chatRoomId: event.chatRoomId,
          timestamp: DateTime.now(),
          type: MessageType.image,
          imageUrl: url,
        );

        add(MessageSendRequested(message: message));
      },
    );
  }

  Future<void> _onMessageSearchRequested(
    MessageSearchRequested event,
    Emitter<ChatState> emit,
  ) async {
    final result = await searchMessages(
      SearchMessagesParams(messages: state.messages, query: event.query),
    );

    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (results) => emit(
        state.copyWith(searchQuery: event.query, searchResults: results),
      ),
    );
  }

  void _onMessageSearchClearRequested(
    MessageSearchClearRequested event,
    Emitter<ChatState> emit,
  ) {
    emit(state.copyWith(clearSearch: true));
  }

  void _onPresenceWatchRequested(
    PresenceWatchRequested event,
    Emitter<ChatState> emit,
  ) {
    _presenceSubscription?.cancel();
    _presenceSubscription = watchUserPresence
        ?.call(event.userIds)
        .listen((status) => add(_ChatPresenceUpdated(status)), onError: (_) {});
  }

  void _onChatPresenceUpdated(
    _ChatPresenceUpdated event,
    Emitter<ChatState> emit,
  ) {
    emit(state.copyWith(onlineStatus: event.onlineStatus));
  }

  Future<void> _onAddChatMemberRequested(
    AddChatMemberRequested event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(clearSuccess: true, isProcessingAdminAction: true));
    final result = await addChatMember?.call(
      AddChatMemberParams(chatRoomId: event.chatRoomId, userId: event.userId),
    );
    if (result == null) {
      emit(state.copyWith(isProcessingAdminAction: false));
      return;
    }
    result.fold(
      (failure) => emit(
        state.copyWith(
          errorMessage: failure.message,
          isProcessingAdminAction: false,
        ),
      ),
      (_) {
        emit(
          state.copyWith(
            successMessage: 'Member added to group',
            lastAction: ChatAction.memberAdded,
            isProcessingAdminAction: false,
          ),
        );
        add(ChatRoomsLoadRequested());
      },
    );
  }

  Future<void> _onRemoveChatMemberRequested(
    RemoveChatMemberRequested event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(clearSuccess: true, isProcessingAdminAction: true));
    final result = await removeChatMember?.call(
      RemoveChatMemberParams(
        chatRoomId: event.chatRoomId,
        userId: event.userId,
      ),
    );
    if (result == null) {
      emit(state.copyWith(isProcessingAdminAction: false));
      return;
    }
    result.fold(
      (failure) => emit(
        state.copyWith(
          errorMessage: failure.message,
          isProcessingAdminAction: false,
        ),
      ),
      (_) => emit(
        state.copyWith(
          successMessage: 'Member removed from group',
          lastAction: ChatAction.memberRemoved,
          isProcessingAdminAction: false,
        ),
      ),
    );
  }

  Future<void> _onLeaveGroupRequested(
    LeaveGroupRequested event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(clearSuccess: true, isProcessingAdminAction: true));
    final result = await leaveChatGroup?.call(
      LeaveChatGroupParams(chatRoomId: event.chatRoomId, userId: event.userId),
    );
    if (result == null) {
      emit(state.copyWith(isProcessingAdminAction: false));
      return;
    }
    result.fold(
      (failure) => emit(
        state.copyWith(
          errorMessage: failure.message,
          isProcessingAdminAction: false,
        ),
      ),
      (_) {
        final updatedRooms = state.chatRooms
            .where((r) => r.id != event.chatRoomId)
            .toList();
        emit(
          state.copyWith(
            chatRooms: updatedRooms,
            successMessage: 'You have left the group',
            lastAction: ChatAction.leftGroup,
            isProcessingAdminAction: false,
          ),
        );
      },
    );
  }

  Future<void> _onMakeAdminRequested(
    MakeAdminRequested event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(clearSuccess: true, isProcessingAdminAction: true));
    final result = await makeAdmin.call(
      MakeAdminParams(chatRoomId: event.chatRoomId, userId: event.userId),
    );
    result.fold(
      (failure) => emit(
        state.copyWith(
          errorMessage: failure.message,
          isProcessingAdminAction: false,
        ),
      ),
      (_) => emit(
        state.copyWith(
          successMessage: 'User is now an admin',
          lastAction: ChatAction.madeAdmin,
          isProcessingAdminAction: false,
        ),
      ),
    );
  }

  Future<void> _onRemoveAdminRequested(
    RemoveAdminRequested event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(clearSuccess: true, isProcessingAdminAction: true));
    final result = await removeAdmin.call(
      RemoveAdminParams(chatRoomId: event.chatRoomId, userId: event.userId),
    );
    result.fold(
      (failure) => emit(
        state.copyWith(
          errorMessage: failure.message,
          isProcessingAdminAction: false,
        ),
      ),
      (_) => emit(
        state.copyWith(
          successMessage: 'Admin role removed',
          lastAction: ChatAction.removedAdmin,
          isProcessingAdminAction: false,
        ),
      ),
    );
  }

  Future<void> _onChatRoomFetchRequested(
    ChatRoomFetchRequested event,
    Emitter<ChatState> emit,
  ) async {
    final result = await getChatRoomById(
      GetChatRoomByIdParams(chatRoomId: event.chatRoomId),
    );
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (chatRoom) => emit(state.copyWith(fetchedChatRoom: chatRoom)),
    );
  }

  @override
  Future<void> close() {
    _messagesSubscription?.cancel();
    _typingSubscription?.cancel();
    _presenceSubscription?.cancel();
    _chatRoomsSubscription?.cancel();
    _currentChatRoomSubscription?.cancel();
    return super.close();
  }
}
