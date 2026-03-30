import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/dashboard_data.dart';

class ActivityFeedMapper {
  ActivityFeedMapper._();

  static RecentActivity? fromExpenseDoc(String id, Map<String, dynamic> data) {
    final timestamp = parseDateTime(data['date']);
    final chatRoomId = _asString(data['chatRoomId']);
    if (timestamp == null || chatRoomId == null) {
      return null;
    }

    final amount = _asNum(data['totalAmount'] ?? data['amount']);
    final actorName = _firstNonEmpty([
      data['createdByName'],
      data['ownerName'],
      data['userName'],
    ]);
    final detail = amount != null ? 'RM ${amount.toStringAsFixed(2)}' : null;

    return RecentActivity(
      id: 'expense:$id',
      sourceId: id,
      type: DashboardActivityType.expense,
      title: _firstNonEmpty([data['title']]) ?? 'Expense added',
      description: _joinParts([
        actorName != null ? '$actorName added an expense' : 'New group expense',
        detail,
      ]),
      timestamp: timestamp,
      chatRoomId: chatRoomId,
      userId: _asString(data['ownerId'] ?? data['userId']),
      userName: actorName,
    );
  }

  static RecentActivity? fromTaskDoc(String id, Map<String, dynamic> data) {
    final timestamp = parseDateTime(data['createdAt']);
    final chatRoomId = _asString(data['chatRoomId']);
    if (timestamp == null || chatRoomId == null) {
      return null;
    }

    final assignedToName = _firstNonEmpty([data['assignedToName']]);
    final description = _firstNonEmpty([
      assignedToName != null ? 'Assigned to $assignedToName' : null,
      data['description'],
      'New task in your group',
    ]);

    return RecentActivity(
      id: 'task:$id',
      sourceId: id,
      type: DashboardActivityType.task,
      title: _firstNonEmpty([data['title']]) ?? 'Task added',
      description: description!,
      timestamp: timestamp,
      chatRoomId: chatRoomId,
      userId: _asString(data['createdBy']),
      userName: _firstNonEmpty([data['createdByName']]),
    );
  }

  static RecentActivity? fromBillDoc(String id, Map<String, dynamic> data) {
    final timestamp = parseDateTime(data['createdAt']);
    final chatRoomId = _asString(data['chatRoomId']);
    if (timestamp == null || chatRoomId == null) {
      return null;
    }

    final amount = _asNum(data['amount']);
    final dueDate = parseDateTime(data['dueDate']);
    final dueText = dueDate != null
        ? 'Due ${dueDate.day}/${dueDate.month}'
        : null;

    return RecentActivity(
      id: 'bill:$id',
      sourceId: id,
      type: DashboardActivityType.bill,
      title: _firstNonEmpty([data['title']]) ?? 'Bill added',
      description: _joinParts([
        amount != null ? 'RM ${amount.toStringAsFixed(2)}' : null,
        dueText,
      ]),
      timestamp: timestamp,
      chatRoomId: chatRoomId,
      userId: _asString(data['createdBy']),
      userName: _firstNonEmpty([data['createdByName']]),
    );
  }

  static RecentActivity? fromGroceryDoc(String id, Map<String, dynamic> data) {
    final timestamp = parseDateTime(data['createdAt']);
    final chatRoomId = _asString(data['chatRoomId']);
    if (timestamp == null || chatRoomId == null) {
      return null;
    }

    final addedByName = _firstNonEmpty([data['addedByName']]);
    final quantity = (data['quantity'] as num?)?.toInt();

    return RecentActivity(
      id: 'grocery:$id',
      sourceId: id,
      type: DashboardActivityType.grocery,
      title: _firstNonEmpty([data['name']]) ?? 'Grocery item added',
      description: _joinParts([
        quantity != null && quantity > 1 ? 'Qty $quantity' : null,
        addedByName != null ? 'Added by $addedByName' : 'Added to grocery list',
      ]),
      timestamp: timestamp,
      chatRoomId: chatRoomId,
      userId: _asString(data['addedBy']),
      userName: addedByName,
    );
  }

  static RecentActivity? fromChatRoomDoc({
    required String currentUserId,
    required String roomId,
    required Map<String, dynamic> data,
  }) {
    final timestamp = parseDateTime(data['lastMessageAt']);
    if (timestamp == null) {
      return null;
    }

    final lastMessage = data['lastMessage'];
    if (lastMessage is! Map<String, dynamic>) {
      return null;
    }

    final senderName = _firstNonEmpty([lastMessage['senderName']]);
    final content = _chatPreview(lastMessage);
    final title = _chatRoomName(
      currentUserId: currentUserId,
      roomId: roomId,
      data: data,
    );

    return RecentActivity(
      id: 'chat:$roomId',
      sourceId: roomId,
      type: DashboardActivityType.chat,
      title: title,
      description: senderName != null ? '$senderName: $content' : content,
      timestamp: timestamp,
      chatRoomId: roomId,
      userId: _asString(lastMessage['senderId']),
      userName: senderName,
    );
  }

  static List<RecentActivity> mergeAndLimit(
    Iterable<List<RecentActivity>> activityLists, {
    required int limit,
  }) {
    final merged = activityLists.expand((list) => list).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return merged.take(limit).toList(growable: false);
  }

  static DateTime? parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static String _chatPreview(Map<String, dynamic> lastMessage) {
    final type = _asString(lastMessage['type']) ?? 'text';
    final content = _asString(lastMessage['content']);
    if (content != null && content.trim().isNotEmpty) {
      return content.trim();
    }

    switch (type) {
      case 'image':
        return 'Sent a photo';
      case 'file':
        return 'Sent a file';
      case 'expense':
        return 'Shared an expense';
      case 'grocery':
        return 'Updated the grocery list';
      case 'bill':
        return 'Updated a bill';
      default:
        return 'Sent a message';
    }
  }

  static String _chatRoomName({
    required String currentUserId,
    required String roomId,
    required Map<String, dynamic> data,
  }) {
    final isGroup = data['isGroup'] == true;
    final name = _asString(data['name']);
    if (isGroup && name != null && name.isNotEmpty) {
      return name;
    }

    final memberNames = data['memberNames'];
    if (memberNames is Map) {
      for (final entry in memberNames.entries) {
        if (entry.key.toString() != currentUserId &&
            entry.value.toString().trim().isNotEmpty) {
          return entry.value.toString();
        }
      }
    }

    return name ?? 'Chat $roomId';
  }

  static String _joinParts(List<String?> parts) {
    return parts
        .whereType<String>()
        .where((part) => part.isNotEmpty)
        .join(' • ');
  }

  static String? _firstNonEmpty(List<Object?> values) {
    for (final value in values) {
      final text = _asString(value);
      if (text != null && text.isNotEmpty) {
        return text;
      }
    }
    return null;
  }

  static String? _asString(Object? value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static num? _asNum(Object? value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value);
    return null;
  }
}
