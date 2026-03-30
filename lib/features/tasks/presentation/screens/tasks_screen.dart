import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_animations.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../chat/presentation/bloc/chat_bloc.dart';
import '../../../chat/domain/entities/message.dart';
import '../../../home/presentation/widgets/member_avatar_card.dart';
import '../../domain/entities/task.dart';
import '../bloc/task_bloc.dart';
import '../widgets/task_form_dialog.dart';

enum _TaskFilter { pending, myTasks, completed }

/// Tasks & Chores Management Screen following friend's design pattern
class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  _TaskFilter _activeFilter = _TaskFilter.pending;
  String? _selectedRoomId;

  @override
  void initState() {
    super.initState();

    // Initialize selected room from chat rooms if available
    final chatState = context.read<ChatBloc>().state;
    if (chatState.chatRooms.isNotEmpty) {
      _selectedRoomId = chatState.chatRooms.first.id;
    }

    _loadTasks();
  }

  void _loadTasks() {
    if (_selectedRoomId != null) {
      context.read<TaskBloc>().add(
        TaskLoadRequested(chatRoomIds: [_selectedRoomId!]),
      );
    } else {
      final chatState = context.read<ChatBloc>().state;
      final chatRoomIds = chatState.chatRooms.map((r) => r.id).toList();
      context.read<TaskBloc>().add(TaskLoadRequested(chatRoomIds: chatRoomIds));
    }
  }

  List<Task> _getFilteredTasks(TaskState state) {
    final authState = context.read<AuthBloc>().state;
    final currentUserId = authState.user?.id;

    List<Task> filtered;
    switch (_activeFilter) {
      case _TaskFilter.pending:
        filtered = state.tasks
            .where((t) => t.status != TaskStatus.completed)
            .toList();
        break;
      case _TaskFilter.myTasks:
        filtered = state.tasks
            .where(
              (t) => t.assignedTo == currentUserId || t.assignedToName == 'You',
            )
            .toList();
        break;
      case _TaskFilter.completed:
        filtered = state.tasks
            .where((t) => t.status == TaskStatus.completed)
            .toList();
        break;
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<TaskBloc, TaskState>(
      builder: (context, state) {
        final filteredTasks = _getFilteredTasks(state);

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: GlassAppBar(
            title: 'Tasks & Chores',
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.filter_list,
                  color: AppColors.textPrimary,
                ),
                onPressed: _showRoomSelector,
              ),
            ],
          ),
          body: Column(
            children: [
              _buildSummaryCard(theme, state),
              _buildFilterChips(state),
              Expanded(
                child: state.status == TaskBlocStatus.loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    : filteredTasks.isEmpty
                    ? _buildEmptyState()
                    : _buildGroupedList(state, filteredTasks),
              ),
            ],
          ),
          bottomNavigationBar: _buildBottomAction(context, theme),
        );
      },
    );
  }

  Widget _buildBottomAction(BuildContext context, ThemeData theme) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        16 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.8),
        border: Border(top: BorderSide(color: AppColors.getGlassBorder(0.1))),
      ),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.secondary],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showAddTaskDialog(context, theme),
            borderRadius: BorderRadius.circular(16),
            child: const Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_task, color: Colors.black, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'ADD NEW TASK',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(ThemeData theme, TaskState state) {
    final total = state.tasks.length;
    final done = state.completedCount;
    final progress = total == 0 ? 0.0 : done / total;
    final percent = (progress * 100).toInt();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary,
              AppColors.secondary.withValues(alpha: 0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            // Circular Progress
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 70,
                  height: 70,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                ),
                Text(
                  '$percent%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 20),
            // Stats Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Group Progress',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$done of $total chores finished',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // Request Badge if any
            if (state.requestCount > 0)
              _buildSummaryBadge(
                count: state.requestCount,
                label: 'Requests',
                color: Colors.amber,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryBadge({
    required int count,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(TaskState state) {
    final authState = context.read<AuthBloc>().state;
    final currentUserId = authState.user?.id;

    final pendingCount = state.tasks
        .where((t) => t.status != TaskStatus.completed)
        .length;
    final myTasksCount = state.tasks
        .where(
          (t) => t.assignedTo == currentUserId || t.assignedToName == 'You',
        )
        .length;
    final doneCount = state.tasks
        .where((t) => t.status == TaskStatus.completed)
        .length;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingMd,
        vertical: AppDimensions.spacingSm,
      ),
      child: Row(
        children: [
          _buildTabChip(
            label: 'Pending',
            count: pendingCount,
            color: AppColors.warning,
            filter: _TaskFilter.pending,
          ),
          const SizedBox(width: 8),
          _buildTabChip(
            label: 'Mine',
            count: myTasksCount,
            color: AppColors.primary,
            filter: _TaskFilter.myTasks,
          ),
          const SizedBox(width: 8),
          _buildTabChip(
            label: 'Done',
            count: doneCount,
            color: AppColors.success,
            filter: _TaskFilter.completed,
          ),
        ],
      ),
    );
  }

  Widget _buildTabChip({
    required String label,
    required int count,
    required Color color,
    required _TaskFilter filter,
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

  Widget _buildGroupedList(TaskState state, List<Task> filteredTasks) {
    final chatState = context.watch<ChatBloc>().state;

    // Group tasks by chatRoomId
    final Map<String, List<Task>> grouped = {};
    for (var task in filteredTasks) {
      grouped.putIfAbsent(task.chatRoomId, () => []).add(task);
    }

    final chatRoomIds = grouped.keys.toList();

    return RefreshIndicator(
      onRefresh: () async => _loadTasks(),
      child: AnimationLimiter(
        child: ListView.builder(
          padding: const EdgeInsets.all(AppDimensions.spacingMd),
          itemCount: chatRoomIds.length,
          itemBuilder: (context, index) {
            final roomId = chatRoomIds[index];
            final tasks = grouped[roomId]!;

            final chatRoom = chatState.chatRooms.cast<ChatRoom>().firstWhere(
              (r) => r.id == roomId,
              orElse: () => chatState.chatRooms.first,
            );

            return AnimationConfiguration.staggeredList(
              position: index,
              duration: AppAnimations.medium,
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Section Header
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12, top: 8),
                        child: Row(
                          children: [
                            Icon(
                              chatRoom.members.length > 2
                                  ? Icons.groups
                                  : Icons.person,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                chatRoom.name,
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${tasks.length} tasks',
                              style: const TextStyle(
                                color: AppColors.textTertiary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...tasks.map(_buildTaskCard),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTaskCard(Task task) {
    final isOverdue = task.isOverdue;
    final catColor = _getCategoryColor(task.category);
    final priorityColor = _getPriorityColor(task.priority);
    final isHighPriority = task.priority == TaskPriority.high;

    // Calculate sub-task progress
    double subTaskProgress = 0;
    if (task.subTasks.isNotEmpty) {
      final done = task.subTasks.where((t) => t.isDone).length;
      subTaskProgress = done / task.subTasks.length;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: isHighPriority || isOverdue
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                boxShadow: [
                  BoxShadow(
                    color: (isOverdue ? AppColors.error : priorityColor)
                        .withValues(alpha: 0.2),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              )
            : null,
        child: GlassCard(
          padding: EdgeInsets.zero,
          onTap: () => _showTaskDetails(context, task),
          borderColor: isOverdue ? AppColors.error : priorityColor,
          borderOpacity: isHighPriority || isOverdue ? 0.8 : 0.4,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.getGlassBorder(0.1)),
                  ),
                  child: Center(
                    child: Icon(
                      _getCategoryIcon(task.category),
                      color: catColor,
                      size: 24,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 12, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    task.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      decoration:
                                          task.status == TaskStatus.completed
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                  if (task.subTasks.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(2),
                                      child: LinearProgressIndicator(
                                        value: subTaskProgress,
                                        minHeight: 3,
                                        backgroundColor: Colors.white
                                            .withValues(alpha: 0.1),
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              catColor,
                                            ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (task.evidenceImageUrl != null)
                              const Icon(
                                Icons.verified,
                                color: AppColors.success,
                                size: 16,
                              ),
                          ],
                        ),
                        if (task.extensionRequestDate != null)
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.history,
                                  size: 12,
                                  color: AppColors.warning,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Extension Pending',
                                  style: TextStyle(
                                    color: AppColors.warning,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            // Assignee Avatar
                            BlocBuilder<ChatBloc, ChatState>(
                              builder: (context, chatState) {
                                return MemberAvatarCard(
                                  name: task.assignedToName,
                                  avatarInitial: task.assignedToName.isNotEmpty
                                      ? task.assignedToName[0]
                                      : '?',
                                  isOnline: false,
                                  showStatus: false,
                                  showName: false,
                                  compact: true,
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      task.assignedToName,
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.calendar_today_outlined,
                                    size: 14,
                                    color: isOverdue
                                        ? AppColors.error
                                        : AppColors.textTertiary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatDate(task.dueDate),
                                    style: TextStyle(
                                      color: isOverdue
                                          ? AppColors.error
                                          : AppColors.textTertiary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (task.status != TaskStatus.completed)
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _completeWithEvidence(task.id),
                      child: Container(
                        width: 50,
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(
                              color: AppColors.getGlassBorder(0.1),
                            ),
                          ),
                        ),
                        child: const Icon(
                          Icons.camera_alt_outlined,
                          color: AppColors.success,
                          size: 20,
                        ),
                      ),
                    ),
                  )
                else
                  const SizedBox(
                    width: 50,
                    child: Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
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
            Icons.assignment_turned_in_outlined,
            size: 64,
            color: AppColors.textTertiary.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          const Text(
            'No tasks found',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
        ],
      ),
    );
  }

  void _showRoomSelector() {
    final chatState = context.read<ChatBloc>().state;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.9),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Filter by Room',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              ListTile(
                title: const Text(
                  'All Rooms',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                leading: const Icon(
                  Icons.all_inclusive,
                  color: AppColors.primary,
                ),
                onTap: () {
                  setState(() => _selectedRoomId = null);
                  _loadTasks();
                  Navigator.pop(context);
                },
              ),
              ...chatState.chatRooms.map(
                (room) => ListTile(
                  title: Text(
                    room.name,
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                  leading: const Icon(
                    Icons.forum_outlined,
                    color: AppColors.primary,
                  ),
                  onTap: () {
                    setState(() => _selectedRoomId = room.id);
                    _loadTasks();
                    Navigator.pop(context);
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showTaskDetails(BuildContext context, Task task) {
    final theme = Theme.of(context);
    final catColor = _getCategoryColor(task.category);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXl),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            decoration: BoxDecoration(
              color: AppColors.getGlassBackground(0.08),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppDimensions.radiusXl),
              ),
              border: Border.all(
                color: AppColors.getGlassBorder(0.3),
                width: 1.5,
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textTertiary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: catColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getCategoryIcon(task.category),
                          color: catColor,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.title,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Task in ${task.category.name}',
                              style: TextStyle(
                                color: catColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  if (task.subTasks.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text(
                      'Checklist',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...task.subTasks.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: InkWell(
                          onTap: task.status != TaskStatus.completed
                              ? () {
                                  final newSubTasks = task.subTasks.map((t) {
                                    if (t.id == item.id) {
                                      return t.copyWith(isDone: !t.isDone);
                                    }
                                    return t;
                                  }).toList();
                                  final updatedTask = Task(
                                    id: task.id,
                                    title: task.title,
                                    description: task.description,
                                    chatRoomId: task.chatRoomId,
                                    assignedTo: task.assignedTo,
                                    assignedToName: task.assignedToName,
                                    dueDate: task.dueDate,
                                    priority: task.priority,
                                    status: task.status,
                                    category: task.category,
                                    createdAt: task.createdAt,
                                    createdBy: task.createdBy,
                                    attachments: task.attachments,
                                    isRecurring: task.isRecurring,
                                    recurringPattern: task.recurringPattern,
                                    extensionRequestDate:
                                        task.extensionRequestDate,
                                    subTasks: newSubTasks,
                                  );
                                  context.read<TaskBloc>().add(
                                    TaskUpdateRequested(task: updatedTask),
                                  );
                                }
                              : null,
                          child: Row(
                            children: [
                              Icon(
                                item.isDone
                                    ? Icons.check_box
                                    : Icons.check_box_outline_blank,
                                size: 20,
                                color: item.isDone
                                    ? AppColors.success
                                    : AppColors.textTertiary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 14,
                                    decoration: item.isDone
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],

                  if (task.evidenceImageUrl != null) ...[
                    const SizedBox(height: 20),
                    const Text(
                      'Completion Evidence',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        task.evidenceImageUrl!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  _buildDetailRow('Assigned to', task.assignedToName),
                  _buildDetailRow('Due Date', _formatDate(task.dueDate)),
                  _buildDetailRow('Priority', task.priority.name.toUpperCase()),
                  _buildDetailRow(
                    'Status',
                    task.status == TaskStatus.inProgress
                        ? 'IN PROGRESS'
                        : task.status.name.toUpperCase(),
                  ),
                  if (task.isRecurring)
                    _buildDetailRow(
                      'Recurring',
                      task.recurringPattern ?? 'Yes',
                    ),

                  // Extension Request Info
                  if (task.extensionRequestDate != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.history,
                                color: AppColors.warning,
                                size: 16,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Extension Requested',
                                style: TextStyle(
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Requested New Date: ${_formatDate(task.extensionRequestDate!)}',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                            ),
                          ),
                          if (task.assignedTo !=
                              context.read<AuthBloc>().state.user?.id) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      context.read<TaskBloc>().add(
                                        TaskExtensionHandled(
                                          taskId: task.id,
                                          accepted: false,
                                        ),
                                      );
                                      Navigator.pop(context);
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.error,
                                    ),
                                    child: const Text('Decline'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      context.read<TaskBloc>().add(
                                        TaskExtensionHandled(
                                          taskId: task.id,
                                          accepted: true,
                                        ),
                                      );
                                      Navigator.pop(context);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.warning,
                                      foregroundColor: Colors.black,
                                    ),
                                    child: const Text('Approve'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),
                  if (task.status != TaskStatus.completed)
                    Column(
                      children: [
                        Row(
                          children: [
                            if (task.status == TaskStatus.pending)
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      context.read<TaskBloc>().add(
                                        TaskStatusChanged(
                                          taskId: task.id,
                                          newStatus: TaskStatus.inProgress,
                                        ),
                                      );
                                      Navigator.pop(context);
                                    },
                                    icon: const Icon(Icons.play_arrow),
                                    label: const Text('Start Now'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.primary,
                                      side: const BorderSide(
                                        color: AppColors.primary,
                                      ),
                                      minimumSize: const Size(
                                        double.infinity,
                                        52,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _completeWithEvidence(task.id);
                                },
                                icon: const Icon(Icons.camera_alt),
                                label: const Text('Complete with Proof'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.success,
                                  foregroundColor: Colors.black,
                                  minimumSize: const Size(double.infinity, 52),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (task.assignedTo ==
                            context.read<AuthBloc>().state.user?.id) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => _showExtensionPicker(task),
                              icon: const Icon(Icons.history),
                              label: const Text('Request Extension'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.textSecondary,
                                side: BorderSide(
                                  color: AppColors.textTertiary.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                                minimumSize: const Size(double.infinity, 52),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return AppColors.error;
      case TaskPriority.medium:
        return AppColors.warning;
      case TaskPriority.low:
        return AppColors.primary;
    }
  }

  IconData _getCategoryIcon(TaskCategory category) {
    switch (category) {
      case TaskCategory.cleaning:
        return Icons.cleaning_services;
      case TaskCategory.cooking:
        return Icons.restaurant;
      case TaskCategory.shopping:
        return Icons.shopping_cart;
      case TaskCategory.maintenance:
        return Icons.build;
      case TaskCategory.other:
        return Icons.task;
    }
  }

  Color _getCategoryColor(TaskCategory category) {
    switch (category) {
      case TaskCategory.cleaning:
        return AppColors.primary;
      case TaskCategory.cooking:
        return AppColors.warning;
      case TaskCategory.shopping:
        return AppColors.success;
      case TaskCategory.maintenance:
        return AppColors.neonPurple;
      case TaskCategory.other:
        return AppColors.textTertiary;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Tomorrow';
    if (difference == -1) return 'Yesterday';
    if (difference < 0) return '${-difference} days ago';
    return 'In $difference days';
  }

  Future<void> _completeWithEvidence(String taskId) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
      maxWidth: 1024,
    );
    if (image != null) {
      if (!mounted) return;
      context.read<TaskBloc>().add(
        TaskCompletedWithEvidence(taskId: taskId, imageFile: File(image.path)),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Uploading evidence and completing task...'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  Future<void> _showExtensionPicker(Task task) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: task.dueDate.add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      if (!mounted) return;
      context.read<TaskBloc>().add(
        TaskExtensionRequested(taskId: task.id, newDueDate: picked),
      );
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Extension requested'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  void _showAddTaskDialog(BuildContext context, ThemeData theme) {
    final chatState = context.read<ChatBloc>().state;
    final authState = context.read<AuthBloc>().state;
    final userId = authState.user?.id ?? '';

    showDialog(
      context: context,
      builder: (ctx) => TaskFormDialog(
        chatRooms: chatState.chatRooms,
        preselectedChatRoomId: _selectedRoomId,
        currentUserId: userId,
        onSubmit: (task) {
          context.read<TaskBloc>().add(TaskCreateRequested(task: task));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Task added successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
        },
      ),
    );
  }
}
