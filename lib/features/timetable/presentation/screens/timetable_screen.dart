import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/timetable_entry.dart';
import '../bloc/timetable_bloc.dart';
import '../widgets/daily_list_view.dart';
import '../widgets/day_selector.dart';
import '../widgets/view_mode_toggle.dart';
import '../widgets/weekly_grid_view.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
      _loadTimetable();
    }
  }

  void _loadTimetable() {
    final userId = context.read<AuthBloc>().state.user?.id;
    if (userId != null) {
      context.read<TimetableBloc>().add(TimetableLoadRequested(userId: userId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TimetableBloc, TimetableState>(
      listener: (context, state) {
        if (state.status == TimetableStatus.error &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.error.withValues(alpha: 0.9),
              content: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppColors.white,
                    size: 20,
                  ),
                  const SizedBox(width: AppDimensions.spacingSm),
                  Expanded(child: Text(state.errorMessage!)),
                ],
              ),
            ),
          );
        }
        if (state.lastOperation == LastOperation.delete &&
            state.status == TimetableStatus.loaded) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.success.withValues(alpha: 0.9),
              content: const Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: AppColors.white,
                    size: 20,
                  ),
                  SizedBox(width: AppDimensions.spacingSm),
                  Text('Entry deleted'),
                ],
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: GlassAppBar(
            title: 'My Calendar',
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: AppDimensions.spacingSm),
                child: ViewModeToggle(
                  viewMode: state.viewMode,
                  onChanged: (mode) {
                    context.read<TimetableBloc>().add(
                      TimetableViewModeChangeRequested(viewMode: mode),
                    );
                  },
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                DateSelector(
                  selectedDate: state.selectedDate,
                  onDateSelected: (date) {
                    context.read<TimetableBloc>().add(
                      TimetableDateSelectRequested(date: date),
                    );
                  },
                  onPreviousWeek: () {
                    context.read<TimetableBloc>().add(
                      TimetableDateSelectRequested(
                        date: state.selectedDate.subtract(
                          const Duration(days: 7),
                        ),
                      ),
                    );
                  },
                  onNextWeek: () {
                    context.read<TimetableBloc>().add(
                      TimetableDateSelectRequested(
                        date: state.selectedDate.add(const Duration(days: 7)),
                      ),
                    );
                  },
                  onPickDate: _pickDate,
                ),
                Expanded(child: _buildContent(context, state)),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              final result = await Navigator.pushNamed(
                context,
                '/timetable/add',
                arguments: {'initialDate': state.selectedDate},
              );
              if (!mounted) return;
              if (result == true) {
                _loadTimetable();
              }
            },
            tooltip: 'Add entry',
            backgroundColor: AppColors.schedule,
            child: const Icon(Icons.add, color: AppColors.white),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, TimetableState state) {
    if (state.status == TimetableStatus.loading &&
        state.activeOccurrences.isEmpty) {
      return const Center(child: LoadingIndicator(color: AppColors.schedule));
    }

    if (state.status == TimetableStatus.error &&
        state.activeOccurrences.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingLg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: AppDimensions.spacingMd),
              const Text(
                'Failed to load calendar',
                style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppDimensions.spacingSm),
              CustomButton(
                text: 'Retry',
                onPressed: _loadTimetable,
                backgroundColor: AppColors.schedule,
              ),
            ],
          ),
        ),
      );
    }

    if (state.viewMode == ViewMode.weekly) {
      return RefreshIndicator(
        color: AppColors.schedule,
        onRefresh: () async {
          _loadTimetable();
          await context.read<TimetableBloc>().stream.firstWhere(
            (nextState) => nextState.status != TimetableStatus.loading,
          );
        },
        child: WeeklyGridView(
          weekDates: state.weekDates,
          entriesByDate: state.weekEntriesByDate,
          onEntryTap: _navigateToEdit,
          onDayTap: (date) {
            context.read<TimetableBloc>().add(
              TimetableDateSelectRequested(date: date),
            );
            context.read<TimetableBloc>().add(
              const TimetableViewModeChangeRequested(viewMode: ViewMode.daily),
            );
          },
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.schedule,
      onRefresh: () async {
        _loadTimetable();
        await context.read<TimetableBloc>().stream.firstWhere(
          (nextState) => nextState.status != TimetableStatus.loading,
        );
      },
      child: DailyListView(
        entries: state.selectedDateEntries,
        date: state.selectedDate,
        onEntryTap: _navigateToEdit,
        onEntryLongPress: (entry) => _showDeleteDialog(context, entry),
        isOwner: true,
      ),
    );
  }

  Future<void> _pickDate() async {
    final bloc = context.read<TimetableBloc>();
    final date = await showDatePicker(
      context: context,
      initialDate: bloc.state.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (date != null && mounted) {
      bloc.add(TimetableDateSelectRequested(date: date));
    }
  }

  Future<void> _navigateToEdit(TimetableEntry entry) async {
    var targetEntry = entry;
    var scope = TimetableEditScope.wholeSeries;

    if (entry.canEditAsSeries) {
      final selectedScope = await _showScopePicker(entry);
      if (!mounted || selectedScope == null) return;
      scope = selectedScope;
      if (scope == TimetableEditScope.wholeSeries) {
        final rootEntry = context
            .read<TimetableBloc>()
            .state
            .entries
            .where((candidate) => candidate.id == entry.rootSeriesId)
            .cast<TimetableEntry?>()
            .firstWhere((candidate) => candidate != null, orElse: () => null);
        if (rootEntry != null) {
          targetEntry = rootEntry;
        }
      }
    }

    final result = await Navigator.pushNamed(
      context,
      '/timetable/edit',
      arguments: {'entry': targetEntry, 'editScope': scope},
    );
    if (!mounted) return;
    if (result == true) {
      _loadTimetable();
    }
  }

  Future<TimetableEditScope?> _showScopePicker(TimetableEntry entry) {
    return showModalBottomSheet<TimetableEditScope>(
      context: context,
      backgroundColor: AppColors.background,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.spacingLg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  entry.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingSm),
                const Text(
                  'Apply changes to this occurrence or the full series?',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppDimensions.spacingLg),
                ListTile(
                  leading: const Icon(Icons.event_available),
                  title: const Text('This occurrence'),
                  onTap: () =>
                      Navigator.pop(context, TimetableEditScope.thisOccurrence),
                ),
                ListTile(
                  leading: const Icon(Icons.event_repeat),
                  title: const Text('Whole series'),
                  onTap: () =>
                      Navigator.pop(context, TimetableEditScope.wholeSeries),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool?> _showDeleteDialog(
    BuildContext context,
    TimetableEntry entry,
  ) async {
    TimetableEditScope scope = TimetableEditScope.wholeSeries;
    if (entry.canEditAsSeries) {
      final selectedScope = await _showDeleteScopePicker(entry);
      if (selectedScope == null || !context.mounted) {
        return null;
      }
      scope = selectedScope;
    }

    if (!context.mounted) return null;

    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.glassBorder, width: 1.5),
        ),
        title: const Text('Delete Entry'),
        content: Text(
          scope == TimetableEditScope.thisOccurrence
              ? 'Delete this occurrence of "${entry.title}"?'
              : 'Delete "${entry.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx, true);
              context.read<TimetableBloc>().add(
                TimetableOccurrenceDeleteRequested(entry: entry, scope: scope),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<TimetableEditScope?> _showDeleteScopePicker(TimetableEntry entry) {
    return showModalBottomSheet<TimetableEditScope>(
      context: context,
      backgroundColor: AppColors.background,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.spacingLg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Delete "${entry.title}"',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingLg),
                ListTile(
                  leading: const Icon(Icons.event_available),
                  title: const Text('Delete this occurrence'),
                  onTap: () =>
                      Navigator.pop(context, TimetableEditScope.thisOccurrence),
                ),
                ListTile(
                  leading: const Icon(Icons.event_repeat),
                  title: const Text('Delete whole series'),
                  onTap: () =>
                      Navigator.pop(context, TimetableEditScope.wholeSeries),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
