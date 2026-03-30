import 'package:equatable/equatable.dart';

class TaskItem extends Equatable {
  final String id;
  final String title;
  final bool isDone;

  const TaskItem({
    required this.id,
    required this.title,
    this.isDone = false,
  });

  TaskItem copyWith({String? id, String? title, bool? isDone}) {
    return TaskItem(
      id: id ?? this.id,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
    );
  }

  @override
  List<Object?> get props => [id, title, isDone];
}

enum TaskPriority { low, medium, high }
enum TaskStatus { pending, inProgress, completed }
enum TaskCategory { cleaning, cooking, shopping, maintenance, other }

class Task extends Equatable {
  final String id;
  final String title;
  final String description;
  final String chatRoomId;
  final String assignedTo;
  final String assignedToName;
  final DateTime dueDate;
  final TaskPriority priority;
  final TaskStatus status;
  final TaskCategory category;
  final DateTime createdAt;
  final String createdBy;
  final List<String> attachments;
  final bool isRecurring;
  final String? recurringPattern;
  final String? evidenceImageUrl;
  final DateTime? extensionRequestDate;
  final List<TaskItem> subTasks;

  const Task({
    required this.id,
    required this.title,
    required this.description,
    required this.chatRoomId,
    required this.assignedTo,
    required this.assignedToName,
    required this.dueDate,
    this.priority = TaskPriority.medium,
    this.status = TaskStatus.pending,
    this.category = TaskCategory.other,
    required this.createdAt,
    required this.createdBy,
    this.attachments = const [],
    this.isRecurring = false,
    this.recurringPattern,
    this.evidenceImageUrl,
    this.extensionRequestDate,
    this.subTasks = const [],
  });

  bool get isOverdue => dueDate.isBefore(DateTime.now()) && status != TaskStatus.completed;

  @override
  List<Object?> get props => [
        id,
        title,
        chatRoomId,
        status,
        priority,
        dueDate,
        assignedTo,
        evidenceImageUrl,
        extensionRequestDate,
        subTasks,
      ];
}
