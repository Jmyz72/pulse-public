import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/failures.dart';
import 'package:pulse/features/timetable/domain/entities/timetable_entry.dart';
import 'package:pulse/features/timetable/domain/repositories/timetable_repository.dart';
import 'package:pulse/features/timetable/domain/usecases/get_shared_timetable.dart';

class MockTimetableRepository extends Mock implements TimetableRepository {}

void main() {
  late GetSharedTimetable usecase;
  late MockTimetableRepository mockRepository;

  final tEntries = [
    TimetableEntry(
      id: 'series-1',
      userId: 'friend-1',
      startAt: DateTime(2026, 3, 20, 9),
      endAt: DateTime(2026, 3, 20, 10),
      title: 'Shared Lecture',
      createdAt: DateTime(2026, 3, 1),
      entryType: TimetableEntryType.series,
      recurrenceFrequency: TimetableRecurrenceFrequency.weekly,
      recurrenceWeekdays: const [5],
    ),
  ];

  setUp(() {
    mockRepository = MockTimetableRepository();
    usecase = GetSharedTimetable(mockRepository);
  });

  test('should delegate to repository with viewer and range', () async {
    when(
      () => mockRepository.getSharedTimetable(
        'friend-1',
        'viewer-1',
        TimetableQueryRange(
          rangeStart: DateTime(2026, 3, 17),
          rangeEnd: DateTime(2026, 3, 24),
        ),
      ),
    ).thenAnswer((_) async => Right(tEntries));

    final result = await usecase(
      GetSharedTimetableParams(
        targetUserId: 'friend-1',
        viewerId: 'viewer-1',
        rangeStart: DateTime(2026, 3, 17),
        rangeEnd: DateTime(2026, 3, 24),
      ),
    );

    expect(result, Right(tEntries));
  });

  test('should surface repository failures', () async {
    when(
      () => mockRepository.getSharedTimetable(
        'friend-1',
        'viewer-1',
        TimetableQueryRange(
          rangeStart: DateTime(2026, 3, 17),
          rangeEnd: DateTime(2026, 3, 24),
        ),
      ),
    ).thenAnswer((_) async => const Left(NetworkFailure()));

    final result = await usecase(
      GetSharedTimetableParams(
        targetUserId: 'friend-1',
        viewerId: 'viewer-1',
        rangeStart: DateTime(2026, 3, 17),
        rangeEnd: DateTime(2026, 3, 24),
      ),
    );

    expect(result, const Left(NetworkFailure()));
  });
}
