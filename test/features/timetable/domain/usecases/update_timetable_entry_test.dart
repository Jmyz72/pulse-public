import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/failures.dart';
import 'package:pulse/features/timetable/domain/entities/timetable_entry.dart';
import 'package:pulse/features/timetable/domain/repositories/timetable_repository.dart';
import 'package:pulse/features/timetable/domain/usecases/update_timetable_entry.dart';

class MockTimetableRepository extends Mock implements TimetableRepository {}

void main() {
  late UpdateTimetableEntry usecase;
  late MockTimetableRepository mockRepository;

  final tEntry = TimetableEntry(
    id: 'series-1',
    userId: 'user-123',
    startAt: DateTime(2026, 3, 20, 9),
    endAt: DateTime(2026, 3, 20, 10, 30),
    title: 'Math Class',
    createdAt: DateTime(2026, 3, 1),
    entryType: TimetableEntryType.series,
    recurrenceFrequency: TimetableRecurrenceFrequency.weekly,
    recurrenceWeekdays: const [5],
  );

  setUp(() {
    mockRepository = MockTimetableRepository();
    usecase = UpdateTimetableEntry(mockRepository);
  });

  setUpAll(() {
    registerFallbackValue(tEntry);
  });

  test('should return updated entry when repository succeeds', () async {
    when(
      () => mockRepository.updateEntry(any()),
    ).thenAnswer((_) async => Right(tEntry.copyWith(title: 'Updated')));

    final result = await usecase(UpdateTimetableEntryParams(entry: tEntry));

    expect(result, Right(tEntry.copyWith(title: 'Updated')));
    verify(() => mockRepository.updateEntry(any())).called(1);
  });

  test('should return repository failures unchanged', () async {
    when(
      () => mockRepository.updateEntry(any()),
    ).thenAnswer((_) async => const Left(NetworkFailure()));

    final result = await usecase(UpdateTimetableEntryParams(entry: tEntry));

    expect(result, const Left(NetworkFailure()));
  });
}
