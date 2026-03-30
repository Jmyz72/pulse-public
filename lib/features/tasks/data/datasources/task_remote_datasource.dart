import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_collections.dart';
import '../../../../core/error/exceptions.dart';
import '../models/task_model.dart';

abstract class TaskRemoteDataSource {
  Future<List<TaskModel>> getTasks(List<String> chatRoomIds);
  Future<TaskModel> getTaskById(String id);
  Future<TaskModel> createTask(TaskModel task);
  Future<TaskModel> updateTask(TaskModel task);
  Future<void> deleteTask(String id);
  Future<List<TaskModel>> getTasksByChatRoom(String chatRoomId);
}

class TaskRemoteDataSourceImpl implements TaskRemoteDataSource {
  final FirebaseFirestore firestore;

  TaskRemoteDataSourceImpl({required this.firestore});

  @override
  Future<List<TaskModel>> getTasks(List<String> chatRoomIds) async {
    try {
      if (chatRoomIds.isEmpty) {
        return [];
      }

      final List<TaskModel> allTasks = [];

      // Firestore whereIn limit is 30, batch if needed
      for (var i = 0; i < chatRoomIds.length; i += 30) {
        final batch = chatRoomIds.skip(i).take(30).toList();
        final snapshot = await firestore
            .collection(FirestoreCollections.tasks)
            .where('chatRoomId', whereIn: batch)
            .orderBy('dueDate')
            .get();

        allTasks.addAll(snapshot.docs
            .map((doc) => TaskModel.fromJson({'id': doc.id, ...doc.data()})));
      }

      // Sort by due date after combining batches
      allTasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));
      return allTasks;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<TaskModel> getTaskById(String id) async {
    try {
      final doc = await firestore.collection(FirestoreCollections.tasks).doc(id).get();
      if (!doc.exists) {
        throw const ServerException(message: 'Task not found');
      }
      return TaskModel.fromJson({'id': doc.id, ...doc.data()!});
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<TaskModel> createTask(TaskModel task) async {
    try {
      final data = task.toJson();
      data.remove('id');
      final docRef = await firestore.collection(FirestoreCollections.tasks).add(data);
      return TaskModel.fromJson({'id': docRef.id, ...data});
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<TaskModel> updateTask(TaskModel task) async {
    try {
      final data = task.toJson();
      data.remove('id');
      await firestore.collection(FirestoreCollections.tasks).doc(task.id).update(data);
      return task;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> deleteTask(String id) async {
    try {
      await firestore.collection(FirestoreCollections.tasks).doc(id).delete();
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<TaskModel>> getTasksByChatRoom(String chatRoomId) async {
    try {
      final snapshot = await firestore
          .collection(FirestoreCollections.tasks)
          .where('chatRoomId', isEqualTo: chatRoomId)
          .orderBy('dueDate')
          .get();

      return snapshot.docs
          .map((doc) => TaskModel.fromJson({'id': doc.id, ...doc.data()}))
          .toList();
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }
}
