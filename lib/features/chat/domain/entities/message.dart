import 'package:equatable/equatable.dart';

enum MessageType { text, image, file, event, expense, grocery, location, bill, paymentRequest, system }

enum MessageSendStatus { sending, sent, failed }

class Message extends Equatable {
  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final String chatRoomId;
  final DateTime timestamp;
  final MessageType type;
  final Map<String, DateTime> readBy;
  final String? imageUrl;
  final String? replyToId;
  final DateTime? editedAt;
  final bool isDeleted;
  final MessageSendStatus sendStatus;
  final Map<String, dynamic>? eventData;

  const Message({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.chatRoomId,
    required this.timestamp,
    this.type = MessageType.text,
    this.readBy = const {},
    this.imageUrl,
    this.replyToId,
    this.editedAt,
    this.isDeleted = false,
    this.sendStatus = MessageSendStatus.sent,
    this.eventData,
  });

  bool isReadBy(String userId) => readBy.containsKey(userId);

  Message copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? content,
    String? chatRoomId,
    DateTime? timestamp,
    MessageType? type,
    Map<String, DateTime>? readBy,
    String? imageUrl,
    String? replyToId,
    DateTime? editedAt,
    bool? isDeleted,
    MessageSendStatus? sendStatus,
    Map<String, dynamic>? eventData,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      content: content ?? this.content,
      chatRoomId: chatRoomId ?? this.chatRoomId,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      readBy: readBy ?? this.readBy,
      imageUrl: imageUrl ?? this.imageUrl,
      replyToId: replyToId ?? this.replyToId,
      editedAt: editedAt ?? this.editedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      sendStatus: sendStatus ?? this.sendStatus,
      eventData: eventData ?? this.eventData,
    );
  }

  @override
  List<Object?> get props => [id, senderId, senderName, content, chatRoomId, timestamp, type, readBy, imageUrl, replyToId, editedAt, isDeleted, sendStatus, eventData];
}

class ChatRoom extends Equatable {
  final String id;
  final String name;
  final List<String> members;
  final Message? lastMessage;
  final DateTime? lastMessageAt; // Timestamp for sorting by recent activity
  final DateTime createdAt;
  final bool isGroup;
  final String? imageUrl;
  final Map<String, DateTime> lastReadAt;
  final String? createdBy;
  final List<String> admins;
  final Map<String, String> memberNames;

  const ChatRoom({
    required this.id,
    required this.name,
    required this.members,
    this.lastMessage,
    this.lastMessageAt,
    required this.createdAt,
    this.isGroup = false,
    this.imageUrl,
    this.lastReadAt = const {},
    this.createdBy,
    this.admins = const [],
    this.memberNames = const {},
  });

  /// Check if a user is an admin.
  /// For backward compatibility: if admins list is empty, treat first member as admin.
  bool isAdmin(String userId) {
    if (admins.isNotEmpty) {
      return admins.contains(userId);
    }
    return members.isNotEmpty && members.first == userId;
  }

  /// Returns the display name for the given user in this chat room.
  /// For group chats, returns the room name. For 1:1 chats, returns the
  /// other user's name from [memberNames], falling back to [name].
  String displayNameFor(String currentUserId) {
    if (isGroup) return name;
    final otherUserId = members.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
    if (otherUserId.isEmpty) return name;
    return memberNames[otherUserId] ?? name;
  }

  @override
  List<Object?> get props => [id, name, members, lastMessage, lastMessageAt, createdAt, isGroup, imageUrl, lastReadAt, createdBy, admins, memberNames];
}
