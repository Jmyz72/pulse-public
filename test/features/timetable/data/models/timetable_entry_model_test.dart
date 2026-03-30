import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/timetable/data/models/timetable_entry_model.dart';
import 'package:pulse/features/timetable/domain/entities/timetable_entry.dart';

void main() {
  final tStartAt = DateTime(2026, 3, 20, 9, 0);
  final tEndAt = DateTime(2026, 3, 20, 10, 30);
  final tCreatedAt = DateTime(2026, 3, 1, 8, 0);
  final tUpdatedAt = DateTime(2026, 3, 10, 8, 0);
  final tOccurrenceDate = DateTime(2026, 3, 20);

  final tModel = TimetableEntryModel(
    id: 'entry-1',
    userId: 'user-123',
    startAt: tStartAt,
    endAt: tEndAt,
    title: 'Math Class',
    description: 'Room 101',
    color: '#6366F1',
    visibility: 'friends',
    visibleTo: const ['user-456'],
    createdAt: tCreatedAt,
    updatedAt: tUpdatedAt,
    entryType: TimetableEntryType.series,
    recurrenceFrequency: TimetableRecurrenceFrequency.weekly,
    recurrenceInterval: 2,
    recurrenceWeekdays: const [1, 3],
    recurrenceUntil: DateTime(2026, 6, 1, 23, 59),
    recurrenceCount: 12,
  );

  group('TimetableEntryModel', () {
    test('should deserialize recurrence-aware entry fields', () {
      final json = {
        'id': 'override-1',
        'userId': 'user-123',
        'startAt': Timestamp.fromDate(tStartAt),
        'endAt': Timestamp.fromDate(tEndAt),
        'title': 'Edited Class',
        'description': 'Moved room',
        'color': '#0EA5E9',
        'visibility': 'private',
        'visibleTo': const <String>[],
        'createdAt': Timestamp.fromDate(tCreatedAt),
        'updatedAt': Timestamp.fromDate(tUpdatedAt),
        'entryType': 'override',
        'seriesId': 'series-1',
        'recurrenceFrequency': 'none',
        'recurrenceInterval': 1,
        'recurrenceWeekdays': const <int>[],
        'occurrenceDate': Timestamp.fromDate(tOccurrenceDate),
        'isCancelled': false,
      };

      final result = TimetableEntryModel.fromJson(json);

      expect(result.entryType, TimetableEntryType.overrideEntry);
      expect(result.seriesId, 'series-1');
      expect(result.occurrenceDate, tOccurrenceDate);
      expect(result.startAt, tStartAt);
      expect(result.endAt, tEndAt);
    });

    test('should serialize recurrence-aware entry fields', () {
      final result = tModel.toJson();

      expect(result['startAt'], isA<Timestamp>());
      expect(result['endAt'], isA<Timestamp>());
      expect(result['entryType'], 'series');
      expect(result['recurrenceFrequency'], 'weekly');
      expect(result['recurrenceInterval'], 2);
      expect(result['recurrenceWeekdays'], [1, 3]);
      expect(result['recurrenceCount'], 12);
      expect(result['recurrenceUntil'], isA<Timestamp>());
    });

    test('should create model from entity', () {
      final entity = TimetableEntry(
        id: 'entry-2',
        userId: 'user-999',
        startAt: tStartAt,
        endAt: tEndAt,
        title: 'Planning',
        createdAt: tCreatedAt,
        entryType: TimetableEntryType.single,
      );

      final result = TimetableEntryModel.fromEntity(entity);

      expect(result.id, entity.id);
      expect(result.startAt, entity.startAt);
      expect(result.endAt, entity.endAt);
      expect(result.entryType, TimetableEntryType.single);
      expect(result.recurrenceFrequency, TimetableRecurrenceFrequency.none);
    });
  });
}
