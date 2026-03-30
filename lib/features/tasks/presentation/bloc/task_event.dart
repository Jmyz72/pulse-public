part of 'task_bloc.dart';

abstract class TaskEvent extends Equatable {
  const TaskEvent();

  @override
  List<Object?> get props => [];
}

class TaskLoadRequested extends TaskEvent {
  final List<String> chatRoomIds;

  const TaskLoadRequested({required this.chatRoomIds});

  @override
  List<Object> get props => [chatRoomIds];
}

class TaskCreateRequested extends TaskEvent {
  final Task task;

  const TaskCreateRequested({required this.task});

  @override
  List<Object> get props => [task];
}

class TaskUpdateRequested extends TaskEvent {
  final Task task;

  const TaskUpdateRequested({required this.task});

  @override
  List<Object> get props => [task];
}

class TaskDeleteRequested extends TaskEvent {
  final String id;

  const TaskDeleteRequested({required this.id});

  @override
  List<Object> get props => [id];
}

class TaskStatusChanged extends TaskEvent {
  final String taskId;
  final TaskStatus newStatus;

  const TaskStatusChanged({required this.taskId, required this.newStatus});

  @override
  List<Object> get props => [taskId, newStatus];
}

class TaskCompletedWithEvidence extends TaskEvent {
  final String taskId;
  final dynamic imageFile;

  const TaskCompletedWithEvidence({required this.taskId, required this.imageFile});

  @override
  List<Object> get props => [taskId, imageFile];
}

class TaskExtensionRequested extends TaskEvent {
  final String taskId;
  final DateTime newDueDate;

  const TaskExtensionRequested({required this.taskId, required this.newDueDate});

  @override
  List<Object> get props => [taskId, newDueDate];
}

class TaskExtensionHandled extends TaskEvent {
  final String taskId;
  final bool accepted;

  const TaskExtensionHandled({required this.taskId, required this.accepted});

  @override
  List<Object> get props => [taskId, accepted];
}

class TaskFilterChanged extends TaskEvent {
  final TaskStatus? statusFilter;
  final TaskCategory? categoryFilter;

  const TaskFilterChanged({this.statusFilter, this.categoryFilter});

  @override
  List<Object?> get props => [statusFilter, categoryFilter];
}
