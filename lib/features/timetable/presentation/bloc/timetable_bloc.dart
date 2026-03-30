import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/bloc_event_transformers.dart';
import '../../domain/entities/timetable_entry.dart';
import '../../domain/usecases/add_timetable_entry.dart';
import '../../domain/usecases/delete_timetable_entry.dart';
import '../../domain/usecases/expand_timetable_occurrences.dart';
import '../../domain/usecases/get_my_timetable.dart';
import '../../domain/usecases/get_shared_timetable.dart';
import '../../domain/usecases/update_entry_visibility.dart';
import '../../domain/usecases/update_timetable_entry.dart';

part 'timetable_event.dart';
part 'timetable_state.dart';

class TimetableBloc extends Bloc<TimetableEvent, TimetableState> {
  final GetMyTimetable getMyTimetable;
  final AddTimetableEntry addTimetableEntry;
  final UpdateTimetableEntry updateTimetableEntry;
  final DeleteTimetableEntry deleteTimetableEntry;
  final GetSharedTimetable getSharedTimetable;
  final UpdateEntryVisibility updateEntryVisibility;
  final ExpandTimetableOccurrences expandTimetableOccurrences;

  TimetableBloc({
    required this.getMyTimetable,
    required this.addTimetableEntry,
    required this.updateTimetableEntry,
    required this.deleteTimetableEntry,
    required this.getSharedTimetable,
    required this.updateEntryVisibility,
    required this.expandTimetableOccurrences,
  }) : super(
         TimetableState(
           selectedDate: TimetableState.startOfDay(DateTime.now()),
         ),
       ) {
    on<TimetableLoadRequested>(_onLoadRequested);
    on<TimetableEntryAddRequested>(
      _onEntryAddRequested,
      transformer: throttle(const Duration(milliseconds: 500)),
    );
    on<TimetableEntryUpdateRequested>(
      _onEntryUpdateRequested,
      transformer: throttle(const Duration(milliseconds: 500)),
    );
    on<TimetableOccurrenceUpdateRequested>(
      _onOccurrenceUpdateRequested,
      transformer: throttle(const Duration(milliseconds: 500)),
    );
    on<TimetableOccurrenceDeleteRequested>(
      _onOccurrenceDeleteRequested,
      transformer: throttle(const Duration(milliseconds: 500)),
    );
    on<TimetableDateSelectRequested>(_onDateSelectRequested);
    on<TimetableViewModeChangeRequested>(_onViewModeChangeRequested);
    on<TimetableVisibilityChangeRequested>(
      _onVisibilityChangeRequested,
      transformer: throttle(const Duration(milliseconds: 500)),
    );
    on<SharedTimetableLoadRequested>(_onSharedTimetableLoadRequested);
  }

  Future<void> _onLoadRequested(
    TimetableLoadRequested event,
    Emitter<TimetableState> emit,
  ) async {
    emit(
      state.copyWith(
        status: TimetableStatus.loading,
        clearErrorMessage: true,
        isViewingShared: false,
        loadedUserId: event.userId,
        sharedUserId: null,
        viewerId: null,
      ),
    );

    await _reloadActiveTimetable(emit);
  }

  Future<void> _onSharedTimetableLoadRequested(
    SharedTimetableLoadRequested event,
    Emitter<TimetableState> emit,
  ) async {
    emit(
      state.copyWith(
        status: TimetableStatus.loading,
        clearErrorMessage: true,
        isViewingShared: true,
        loadedUserId: event.targetUserId,
        sharedUserId: event.targetUserId,
        viewerId: event.viewerId,
      ),
    );

    await _reloadActiveTimetable(emit);
  }

  Future<void> _onEntryAddRequested(
    TimetableEntryAddRequested event,
    Emitter<TimetableState> emit,
  ) async {
    final backupEntries = state.entries;
    final optimisticEntries = [...state.entries, event.entry];
    emit(
      _buildStateFromEntries(
        state.copyWith(lastOperation: LastOperation.add),
        entries: optimisticEntries,
      ),
    );

    final result = await addTimetableEntry(
      AddTimetableEntryParams(entry: event.entry),
    );

    result.fold(
      (failure) => emit(
        _buildStateFromEntries(
          state.copyWith(
            status: TimetableStatus.error,
            errorMessage: failure.message,
            lastOperation: LastOperation.add,
          ),
          entries: backupEntries,
        ),
      ),
      (entry) {
        final confirmedEntries =
            state.entries.where((e) => e.id != event.entry.id).toList()
              ..add(entry);
        emit(
          _buildStateFromEntries(
            state.copyWith(
              status: TimetableStatus.loaded,
              lastOperation: LastOperation.add,
            ),
            entries: confirmedEntries,
          ),
        );
      },
    );
  }

  Future<void> _onEntryUpdateRequested(
    TimetableEntryUpdateRequested event,
    Emitter<TimetableState> emit,
  ) async {
    final backupEntries = state.entries;
    final optimisticEntries = state.entries.map((entry) {
      return entry.id == event.entry.id ? event.entry : entry;
    }).toList();

    emit(
      _buildStateFromEntries(
        state.copyWith(lastOperation: LastOperation.update),
        entries: optimisticEntries,
      ),
    );

    final result = await updateTimetableEntry(
      UpdateTimetableEntryParams(entry: event.entry),
    );

    result.fold(
      (failure) => emit(
        _buildStateFromEntries(
          state.copyWith(
            status: TimetableStatus.error,
            errorMessage: failure.message,
            lastOperation: LastOperation.update,
          ),
          entries: backupEntries,
        ),
      ),
      (entry) {
        final confirmedEntries = state.entries.map((existing) {
          return existing.id == entry.id ? entry : existing;
        }).toList();
        emit(
          _buildStateFromEntries(
            state.copyWith(
              status: TimetableStatus.loaded,
              lastOperation: LastOperation.update,
            ),
            entries: confirmedEntries,
          ),
        );
      },
    );
  }

  Future<void> _onOccurrenceUpdateRequested(
    TimetableOccurrenceUpdateRequested event,
    Emitter<TimetableState> emit,
  ) async {
    if (event.scope == TimetableEditScope.wholeSeries ||
        !event.originalEntry.canEditAsSeries) {
      add(TimetableEntryUpdateRequested(entry: event.updatedEntry));
      return;
    }

    final existingOverride = _findOverride(
      state.entries,
      seriesId: event.originalEntry.rootSeriesId,
      occurrenceDate: event.originalEntry.effectiveOccurrenceDate,
    );
    final overrideEntry = _buildOverrideEntry(
      originalEntry: event.originalEntry,
      updatedEntry: event.updatedEntry,
      existingOverride: existingOverride,
      isCancelled: false,
    );

    final backupEntries = state.entries;
    final optimisticEntries = [
      for (final entry in state.entries)
        if (entry.id != existingOverride?.id) entry,
      overrideEntry,
    ];

    emit(
      _buildStateFromEntries(
        state.copyWith(lastOperation: LastOperation.update),
        entries: optimisticEntries,
      ),
    );

    final result = existingOverride == null
        ? await addTimetableEntry(AddTimetableEntryParams(entry: overrideEntry))
        : await updateTimetableEntry(
            UpdateTimetableEntryParams(entry: overrideEntry),
          );

    result.fold(
      (failure) => emit(
        _buildStateFromEntries(
          state.copyWith(
            status: TimetableStatus.error,
            errorMessage: failure.message,
            lastOperation: LastOperation.update,
          ),
          entries: backupEntries,
        ),
      ),
      (savedEntry) {
        final confirmedEntries = [
          for (final entry in state.entries)
            if (entry.id != overrideEntry.id) entry,
          savedEntry,
        ];
        emit(
          _buildStateFromEntries(
            state.copyWith(
              status: TimetableStatus.loaded,
              lastOperation: LastOperation.update,
            ),
            entries: confirmedEntries,
          ),
        );
      },
    );
  }

  Future<void> _onOccurrenceDeleteRequested(
    TimetableOccurrenceDeleteRequested event,
    Emitter<TimetableState> emit,
  ) async {
    if (event.scope == TimetableEditScope.wholeSeries ||
        !event.entry.canEditAsSeries) {
      await _deletePersistedEntry(event.entry.id, emit);
      return;
    }

    final existingOverride = _findOverride(
      state.entries,
      seriesId: event.entry.rootSeriesId,
      occurrenceDate: event.entry.effectiveOccurrenceDate,
    );
    final cancellationEntry = _buildOverrideEntry(
      originalEntry: event.entry,
      updatedEntry: event.entry,
      existingOverride: existingOverride,
      isCancelled: true,
    );

    final backupEntries = state.entries;
    final optimisticEntries = [
      for (final entry in state.entries)
        if (entry.id != existingOverride?.id) entry,
      cancellationEntry,
    ];

    emit(
      _buildStateFromEntries(
        state.copyWith(lastOperation: LastOperation.delete),
        entries: optimisticEntries,
      ),
    );

    final result = existingOverride == null
        ? await addTimetableEntry(
            AddTimetableEntryParams(entry: cancellationEntry),
          )
        : await updateTimetableEntry(
            UpdateTimetableEntryParams(entry: cancellationEntry),
          );

    result.fold(
      (failure) => emit(
        _buildStateFromEntries(
          state.copyWith(
            status: TimetableStatus.error,
            errorMessage: failure.message,
            lastOperation: LastOperation.delete,
          ),
          entries: backupEntries,
        ),
      ),
      (savedEntry) {
        final confirmedEntries = [
          for (final entry in state.entries)
            if (entry.id != cancellationEntry.id) entry,
          savedEntry,
        ];
        emit(
          _buildStateFromEntries(
            state.copyWith(
              status: TimetableStatus.loaded,
              lastOperation: LastOperation.delete,
            ),
            entries: confirmedEntries,
          ),
        );
      },
    );
  }

  Future<void> _deletePersistedEntry(
    String entryId,
    Emitter<TimetableState> emit,
  ) async {
    final backupEntries = state.entries;
    final optimisticEntries = state.entries
        .where((entry) => entry.id != entryId)
        .toList();

    emit(
      _buildStateFromEntries(
        state.copyWith(lastOperation: LastOperation.delete),
        entries: optimisticEntries,
      ),
    );

    final result = await deleteTimetableEntry(
      DeleteTimetableEntryParams(entryId: entryId),
    );

    result.fold(
      (failure) => emit(
        _buildStateFromEntries(
          state.copyWith(
            status: TimetableStatus.error,
            errorMessage: failure.message,
            lastOperation: LastOperation.delete,
          ),
          entries: backupEntries,
        ),
      ),
      (_) => emit(
        _buildStateFromEntries(
          state.copyWith(
            status: TimetableStatus.loaded,
            lastOperation: LastOperation.delete,
          ),
          entries: optimisticEntries,
        ),
      ),
    );
  }

  Future<void> _onDateSelectRequested(
    TimetableDateSelectRequested event,
    Emitter<TimetableState> emit,
  ) async {
    emit(
      state.copyWith(
        selectedDate: TimetableState.startOfDay(event.date),
        status: TimetableStatus.loading,
        clearErrorMessage: true,
      ),
    );
    await _reloadActiveTimetable(emit);
  }

  Future<void> _onViewModeChangeRequested(
    TimetableViewModeChangeRequested event,
    Emitter<TimetableState> emit,
  ) async {
    emit(
      state.copyWith(
        viewMode: event.viewMode,
        status: TimetableStatus.loading,
        clearErrorMessage: true,
      ),
    );
    await _reloadActiveTimetable(emit);
  }

  Future<void> _onVisibilityChangeRequested(
    TimetableVisibilityChangeRequested event,
    Emitter<TimetableState> emit,
  ) async {
    final backupEntries = state.entries;
    final optimisticEntries = state.entries.map((entry) {
      if (entry.id == event.entryId) {
        return entry.copyWith(
          visibility: event.visibility,
          visibleTo: event.visibleTo,
        );
      }
      return entry;
    }).toList();

    emit(
      _buildStateFromEntries(
        state.copyWith(lastOperation: LastOperation.visibility),
        entries: optimisticEntries,
      ),
    );

    final result = await updateEntryVisibility(
      UpdateEntryVisibilityParams(
        entryId: event.entryId,
        visibility: event.visibility,
        visibleTo: event.visibleTo,
      ),
    );

    result.fold(
      (failure) => emit(
        _buildStateFromEntries(
          state.copyWith(
            status: TimetableStatus.error,
            errorMessage: failure.message,
            lastOperation: LastOperation.visibility,
          ),
          entries: backupEntries,
        ),
      ),
      (_) => emit(
        _buildStateFromEntries(
          state.copyWith(
            status: TimetableStatus.loaded,
            lastOperation: LastOperation.visibility,
          ),
          entries: optimisticEntries,
        ),
      ),
    );
  }

  Future<void> _reloadActiveTimetable(Emitter<TimetableState> emit) async {
    final loadedUserId = state.loadedUserId;
    if (loadedUserId == null) {
      emit(
        state.copyWith(
          status: TimetableStatus.error,
          errorMessage: 'No timetable source selected',
        ),
      );
      return;
    }

    final rangeStart = state.visibleRangeStart;
    final rangeEnd = state.visibleRangeEnd;

    final result = state.isViewingShared
        ? await getSharedTimetable(
            GetSharedTimetableParams(
              targetUserId: loadedUserId,
              viewerId: state.viewerId ?? '',
              rangeStart: rangeStart,
              rangeEnd: rangeEnd,
            ),
          )
        : await getMyTimetable(
            GetMyTimetableParams(
              userId: loadedUserId,
              rangeStart: rangeStart,
              rangeEnd: rangeEnd,
            ),
          );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: TimetableStatus.error,
          errorMessage: failure.message,
        ),
      ),
      (entries) {
        final nextState = state.isViewingShared
            ? _buildStateFromEntries(
                state.copyWith(
                  status: TimetableStatus.loaded,
                  clearErrorMessage: true,
                  lastOperation: LastOperation.load,
                ),
                sharedEntries: entries,
              )
            : _buildStateFromEntries(
                state.copyWith(
                  status: TimetableStatus.loaded,
                  clearErrorMessage: true,
                  lastOperation: LastOperation.load,
                ),
                entries: entries,
              );
        emit(nextState);
      },
    );
  }

  TimetableEntry? _findOverride(
    List<TimetableEntry> entries, {
    required String seriesId,
    required DateTime occurrenceDate,
  }) {
    final normalizedOccurrence = TimetableState.startOfDay(occurrenceDate);
    for (final entry in entries) {
      if (entry.entryType != TimetableEntryType.overrideEntry ||
          entry.seriesId != seriesId ||
          entry.occurrenceDate == null) {
        continue;
      }
      if (TimetableState.isSameDate(
        entry.occurrenceDate!,
        normalizedOccurrence,
      )) {
        return entry;
      }
    }
    return null;
  }

  TimetableEntry _buildOverrideEntry({
    required TimetableEntry originalEntry,
    required TimetableEntry updatedEntry,
    required TimetableEntry? existingOverride,
    required bool isCancelled,
  }) {
    return updatedEntry.copyWith(
      id: existingOverride?.id ?? updatedEntry.id,
      userId: originalEntry.userId,
      createdAt: existingOverride?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      entryType: TimetableEntryType.overrideEntry,
      seriesId: originalEntry.rootSeriesId,
      recurrenceFrequency: TimetableRecurrenceFrequency.none,
      recurrenceInterval: 1,
      recurrenceWeekdays: const [],
      clearRecurrenceUntil: true,
      clearRecurrenceCount: true,
      occurrenceDate: originalEntry.effectiveOccurrenceDate,
      isCancelled: isCancelled,
      clearInstanceId: true,
      isGeneratedOccurrence: false,
    );
  }

  TimetableState _buildStateFromEntries(
    TimetableState baseState, {
    List<TimetableEntry>? entries,
    List<TimetableEntry>? sharedEntries,
  }) {
    final nextEntries = entries ?? baseState.entries;
    final nextSharedEntries = sharedEntries ?? baseState.sharedEntries;
    final personalOccurrences = expandTimetableOccurrences(
      ExpandTimetableOccurrencesParams(
        entries: nextEntries,
        rangeStart: baseState.visibleRangeStart,
        rangeEnd: baseState.visibleRangeEnd,
      ),
    );
    final sharedOccurrences = expandTimetableOccurrences(
      ExpandTimetableOccurrencesParams(
        entries: nextSharedEntries,
        rangeStart: baseState.visibleRangeStart,
        rangeEnd: baseState.visibleRangeEnd,
      ),
    );

    return baseState.copyWith(
      entries: nextEntries,
      sharedEntries: nextSharedEntries,
      occurrences: personalOccurrences,
      sharedOccurrences: sharedOccurrences,
    );
  }
}
