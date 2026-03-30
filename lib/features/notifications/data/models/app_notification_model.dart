import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/notification.dart';

class AppNotificationModel extends AppNotification {
  const AppNotificationModel({
    required super.id,
    required super.userId,
    required super.title,
    required super.body,
    required super.type,
    super.relatedId,
    required super.timestamp,
    super.isRead,
    super.actionUrl,
    super.data,
  });

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    return AppNotificationModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      type: _parseNotificationType(json['type']),
      relatedId: json['relatedId'],
      timestamp: json['timestamp'] != null
          ? (json['timestamp'] is Timestamp
              ? (json['timestamp'] as Timestamp).toDate()
              : DateTime.parse(json['timestamp'].toString()))
          : DateTime.now(),
      isRead: json['isRead'] ?? false,
      actionUrl: json['actionUrl'],
      data: json['data'] != null ? Map<String, dynamic>.from(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'body': body,
      'type': type.name,
      'relatedId': relatedId,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'actionUrl': actionUrl,
      'data': data,
    };
  }

  factory AppNotificationModel.fromEntity(AppNotification notification) {
    return AppNotificationModel(
      id: notification.id,
      userId: notification.userId,
      title: notification.title,
      body: notification.body,
      type: notification.type,
      relatedId: notification.relatedId,
      timestamp: notification.timestamp,
      isRead: notification.isRead,
      actionUrl: notification.actionUrl,
      data: notification.data,
    );
  }

  static NotificationType _parseNotificationType(String? type) {
    switch (type) {
      case 'task':
        return NotificationType.task;
      case 'event':
        return NotificationType.event;
      case 'expense':
        return NotificationType.expense;
      case 'chat':
        return NotificationType.chat;
      case 'location':
        return NotificationType.location;
      case 'system':
      default:
        return NotificationType.system;
    }
  }
}
