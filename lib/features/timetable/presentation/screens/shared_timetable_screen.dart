import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/timetable_bloc.dart';
import '../widgets/daily_list_view.dart';
import '../widgets/day_selector.dart';
import '../widgets/view_mode_toggle.dart';
import '../widgets/weekly_grid_view.dart';

class SharedTimetableScreen extends StatefulWidget {
  final String targetUserId;
  final String? userName;

  const SharedTimetableScreen({
    super.key,
    required this.targetUserId,
    this.userName,
  });

  @override
  State<SharedTimetableScreen> createState() => _SharedTimetableScreenState();
}

class _SharedTimetableScreenState extends State<SharedTimetableScreen> {
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
      _loadSharedTimetable();
    }
  }

  void _loadSharedTimetable() {
    final userId = context.read<AuthBloc>().state.user?.id;
    if (userId != null) {
      context.read<TimetableBloc>().add(
        SharedTimetableLoadRequested(
          targetUserId: widget.targetUserId,
          viewerId: userId,
        ),
      );
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
      },
      builder: (context, state) {
        return Scaffold(
          appBar: GlassAppBar(
            title: widget.userName != null
                ? "${widget.userName}'s Calendar"
                : 'Shared Calendar',
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
                onPressed: _loadSharedTimetable,
                backgroundColor: AppColors.schedule,
              ),
            ],
          ),
        ),
      );
    }

    if (state.activeOccurrences.isEmpty) {
      return RefreshIndicator(
        color: AppColors.schedule,
        onRefresh: () async {
          _loadSharedTimetable();
          await context.read<TimetableBloc>().stream.firstWhere(
            (nextState) => nextState.status != TimetableStatus.loading,
          );
        },
        child: const CustomScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.event_busy,
                      size: 64,
                      color: AppColors.textTertiary,
                    ),
                    SizedBox(height: AppDimensions.spacingMd),
                    Text(
                      'No shared calendar entries',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (state.viewMode == ViewMode.weekly) {
      return RefreshIndicator(
        color: AppColors.schedule,
        onRefresh: () async {
          _loadSharedTimetable();
          await context.read<TimetableBloc>().stream.firstWhere(
            (nextState) => nextState.status != TimetableStatus.loading,
          );
        },
        child: WeeklyGridView(
          weekDates: state.weekDates,
          entriesByDate: state.weekEntriesByDate,
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
        _loadSharedTimetable();
        await context.read<TimetableBloc>().stream.firstWhere(
          (nextState) => nextState.status != TimetableStatus.loading,
        );
      },
      child: DailyListView(
        entries: state.selectedDateEntries,
        date: state.selectedDate,
        isOwner: false,
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
}
