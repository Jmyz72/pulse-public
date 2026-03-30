part of 'timetable_bloc.dart';

enum TimetableStatus { initial, loading, loaded, error }

enum ViewMode { weekly, daily }

enum LastOperation { none, add, update, delete, visibility, load }

class TimetableState extends Equatable {
  final TimetableStatus status;
  final List<TimetableEntry> entries;
  final List<TimetableEntry> sharedEntries;
  final List<TimetableEntry> occurrences;
  final List<TimetableEntry> sharedOccurrences;
  final DateTime selectedDate;
  final ViewMode viewMode;
  final String? errorMessage;
  final bool isViewingShared;
  final String? loadedUserId;
  final String? sharedUserId;
  final String? viewerId;
  final LastOperation lastOperation;

  const TimetableState({
    this.status = TimetableStatus.initial,
    this.entries = const [],
    this.sharedEntries = const [],
    this.occurrences = const [],
    this.sharedOccurrences = const [],
    required this.selectedDate,
    this.viewMode = ViewMode.daily,
    this.errorMessage,
    this.isViewingShared = false,
    this.loadedUserId,
    this.sharedUserId,
    this.viewerId,
    this.lastOperation = LastOperation.none,
  });

  List<TimetableEntry> get activeEntries =>
      isViewingShared ? sharedEntries : entries;

  List<TimetableEntry> get activeOccurrences =>
      isViewingShared ? sharedOccurrences : occurrences;

  DateTime get visibleRangeStart => viewMode == ViewMode.weekly
      ? startOfWeek(selectedDate)
      : startOfDay(selectedDate);

  DateTime get visibleRangeEnd => viewMode == ViewMode.weekly
      ? startOfWeek(selectedDate).add(const Duration(days: 7))
      : startOfDay(selectedDate).add(const Duration(days: 1));

  List<TimetableEntry> get selectedDateEntries {
    final filtered = activeOccurrences.where((entry) {
      return isSameDate(entry.startAt, selectedDate);
    }).toList();
    filtered.sort((left, right) => left.startAt.compareTo(right.startAt));
    return filtered;
  }

  List<DateTime> get weekDates {
    final weekStart = startOfWeek(selectedDate);
    return List.generate(7, (index) => weekStart.add(Duration(days: index)));
  }

  Map<DateTime, List<TimetableEntry>> get weekEntriesByDate {
    final map = <DateTime, List<TimetableEntry>>{
      for (final day in weekDates) day: <TimetableEntry>[],
    };

    for (final entry in activeOccurrences) {
      final key = startOfDay(entry.startAt);
      if (map.containsKey(key)) {
        map[key]!.add(entry);
      }
    }

    for (final entries in map.values) {
      entries.sort((left, right) => left.startAt.compareTo(right.startAt));
    }

    return map;
  }

  TimetableState copyWith({
    TimetableStatus? status,
    List<TimetableEntry>? entries,
    List<TimetableEntry>? sharedEntries,
    List<TimetableEntry>? occurrences,
    List<TimetableEntry>? sharedOccurrences,
    DateTime? selectedDate,
    ViewMode? viewMode,
    String? errorMessage,
    bool clearErrorMessage = false,
    bool? isViewingShared,
    String? loadedUserId,
    bool clearLoadedUserId = false,
    String? sharedUserId,
    bool clearSharedUserId = false,
    String? viewerId,
    bool clearViewerId = false,
    LastOperation? lastOperation,
  }) {
    return TimetableState(
      status: status ?? this.status,
      entries: entries ?? this.entries,
      sharedEntries: sharedEntries ?? this.sharedEntries,
      occurrences: occurrences ?? this.occurrences,
      sharedOccurrences: sharedOccurrences ?? this.sharedOccurrences,
      selectedDate: selectedDate ?? this.selectedDate,
      viewMode: viewMode ?? this.viewMode,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      isViewingShared: isViewingShared ?? this.isViewingShared,
      loadedUserId: clearLoadedUserId
          ? null
          : (loadedUserId ?? this.loadedUserId),
      sharedUserId: clearSharedUserId
          ? null
          : (sharedUserId ?? this.sharedUserId),
      viewerId: clearViewerId ? null : (viewerId ?? this.viewerId),
      lastOperation: lastOperation ?? this.lastOperation,
    );
  }

  static DateTime startOfDay(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static DateTime startOfWeek(DateTime value) {
    final normalized = startOfDay(value);
    return normalized.subtract(Duration(days: normalized.weekday - 1));
  }

  static bool isSameDate(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }

  @override
  List<Object?> get props => [
    status,
    entries,
    sharedEntries,
    occurrences,
    sharedOccurrences,
    selectedDate,
    viewMode,
    errorMessage,
    isViewingShared,
    loadedUserId,
    sharedUserId,
    viewerId,
    lastOperation,
  ];
}
