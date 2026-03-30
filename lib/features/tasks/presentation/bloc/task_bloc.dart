import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/notification_service.dart';
import '../../domain/entities/task.dart';
import '../../domain/usecases/create_task.dart';
import '../../domain/usecases/get_tasks.dart';
import '../../domain/usecases/update_task.dart';
import '../../domain/usecases/complete_task_with_evidence.dart';
import '../../../notifications/domain/entities/notification.dart';
import '../../../notifications/domain/usecases/send_notification.dart';

part 'task_event.dart';
part 'task_state.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final GetTasks getTasks;
  final CreateTask createTask;
  final UpdateTask updateTask;
  final CompleteTaskWithEvidence completeTaskWithEvidence;
  final SendNotification sendNotification;

  TaskBloc({
    required this.getTasks,
    required this.createTask,
    required this.updateTask,
    required this.completeTaskWithEvidence,
    required this.sendNotification,
  }) : super(const TaskState()) {
    on<TaskLoadRequested>(_onLoadRequested);
    on<TaskCreateRequested>(_onCreateRequested);
    on<TaskUpdateRequested>(_onUpdateRequested);
    on<TaskStatusChanged>(_onStatusChanged);
    on<TaskCompletedWithEvidence>(_onCompletedWithEvidence);
    on<TaskExtensionRequested>(_onExtensionRequested);
    on<TaskExtensionHandled>(_onExtensionHandled);
    on<TaskFilterChanged>(_onFilterChanged);
  }

  void _onFilterChanged(
    TaskFilterChanged event,
    Emitter<TaskState> emit,
  ) {
    emit(state.copyWith(
      statusFilter: event.statusFilter,
      categoryFilter: event.categoryFilter,
    ));
  }

  Future<void> _onExtensionRequested(
    TaskExtensionRequested event,
    Emitter<TaskState> emit,
  ) async {
    final task = state.tasks.firstWhere((t) => t.id == event.taskId);
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
      extensionRequestDate: event.newDueDate,
    );
    add(TaskUpdateRequested(task: updatedTask));

    if (task.createdBy != task.assignedTo && task.id.isNotEmpty) {
      await _sendAppNotification(
        userId: task.createdBy,
        title: 'Extension Requested',
        body: 'New due date requested for: ${task.title}',
        relatedId: task.id,
      );
    }
  }

  Future<void> _onExtensionHandled(
    TaskExtensionHandled event,
    Emitter<TaskState> emit,
  ) async {
    final task = state.tasks.firstWhere((t) => t.id == event.taskId);
    if (task.extensionRequestDate == null) return;

    final updatedTask = Task(
      id: task.id,
      title: task.title,
      description: task.description,
      chatRoomId: task.chatRoomId,
      assignedTo: task.assignedTo,
      assignedToName: task.assignedToName,
      dueDate: event.accepted ? task.extensionRequestDate! : task.dueDate,
      priority: task.priority,
      status: task.status,
      category: task.category,
      createdAt: task.createdAt,
      createdBy: task.createdBy,
      attachments: task.attachments,
      isRecurring: task.isRecurring,
      recurringPattern: task.recurringPattern,
      extensionRequestDate: null, 
    );
    add(TaskUpdateRequested(task: updatedTask));

    if (task.id.isNotEmpty) {
      await _sendAppNotification(
        userId: task.assignedTo,
        title: event.accepted ? 'Extension Approved' : 'Extension Declined',
        body: event.accepted 
            ? 'Your extension for "${task.title}" was approved' 
            : 'Your extension for "${task.title}" was declined',
        relatedId: task.id,
      );
    }
  }

  Future<void> _sendAppNotification({
    required String userId,
    required String title,
    required String body,
    required String relatedId,
  }) async {
    await sendNotification(SendNotificationParams(
      notification: AppNotification(
        id: '',
        userId: userId,
        title: title,
        body: body,
        type: NotificationType.task,
        relatedId: relatedId,
        timestamp: DateTime.now(),
        actionUrl: '/tasks',
      ),
    ));
  }

  Future<void> _onCompletedWithEvidence(
    TaskCompletedWithEvidence event,
    Emitter<TaskState> emit,
  ) async {
    emit(state.copyWith(status: TaskBlocStatus.loading));

    final result = await completeTaskWithEvidence(CompleteTaskWithEvidenceParams(
      taskId: event.taskId,
      imageFile: event.imageFile,
    ));

    await result.fold(
      (failure) async => emit(state.copyWith(
        status: TaskBlocStatus.error,
        errorMessage: failure.message,
      )),
      (Task task) async {
        if (task.id.isNotEmpty) {
          NotificationService.cancelReminder(task.id.hashCode);
        }
        
        final List<Task> updatedTasks = state.tasks.map((t) => t.id == task.id ? task : t).toList();
        emit(state.copyWith(
          status: TaskBlocStatus.loaded,
          tasks: updatedTasks,
        ));
      },
    );
  }

  Future<void> _onLoadRequested(
    TaskLoadRequested event,
    Emitter<TaskState> emit,
  ) async {
    emit(state.copyWith(status: TaskBlocStatus.loading));

    final result = await getTasks(GetTasksParams(chatRoomIds: event.chatRoomIds));

    result.fold(
      (failure) => emit(state.copyWith(
        status: TaskBlocStatus.error,
        errorMessage: failure.message,
      )),
      (List<Task> tasks) => emit(state.copyWith(
        status: TaskBlocStatus.loaded,
        tasks: tasks,
      )),
    );
  }

  Future<void> _onCreateRequested(
    TaskCreateRequested event,
    Emitter<TaskState> emit,
  ) async {
    emit(state.copyWith(status: TaskBlocStatus.loading));

    final result = await createTask(CreateTaskParams(task: event.task));

    await result.fold(
      (failure) async => emit(state.copyWith(
        status: TaskBlocStatus.error,
        errorMessage: failure.message,
      )),
      (Task task) async {
        if (task.id.isNotEmpty) {
          await _sendAppNotification(
            userId: task.assignedTo,
            title: 'New Task Assigned',
            body: 'You have been assigned: ${task.title}',
            relatedId: task.id,
          );

          final reminderTime = task.dueDate.subtract(const Duration(minutes: 30));
          try {
            NotificationService.scheduleTaskReminder(
              id: task.id.hashCode,
              title: 'Task Reminder',
              body: 'Your task "${task.title}" is due in 30 minutes!',
              scheduledDate: reminderTime,
            );
          } catch (_) {}
        }

        final List<Task> updatedTasks = [...state.tasks, task];
        emit(state.copyWith(
          status: TaskBlocStatus.loaded,
          tasks: updatedTasks,
        ));
      },
    );
  }

  Future<void> _onUpdateRequested(
    TaskUpdateRequested event,
    Emitter<TaskState> emit,
  ) async {
    final result = await updateTask(UpdateTaskParams(task: event.task));

    await result.fold(
      (failure) async => emit(state.copyWith(
        status: TaskBlocStatus.error,
        errorMessage: failure.message,
      )),
      (Task task) async {
        if (task.id.isNotEmpty) {
          NotificationService.cancelReminder(task.id.hashCode);
          if (task.status != TaskStatus.completed) {
            final reminderTime = task.dueDate.subtract(const Duration(minutes: 30));
            try {
              NotificationService.scheduleTaskReminder(
                id: task.id.hashCode,
                title: 'Task Reminder',
                body: 'Your task "${task.title}" is due in 30 minutes!',
                scheduledDate: reminderTime,
              );
            } catch (_) {}
          }
        }

        final List<Task> updatedTasks = state.tasks.map((t) => t.id == task.id ? task : t).toList();
        emit(state.copyWith(
          status: TaskBlocStatus.loaded,
          tasks: updatedTasks,
        ));
      },
    );
  }

  Future<void> _onStatusChanged(
    TaskStatusChanged event,
    Emitter<TaskState> emit,
  ) async {
    final task = state.tasks.firstWhere((t) => t.id == event.taskId);
    final updatedTask = Task(
      id: task.id,
      title: task.title,
      description: task.description,
      chatRoomId: task.chatRoomId,
      assignedTo: task.assignedTo,
      assignedToName: task.assignedToName,
      dueDate: task.dueDate,
      priority: task.priority,
      status: event.newStatus,
      category: task.category,
      createdAt: task.createdAt,
      createdBy: task.createdBy,
      attachments: task.attachments,
      isRecurring: task.isRecurring,
      recurringPattern: task.recurringPattern,
      extensionRequestDate: task.extensionRequestDate,
    );

    add(TaskUpdateRequested(task: updatedTask));
  }
}
