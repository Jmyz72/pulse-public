import '../../domain/entities/task.dart';

class TaskItemModel extends TaskItem {
  const TaskItemModel({
    required super.id,
    required super.title,
    super.isDone,
  });

  factory TaskItemModel.fromJson(Map<String, dynamic> json) {
    return TaskItemModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      isDone: json['isDone'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'isDone': isDone,
    };
  }

  factory TaskItemModel.fromEntity(TaskItem item) {
    return TaskItemModel(
      id: item.id,
      title: item.title,
      isDone: item.isDone,
    );
  }
}

class TaskModel extends Task {
  const TaskModel({
    required super.id,
    required super.title,
    required super.description,
    required super.chatRoomId,
    required super.assignedTo,
    required super.assignedToName,
    required super.dueDate,
    super.priority,
    super.status,
    super.category,
    required super.createdAt,
    required super.createdBy,
    super.attachments,
    super.isRecurring,
    super.recurringPattern,
    super.evidenceImageUrl,
    super.extensionRequestDate,
    super.subTasks,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      chatRoomId: json['chatRoomId'] ?? '',
      assignedTo: json['assignedTo'] ?? '',
      assignedToName: json['assignedToName'] ?? '',
      dueDate: DateTime.parse(json['dueDate']),
      priority: TaskPriority.values.firstWhere(
        (p) => p.name == json['priority'],
        orElse: () => TaskPriority.medium,
      ),
      status: TaskStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => TaskStatus.pending,
      ),
      category: TaskCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => TaskCategory.other,
      ),
      createdAt: DateTime.parse(json['createdAt']),
      createdBy: json['createdBy'] ?? '',
      attachments: List<String>.from(json['attachments'] ?? []),
      isRecurring: json['isRecurring'] ?? false,
      recurringPattern: json['recurringPattern'],
      evidenceImageUrl: json['evidenceImageUrl'],
      extensionRequestDate: json['extensionRequestDate'] != null 
          ? DateTime.parse(json['extensionRequestDate']) 
          : null,
      subTasks: (json['subTasks'] as List<dynamic>?)
              ?.map((item) => TaskItemModel.fromJson(item as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'chatRoomId': chatRoomId,
      'assignedTo': assignedTo,
      'assignedToName': assignedToName,
      'dueDate': dueDate.toIso8601String(),
      'priority': priority.name,
      'status': status.name,
      'category': category.name,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
      'attachments': attachments,
      'isRecurring': isRecurring,
      'recurringPattern': recurringPattern,
      'evidenceImageUrl': evidenceImageUrl,
      'extensionRequestDate': extensionRequestDate?.toIso8601String(),
      'subTasks': subTasks
          .map((item) => TaskItemModel.fromEntity(item).toJson())
          .toList(),
    };
  }

  factory TaskModel.fromEntity(Task task) {
    return TaskModel(
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
      evidenceImageUrl: task.evidenceImageUrl,
      extensionRequestDate: task.extensionRequestDate,
      subTasks: task.subTasks,
    );
  }
}
