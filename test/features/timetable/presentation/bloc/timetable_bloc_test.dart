import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/failures.dart';
import 'package:pulse/features/timetable/domain/entities/timetable_entry.dart';
import 'package:pulse/features/timetable/domain/usecases/add_timetable_entry.dart';
import 'package:pulse/features/timetable/domain/usecases/delete_timetable_entry.dart';
import 'package:pulse/features/timetable/domain/usecases/expand_timetable_occurrences.dart';
import 'package:pulse/features/timetable/domain/usecases/get_my_timetable.dart';
import 'package:pulse/features/timetable/domain/usecases/get_shared_timetable.dart';
import 'package:pulse/features/timetable/domain/usecases/update_entry_visibility.dart';
import 'package:pulse/features/timetable/domain/usecases/update_timetable_entry.dart';
import 'package:pulse/features/timetable/presentation/bloc/timetable_bloc.dart';

class MockGetMyTimetable extends Mock implements GetMyTimetable {}

class MockAddTimetableEntry extends Mock implements AddTimetableEntry {}

class MockUpdateTimetableEntry extends Mock implements UpdateTimetableEntry {}

class MockDeleteTimetableEntry extends Mock implements DeleteTimetableEntry {}

class MockGetSharedTimetable extends Mock implements GetSharedTimetable {}

class MockUpdateEntryVisibility extends Mock implements UpdateEntryVisibility {}

void main() {
  late TimetableBloc bloc;
  late MockGetMyTimetable mockGetMyTimetable;
  late MockAddTimetableEntry mockAddTimetableEntry;
  late MockUpdateTimetableEntry mockUpdateTimetableEntry;
  late MockDeleteTimetableEntry mockDeleteTimetableEntry;
  late MockGetSharedTimetable mockGetSharedTimetable;
  late MockUpdateEntryVisibility mockUpdateEntryVisibility;
  late TimetableEntry tSingleEntry;
  late TimetableEntry tSeriesEntry;

  setUp(() {
    mockGetMyTimetable = MockGetMyTimetable();
    mockAddTimetableEntry = MockAddTimetableEntry();
    mockUpdateTimetableEntry = MockUpdateTimetableEntry();
    mockDeleteTimetableEntry = MockDeleteTimetableEntry();
    mockGetSharedTimetable = MockGetSharedTimetable();
    mockUpdateEntryVisibility = MockUpdateEntryVisibility();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    tSingleEntry = TimetableEntry(
      id: 'single-1',
      userId: 'user-123',
      startAt: DateTime(today.year, today.month, today.day, 9),
      endAt: DateTime(today.year, today.month, today.day, 10),
      title: 'Math',
      createdAt: today.subtract(const Duration(days: 10)),
    );
    tSeriesEntry = TimetableEntry(
      id: 'series-1',
      userId: 'user-123',
      startAt: DateTime(
        today.subtract(const Duration(days: 7)).year,
        today.subtract(const Duration(days: 7)).month,
        today.subtract(const Duration(days: 7)).day,
        9,
      ),
      endAt: DateTime(
        today.subtract(const Duration(days: 7)).year,
        today.subtract(const Duration(days: 7)).month,
        today.subtract(const Duration(days: 7)).day,
        10,
      ),
      title: 'Weekly Class',
      createdAt: today.subtract(const Duration(days: 14)),
      entryType: TimetableEntryType.series,
      recurrenceFrequency: TimetableRecurrenceFrequency.weekly,
      recurrenceWeekdays: [today.weekday],
    );

    bloc = TimetableBloc(
      getMyTimetable: mockGetMyTimetable,
      addTimetableEntry: mockAddTimetableEntry,
      updateTimetableEntry: mockUpdateTimetableEntry,
      deleteTimetableEntry: mockDeleteTimetableEntry,
      getSharedTimetable: mockGetSharedTimetable,
      updateEntryVisibility: mockUpdateEntryVisibility,
      expandTimetableOccurrences: const ExpandTimetableOccurrences(),
    );
  });

  tearDown(() => bloc.close());

  setUpAll(() {
    registerFallbackValue(
      GetMyTimetableParams(
        userId: 'user-123',
        rangeStart: DateTime(2026, 3, 20),
        rangeEnd: DateTime(2026, 3, 21),
      ),
    );
    registerFallbackValue(
      const DeleteTimetableEntryParams(entryId: 'single-1'),
    );
    registerFallbackValue(
      GetSharedTimetableParams(
        targetUserId: 'friend-1',
        viewerId: 'user-123',
        rangeStart: DateTime(2026, 3, 20),
        rangeEnd: DateTime(2026, 3, 21),
      ),
    );
    registerFallbackValue(
      const UpdateEntryVisibilityParams(
        entryId: 'single-1',
        visibility: 'public',
      ),
    );
  });

  test('initial state should select today', () {
    final now = DateTime.now();
    expect(bloc.state.selectedDate, DateTime(now.year, now.month, now.day));
    expect(bloc.state.viewMode, ViewMode.daily);
  });

  blocTest<TimetableBloc, TimetableState>(
    'loads personal timetable and computes visible occurrences',
    build: () {
      when(
        () => mockGetMyTimetable(any()),
      ).thenAnswer((_) async => Right([tSingleEntry]));
      return bloc;
    },
    act: (bloc) => bloc.add(const TimetableLoadRequested(userId: 'user-123')),
    expect: () => [
      isA<TimetableState>().having(
        (state) => state.status,
        'status',
        TimetableStatus.loading,
      ),
      isA<TimetableState>()
          .having((state) => state.status, 'status', TimetableStatus.loaded)
          .having((state) => state.entries.length, 'raw entries', 1)
          .having((state) => state.occurrences.length, 'occurrences', 1),
    ],
  );

  blocTest<TimetableBloc, TimetableState>(
    'adds a new personal entry optimistically and confirms on success',
    build: () {
      registerFallbackValue(AddTimetableEntryParams(entry: tSingleEntry));
      when(
        () => mockAddTimetableEntry(any()),
      ).thenAnswer((_) async => Right(tSingleEntry));
      return bloc;
    },
    act: (bloc) => bloc.add(TimetableEntryAddRequested(entry: tSingleEntry)),
    expect: () => [
      isA<TimetableState>().having(
        (state) => state.entries.length,
        'optimistic entry count',
        1,
      ),
      isA<TimetableState>()
          .having((state) => state.status, 'status', TimetableStatus.loaded)
          .having((state) => state.entries.length, 'confirmed entry count', 1),
    ],
  );

  blocTest<TimetableBloc, TimetableState>(
    'creates cancellation override when deleting one recurring occurrence',
    build: () {
      registerFallbackValue(AddTimetableEntryParams(entry: tSeriesEntry));
      when(
        () => mockGetMyTimetable(any()),
      ).thenAnswer((_) async => Right([tSeriesEntry]));
      when(() => mockAddTimetableEntry(any())).thenAnswer((invocation) async {
        final params =
            invocation.positionalArguments.first as AddTimetableEntryParams;
        return Right(params.entry.copyWith(id: 'override-1'));
      });
      return bloc;
    },
    act: (bloc) async {
      bloc.add(const TimetableLoadRequested(userId: 'user-123'));
      await Future<void>.delayed(Duration.zero);
      final visibleOccurrence = bloc.state.occurrences.single;
      bloc.add(
        TimetableOccurrenceDeleteRequested(
          entry: visibleOccurrence,
          scope: TimetableEditScope.thisOccurrence,
        ),
      );
    },
    skip: 2,
    expect: () => [
      isA<TimetableState>().having(
        (state) => state.lastOperation,
        'last operation',
        LastOperation.delete,
      ),
      isA<TimetableState>()
          .having((state) => state.status, 'status', TimetableStatus.loaded)
          .having(
            (state) => state.occurrences.isEmpty,
            'occurrences hidden',
            true,
          ),
    ],
  );

  blocTest<TimetableBloc, TimetableState>(
    're-loads timetable when selected date changes',
    build: () {
      when(
        () => mockGetMyTimetable(any()),
      ).thenAnswer((_) async => Right([tSingleEntry]));
      return bloc;
    },
    act: (bloc) async {
      bloc.add(const TimetableLoadRequested(userId: 'user-123'));
      await Future<void>.delayed(Duration.zero);
      bloc.add(
        TimetableDateSelectRequested(
          date: DateTime.now().add(const Duration(days: 1)),
        ),
      );
    },
    verify: (_) {
      verify(() => mockGetMyTimetable(any())).called(greaterThanOrEqualTo(2));
    },
  );

  blocTest<TimetableBloc, TimetableState>(
    'emits error when load fails',
    build: () {
      when(
        () => mockGetMyTimetable(any()),
      ).thenAnswer((_) async => const Left(ServerFailure(message: 'boom')));
      return bloc;
    },
    act: (bloc) => bloc.add(const TimetableLoadRequested(userId: 'user-123')),
    expect: () => [
      isA<TimetableState>().having(
        (state) => state.status,
        'status',
        TimetableStatus.loading,
      ),
      isA<TimetableState>()
          .having((state) => state.status, 'status', TimetableStatus.error)
          .having((state) => state.errorMessage, 'message', 'boom'),
    ],
  );
}
