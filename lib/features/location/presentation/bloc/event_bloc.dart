import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/event.dart';
import '../../domain/usecases/create_event.dart';
import '../../domain/usecases/join_event.dart';
import '../../domain/usecases/leave_event.dart';
import '../../domain/usecases/watch_events.dart';
import '../../domain/usecases/delete_event.dart';

part 'event_event.dart';
part 'event_state.dart';

class EventBloc extends Bloc<EventBlocEvent, EventState> {
  final CreateEvent createEvent;
  final WatchEvents watchEvents;
  final JoinEvent joinEvent;
  final LeaveEvent leaveEvent;
  final DeleteEvent deleteEvent;

  StreamSubscription<List<Event>>? _eventsSubscription;

  EventBloc({
    required this.createEvent,
    required this.watchEvents,
    required this.joinEvent,
    required this.leaveEvent,
    required this.deleteEvent,
  }) : super(const EventState()) {
    on<EventWatchRequested>(_onWatchRequested);
    on<EventCreateRequested>(_onCreateRequested);
    on<EventJoinRequested>(_onJoinRequested);
    on<EventLeaveRequested>(_onLeaveRequested);
    on<EventDeleteRequested>(_onDeleteRequested);
    on<EventsUpdated>(_onEventsUpdated);
  }

  Future<void> _onWatchRequested(
    EventWatchRequested event,
    Emitter<EventState> emit,
  ) async {
    await _eventsSubscription?.cancel();
    _eventsSubscription = watchEvents(
      event.userId,
    ).listen((events) => add(EventsUpdated(events: events)));
  }

  Future<void> _onDeleteRequested(
    EventDeleteRequested event,
    Emitter<EventState> emit,
  ) async {
    final result = await deleteEvent(DeleteEventParams(eventId: event.eventId));

    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) {},
    );
  }

  Future<void> _onCreateRequested(
    EventCreateRequested event,
    Emitter<EventState> emit,
  ) async {
    emit(state.copyWith(createStatus: EventCreateStatus.creating));

    final result = await createEvent(CreateEventParams(event: event.event));

    result.fold(
      (failure) => emit(
        state.copyWith(
          createStatus: EventCreateStatus.error,
          errorMessage: failure.message,
        ),
      ),
      (_) => emit(state.copyWith(createStatus: EventCreateStatus.created)),
    );
  }

  Future<void> _onJoinRequested(
    EventJoinRequested event,
    Emitter<EventState> emit,
  ) async {
    final result = await joinEvent(
      JoinEventParams(
        eventId: event.eventId,
        userId: event.userId,
        userName: event.userName,
      ),
    );

    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) {},
    );
  }

  Future<void> _onLeaveRequested(
    EventLeaveRequested event,
    Emitter<EventState> emit,
  ) async {
    final result = await leaveEvent(
      LeaveEventParams(eventId: event.eventId, userId: event.userId),
    );

    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) {},
    );
  }

  void _onEventsUpdated(EventsUpdated event, Emitter<EventState> emit) {
    emit(state.copyWith(status: EventStatus.loaded, events: event.events));
  }

  @override
  Future<void> close() {
    _eventsSubscription?.cancel();
    return super.close();
  }
}
