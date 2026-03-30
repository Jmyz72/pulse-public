part of 'notification_bloc.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

class NotificationLoadRequested extends NotificationEvent {
  const NotificationLoadRequested();
}

class NotificationClearRequested extends NotificationEvent {
  const NotificationClearRequested();
}

class NotificationMarkAsReadRequested extends NotificationEvent {
  final String id;

  const NotificationMarkAsReadRequested({required this.id});

  @override
  List<Object> get props => [id];
}

class NotificationMarkAllAsReadRequested extends NotificationEvent {
  const NotificationMarkAllAsReadRequested();
}

class NotificationDeleteRequested extends NotificationEvent {
  final String id;

  const NotificationDeleteRequested({required this.id});

  @override
  List<Object> get props => [id];
}
