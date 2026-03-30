import 'package:equatable/equatable.dart';

enum NotificationType { task, event, expense, chat, location, system }

class AppNotification extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final String? relatedId;
  final DateTime timestamp;
  final bool isRead;
  final String? actionUrl;
  final Map<String, dynamic>? data;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.relatedId,
    required this.timestamp,
    this.isRead = false,
    this.actionUrl,
    this.data,
  });

  AppNotification copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    NotificationType? type,
    String? relatedId,
    DateTime? timestamp,
    bool? isRead,
    String? actionUrl,
    Map<String, dynamic>? data,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      relatedId: relatedId ?? this.relatedId,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      actionUrl: actionUrl ?? this.actionUrl,
      data: data ?? this.data,
    );
  }

  @override
  List<Object?> get props => [id, userId, title, body, type, relatedId, timestamp, isRead, actionUrl, data];
}
