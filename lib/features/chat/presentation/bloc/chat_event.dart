part of 'chat_bloc.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class ChatRoomsLoadRequested extends ChatEvent {}

class ChatRoomsWatchRequested extends ChatEvent {}

class ChatRoomsWatchStopRequested extends ChatEvent {}

class ChatClearedRequested extends ChatEvent {}

class _ChatRoomsUpdated extends ChatEvent {
  final List<ChatRoom> chatRooms;

  const _ChatRoomsUpdated(this.chatRooms);

  @override
  List<Object> get props => [chatRooms];
}

class _CurrentChatRoomUpdated extends ChatEvent {
  final ChatRoom chatRoom;

  const _CurrentChatRoomUpdated(this.chatRoom);

  @override
  List<Object> get props => [chatRoom];
}

class ChatMessagesLoadRequested extends ChatEvent {
  final String chatRoomId;

  const ChatMessagesLoadRequested({required this.chatRoomId});

  @override
  List<Object> get props => [chatRoomId];
}

class MessageSendRequested extends ChatEvent {
  final Message message;

  const MessageSendRequested({required this.message});

  @override
  List<Object> get props => [message];
}

class ChatMessagesWatchRequested extends ChatEvent {
  final String chatRoomId;

  const ChatMessagesWatchRequested({required this.chatRoomId});

  @override
  List<Object> get props => [chatRoomId];
}

class ChatMessagesWatchStopRequested extends ChatEvent {}

class _ChatMessagesUpdated extends ChatEvent {
  final List<Message> messages;

  const _ChatMessagesUpdated(this.messages);

  @override
  List<Object> get props => [messages];
}

class ChatRoomDeleteRequested extends ChatEvent {
  final String chatRoomId;

  const ChatRoomDeleteRequested({required this.chatRoomId});

  @override
  List<Object> get props => [chatRoomId];
}

class MarkAsReadRequested extends ChatEvent {
  final String chatRoomId;
  final String userId;

  const MarkAsReadRequested({required this.chatRoomId, required this.userId});

  @override
  List<Object> get props => [chatRoomId, userId];
}

class ChatRoomCreateRequested extends ChatEvent {
  final ChatRoom chatRoom;

  const ChatRoomCreateRequested({required this.chatRoom});

  @override
  List<Object> get props => [chatRoom];
}

// Pagination
class ChatMoreMessagesLoadRequested extends ChatEvent {
  final String chatRoomId;

  const ChatMoreMessagesLoadRequested({required this.chatRoomId});

  @override
  List<Object> get props => [chatRoomId];
}

// Edit / Delete
class MessageEditRequested extends ChatEvent {
  final String chatRoomId;
  final String messageId;
  final String newContent;

  const MessageEditRequested({
    required this.chatRoomId,
    required this.messageId,
    required this.newContent,
  });

  @override
  List<Object> get props => [chatRoomId, messageId, newContent];
}

class MessageDeleteRequested extends ChatEvent {
  final String chatRoomId;
  final String messageId;

  const MessageDeleteRequested({
    required this.chatRoomId,
    required this.messageId,
  });

  @override
  List<Object> get props => [chatRoomId, messageId];
}

// Offline retry
class MessageRetryRequested extends ChatEvent {
  final Message message;

  const MessageRetryRequested({required this.message});

  @override
  List<Object> get props => [message];
}

// Typing
class ChatTypingStatusChangeRequested extends ChatEvent {
  final String chatRoomId;
  final String userId;
  final bool isTyping;

  const ChatTypingStatusChangeRequested({
    required this.chatRoomId,
    required this.userId,
    required this.isTyping,
  });

  @override
  List<Object> get props => [chatRoomId, userId, isTyping];
}

class ChatTypingWatchRequested extends ChatEvent {
  final String chatRoomId;
  final String currentUserId;

  const ChatTypingWatchRequested({
    required this.chatRoomId,
    required this.currentUserId,
  });

  @override
  List<Object> get props => [chatRoomId, currentUserId];
}

class _ChatTypingUsersUpdated extends ChatEvent {
  final List<String> typingUserIds;

  const _ChatTypingUsersUpdated(this.typingUserIds);

  @override
  List<Object> get props => [typingUserIds];
}

// Media
class MediaMessageSendRequested extends ChatEvent {
  final String chatRoomId;
  final String senderId;
  final String senderName;
  final String filePath;
  final String fileName;

  const MediaMessageSendRequested({
    required this.chatRoomId,
    required this.senderId,
    required this.senderName,
    required this.filePath,
    required this.fileName,
  });

  @override
  List<Object> get props => [
    chatRoomId,
    senderId,
    senderName,
    filePath,
    fileName,
  ];
}

// Search
class MessageSearchRequested extends ChatEvent {
  final String query;

  const MessageSearchRequested({required this.query});

  @override
  List<Object> get props => [query];
}

class MessageSearchClearRequested extends ChatEvent {}

// Presence
class PresenceWatchRequested extends ChatEvent {
  final List<String> userIds;

  const PresenceWatchRequested({required this.userIds});

  @override
  List<Object> get props => [userIds];
}

// Member management
class AddChatMemberRequested extends ChatEvent {
  final String chatRoomId;
  final String userId;

  const AddChatMemberRequested({
    required this.chatRoomId,
    required this.userId,
  });

  @override
  List<Object> get props => [chatRoomId, userId];
}

class RemoveChatMemberRequested extends ChatEvent {
  final String chatRoomId;
  final String userId;

  const RemoveChatMemberRequested({
    required this.chatRoomId,
    required this.userId,
  });

  @override
  List<Object> get props => [chatRoomId, userId];
}

class LeaveGroupRequested extends ChatEvent {
  final String chatRoomId;
  final String userId;

  const LeaveGroupRequested({required this.chatRoomId, required this.userId});

  @override
  List<Object> get props => [chatRoomId, userId];
}

class MakeAdminRequested extends ChatEvent {
  final String chatRoomId;
  final String userId;

  const MakeAdminRequested({required this.chatRoomId, required this.userId});

  @override
  List<Object> get props => [chatRoomId, userId];
}

class RemoveAdminRequested extends ChatEvent {
  final String chatRoomId;
  final String userId;

  const RemoveAdminRequested({required this.chatRoomId, required this.userId});

  @override
  List<Object> get props => [chatRoomId, userId];
}

class _ChatMessagesWatchError extends ChatEvent {
  final String errorMessage;

  const _ChatMessagesWatchError(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}

class _ChatPresenceUpdated extends ChatEvent {
  final Map<String, bool> onlineStatus;

  const _ChatPresenceUpdated(this.onlineStatus);

  @override
  List<Object> get props => [onlineStatus];
}

class ChatRoomFetchRequested extends ChatEvent {
  final String chatRoomId;

  const ChatRoomFetchRequested({required this.chatRoomId});

  @override
  List<Object> get props => [chatRoomId];
}
