import '../entities/timetable_entry.dart';

class ExpandTimetableOccurrences {
  const ExpandTimetableOccurrences();

  List<TimetableEntry> call(ExpandTimetableOccurrencesParams params) {
    final rangeStart = params.rangeStart;
    final rangeEnd = params.rangeEnd;
    final singles = <TimetableEntry>[];
    final overrides = <TimetableEntry>[];
    final seriesEntries = <TimetableEntry>[];

    for (final entry in params.entries) {
      switch (entry.entryType) {
        case TimetableEntryType.single:
          if (_isVisibleOccurrence(entry, rangeStart, rangeEnd)) {
            singles.add(_normalizePersistedEntry(entry));
          }
          break;
        case TimetableEntryType.overrideEntry:
          overrides.add(entry);
          break;
        case TimetableEntryType.series:
          seriesEntries.add(entry);
          break;
      }
    }

    final overridesByKey = <String, TimetableEntry>{};
    for (final entry in overrides) {
      final seriesId = entry.seriesId;
      final occurrenceDate = entry.occurrenceDate;
      if (seriesId != null && occurrenceDate != null) {
        overridesByKey[_overrideKey(seriesId, occurrenceDate)] = entry;
      }
    }

    final matchedOverrideIds = <String>{};
    final activeSeriesIds = seriesEntries.map((entry) => entry.id).toSet();
    final occurrences = <TimetableEntry>[...singles];

    for (final series in seriesEntries) {
      for (final occurrence in _expandSeries(series, rangeStart, rangeEnd)) {
        final key = _overrideKey(series.id, occurrence.effectiveOccurrenceDate);
        final override = overridesByKey[key];
        if (override == null) {
          occurrences.add(occurrence);
          continue;
        }

        matchedOverrideIds.add(override.id);
        if (override.isCancelled) {
          continue;
        }
        if (_isVisibleOccurrence(override, rangeStart, rangeEnd)) {
          occurrences.add(_normalizePersistedEntry(override));
        }
      }
    }

    for (final override in overrides) {
      if (matchedOverrideIds.contains(override.id) || override.isCancelled) {
        continue;
      }
      if (override.seriesId != null &&
          !activeSeriesIds.contains(override.seriesId)) {
        continue;
      }
      if (_isVisibleOccurrence(override, rangeStart, rangeEnd)) {
        occurrences.add(_normalizePersistedEntry(override));
      }
    }

    occurrences.sort((left, right) {
      final byStart = left.startAt.compareTo(right.startAt);
      if (byStart != 0) return byStart;
      return left.title.compareTo(right.title);
    });
    return occurrences;
  }

  List<TimetableEntry> _expandSeries(
    TimetableEntry series,
    DateTime rangeStart,
    DateTime rangeEnd,
  ) {
    if (!series.isRecurring) {
      return _isVisibleOccurrence(series, rangeStart, rangeEnd)
          ? [
              _normalizeGeneratedOccurrence(
                series,
                series.startAt,
                series.endAt,
              ),
            ]
          : const [];
    }

    switch (series.recurrenceFrequency) {
      case TimetableRecurrenceFrequency.daily:
        return _expandDailySeries(series, rangeStart, rangeEnd);
      case TimetableRecurrenceFrequency.weekly:
        return _expandWeeklySeries(series, rangeStart, rangeEnd);
      case TimetableRecurrenceFrequency.monthly:
        return _expandMonthlySeries(series, rangeStart, rangeEnd);
      case TimetableRecurrenceFrequency.none:
        return _isVisibleOccurrence(series, rangeStart, rangeEnd)
            ? [
                _normalizeGeneratedOccurrence(
                  series,
                  series.startAt,
                  series.endAt,
                ),
              ]
            : const [];
    }
  }

  List<TimetableEntry> _expandDailySeries(
    TimetableEntry series,
    DateTime rangeStart,
    DateTime rangeEnd,
  ) {
    final occurrences = <TimetableEntry>[];
    final duration = series.endAt.difference(series.startAt);
    var count = 0;
    var currentStart = series.startAt;

    while (!currentStart.isAfter(rangeEnd)) {
      if (_hasReachedCount(series, count) ||
          _isAfterUntil(series, currentStart)) {
        break;
      }

      final currentEnd = currentStart.add(duration);
      count++;
      if (_overlaps(currentStart, currentEnd, rangeStart, rangeEnd)) {
        occurrences.add(
          _normalizeGeneratedOccurrence(series, currentStart, currentEnd),
        );
      }

      currentStart = currentStart.add(
        Duration(days: series.recurrenceInterval),
      );
    }

    return occurrences;
  }

  List<TimetableEntry> _expandWeeklySeries(
    TimetableEntry series,
    DateTime rangeStart,
    DateTime rangeEnd,
  ) {
    final occurrences = <TimetableEntry>[];
    final duration = series.endAt.difference(series.startAt);
    final weekdays =
        (series.recurrenceWeekdays.isEmpty
                ? [series.startAt.weekday]
                : series.recurrenceWeekdays)
            .toSet()
            .toList()
          ..sort();

    final baseWeekStart = _startOfWeek(series.startAt);
    var count = 0;
    var weekOffset = 0;

    while (true) {
      final currentWeekStart = baseWeekStart.add(
        Duration(days: weekOffset * 7),
      );
      if (currentWeekStart.isAfter(rangeEnd)) {
        break;
      }

      for (final weekday in weekdays) {
        final candidateDay = currentWeekStart.add(Duration(days: weekday - 1));
        final candidateStart = DateTime(
          candidateDay.year,
          candidateDay.month,
          candidateDay.day,
          series.startAt.hour,
          series.startAt.minute,
        );

        if (candidateStart.isBefore(series.startAt)) {
          continue;
        }
        if (_hasReachedCount(series, count) ||
            _isAfterUntil(series, candidateStart)) {
          return occurrences;
        }

        final candidateEnd = candidateStart.add(duration);
        count++;
        if (_overlaps(candidateStart, candidateEnd, rangeStart, rangeEnd)) {
          occurrences.add(
            _normalizeGeneratedOccurrence(series, candidateStart, candidateEnd),
          );
        }
      }

      weekOffset += series.recurrenceInterval;
    }

    return occurrences;
  }

  List<TimetableEntry> _expandMonthlySeries(
    TimetableEntry series,
    DateTime rangeStart,
    DateTime rangeEnd,
  ) {
    final occurrences = <TimetableEntry>[];
    final duration = series.endAt.difference(series.startAt);
    var count = 0;
    var monthOffset = 0;

    while (true) {
      final targetMonth = _monthAtOffset(series.startAt, monthOffset);
      if (targetMonth.isAfter(rangeEnd)) {
        break;
      }
      final candidateStart = _dateAtMonthOffset(series.startAt, monthOffset);
      if (candidateStart != null) {
        if (candidateStart.isAfter(rangeEnd)) {
          break;
        }
        if (_hasReachedCount(series, count) ||
            _isAfterUntil(series, candidateStart)) {
          break;
        }

        final candidateEnd = candidateStart.add(duration);
        count++;
        if (_overlaps(candidateStart, candidateEnd, rangeStart, rangeEnd)) {
          occurrences.add(
            _normalizeGeneratedOccurrence(series, candidateStart, candidateEnd),
          );
        }
      }

      monthOffset += series.recurrenceInterval;
    }

    return occurrences;
  }

  TimetableEntry _normalizePersistedEntry(TimetableEntry entry) {
    return entry.copyWith(
      instanceId: entry.effectiveInstanceId,
      occurrenceDate: entry.effectiveOccurrenceDate,
      isGeneratedOccurrence: false,
    );
  }

  TimetableEntry _normalizeGeneratedOccurrence(
    TimetableEntry series,
    DateTime startAt,
    DateTime endAt,
  ) {
    final occurrenceDate = DateTime(startAt.year, startAt.month, startAt.day);
    return series.copyWith(
      startAt: startAt,
      endAt: endAt,
      occurrenceDate: occurrenceDate,
      instanceId: '${series.id}:${occurrenceDate.toIso8601String()}',
      isGeneratedOccurrence: true,
    );
  }

  bool _isVisibleOccurrence(
    TimetableEntry entry,
    DateTime rangeStart,
    DateTime rangeEnd,
  ) {
    return _overlaps(entry.startAt, entry.endAt, rangeStart, rangeEnd);
  }

  bool _overlaps(
    DateTime startAt,
    DateTime endAt,
    DateTime rangeStart,
    DateTime rangeEnd,
  ) {
    return startAt.isBefore(rangeEnd) && endAt.isAfter(rangeStart);
  }

  bool _hasReachedCount(TimetableEntry series, int count) {
    final recurrenceCount = series.recurrenceCount;
    return recurrenceCount != null && count >= recurrenceCount;
  }

  bool _isAfterUntil(TimetableEntry series, DateTime candidateStart) {
    final recurrenceUntil = series.recurrenceUntil;
    if (recurrenceUntil == null) {
      return false;
    }
    final untilDay = DateTime(
      recurrenceUntil.year,
      recurrenceUntil.month,
      recurrenceUntil.day,
      23,
      59,
      59,
      999,
    );
    return candidateStart.isAfter(untilDay);
  }

  DateTime _startOfWeek(DateTime value) {
    final dateOnly = DateTime(value.year, value.month, value.day);
    return dateOnly.subtract(Duration(days: value.weekday - 1));
  }

  DateTime? _dateAtMonthOffset(DateTime date, int monthOffset) {
    final monthIndex = date.month - 1 + monthOffset;
    final year = date.year + (monthIndex ~/ 12);
    final month = (monthIndex % 12) + 1;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    if (date.day > daysInMonth) {
      return null;
    }

    return DateTime(
      year,
      month,
      date.day,
      date.hour,
      date.minute,
      date.second,
      date.millisecond,
      date.microsecond,
    );
  }

  DateTime _monthAtOffset(DateTime date, int monthOffset) {
    final monthIndex = date.month - 1 + monthOffset;
    final year = date.year + (monthIndex ~/ 12);
    final month = (monthIndex % 12) + 1;
    return DateTime(year, month, 1);
  }

  String _overrideKey(String seriesId, DateTime occurrenceDate) {
    final normalized = DateTime(
      occurrenceDate.year,
      occurrenceDate.month,
      occurrenceDate.day,
    );
    return '$seriesId:${normalized.toIso8601String()}';
  }
}

class ExpandTimetableOccurrencesParams {
  final List<TimetableEntry> entries;
  final DateTime rangeStart;
  final DateTime rangeEnd;

  const ExpandTimetableOccurrencesParams({
    required this.entries,
    required this.rangeStart,
    required this.rangeEnd,
  });
}
