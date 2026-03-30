import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/failures.dart';
import 'package:pulse/features/location/domain/entities/event.dart';
import 'package:pulse/features/location/domain/repositories/event_repository.dart';
import 'package:pulse/features/location/domain/usecases/create_event.dart';

class MockEventRepository extends Mock implements EventRepository {}

void main() {
  late CreateEvent usecase;
  late MockEventRepository mockRepository;

  setUp(() {
    mockRepository = MockEventRepository();
    usecase = CreateEvent(mockRepository);
  });

  final tEvent = Event(
    id: '',
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

  final tCreatedEvent = Event(
    id: 'event-123',
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

  test('should return created Event when creation is successful', () async {
    // arrange
    when(() => mockRepository.createEvent(tEvent))
        .thenAnswer((_) async => Right(tCreatedEvent));

    // act
    final result = await usecase(CreateEventParams(event: tEvent));

    // assert
    expect(result, Right(tCreatedEvent));
    verify(() => mockRepository.createEvent(tEvent)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return ServerFailure when creation fails', () async {
    // arrange
    when(() => mockRepository.createEvent(tEvent))
        .thenAnswer((_) async => const Left(ServerFailure(message: 'Failed to create event')));

    // act
    final result = await usecase(CreateEventParams(event: tEvent));

    // assert
    expect(result, const Left(ServerFailure(message: 'Failed to create event')));
    verify(() => mockRepository.createEvent(tEvent)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return NetworkFailure when there is no internet connection', () async {
    // arrange
    when(() => mockRepository.createEvent(tEvent))
        .thenAnswer((_) async => const Left(NetworkFailure()));

    // act
    final result = await usecase(CreateEventParams(event: tEvent));

    // assert
    expect(result, const Left(NetworkFailure()));
    verify(() => mockRepository.createEvent(tEvent)).called(1);
  });

  test('CreateEventParams should have correct props', () {
    final params = CreateEventParams(event: tEvent);
    expect(params.props, [tEvent]);
  });
}
