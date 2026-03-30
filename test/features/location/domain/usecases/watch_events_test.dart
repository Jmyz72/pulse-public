import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/features/location/domain/entities/event.dart';
import 'package:pulse/features/location/domain/repositories/event_repository.dart';
import 'package:pulse/features/location/domain/usecases/watch_events.dart';

class MockEventRepository extends Mock implements EventRepository {}

void main() {
  late WatchEvents usecase;
  late MockEventRepository mockRepository;
  const tUserId = 'user-1';

  setUp(() {
    mockRepository = MockEventRepository();
    usecase = WatchEvents(mockRepository);
  });

  final tEvent1 = Event(
    id: 'event-1',
    title: 'Team Dinner',
    latitude: 3.1390,
    longitude: 101.6869,
    eventDate: DateTime(2024, 6, 15),
    eventTime: '7:00 PM',
    creatorId: 'user-1',
    creatorName: 'Alice',
    attendeeIds: const ['user-1'],
    attendeeNames: const ['Alice'],
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
    creatorName: 'Bob',
    attendeeIds: const ['user-2'],
    attendeeNames: const ['Bob'],
    createdAt: DateTime(2024, 6, 12),
  );

  test('should return stream of events from repository', () {
    // arrange
    final tEvents = [tEvent1, tEvent2];
    when(
      () => mockRepository.watchEvents(tUserId),
    ).thenAnswer((_) => Stream.value(tEvents));

    // act
    final result = usecase(tUserId);

    // assert
    expect(result, emits(tEvents));
    verify(() => mockRepository.watchEvents(tUserId)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return empty list stream when no events exist', () {
    // arrange
    when(
      () => mockRepository.watchEvents(tUserId),
    ).thenAnswer((_) => Stream.value(const []));

    // act
    final result = usecase(tUserId);

    // assert
    expect(result, emits(const <Event>[]));
    verify(() => mockRepository.watchEvents(tUserId)).called(1);
  });

  test('should emit multiple updates when events change', () {
    // arrange
    final firstBatch = [tEvent1];
    final secondBatch = [tEvent1, tEvent2];
    when(
      () => mockRepository.watchEvents(tUserId),
    ).thenAnswer((_) => Stream.fromIterable([firstBatch, secondBatch]));

    // act
    final result = usecase(tUserId);

    // assert
    expect(result, emitsInOrder([firstBatch, secondBatch]));
    verify(() => mockRepository.watchEvents(tUserId)).called(1);
  });
}
