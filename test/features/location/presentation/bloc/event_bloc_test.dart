import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/failures.dart';
import 'package:pulse/features/location/domain/entities/event.dart';
import 'package:pulse/features/location/domain/usecases/create_event.dart';
import 'package:pulse/features/location/domain/usecases/delete_event.dart';
import 'package:pulse/features/location/domain/usecases/join_event.dart';
import 'package:pulse/features/location/domain/usecases/leave_event.dart';
import 'package:pulse/features/location/domain/usecases/watch_events.dart';
import 'package:pulse/features/location/presentation/bloc/event_bloc.dart';

class MockCreateEvent extends Mock implements CreateEvent {}

class MockWatchEvents extends Mock implements WatchEvents {}

class MockJoinEvent extends Mock implements JoinEvent {}

class MockLeaveEvent extends Mock implements LeaveEvent {}

class MockDeleteEvent extends Mock implements DeleteEvent {}

void main() {
  late EventBloc bloc;
  late MockCreateEvent mockCreateEvent;
  late MockWatchEvents mockWatchEvents;
  late MockJoinEvent mockJoinEvent;
  late MockLeaveEvent mockLeaveEvent;
  late MockDeleteEvent mockDeleteEvent;
  const tUserId = 'user-1';

  setUp(() {
    mockCreateEvent = MockCreateEvent();
    mockWatchEvents = MockWatchEvents();
    mockJoinEvent = MockJoinEvent();
    mockLeaveEvent = MockLeaveEvent();
    mockDeleteEvent = MockDeleteEvent();

    bloc = EventBloc(
      createEvent: mockCreateEvent,
      watchEvents: mockWatchEvents,
      joinEvent: mockJoinEvent,
      leaveEvent: mockLeaveEvent,
      deleteEvent: mockDeleteEvent,
    );
  });

  tearDown(() {
    bloc.close();
  });

  final tEvent = Event(
    id: 'event-1',
    title: 'Team Dinner',
    latitude: 3.1390,
    longitude: 101.6869,
    eventDate: DateTime(2024, 6, 15),
    eventTime: '7:00 PM',
    creatorId: 'user-1',
    creatorName: 'Test User',
    attendeeIds: const ['user-1'],
    attendeeNames: const ['Test User'],
    createdAt: DateTime(2024, 6, 10),
  );

  final tEvent2 = Event(
    id: 'event-2',
    title: 'Movie Night',
    latitude: 3.1400,
    longitude: 101.6900,
    eventDate: DateTime(2024, 6, 20),
    eventTime: '9:00 PM',
    creatorId: 'user-2',
    creatorName: 'Alice',
    attendeeIds: const ['user-2'],
    attendeeNames: const ['Alice'],
    createdAt: DateTime(2024, 6, 12),
  );

  setUpAll(() {
    registerFallbackValue(CreateEventParams(event: tEvent));
    registerFallbackValue(
      const JoinEventParams(
        eventId: 'event-1',
        userId: 'user-1',
        userName: 'Test User',
      ),
    );
    registerFallbackValue(
      const LeaveEventParams(eventId: 'event-1', userId: 'user-1'),
    );
  });

  group('Initial state', () {
    test('should have initial state', () {
      expect(bloc.state, const EventState());
      expect(bloc.state.status, EventStatus.initial);
      expect(bloc.state.createStatus, EventCreateStatus.initial);
      expect(bloc.state.events, const []);
      expect(bloc.state.errorMessage, null);
    });
  });

  group('EventWatchRequested', () {
    blocTest<EventBloc, EventState>(
      'emits [loaded] when stream emits events',
      build: () {
        when(
          () => mockWatchEvents(tUserId),
        ).thenAnswer((_) => Stream.value([tEvent, tEvent2]));
        return bloc;
      },
      act: (bloc) => bloc.add(const EventWatchRequested(userId: tUserId)),
      wait: const Duration(milliseconds: 100),
      expect: () => [
        EventState(status: EventStatus.loaded, events: [tEvent, tEvent2]),
      ],
      verify: (_) {
        verify(() => mockWatchEvents(tUserId)).called(1);
      },
    );

    blocTest<EventBloc, EventState>(
      'emits [loaded] with empty list when no events',
      build: () {
        when(
          () => mockWatchEvents(tUserId),
        ).thenAnswer((_) => Stream.value(const []));
        return bloc;
      },
      act: (bloc) => bloc.add(const EventWatchRequested(userId: tUserId)),
      wait: const Duration(milliseconds: 100),
      expect: () => [const EventState(status: EventStatus.loaded, events: [])],
      verify: (_) {
        verify(() => mockWatchEvents(tUserId)).called(1);
      },
    );
  });

  group('EventCreateRequested', () {
    blocTest<EventBloc, EventState>(
      'emits [creating, created] when CreateEvent succeeds',
      build: () {
        when(
          () => mockCreateEvent(any()),
        ).thenAnswer((_) async => Right(tEvent));
        return bloc;
      },
      act: (bloc) => bloc.add(EventCreateRequested(event: tEvent)),
      expect: () => [
        const EventState(createStatus: EventCreateStatus.creating),
        const EventState(createStatus: EventCreateStatus.created),
      ],
      verify: (_) {
        verify(() => mockCreateEvent(any())).called(1);
      },
    );

    blocTest<EventBloc, EventState>(
      'emits [creating, error] when CreateEvent fails',
      build: () {
        when(() => mockCreateEvent(any())).thenAnswer(
          (_) async =>
              const Left(ServerFailure(message: 'Failed to create event')),
        );
        return bloc;
      },
      act: (bloc) => bloc.add(EventCreateRequested(event: tEvent)),
      expect: () => [
        const EventState(createStatus: EventCreateStatus.creating),
        const EventState(
          createStatus: EventCreateStatus.error,
          errorMessage: 'Failed to create event',
        ),
      ],
    );
  });

  group('EventJoinRequested', () {
    blocTest<EventBloc, EventState>(
      'emits nothing when JoinEvent succeeds',
      build: () {
        when(
          () => mockJoinEvent(any()),
        ).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (bloc) => bloc.add(
        const EventJoinRequested(
          eventId: 'event-1',
          userId: 'user-1',
          userName: 'Test User',
        ),
      ),
      expect: () => const [],
      verify: (_) {
        verify(() => mockJoinEvent(any())).called(1);
      },
    );

    blocTest<EventBloc, EventState>(
      'emits error state when JoinEvent fails',
      build: () {
        when(() => mockJoinEvent(any())).thenAnswer(
          (_) async => const Left(ServerFailure(message: 'Failed to join')),
        );
        return bloc;
      },
      act: (bloc) => bloc.add(
        const EventJoinRequested(
          eventId: 'event-1',
          userId: 'user-1',
          userName: 'Test User',
        ),
      ),
      expect: () => [const EventState(errorMessage: 'Failed to join')],
    );
  });

  group('EventLeaveRequested', () {
    blocTest<EventBloc, EventState>(
      'emits nothing when LeaveEvent succeeds',
      build: () {
        when(
          () => mockLeaveEvent(any()),
        ).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (bloc) => bloc.add(
        const EventLeaveRequested(eventId: 'event-1', userId: 'user-1'),
      ),
      expect: () => const [],
      verify: (_) {
        verify(() => mockLeaveEvent(any())).called(1);
      },
    );

    blocTest<EventBloc, EventState>(
      'emits error state when LeaveEvent fails',
      build: () {
        when(() => mockLeaveEvent(any())).thenAnswer(
          (_) async => const Left(ServerFailure(message: 'Failed to leave')),
        );
        return bloc;
      },
      act: (bloc) => bloc.add(
        const EventLeaveRequested(eventId: 'event-1', userId: 'user-1'),
      ),
      expect: () => [const EventState(errorMessage: 'Failed to leave')],
    );
  });

  group('Event props', () {
    test('EventWatchRequested should have correct props', () {
      const event = EventWatchRequested(userId: tUserId);
      expect(event.props, [tUserId]);
    });

    test('EventCreateRequested should have correct props', () {
      final event = EventCreateRequested(event: tEvent);
      expect(event.props, [tEvent]);
    });

    test('EventJoinRequested should have correct props', () {
      const event = EventJoinRequested(
        eventId: 'event-1',
        userId: 'user-1',
        userName: 'Test User',
      );
      expect(event.props, ['event-1', 'user-1', 'Test User']);
    });

    test('EventLeaveRequested should have correct props', () {
      const event = EventLeaveRequested(eventId: 'event-1', userId: 'user-1');
      expect(event.props, ['event-1', 'user-1']);
    });

    test('EventsUpdated should have correct props', () {
      final event = EventsUpdated(events: [tEvent]);
      expect(event.props, [
        [tEvent],
      ]);
    });
  });
}
