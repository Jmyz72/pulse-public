import 'package:dartz/dartz.dart' hide Task;

import '../../../../core/error/failures.dart';
import '../entities/task.dart';

abstract class TaskRepository {
  Future<Either<Failure, List<Task>>> getTasks(List<String> chatRoomIds);
  Future<Either<Failure, Task>> getTaskById(String id);
  Future<Either<Failure, Task>> createTask(Task task);
  Future<Either<Failure, Task>> updateTask(Task task);
  Future<Either<Failure, void>> deleteTask(String id);
  Future<Either<Failure, List<Task>>> getTasksByChatRoom(String chatRoomId);
  Future<Either<Failure, String>> uploadTaskEvidence(String taskId, dynamic imageFile);
  Future<Either<Failure, Task>> completeTaskWithEvidence(String taskId, dynamic imageFile);
}
