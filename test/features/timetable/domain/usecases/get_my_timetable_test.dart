import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/failures.dart';
import 'package:pulse/features/timetable/domain/entities/timetable_entry.dart';
import 'package:pulse/features/timetable/domain/repositories/timetable_repository.dart';
import 'package:pulse/features/timetable/domain/usecases/get_my_timetable.dart';

class MockTimetableRepository extends Mock implements TimetableRepository {}

void main() {
  late GetMyTimetable usecase;
  late MockTimetableRepository mockRepository;

  final tRangeStart = DateTime(2026, 3, 17);
  final tRangeEnd = DateTime(2026, 3, 24);
  final tEntries = [
    TimetableEntry(
      id: '1',
      userId: 'user-123',
      startAt: DateTime(2026, 3, 20, 9),
      endAt: DateTime(2026, 3, 20, 10),
      title: 'Math Class',
      createdAt: DateTime(2026, 3, 1),
    ),
  ];

  setUp(() {
    mockRepository = MockTimetableRepository();
    usecase = GetMyTimetable(mockRepository);
  });

  test('should delegate to repository with query window', () async {
    when(
      () => mockRepository.getMyTimetable(
        'user-123',
        TimetableQueryRange(
          rangeStart: DateTime(2026, 3, 17),
          rangeEnd: DateTime(2026, 3, 24),
        ),
      ),
    ).thenAnswer((_) async => Right(tEntries));

    final result = await usecase(
      GetMyTimetableParams(
        userId: 'user-123',
        rangeStart: DateTime(2026, 3, 17),
        rangeEnd: DateTime(2026, 3, 24),
      ),
    );

    expect(result, Right(tEntries));
    verify(
      () => mockRepository.getMyTimetable(
        'user-123',
        TimetableQueryRange(
          rangeStart: DateTime(2026, 3, 17),
          rangeEnd: DateTime(2026, 3, 24),
        ),
      ),
    ).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return repository failures unchanged', () async {
    when(
      () => mockRepository.getMyTimetable(
        'user-123',
        TimetableQueryRange(rangeStart: tRangeStart, rangeEnd: tRangeEnd),
      ),
    ).thenAnswer(
      (_) async => const Left(ServerFailure(message: 'Server error')),
    );

    final result = await usecase(
      GetMyTimetableParams(
        userId: 'user-123',
        rangeStart: tRangeStart,
        rangeEnd: tRangeEnd,
      ),
    );

    expect(result, const Left(ServerFailure(message: 'Server error')));
  });
}
