import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../location/presentation/bloc/event_bloc.dart';
import '../../../location/domain/entities/event.dart';
import '../../../location/presentation/widgets/event_details_sheet.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/widgets/glass_card.dart';

enum _EventFilter { upcoming, attending, past }

/// Events & Calendar Management Screen following friend's design pattern
class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  _EventFilter _activeFilter = _EventFilter.upcoming;
  String? _selectedRoomId;
  bool _isCalendarView = false;
  late DateTime _selectedCalendarDate;
  bool _hasInitialEventShown = false;

  @override
  void initState() {
    super.initState();
    _selectedCalendarDate = DateTime.now();
    _loadEvents();
  }

  void _loadEvents() {
    final authUser = context.read<AuthBloc>().state.user;
    if (authUser == null) return;
    context.read<EventBloc>().add(EventWatchRequested(userId: authUser.id));
  }

  void _checkInitialEvent(List<Event> events) {
    if (_hasInitialEventShown) return;

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final eventId = args?['eventId'] as String?;

    if (eventId != null) {
      final event = events.where((e) => e.id == eventId).firstOrNull;
      if (event != null) {
        _hasInitialEventShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => EventDetailsSheet(event: event),
          );
        });
      }
    }
  }

  List<Event> _getFilteredEvents(List<Event> allEvents) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final authUser = context.read<AuthBloc>().state.user;
    final currentUserId = authUser?.id;

    List<Event> filtered;
    switch (_activeFilter) {
      case _EventFilter.upcoming:
        filtered =
            allEvents
                .where(
                  (e) => e.eventDate.isAfter(
                    today.subtract(const Duration(seconds: 1)),
                  ),
                )
                .toList()
              ..sort((a, b) => a.eventDate.compareTo(b.eventDate));
        break;
      case _EventFilter.attending:
        filtered =
            allEvents
                .where(
                  (e) =>
                      currentUserId != null &&
                      e.attendeeIds.contains(currentUserId),
                )
                .toList()
              ..sort((a, b) => a.eventDate.compareTo(b.eventDate));
        break;
      case _EventFilter.past:
        filtered = allEvents.where((e) => e.eventDate.isBefore(today)).toList()
          ..sort((a, b) => b.eventDate.compareTo(a.eventDate));
        break;
    }

    if (_selectedRoomId != null) {
      // If we had roomId in Event entity, we would filter here
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<EventBloc, EventState>(
      listenWhen: (prev, curr) =>
          prev.status != curr.status && curr.status == EventStatus.loaded,
      listener: (context, state) => _checkInitialEvent(state.events),
      child: BlocBuilder<EventBloc, EventState>(
        builder: (context, state) {
          final filteredEvents = _getFilteredEvents(state.events);

          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: GlassAppBar(
              title: 'Events',
              actions: [
                IconButton(
                  icon: Icon(
                    _isCalendarView ? Icons.list : Icons.calendar_month,
                    color: AppColors.textPrimary,
                  ),
                  onPressed: () {
                    setState(() => _isCalendarView = !_isCalendarView);
                  },
                ),
              ],
            ),
            body: Column(
              children: [
                _buildSummaryCard(theme, state),
                _buildFilterChips(state),
                Expanded(
                  child: state.status == EventStatus.loading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        )
                      : _isCalendarView
                      ? _buildCalendarView(filteredEvents)
                      : filteredEvents.isEmpty
                      ? _buildEmptyState()
                      : _buildGroupedList(state, filteredEvents),
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                Navigator.pushNamed(context, '/home');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Use the map to create a new event'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: AppColors.secondary,
                  ),
                );
              },
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: AppColors.background),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(ThemeData theme, EventState state) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final upcomingCount = state.events
        .where(
          (e) =>
              e.eventDate.isAfter(today.subtract(const Duration(seconds: 1))),
        )
        .length;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.event, AppColors.secondary],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Upcoming Events',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$upcomingCount Planned',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Icon(Icons.event_available, color: Colors.white, size: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips(EventState state) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final authUser = context.read<AuthBloc>().state.user;

    final upcomingCount = state.events
        .where(
          (e) =>
              e.eventDate.isAfter(today.subtract(const Duration(seconds: 1))),
        )
        .length;
    final attendingCount = state.events
        .where((e) => authUser != null && e.attendeeIds.contains(authUser.id))
        .length;
    final pastCount = state.events
        .where((e) => e.eventDate.isBefore(today))
        .length;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingMd,
        vertical: AppDimensions.spacingSm,
      ),
      child: Row(
        children: [
          _buildTabChip(
            label: 'Upcoming',
            count: upcomingCount,
            color: AppColors.primary,
            filter: _EventFilter.upcoming,
          ),
          const SizedBox(width: 8),
          _buildTabChip(
            label: 'Attending',
            count: attendingCount,
            color: AppColors.secondary,
            filter: _EventFilter.attending,
          ),
          const SizedBox(width: 8),
          _buildTabChip(
            label: 'Past',
            count: pastCount,
            color: AppColors.textTertiary,
            filter: _EventFilter.past,
          ),
        ],
      ),
    );
  }

  Widget _buildTabChip({
    required String label,
    required int count,
    required Color color,
    required _EventFilter filter,
  }) {
    final isSelected = _activeFilter == filter;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeFilter = filter),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? color : Colors.grey.withValues(alpha: 0.2),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Center(
            child: Text(
              '$label ($count)',
              style: TextStyle(
                color: isSelected ? color : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGroupedList(EventState state, List<Event> filteredEvents) {
    return RefreshIndicator(
      onRefresh: () async => _loadEvents(),
      child: ListView.builder(
        padding: const EdgeInsets.all(AppDimensions.spacingMd),
        itemCount: filteredEvents.length,
        itemBuilder: (context, index) {
          final event = filteredEvents[index];
          return _buildEventCard(event);
        },
      ),
    );
  }

  Widget _buildCalendarView(List<Event> events) {
    final now = DateTime.now();
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0).day;

    // Filter events for the selected day
    final dailyEvents = events
        .where(
          (e) =>
              e.eventDate.year == _selectedCalendarDate.year &&
              e.eventDate.month == _selectedCalendarDate.month &&
              e.eventDate.day == _selectedCalendarDate.day,
        )
        .toList();

    return Column(
      children: [
        // Month/Year Header
        Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingMd),
          child: Row(
            children: [
              Text(
                '${DateFormatter.formatMonth(now)} ${now.year}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        // Horizontal Date Strip
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingSm,
            ),
            itemCount: lastDayOfMonth,
            itemBuilder: (context, index) {
              final day = index + 1;
              final date = DateTime(now.year, now.month, day);
              final isSelected = _selectedCalendarDate.day == day;
              final hasEvents = events.any(
                (e) =>
                    e.eventDate.year == date.year &&
                    e.eventDate.month == date.month &&
                    e.eventDate.day == date.day,
              );

              return GestureDetector(
                onTap: () => setState(() => _selectedCalendarDate = date),
                child: Container(
                  width: 60,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.getGlassBackground(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.getGlassBorder(0.2),
                      width: 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormatter.formatDayOfWeek(date).toUpperCase(),
                        style: TextStyle(
                          color: isSelected
                              ? Colors.black
                              : AppColors.textTertiary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$day',
                        style: TextStyle(
                          color: isSelected
                              ? Colors.black
                              : AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (hasEvents && !isSelected)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const Divider(color: AppColors.glassBorder, height: 1),

        // Selected Day's Events
        Expanded(
          child: dailyEvents.isEmpty
              ? Center(
                  child: Text(
                    'No events for ${DateFormatter.formatDate(_selectedCalendarDate)}',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(AppDimensions.spacingMd),
                  itemCount: dailyEvents.length,
                  itemBuilder: (context, index) =>
                      _buildEventCard(dailyEvents[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildEventCard(Event event) {
    final catColor = _getCategoryColor(event.category);
    final isFull =
        event.maxCapacity != null &&
        event.attendeeIds.length >= event.maxCapacity!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: EdgeInsets.zero,
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => EventDetailsSheet(event: event),
          );
        },
        child: SizedBox(
          height: 100,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 70,
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.1),
                  border: Border(
                    right: BorderSide(color: AppColors.getGlassBorder(0.1)),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getCategoryIcon(event.category),
                      color: catColor,
                      size: 18,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormatter.formatMonth(event.eventDate).toUpperCase(),
                      style: TextStyle(
                        color: catColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '${event.eventDate.day}',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              event.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (event.maxCapacity != null)
                            _buildCapacityBadge(
                              event.attendeeIds.length,
                              event.maxCapacity!,
                              isFull,
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            event.eventTime,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'by ${event.creatorName}',
                            style: const TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCapacityBadge(int current, int max, bool isFull) {
    final color = isFull ? AppColors.error : AppColors.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color, width: 0.5),
      ),
      child: Text(
        '$current/$max',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_note_outlined,
            size: 64,
            color: AppColors.textTertiary.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          const Text(
            'No events found',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'restaurant':
        return Icons.restaurant;
      case 'gym':
        return Icons.fitness_center;
      case 'study':
        return Icons.book;
      case 'movie':
        return Icons.movie;
      case 'party':
        return Icons.celebration;
      case 'shopping':
        return Icons.shopping_bag;
      default:
        return Icons.event;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'restaurant':
        return AppColors.success;
      case 'gym':
        return AppColors.primary;
      case 'study':
        return AppColors.warning;
      case 'movie':
        return AppColors.neonPurple;
      case 'party':
        return AppColors.neonMagenta;
      case 'shopping':
        return AppColors.secondary;
      default:
        return AppColors.event;
    }
  }
}
