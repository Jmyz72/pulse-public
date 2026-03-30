import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/failures.dart';
import 'package:pulse/features/timetable/domain/entities/timetable_entry.dart';
import 'package:pulse/features/timetable/domain/repositories/timetable_repository.dart';
import 'package:pulse/features/timetable/domain/usecases/add_timetable_entry.dart';

class MockTimetableRepository extends Mock implements TimetableRepository {}

void main() {
  late AddTimetableEntry usecase;
  late MockTimetableRepository mockRepository;

  final tEntry = TimetableEntry(
    id: 'temp-1',
    userId: 'user-123',
    startAt: DateTime(2026, 3, 20, 9),
    endAt: DateTime(2026, 3, 20, 10, 30),
    title: 'Math Class',
    createdAt: DateTime(2026, 3, 1),
  );

  setUp(() {
    mockRepository = MockTimetableRepository();
    usecase = AddTimetableEntry(mockRepository);
  });

  setUpAll(() {
    registerFallbackValue(tEntry);
  });

  test('should return created entry when repository succeeds', () async {
    when(
      () => mockRepository.addEntry(any()),
    ).thenAnswer((_) async => Right(tEntry.copyWith(id: 'entry-1')));

    final result = await usecase(AddTimetableEntryParams(entry: tEntry));

    expect(result, Right(tEntry.copyWith(id: 'entry-1')));
    verify(() => mockRepository.addEntry(any())).called(1);
  });

  test('should return repository failure unchanged', () async {
    when(
      () => mockRepository.addEntry(any()),
    ).thenAnswer((_) async => const Left(ServerFailure(message: 'Failed')));

    final result = await usecase(AddTimetableEntryParams(entry: tEntry));

    expect(result, const Left(ServerFailure(message: 'Failed')));
  });
}
