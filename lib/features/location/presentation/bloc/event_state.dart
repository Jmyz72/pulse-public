part of 'event_bloc.dart';

enum EventStatus { initial, loading, loaded, error }
enum EventCreateStatus { initial, creating, created, error }

class EventState extends Equatable {
  final EventStatus status;
  final EventCreateStatus createStatus;
  final List<Event> events;
  final String? errorMessage;

  const EventState({
    this.status = EventStatus.initial,
    this.createStatus = EventCreateStatus.initial,
    this.events = const [],
    this.errorMessage,
  });

  EventState copyWith({
    EventStatus? status,
    EventCreateStatus? createStatus,
    List<Event>? events,
    String? errorMessage,
  }) {
    return EventState(
      status: status ?? this.status,
      createStatus: createStatus ?? this.createStatus,
      events: events ?? this.events,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, createStatus, events, errorMessage];
}
