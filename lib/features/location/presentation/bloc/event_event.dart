part of 'event_bloc.dart';

abstract class EventBlocEvent extends Equatable {
  const EventBlocEvent();

  @override
  List<Object?> get props => [];
}

class EventWatchRequested extends EventBlocEvent {
  final String userId;

  const EventWatchRequested({required this.userId});

  @override
  List<Object> get props => [userId];
}

class EventCreateRequested extends EventBlocEvent {
  final Event event;

  const EventCreateRequested({required this.event});

  @override
  List<Object> get props => [event];
}

class EventJoinRequested extends EventBlocEvent {
  final String eventId;
  final String userId;
  final String userName;

  const EventJoinRequested({
    required this.eventId,
    required this.userId,
    required this.userName,
  });

  @override
  List<Object> get props => [eventId, userId, userName];
}

class EventLeaveRequested extends EventBlocEvent {
  final String eventId;
  final String userId;

  const EventLeaveRequested({required this.eventId, required this.userId});

  @override
  List<Object> get props => [eventId, userId];
}

class EventDeleteRequested extends EventBlocEvent {
  final String eventId;

  const EventDeleteRequested({required this.eventId});

  @override
  List<Object> get props => [eventId];
}

class EventsUpdated extends EventBlocEvent {
  final List<Event> events;

  const EventsUpdated({required this.events});

  @override
  List<Object> get props => [events];
}
