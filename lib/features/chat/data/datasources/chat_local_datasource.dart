import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/message.dart';
import '../../domain/repositories/failed_message_storage.dart';

abstract class ChatLocalDataSource implements FailedMessageStorage {
  @override
  Future<void> saveFailedMessage(Message message);
  @override
  Future<List<Message>> getFailedMessages(String chatRoomId);
  @override
  Future<void> removeFailedMessage(String chatRoomId, String messageId);
}

class ChatLocalDataSourceImpl implements ChatLocalDataSource {
  final SharedPreferences sharedPreferences;

  ChatLocalDataSourceImpl({required this.sharedPreferences});

  String _key(String chatRoomId) => 'failed_messages_$chatRoomId';

  @override
  Future<void> saveFailedMessage(Message message) async {
    final key = _key(message.chatRoomId);
    final existing = sharedPreferences.getStringList(key) ?? [];
    existing.add(jsonEncode(_messageToJson(message)));
    await sharedPreferences.setStringList(key, existing);
  }

  @override
  Future<List<Message>> getFailedMessages(String chatRoomId) async {
    final key = _key(chatRoomId);
    final existing = sharedPreferences.getStringList(key) ?? [];
    return existing.map((e) => _messageFromJson(jsonDecode(e) as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> removeFailedMessage(String chatRoomId, String messageId) async {
    final key = _key(chatRoomId);
    final existing = sharedPreferences.getStringList(key) ?? [];
    final filtered = existing.where((e) {
      final map = jsonDecode(e) as Map<String, dynamic>;
      return map['id'] != messageId;
    }).toList();
    await sharedPreferences.setStringList(key, filtered);
  }

  Map<String, dynamic> _messageToJson(Message m) => {
        'id': m.id,
        'senderId': m.senderId,
        'senderName': m.senderName,
        'content': m.content,
        'chatRoomId': m.chatRoomId,
        'timestamp': m.timestamp.toIso8601String(),
        'type': m.type.name,
        'imageUrl': m.imageUrl,
        'replyToId': m.replyToId,
        'editedAt': m.editedAt?.toIso8601String(),
        'readBy': m.readBy.map((k, v) => MapEntry(k, v.toIso8601String())),
      };

  Message _messageFromJson(Map<String, dynamic> json) {
    final Map<String, DateTime> readByMap = {};
    if (json['readBy'] != null && json['readBy'] is Map) {
      final raw = json['readBy'] as Map;
      for (final entry in raw.entries) {
        readByMap[entry.key.toString()] = DateTime.parse(entry.value as String);
      }
    }

    return Message(
      id: json['id'] as String,
      senderId: json['senderId'] as String,
      senderName: json['senderName'] as String,
      content: json['content'] as String,
      chatRoomId: json['chatRoomId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      type: MessageType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => MessageType.text,
      ),
      imageUrl: json['imageUrl'] as String?,
      replyToId: json['replyToId'] as String?,
      editedAt: json['editedAt'] != null
          ? DateTime.parse(json['editedAt'] as String)
          : null,
      readBy: readByMap,
      sendStatus: MessageSendStatus.failed,
    );
  }
}
