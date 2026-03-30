part of 'notification_bloc.dart';

enum NotificationStatus { initial, loading, loaded, error }

class NotificationState extends Equatable {
  final NotificationStatus status;
  final List<AppNotification> notifications;
  final String? errorMessage;

  const NotificationState({
    this.status = NotificationStatus.initial,
    this.notifications = const [],
    this.errorMessage,
  });

  int get unreadCount => notifications.where((n) => !n.isRead).length;
  List<AppNotification> get unreadNotifications => notifications.where((n) => !n.isRead).toList();

  NotificationState copyWith({
    NotificationStatus? status,
    List<AppNotification>? notifications,
    String? errorMessage,
  }) {
    return NotificationState(
      status: status ?? this.status,
      notifications: notifications ?? this.notifications,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, notifications, errorMessage];
}
