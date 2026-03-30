import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/exceptions.dart';
import 'package:pulse/core/error/failures.dart';
import 'package:pulse/core/network/network_info.dart';
import 'package:pulse/features/location/data/datasources/event_remote_datasource.dart';
import 'package:pulse/features/location/data/models/event_model.dart';
import 'package:pulse/features/location/data/repositories/event_repository_impl.dart';
import 'package:pulse/features/location/domain/entities/event.dart';

class MockEventRemoteDataSource extends Mock implements EventRemoteDataSource {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

void main() {
  late EventRepositoryImpl repository;
  late MockEventRemoteDataSource mockRemoteDataSource;
  late MockNetworkInfo mockNetworkInfo;

  const tEventId = 'event-123';
  const tUserId = 'user-1';
  const tUserName = 'Alice';

  final tEvent = Event(
    id: '',
    title: 'Team Dinner',
    latitude: 3.1390,
    longitude: 101.6869,
    eventDate: DateTime(2024, 6, 15),
    eventTime: '7:00 PM',
    creatorId: tUserId,
    creatorName: tUserName,
    attendeeIds: const [tUserId],
    attendeeNames: const [tUserName],
    createdAt: DateTime(2024, 6, 10),
  );

  final tCreatedEventModel = EventModel(
    id: tEventId,
    title: 'Team Dinner',
    latitude: 3.1390,
    longitude: 101.6869,
    eventDate: DateTime(2024, 6, 15),
    eventTime: '7:00 PM',
    creatorId: tUserId,
    creatorName: tUserName,
    attendeeIds: const [tUserId],
    attendeeNames: const [tUserName],
    createdAt: DateTime(2024, 6, 10),
  );

  setUpAll(() {
    registerFallbackValue(EventModel.fromEntity(tEvent));
  });

  setUp(() {
    mockRemoteDataSource = MockEventRemoteDataSource();
    mockNetworkInfo = MockNetworkInfo();
    repository = EventRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      networkInfo: mockNetworkInfo,
    );
  });

  group('createEvent', () {
    test('returns NetworkFailure when device is offline', () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

      final result = await repository.createEvent(tEvent);

      expect(result, const Left(NetworkFailure()));
      verifyNever(() => mockRemoteDataSource.createEvent(any()));
    });

    test('returns created event when online and call succeeds', () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(
        () => mockRemoteDataSource.createEvent(any()),
      ).thenAnswer((_) async => tCreatedEventModel);

      final result = await repository.createEvent(tEvent);

      expect(result, Right(tCreatedEventModel));
      verify(() => mockRemoteDataSource.createEvent(any())).called(1);
    });

    test('returns ServerFailure when remote throws', () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(
        () => mockRemoteDataSource.createEvent(any()),
      ).thenThrow(const ServerException(message: 'create failed'));

      final result = await repository.createEvent(tEvent);

      expect(result, const Left(ServerFailure(message: 'create failed')));
    });
  });

  group('joinEvent', () {
    test('returns NetworkFailure when device is offline', () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

      final result = await repository.joinEvent(tEventId, tUserId, tUserName);

      expect(result, const Left(NetworkFailure()));
      verifyNever(() => mockRemoteDataSource.joinEvent(any(), any(), any()));
    });

    test('returns Right(null) when online and call succeeds', () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(
        () => mockRemoteDataSource.joinEvent(tEventId, tUserId, tUserName),
      ).thenAnswer((_) async {});

      final result = await repository.joinEvent(tEventId, tUserId, tUserName);

      expect(result, const Right(null));
      verify(
        () => mockRemoteDataSource.joinEvent(tEventId, tUserId, tUserName),
      ).called(1);
    });

    test('returns ServerFailure when remote throws', () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(
        () => mockRemoteDataSource.joinEvent(tEventId, tUserId, tUserName),
      ).thenThrow(const ServerException(message: 'join failed'));

      final result = await repository.joinEvent(tEventId, tUserId, tUserName);

      expect(result, const Left(ServerFailure(message: 'join failed')));
    });
  });

  group('watchEvents', () {
    test('forwards userId to remote data source', () async {
      final stream = Stream.value([tCreatedEventModel]);
      when(
        () => mockRemoteDataSource.watchEvents(tUserId),
      ).thenAnswer((_) => stream);

      final result = repository.watchEvents(tUserId);

      expect(result, emits([tCreatedEventModel]));
      verify(() => mockRemoteDataSource.watchEvents(tUserId)).called(1);
      verifyNoMoreInteractions(mockRemoteDataSource);
    });
  });

  group('leaveEvent', () {
    test('returns NetworkFailure when device is offline', () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

      final result = await repository.leaveEvent(tEventId, tUserId);

      expect(result, const Left(NetworkFailure()));
      verifyNever(() => mockRemoteDataSource.leaveEvent(any(), any()));
    });

    test('returns Right(null) when online and call succeeds', () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(
        () => mockRemoteDataSource.leaveEvent(tEventId, tUserId),
      ).thenAnswer((_) async {});

      final result = await repository.leaveEvent(tEventId, tUserId);

      expect(result, const Right(null));
      verify(
        () => mockRemoteDataSource.leaveEvent(tEventId, tUserId),
      ).called(1);
    });

    test('returns ServerFailure when remote throws', () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(
        () => mockRemoteDataSource.leaveEvent(tEventId, tUserId),
      ).thenThrow(const ServerException(message: 'leave failed'));

      final result = await repository.leaveEvent(tEventId, tUserId);

      expect(result, const Left(ServerFailure(message: 'leave failed')));
    });
  });
}
