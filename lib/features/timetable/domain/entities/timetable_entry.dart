import 'package:equatable/equatable.dart';

enum TimetableEntryType { single, series, overrideEntry }

enum TimetableRecurrenceFrequency { none, daily, weekly, monthly }

enum TimetableEditScope { thisOccurrence, wholeSeries }

class TimetableEntry extends Equatable {
  final String id;
  final String userId;
  final DateTime startAt;
  final DateTime endAt;
  final String title;
  final String? description;
  final String? color;
  final String visibility;
  final List<String> visibleTo;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final TimetableEntryType entryType;
  final String? seriesId;
  final TimetableRecurrenceFrequency recurrenceFrequency;
  final int recurrenceInterval;
  final List<int> recurrenceWeekdays;
  final DateTime? recurrenceUntil;
  final int? recurrenceCount;
  final DateTime? occurrenceDate;
  final bool isCancelled;
  final String? instanceId;
  final bool isGeneratedOccurrence;

  const TimetableEntry({
    required this.id,
    required this.userId,
    required this.startAt,
    required this.endAt,
    required this.title,
    this.description,
    this.color,
    this.visibility = 'private',
    this.visibleTo = const [],
    required this.createdAt,
    this.updatedAt,
    this.entryType = TimetableEntryType.single,
    this.seriesId,
    this.recurrenceFrequency = TimetableRecurrenceFrequency.none,
    this.recurrenceInterval = 1,
    this.recurrenceWeekdays = const [],
    this.recurrenceUntil,
    this.recurrenceCount,
    this.occurrenceDate,
    this.isCancelled = false,
    this.instanceId,
    this.isGeneratedOccurrence = false,
  });

  bool get isRecurring =>
      entryType == TimetableEntryType.series &&
      recurrenceFrequency != TimetableRecurrenceFrequency.none;

  bool get isSeriesOverride => entryType == TimetableEntryType.overrideEntry;

  bool get canEditAsSeries =>
      entryType == TimetableEntryType.series || seriesId != null;

  String get rootSeriesId =>
      entryType == TimetableEntryType.series ? id : (seriesId ?? id);

  DateTime get effectiveOccurrenceDate => DateTime(
    (occurrenceDate ?? startAt).year,
    (occurrenceDate ?? startAt).month,
    (occurrenceDate ?? startAt).day,
  );

  String get effectiveInstanceId => instanceId ?? id;

  TimetableEntry copyWith({
    String? id,
    String? userId,
    DateTime? startAt,
    DateTime? endAt,
    String? title,
    String? description,
    bool clearDescription = false,
    String? color,
    bool clearColor = false,
    String? visibility,
    List<String>? visibleTo,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearUpdatedAt = false,
    TimetableEntryType? entryType,
    String? seriesId,
    bool clearSeriesId = false,
    TimetableRecurrenceFrequency? recurrenceFrequency,
    int? recurrenceInterval,
    List<int>? recurrenceWeekdays,
    DateTime? recurrenceUntil,
    bool clearRecurrenceUntil = false,
    int? recurrenceCount,
    bool clearRecurrenceCount = false,
    DateTime? occurrenceDate,
    bool clearOccurrenceDate = false,
    bool? isCancelled,
    String? instanceId,
    bool clearInstanceId = false,
    bool? isGeneratedOccurrence,
  }) {
    return TimetableEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      title: title ?? this.title,
      description: clearDescription ? null : (description ?? this.description),
      color: clearColor ? null : (color ?? this.color),
      visibility: visibility ?? this.visibility,
      visibleTo: visibleTo ?? this.visibleTo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: clearUpdatedAt ? null : (updatedAt ?? this.updatedAt),
      entryType: entryType ?? this.entryType,
      seriesId: clearSeriesId ? null : (seriesId ?? this.seriesId),
      recurrenceFrequency: recurrenceFrequency ?? this.recurrenceFrequency,
      recurrenceInterval: recurrenceInterval ?? this.recurrenceInterval,
      recurrenceWeekdays: recurrenceWeekdays ?? this.recurrenceWeekdays,
      recurrenceUntil: clearRecurrenceUntil
          ? null
          : (recurrenceUntil ?? this.recurrenceUntil),
      recurrenceCount: clearRecurrenceCount
          ? null
          : (recurrenceCount ?? this.recurrenceCount),
      occurrenceDate: clearOccurrenceDate
          ? null
          : (occurrenceDate ?? this.occurrenceDate),
      isCancelled: isCancelled ?? this.isCancelled,
      instanceId: clearInstanceId ? null : (instanceId ?? this.instanceId),
      isGeneratedOccurrence:
          isGeneratedOccurrence ?? this.isGeneratedOccurrence,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    startAt,
    endAt,
    title,
    description,
    color,
    visibility,
    visibleTo,
    createdAt,
    updatedAt,
    entryType,
    seriesId,
    recurrenceFrequency,
    recurrenceInterval,
    recurrenceWeekdays,
    recurrenceUntil,
    recurrenceCount,
    occurrenceDate,
    isCancelled,
    instanceId,
    isGeneratedOccurrence,
  ];
}
