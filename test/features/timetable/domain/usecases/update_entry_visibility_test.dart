import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/failures.dart';
import 'package:pulse/features/timetable/domain/repositories/timetable_repository.dart';
import 'package:pulse/features/timetable/domain/usecases/update_entry_visibility.dart';

class MockTimetableRepository extends Mock implements TimetableRepository {}

void main() {
  late UpdateEntryVisibility usecase;
  late MockTimetableRepository mockRepository;

  setUp(() {
    mockRepository = MockTimetableRepository();
    usecase = UpdateEntryVisibility(mockRepository);
  });

  const tEntryId = 'entry-1';
  const tVisibility = 'public';
  const tVisibleTo = <String>[];

  test('should return void when visibility update is successful', () async {
    // arrange
    when(
      () => mockRepository.updateVisibility(tEntryId, tVisibility, tVisibleTo),
    ).thenAnswer((_) async => const Right(null));

    // act
    final result = await usecase(
      const UpdateEntryVisibilityParams(
        entryId: tEntryId,
        visibility: tVisibility,
        visibleTo: tVisibleTo,
      ),
    );

    // assert
    expect(result, const Right(null));
    verify(
      () => mockRepository.updateVisibility(tEntryId, tVisibility, tVisibleTo),
    ).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should handle custom visibleTo list', () async {
    // arrange
    const customVisibleTo = ['user-1', 'user-2', 'user-3'];
    when(
      () =>
          mockRepository.updateVisibility(tEntryId, 'private', customVisibleTo),
    ).thenAnswer((_) async => const Right(null));

    // act
    final result = await usecase(
      const UpdateEntryVisibilityParams(
        entryId: tEntryId,
        visibility: 'private',
        visibleTo: customVisibleTo,
      ),
    );

    // assert
    expect(result, const Right(null));
    verify(
      () =>
          mockRepository.updateVisibility(tEntryId, 'private', customVisibleTo),
    ).called(1);
  });

  test('should return ServerFailure when server error occurs', () async {
    // arrange
    when(
      () => mockRepository.updateVisibility(tEntryId, tVisibility, tVisibleTo),
    ).thenAnswer(
      (_) async =>
          const Left(ServerFailure(message: 'Failed to update visibility')),
    );

    // act
    final result = await usecase(
      const UpdateEntryVisibilityParams(
        entryId: tEntryId,
        visibility: tVisibility,
        visibleTo: tVisibleTo,
      ),
    );

    // assert
    expect(
      result,
      const Left(ServerFailure(message: 'Failed to update visibility')),
    );
    verify(
      () => mockRepository.updateVisibility(tEntryId, tVisibility, tVisibleTo),
    ).called(1);
  });

  test('should return NetworkFailure when there is no internet', () async {
    // arrange
    when(
      () => mockRepository.updateVisibility(tEntryId, tVisibility, tVisibleTo),
    ).thenAnswer((_) async => const Left(NetworkFailure()));

    // act
    final result = await usecase(
      const UpdateEntryVisibilityParams(
        entryId: tEntryId,
        visibility: tVisibility,
        visibleTo: tVisibleTo,
      ),
    );

    // assert
    expect(result, const Left(NetworkFailure()));
    verify(
      () => mockRepository.updateVisibility(tEntryId, tVisibility, tVisibleTo),
    ).called(1);
  });
}
