import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart' hide Task;
import 'package:dartz/dartz.dart' hide Task;

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_remote_datasource.dart';
import '../models/task_model.dart';

class TaskRepositoryImpl implements TaskRepository {
  final TaskRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;
  final FirebaseStorage firebaseStorage;

  TaskRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
    required this.firebaseStorage,
  });

  @override
  Future<Either<Failure, List<Task>>> getTasks(List<String> chatRoomIds) async {
    try {
      final tasks = await remoteDataSource.getTasks(chatRoomIds);
      return Right(tasks);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, Task>> getTaskById(String id) async {
    try {
      final task = await remoteDataSource.getTaskById(id);
      return Right(task as Task);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, Task>> createTask(Task task) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final model = TaskModel.fromEntity(task);
      final created = await remoteDataSource.createTask(model);
      return Right(created as Task);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, Task>> updateTask(Task task) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final model = TaskModel.fromEntity(task);
      final updated = await remoteDataSource.updateTask(model);
      return Right(updated as Task);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTask(String id) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      await remoteDataSource.deleteTask(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, List<Task>>> getTasksByChatRoom(
    String chatRoomId,
  ) async {
    try {
      final tasks = await remoteDataSource.getTasksByChatRoom(chatRoomId);
      return Right(tasks);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, String>> uploadTaskEvidence(
    String taskId,
    dynamic imageFile,
  ) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final ref = firebaseStorage.ref().child(
        'task_evidence/$taskId/evidence.jpg',
      );
      final uploadTask = await ref.putFile(imageFile as File);
      final url = await uploadTask.ref.getDownloadURL();
      return Right(url);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Task>> completeTaskWithEvidence(
    String taskId,
    dynamic imageFile,
  ) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      // 1. Get task
      final task = await remoteDataSource.getTaskById(taskId);

      // 2. Upload image
      final uploadResult = await uploadTaskEvidence(taskId, imageFile);

      return await uploadResult.fold((failure) async => Left(failure), (
        imageUrl,
      ) async {
        // 3. Update task
        final updatedTask = TaskModel(
          id: task.id,
          title: task.title,
          description: task.description,
          chatRoomId: task.chatRoomId,
          assignedTo: task.assignedTo,
          assignedToName: task.assignedToName,
          dueDate: task.dueDate,
          priority: task.priority,
          status: TaskStatus.completed,
          category: task.category,
          createdAt: task.createdAt,
          createdBy: task.createdBy,
          evidenceImageUrl: imageUrl,
        );

        final result = await remoteDataSource.updateTask(updatedTask);

        // 4. Handle recurring task generation
        if (task.isRecurring && task.recurringPattern != null) {
          final nextDueDate = _getNextDueDate(
            task.dueDate,
            task.recurringPattern!,
          );
          final nextTask = TaskModel(
            id: '',
            title: task.title,
            description: task.description,
            chatRoomId: task.chatRoomId,
            assignedTo: task.assignedTo,
            assignedToName: task.assignedToName,
            dueDate: nextDueDate,
            priority: task.priority,
            status: TaskStatus.pending,
            category: task.category,
            createdAt: DateTime.now(),
            createdBy: task.createdBy,
            isRecurring: true,
            recurringPattern: task.recurringPattern,
          );
          await remoteDataSource.createTask(nextTask);
        }

        return Right(result as Task);
      });
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  DateTime _getNextDueDate(DateTime current, String pattern) {
    switch (pattern.toLowerCase()) {
      case 'daily':
        return current.add(const Duration(days: 1));
      case 'weekly':
        return current.add(const Duration(days: 7));
      case 'monthly':
        return DateTime(current.year, current.month + 1, current.day);
      default:
        return current.add(const Duration(days: 7));
    }
  }
}
