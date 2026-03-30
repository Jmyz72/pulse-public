import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../shared/mixins/stagger_animation_mixin.dart';
import '../../../../../shared/widgets/glass_card.dart';
import '../../../../../shared/widgets/loading_indicator.dart';
import '../../../domain/entities/dashboard_data.dart';
import '../../../domain/usecases/get_activity_metadata.dart';
import '../../widgets/activity_card.dart';

enum _ActivityFilter { all, expenses, tasks, bills, grocery, messages }

class ActivityTab extends StatefulWidget {
  final List<RecentActivity> activities;
  final Future<void> Function() onRefresh;
  final bool isLoading;
  final String? errorMessage;

  const ActivityTab({
    super.key,
    required this.activities,
    required this.onRefresh,
    this.isLoading = false,
    this.errorMessage,
  });

  @override
  State<ActivityTab> createState() => _ActivityTabState();
}

class _ActivityTabState extends State<ActivityTab> with StaggerAnimationMixin {
  _ActivityFilter _activeFilter = _ActivityFilter.all;

  @override
  int get staggerCount => 2;

  @override
  void initState() {
    super.initState();
    startStaggerAnimation();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activities = _filteredActivities();

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            title: staggerIn(index: 0, child: const Text('Activity')),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.spacingLg,
                AppDimensions.spacingMd,
                AppDimensions.spacingLg,
                AppDimensions.spacingMd,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  staggerIn(
                    index: 1,
                    child: Text(
                      'Latest updates across your household',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _FilterHeaderDelegate(
              minExtentValue: 68,
              maxExtentValue: 68,
              child: Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.spacingLg,
                  0,
                  AppDimensions.spacingLg,
                  AppDimensions.spacingSm,
                ),
                alignment: Alignment.bottomLeft,
                child: _buildFilterChips(theme),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.spacingLg,
              0,
              AppDimensions.spacingLg,
              AppDimensions.spacingLg,
            ),
            sliver: widget.isLoading
                ? _buildLoadingState()
                : widget.errorMessage != null
                ? _buildErrorState(theme)
                : activities.isEmpty
                ? _buildEmptyState(theme)
                : _buildActivitySections(theme, activities),
          ),
        ],
      ),
    );
  }

  List<RecentActivity> _filteredActivities() {
    final supported = widget.activities
        .where(ActivityMetadata.isSupported)
        .toList(growable: false);

    return supported
        .where((activity) {
          switch (_activeFilter) {
            case _ActivityFilter.all:
              return true;
            case _ActivityFilter.expenses:
              return activity.type == DashboardActivityType.expense;
            case _ActivityFilter.tasks:
              return activity.type == DashboardActivityType.task;
            case _ActivityFilter.bills:
              return activity.type == DashboardActivityType.bill;
            case _ActivityFilter.grocery:
              return activity.type == DashboardActivityType.grocery;
            case _ActivityFilter.messages:
              return activity.type == DashboardActivityType.chat;
          }
        })
        .toList(growable: false);
  }

  Widget _buildFilterChips(ThemeData theme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(theme, label: 'All', filter: _ActivityFilter.all),
          _buildFilterChip(
            theme,
            label: 'Expenses',
            filter: _ActivityFilter.expenses,
          ),
          _buildFilterChip(
            theme,
            label: 'Tasks',
            filter: _ActivityFilter.tasks,
          ),
          _buildFilterChip(
            theme,
            label: 'Bills',
            filter: _ActivityFilter.bills,
          ),
          _buildFilterChip(
            theme,
            label: 'Grocery',
            filter: _ActivityFilter.grocery,
          ),
          _buildFilterChip(
            theme,
            label: 'Messages',
            filter: _ActivityFilter.messages,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    ThemeData theme, {
    required String label,
    required _ActivityFilter filter,
  }) {
    final isSelected = _activeFilter == filter;
    final count = _countForFilter(filter);

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: ChoiceChip(
        label: Text('$label ($count)'),
        selected: isSelected,
        onSelected: (_) => setState(() => _activeFilter = filter),
        labelStyle: theme.textTheme.bodySmall?.copyWith(
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
        side: BorderSide(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.6)
              : AppColors.textTertiary.withValues(alpha: 0.35),
        ),
        backgroundColor: Colors.transparent,
        selectedColor: AppColors.primary.withValues(alpha: 0.14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }

  int _countForFilter(_ActivityFilter filter) {
    if (filter == _ActivityFilter.all) {
      return widget.activities.where(ActivityMetadata.isSupported).length;
    }

    return widget.activities.where((activity) {
      if (!ActivityMetadata.isSupported(activity)) {
        return false;
      }
      switch (filter) {
        case _ActivityFilter.all:
          return true;
        case _ActivityFilter.expenses:
          return activity.type == DashboardActivityType.expense;
        case _ActivityFilter.tasks:
          return activity.type == DashboardActivityType.task;
        case _ActivityFilter.bills:
          return activity.type == DashboardActivityType.bill;
        case _ActivityFilter.grocery:
          return activity.type == DashboardActivityType.grocery;
        case _ActivityFilter.messages:
          return activity.type == DashboardActivityType.chat;
      }
    }).length;
  }

  Widget _buildLoadingState() {
    return const SliverFillRemaining(child: Center(child: LoadingIndicator()));
  }

  Widget _buildErrorState(ThemeData theme) {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: AppDimensions.spacingMd),
            Text(
              widget.errorMessage ?? 'Something went wrong',
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spacingMd),
            OutlinedButton.icon(
              onPressed: widget.onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return SliverFillRemaining(
      child: Center(
        child: GlassContainer(
          borderRadius: AppDimensions.radiusXl,
          padding: const EdgeInsets.all(AppDimensions.spacingLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.timeline,
                size: 64,
                color: AppColors.textTertiary,
              ),
              const SizedBox(height: AppDimensions.spacingMd),
              Text(
                _emptyTitle(),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingSm),
              Text(
                _emptyDescription(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textTertiary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _emptyTitle() {
    if (_activeFilter == _ActivityFilter.all) {
      return 'No household updates yet';
    }

    return 'No ${_labelForFilter(_activeFilter).toLowerCase()} updates';
  }

  String _emptyDescription() {
    if (_activeFilter == _ActivityFilter.all) {
      return 'Activity from messages, expenses, tasks, bills, and grocery will appear here.';
    }

    return 'Try another filter or refresh to check for newer updates.';
  }

  String _labelForFilter(_ActivityFilter filter) {
    switch (filter) {
      case _ActivityFilter.all:
        return 'All';
      case _ActivityFilter.expenses:
        return 'Expenses';
      case _ActivityFilter.tasks:
        return 'Tasks';
      case _ActivityFilter.bills:
        return 'Bills';
      case _ActivityFilter.grocery:
        return 'Grocery';
      case _ActivityFilter.messages:
        return 'Messages';
    }
  }

  Widget _buildActivitySections(
    ThemeData theme,
    List<RecentActivity> activities,
  ) {
    final sections = <Widget>[];
    final today = _activitiesForBucket(activities, _ActivityBucket.today);
    final yesterday = _activitiesForBucket(activities, _ActivityBucket.yesterday);
    final earlierThisWeek = _activitiesForBucket(
      activities,
      _ActivityBucket.earlierThisWeek,
    );
    final older = _activitiesForBucket(activities, _ActivityBucket.older);

    if (today.isNotEmpty) {
      sections.add(_buildSection(theme, 'Today', today));
    }
    if (yesterday.isNotEmpty) {
      sections.add(_buildSection(theme, 'Yesterday', yesterday));
    }
    if (earlierThisWeek.isNotEmpty) {
      sections.add(_buildSection(theme, 'Earlier This Week', earlierThisWeek));
    }
    if (older.isNotEmpty) {
      sections.add(_buildSection(theme, 'Older', older));
    }

    return SliverList(delegate: SliverChildListDelegate.fixed(sections));
  }

  List<RecentActivity> _activitiesForBucket(
    List<RecentActivity> activities,
    _ActivityBucket bucket,
  ) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));
    final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));

    return activities
        .where((activity) {
          final timestamp = activity.timestamp;
          switch (bucket) {
            case _ActivityBucket.today:
              return DateUtils.isSameDay(timestamp, now);
            case _ActivityBucket.yesterday:
              return DateUtils.isSameDay(timestamp, yesterdayStart);
            case _ActivityBucket.earlierThisWeek:
              return timestamp.isBefore(yesterdayStart) &&
                  !timestamp.isBefore(weekStart);
            case _ActivityBucket.older:
              return timestamp.isBefore(weekStart);
          }
        })
        .toList(growable: false)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Widget _buildSection(
    ThemeData theme,
    String title,
    List<RecentActivity> activities,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingSm),
          ...activities.map((activity) {
            final presentation = ActivityMetadata.resolve(activity);
            return ActivityCard(
              title: activity.title,
              description: activity.description,
              timeAgo: activity.timeAgo,
              icon: presentation.icon,
              color: presentation.color,
              onTap: presentation.buildOnTap(context),
              variant: ActivityCardVariant.feed,
            );
          }),
        ],
      ),
    );
  }
}

enum _ActivityBucket { today, yesterday, earlierThisWeek, older }

class _FilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minExtentValue;
  final double maxExtentValue;
  final Widget child;

  const _FilterHeaderDelegate({
    required this.minExtentValue,
    required this.maxExtentValue,
    required this.child,
  });

  @override
  double get minExtent => minExtentValue;

  @override
  double get maxExtent => maxExtentValue;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _FilterHeaderDelegate oldDelegate) {
    return minExtentValue != oldDelegate.minExtentValue ||
        maxExtentValue != oldDelegate.maxExtentValue ||
        child != oldDelegate.child;
  }
}
