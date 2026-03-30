import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_collections.dart';
import '../../../../core/error/exceptions.dart';
import '../models/app_notification_model.dart';

abstract class NotificationRemoteDataSource {
  Future<List<AppNotificationModel>> getNotifications(String userId);
  Future<void> markAsRead(String id);
  Future<void> markAllAsRead(String userId);
  Future<void> deleteNotification(String id);
  Future<int> getUnreadCount(String userId);
  Future<void> sendNotification(AppNotificationModel notification);
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final FirebaseFirestore firestore;

  NotificationRemoteDataSourceImpl({required this.firestore});

  @override
  Future<List<AppNotificationModel>> getNotifications(String userId) async {
    try {
      final snapshot = await firestore
          .collection(FirestoreCollections.notifications)
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(100)
          .get();

      return snapshot.docs
          .map((doc) => AppNotificationModel.fromJson({'id': doc.id, ...doc.data()}))
          .toList();
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> markAsRead(String id) async {
    try {
      await firestore
          .collection(FirestoreCollections.notifications)
          .doc(id)
          .update({'isRead': true});
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    try {
      final snapshot = await firestore
          .collection(FirestoreCollections.notifications)
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      // Chunk into batches of 500 (Firestore batch limit)
      const batchSize = 500;
      for (var i = 0; i < snapshot.docs.length; i += batchSize) {
        final batch = firestore.batch();
        final end = (i + batchSize < snapshot.docs.length) ? i + batchSize : snapshot.docs.length;
        for (var j = i; j < end; j++) {
          batch.update(snapshot.docs[j].reference, {'isRead': true});
        }
        await batch.commit();
      }
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> deleteNotification(String id) async {
    try {
      await firestore.collection(FirestoreCollections.notifications).doc(id).delete();
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<int> getUnreadCount(String userId) async {
    try {
      final snapshot = await firestore
          .collection(FirestoreCollections.notifications)
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> sendNotification(AppNotificationModel notification) async {
    try {
      await firestore
          .collection(FirestoreCollections.notifications)
          .add(notification.toJson());
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }
}
