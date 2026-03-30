import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/message.dart';

class MessageModel extends Message {
  const MessageModel({
    required super.id,
    required super.senderId,
    required super.senderName,
    required super.content,
    required super.chatRoomId,
    required super.timestamp,
    super.type,
    super.readBy,
    super.imageUrl,
    super.replyToId,
    super.editedAt,
    super.isDeleted,
    super.sendStatus,
    super.eventData,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    // Parse readBy map
    final Map<String, DateTime> readByMap = {};
    if (json['readBy'] != null && json['readBy'] is Map) {
      final raw = json['readBy'] as Map;
      for (final entry in raw.entries) {
        final key = entry.key.toString();
        if (entry.value is Timestamp) {
          readByMap[key] = (entry.value as Timestamp).toDate();
        } else if (entry.value is String) {
          readByMap[key] = DateTime.parse(entry.value);
        }
      }
    }

    return MessageModel(
      id: json['id'] ?? '',
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? '',
      content: json['content'] ?? '',
      chatRoomId: json['chatRoomId'] ?? '',
      timestamp: json['timestamp'] != null
          ? (json['timestamp'] is Timestamp
              ? (json['timestamp'] as Timestamp).toDate()
              : DateTime.parse(json['timestamp']))
          : DateTime.now(),
      type: MessageType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => MessageType.text,
      ),
      readBy: readByMap,
      imageUrl: json['imageUrl'],
      replyToId: json['replyToId'],
      editedAt: json['editedAt'] != null
          ? (json['editedAt'] is Timestamp
              ? (json['editedAt'] as Timestamp).toDate()
              : DateTime.parse(json['editedAt']))
          : null,
      isDeleted: json['isDeleted'] ?? false,
      sendStatus: MessageSendStatus.values.firstWhere(
        (s) => s.name == json['sendStatus'],
        orElse: () => MessageSendStatus.sent,
      ),
      eventData: json['eventData'] != null
          ? Map<String, dynamic>.from(json['eventData'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'chatRoomId': chatRoomId,
      'timestamp': timestamp.toIso8601String(),
      'type': type.name,
      'readBy': readBy.map((key, value) => MapEntry(key, value.toIso8601String())),
      'imageUrl': imageUrl,
      'replyToId': replyToId,
      'isDeleted': isDeleted,
      'sendStatus': sendStatus.name,
    };
    if (editedAt != null) {
      map['editedAt'] = editedAt!.toIso8601String();
    }
    if (eventData != null) {
      map['eventData'] = eventData;
    }
    return map;
  }

  factory MessageModel.fromEntity(Message message) {
    return MessageModel(
      id: message.id,
      senderId: message.senderId,
      senderName: message.senderName,
      content: message.content,
      chatRoomId: message.chatRoomId,
      timestamp: message.timestamp,
      type: message.type,
      readBy: message.readBy,
      imageUrl: message.imageUrl,
      replyToId: message.replyToId,
      editedAt: message.editedAt,
      isDeleted: message.isDeleted,
      sendStatus: message.sendStatus,
      eventData: message.eventData,
    );
  }
}

class ChatRoomModel extends ChatRoom {
  const ChatRoomModel({
    required super.id,
    required super.name,
    required super.members,
    super.lastMessage,
    super.lastMessageAt,
    required super.createdAt,
    super.isGroup,
    super.imageUrl,
    super.lastReadAt,
    super.createdBy,
    super.admins,
    super.memberNames,
  });

  factory ChatRoomModel.fromJson(Map<String, dynamic> json) {
    final Map<String, DateTime> lastReadAtMap = {};
    if (json['lastReadAt'] != null && json['lastReadAt'] is Map) {
      final raw = json['lastReadAt'] as Map;
      for (final entry in raw.entries) {
        final key = entry.key.toString();
        if (entry.value is Timestamp) {
          lastReadAtMap[key] = (entry.value as Timestamp).toDate();
        } else if (entry.value is String) {
          lastReadAtMap[key] = DateTime.parse(entry.value);
        }
      }
    }

    return ChatRoomModel(
      id: json['id'] as String? ?? '',
      name: json['name'] ?? '',
      members: List<String>.from(json['members'] ?? []),
      lastMessage: json['lastMessage'] != null
          ? MessageModel.fromJson(json['lastMessage'])
          : null,
      lastMessageAt: json['lastMessageAt'] != null
          ? (json['lastMessageAt'] is Timestamp
              ? (json['lastMessageAt'] as Timestamp).toDate()
              : DateTime.parse(json['lastMessageAt']))
          : null,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] is Timestamp
              ? (json['createdAt'] as Timestamp).toDate()
              : DateTime.parse(json['createdAt']))
          : DateTime.now(),
      isGroup: json['isGroup'] ?? false,
      imageUrl: json['imageUrl'],
      lastReadAt: lastReadAtMap,
      createdBy: json['createdBy'],
      admins: List<String>.from(json['admins'] ?? []),
      memberNames: json['memberNames'] != null
          ? Map<String, String>.from(json['memberNames'])
          : const {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // NOTE: Don't include 'id' here - it should come from Firestore doc.id
      // Including it causes the empty string to override the real doc.id when fetching
      'name': name,
      'members': members,
      'lastMessage': lastMessage != null
          ? MessageModel.fromEntity(lastMessage!).toJson()
          : null,
      'lastMessageAt': lastMessageAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'isGroup': isGroup,
      'imageUrl': imageUrl,
      'lastReadAt': lastReadAt.map((key, value) => MapEntry(key, value.toIso8601String())),
      'createdBy': createdBy,
      'admins': admins,
      'memberNames': memberNames,
    };
  }
}
