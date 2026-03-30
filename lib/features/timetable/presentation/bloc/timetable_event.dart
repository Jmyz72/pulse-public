part of 'timetable_bloc.dart';

abstract class TimetableEvent extends Equatable {
  const TimetableEvent();

  @override
  List<Object?> get props => [];
}

class TimetableLoadRequested extends TimetableEvent {
  final String userId;

  const TimetableLoadRequested({required this.userId});

  @override
  List<Object> get props => [userId];
}

class TimetableEntryAddRequested extends TimetableEvent {
  final TimetableEntry entry;

  const TimetableEntryAddRequested({required this.entry});

  @override
  List<Object> get props => [entry];
}

class TimetableEntryUpdateRequested extends TimetableEvent {
  final TimetableEntry entry;

  const TimetableEntryUpdateRequested({required this.entry});

  @override
  List<Object> get props => [entry];
}

class TimetableOccurrenceUpdateRequested extends TimetableEvent {
  final TimetableEntry originalEntry;
  final TimetableEntry updatedEntry;
  final TimetableEditScope scope;

  const TimetableOccurrenceUpdateRequested({
    required this.originalEntry,
    required this.updatedEntry,
    required this.scope,
  });

  @override
  List<Object> get props => [originalEntry, updatedEntry, scope];
}

class TimetableOccurrenceDeleteRequested extends TimetableEvent {
  final TimetableEntry entry;
  final TimetableEditScope scope;

  const TimetableOccurrenceDeleteRequested({
    required this.entry,
    required this.scope,
  });

  @override
  List<Object> get props => [entry, scope];
}

class TimetableDateSelectRequested extends TimetableEvent {
  final DateTime date;

  const TimetableDateSelectRequested({required this.date});

  @override
  List<Object> get props => [date];
}

class TimetableViewModeChangeRequested extends TimetableEvent {
  final ViewMode viewMode;

  const TimetableViewModeChangeRequested({required this.viewMode});

  @override
  List<Object> get props => [viewMode];
}

class TimetableVisibilityChangeRequested extends TimetableEvent {
  final String entryId;
  final String visibility;
  final List<String> visibleTo;

  const TimetableVisibilityChangeRequested({
    required this.entryId,
    required this.visibility,
    this.visibleTo = const [],
  });

  @override
  List<Object> get props => [entryId, visibility, visibleTo];
}

class SharedTimetableLoadRequested extends TimetableEvent {
  final String targetUserId;
  final String viewerId;

  const SharedTimetableLoadRequested({
    required this.targetUserId,
    required this.viewerId,
  });

  @override
  List<Object> get props => [targetUserId, viewerId];
}
