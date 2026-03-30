import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/exceptions.dart';
import 'package:pulse/core/error/failures.dart';
import 'package:pulse/core/network/network_info.dart';
import 'package:pulse/features/timetable/data/datasources/timetable_remote_datasource.dart';
import 'package:pulse/features/timetable/data/models/timetable_entry_model.dart';
import 'package:pulse/features/timetable/data/repositories/timetable_repository_impl.dart';
import 'package:pulse/features/timetable/domain/entities/timetable_entry.dart';
import 'package:pulse/features/timetable/domain/repositories/timetable_repository.dart';

class MockTimetableRemoteDataSource extends Mock
    implements TimetableRemoteDataSource {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

void main() {
  late TimetableRepositoryImpl repository;
  late MockTimetableRemoteDataSource mockRemoteDataSource;
  late MockNetworkInfo mockNetworkInfo;

  final tRange = TimetableQueryRange(
    rangeStart: DateTime(2026, 3, 17),
    rangeEnd: DateTime(2026, 3, 24),
  );

  final tEntryModel = TimetableEntryModel(
    id: 'entry-1',
    userId: 'user-123',
    startAt: DateTime(2026, 3, 20, 9),
    endAt: DateTime(2026, 3, 20, 10),
    title: 'Math Class',
    createdAt: DateTime(2026, 3, 1),
  );

  final tEntry = TimetableEntry(
    id: 'entry-1',
    userId: 'user-123',
    startAt: DateTime(2026, 3, 20, 9),
    endAt: DateTime(2026, 3, 20, 10),
    title: 'Math Class',
    createdAt: DateTime(2026, 3, 1),
  );

  setUp(() {
    mockRemoteDataSource = MockTimetableRemoteDataSource();
    mockNetworkInfo = MockNetworkInfo();
    repository = TimetableRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      networkInfo: mockNetworkInfo,
    );
  });

  setUpAll(() {
    registerFallbackValue(tEntryModel);
  });

  test('getMyTimetable should pass through query range when online', () async {
    when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
    when(
      () => mockRemoteDataSource.getEntriesByUser(
        'user-123',
        tRange.rangeStart,
        tRange.rangeEnd,
      ),
    ).thenAnswer((_) async => [tEntryModel]);

    final result = await repository.getMyTimetable('user-123', tRange);

    expect(result, isA<Right<Failure, List<TimetableEntry>>>());
  });

  test('getMyTimetable should return network failure when offline', () async {
    when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

    final result = await repository.getMyTimetable('user-123', tRange);

    expect(result, const Left(NetworkFailure()));
    verifyNever(
      () => mockRemoteDataSource.getEntriesByUser(any(), any(), any()),
    );
  });

  test('addEntry should wrap server exceptions', () async {
    when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
    when(
      () => mockRemoteDataSource.addEntry(any()),
    ).thenThrow(const ServerException(message: 'Nope'));

    final result = await repository.addEntry(tEntry);

    expect(result, const Left(ServerFailure(message: 'Nope')));
  });

  test(
    'getSharedTimetable should pass through query range when online',
    () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(
        () => mockRemoteDataSource.getSharedEntries(
          'target-1',
          'viewer-1',
          tRange.rangeStart,
          tRange.rangeEnd,
        ),
      ).thenAnswer((_) async => [tEntryModel]);

      final result = await repository.getSharedTimetable(
        'target-1',
        'viewer-1',
        tRange,
      );

      expect(result, isA<Right<Failure, List<TimetableEntry>>>());
    },
  );
}
