import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/timetable/domain/entities/timetable_entry.dart';
import 'package:pulse/features/timetable/domain/usecases/expand_timetable_occurrences.dart';

void main() {
  const usecase = ExpandTimetableOccurrences();
  final rangeStart = DateTime(2026, 3, 16);
  final rangeEnd = DateTime(2026, 3, 23);

  TimetableEntry buildSeries({
    required String id,
    required DateTime startAt,
    required TimetableRecurrenceFrequency frequency,
    List<int> weekdays = const [],
    int? count,
    DateTime? until,
  }) {
    return TimetableEntry(
      id: id,
      userId: 'user-123',
      startAt: startAt,
      endAt: startAt.add(const Duration(hours: 1)),
      title: 'Recurring',
      createdAt: DateTime(2026, 3, 1),
      entryType: TimetableEntryType.series,
      recurrenceFrequency: frequency,
      recurrenceWeekdays: weekdays,
      recurrenceCount: count,
      recurrenceUntil: until,
    );
  }

  test('expands weekly recurring entries inside visible range', () {
    final result = usecase(
      ExpandTimetableOccurrencesParams(
        entries: [
          buildSeries(
            id: 'series-1',
            startAt: DateTime(2026, 3, 2, 9),
            frequency: TimetableRecurrenceFrequency.weekly,
            weekdays: const [1, 3],
          ),
        ],
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
      ),
    );

    expect(result.map((entry) => entry.startAt), [
      DateTime(2026, 3, 16, 9),
      DateTime(2026, 3, 18, 9),
    ]);
    expect(result.every((entry) => entry.isGeneratedOccurrence), isTrue);
  });

  test('applies overrides over generated occurrences', () {
    final result = usecase(
      ExpandTimetableOccurrencesParams(
        entries: [
          buildSeries(
            id: 'series-1',
            startAt: DateTime(2026, 3, 2, 9),
            frequency: TimetableRecurrenceFrequency.weekly,
            weekdays: const [1],
          ),
          TimetableEntry(
            id: 'override-1',
            userId: 'user-123',
            startAt: DateTime(2026, 3, 16, 14),
            endAt: DateTime(2026, 3, 16, 15),
            title: 'Moved occurrence',
            createdAt: DateTime(2026, 3, 10),
            entryType: TimetableEntryType.overrideEntry,
            seriesId: 'series-1',
            occurrenceDate: DateTime(2026, 3, 16),
          ),
        ],
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
      ),
    );

    expect(result, hasLength(1));
    expect(result.first.title, 'Moved occurrence');
    expect(result.first.startAt, DateTime(2026, 3, 16, 14));
  });

  test('suppresses cancelled occurrences', () {
    final result = usecase(
      ExpandTimetableOccurrencesParams(
        entries: [
          buildSeries(
            id: 'series-1',
            startAt: DateTime(2026, 3, 2, 9),
            frequency: TimetableRecurrenceFrequency.weekly,
            weekdays: const [1],
            count: 10,
          ),
          TimetableEntry(
            id: 'override-1',
            userId: 'user-123',
            startAt: DateTime(2026, 3, 16, 9),
            endAt: DateTime(2026, 3, 16, 10),
            title: 'Cancelled',
            createdAt: DateTime(2026, 3, 10),
            entryType: TimetableEntryType.overrideEntry,
            seriesId: 'series-1',
            occurrenceDate: DateTime(2026, 3, 16),
            isCancelled: true,
          ),
        ],
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
      ),
    );

    expect(result, isEmpty);
  });
}
