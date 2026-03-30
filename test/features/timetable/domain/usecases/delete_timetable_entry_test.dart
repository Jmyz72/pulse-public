import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/failures.dart';
import 'package:pulse/features/timetable/domain/repositories/timetable_repository.dart';
import 'package:pulse/features/timetable/domain/usecases/delete_timetable_entry.dart';

class MockTimetableRepository extends Mock implements TimetableRepository {}

void main() {
  late DeleteTimetableEntry usecase;
  late MockTimetableRepository mockRepository;

  setUp(() {
    mockRepository = MockTimetableRepository();
    usecase = DeleteTimetableEntry(mockRepository);
  });

  test('should return void when repository succeeds', () async {
    when(
      () => mockRepository.deleteEntry('entry-1'),
    ).thenAnswer((_) async => const Right(null));

    final result = await usecase(
      const DeleteTimetableEntryParams(entryId: 'entry-1'),
    );

    expect(result, const Right(null));
    verify(() => mockRepository.deleteEntry('entry-1')).called(1);
  });

  test('should return repository failures unchanged', () async {
    when(
      () => mockRepository.deleteEntry('entry-1'),
    ).thenAnswer((_) async => const Left(ServerFailure(message: 'Denied')));

    final result = await usecase(
      const DeleteTimetableEntryParams(entryId: 'entry-1'),
    );

    expect(result, const Left(ServerFailure(message: 'Denied')));
  });
}
