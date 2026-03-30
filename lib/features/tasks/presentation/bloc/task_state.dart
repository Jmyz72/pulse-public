part of 'task_bloc.dart';

enum TaskBlocStatus { initial, loading, loaded, error }

class TaskState extends Equatable {
  final TaskBlocStatus status;
  final List<Task> tasks;
  final String? errorMessage;
  final TaskStatus? statusFilter;
  final TaskCategory? categoryFilter;

  const TaskState({
    this.status = TaskBlocStatus.initial,
    this.tasks = const [],
    this.errorMessage,
    this.statusFilter,
    this.categoryFilter,
  });

  List<Task> get filteredTasks {
    var filtered = tasks;
    if (statusFilter != null) {
      filtered = filtered.where((t) => t.status == statusFilter).toList();
    }
    if (categoryFilter != null) {
      filtered = filtered.where((t) => t.category == categoryFilter).toList();
    }
    return filtered;
  }

  int get pendingCount => tasks.where((t) => t.status != TaskStatus.completed).length;
  int get completedCount => tasks.where((t) => t.status == TaskStatus.completed).length;
  int get overdueCount => tasks.where((t) => t.isOverdue).length;
  int get requestCount => tasks.where((t) => t.extensionRequestDate != null).length;

  TaskState copyWith({
    TaskBlocStatus? status,
    List<Task>? tasks,
    String? errorMessage,
    TaskStatus? statusFilter,
    TaskCategory? categoryFilter,
  }) {
    return TaskState(
      status: status ?? this.status,
      tasks: tasks ?? this.tasks,
      errorMessage: errorMessage,
      statusFilter: statusFilter ?? this.statusFilter,
      categoryFilter: categoryFilter ?? this.categoryFilter,
    );
  }

  @override
  List<Object?> get props => [status, tasks, errorMessage, statusFilter, categoryFilter];
}
