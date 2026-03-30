import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/timetable_entry.dart';

class TimetableEntryModel extends TimetableEntry {
  const TimetableEntryModel({
    required super.id,
    required super.userId,
    required super.startAt,
    required super.endAt,
    required super.title,
    super.description,
    super.color,
    super.visibility,
    super.visibleTo,
    required super.createdAt,
    super.updatedAt,
    super.entryType,
    super.seriesId,
    super.recurrenceFrequency,
    super.recurrenceInterval,
    super.recurrenceWeekdays,
    super.recurrenceUntil,
    super.recurrenceCount,
    super.occurrenceDate,
    super.isCancelled,
  });

  factory TimetableEntryModel.fromJson(Map<String, dynamic> json) {
    return TimetableEntryModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      startAt: _parseDateTime(json['startAt']),
      endAt: _parseDateTime(json['endAt']),
      title: json['title'] ?? '',
      description: json['description'],
      color: json['color'],
      visibility: json['visibility'] ?? 'private',
      visibleTo:
          (json['visibleTo'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseNullableDateTime(json['updatedAt']),
      entryType: _parseEntryType(json['entryType']),
      seriesId: json['seriesId'] as String?,
      recurrenceFrequency: _parseFrequency(json['recurrenceFrequency']),
      recurrenceInterval: (json['recurrenceInterval'] as num?)?.toInt() ?? 1,
      recurrenceWeekdays:
          (json['recurrenceWeekdays'] as List<dynamic>?)
              ?.map((value) => (value as num).toInt())
              .toList() ??
          const [],
      recurrenceUntil: _parseNullableDateTime(json['recurrenceUntil']),
      recurrenceCount: (json['recurrenceCount'] as num?)?.toInt(),
      occurrenceDate: _parseNullableDateTime(json['occurrenceDate']),
      isCancelled: json['isCancelled'] == true,
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }

  static DateTime? _parseNullableDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.parse(value);
    return null;
  }

  static TimetableEntryType _parseEntryType(dynamic value) {
    switch (value) {
      case 'series':
        return TimetableEntryType.series;
      case 'override':
        return TimetableEntryType.overrideEntry;
      default:
        return TimetableEntryType.single;
    }
  }

  static TimetableRecurrenceFrequency _parseFrequency(dynamic value) {
    switch (value) {
      case 'daily':
        return TimetableRecurrenceFrequency.daily;
      case 'weekly':
        return TimetableRecurrenceFrequency.weekly;
      case 'monthly':
        return TimetableRecurrenceFrequency.monthly;
      default:
        return TimetableRecurrenceFrequency.none;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'startAt': Timestamp.fromDate(startAt),
      'endAt': Timestamp.fromDate(endAt),
      'title': title,
      'description': description,
      'color': color,
      'visibility': visibility,
      'visibleTo': visibleTo,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'entryType': _entryTypeToJson(entryType),
      'seriesId': seriesId,
      'recurrenceFrequency': _frequencyToJson(recurrenceFrequency),
      'recurrenceInterval': recurrenceInterval,
      'recurrenceWeekdays': recurrenceWeekdays,
      'recurrenceUntil': recurrenceUntil != null
          ? Timestamp.fromDate(recurrenceUntil!)
          : null,
      'recurrenceCount': recurrenceCount,
      'occurrenceDate': occurrenceDate != null
          ? Timestamp.fromDate(occurrenceDate!)
          : null,
      'isCancelled': isCancelled,
    };
  }

  factory TimetableEntryModel.fromEntity(TimetableEntry entry) {
    return TimetableEntryModel(
      id: entry.id,
      userId: entry.userId,
      startAt: entry.startAt,
      endAt: entry.endAt,
      title: entry.title,
      description: entry.description,
      color: entry.color,
      visibility: entry.visibility,
      visibleTo: entry.visibleTo,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
      entryType: entry.entryType,
      seriesId: entry.seriesId,
      recurrenceFrequency: entry.recurrenceFrequency,
      recurrenceInterval: entry.recurrenceInterval,
      recurrenceWeekdays: entry.recurrenceWeekdays,
      recurrenceUntil: entry.recurrenceUntil,
      recurrenceCount: entry.recurrenceCount,
      occurrenceDate: entry.occurrenceDate,
      isCancelled: entry.isCancelled,
    );
  }

  static String _entryTypeToJson(TimetableEntryType type) {
    switch (type) {
      case TimetableEntryType.series:
        return 'series';
      case TimetableEntryType.overrideEntry:
        return 'override';
      case TimetableEntryType.single:
        return 'single';
    }
  }

  static String _frequencyToJson(TimetableRecurrenceFrequency frequency) {
    switch (frequency) {
      case TimetableRecurrenceFrequency.daily:
        return 'daily';
      case TimetableRecurrenceFrequency.weekly:
        return 'weekly';
      case TimetableRecurrenceFrequency.monthly:
        return 'monthly';
      case TimetableRecurrenceFrequency.none:
        return 'none';
    }
  }
}
