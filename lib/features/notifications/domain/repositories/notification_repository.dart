import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/notification.dart';

abstract class NotificationRepository {
  Future<Either<Failure, List<AppNotification>>> getNotifications();
  Future<Either<Failure, void>> markAsRead(String id);
  Future<Either<Failure, void>> markAllAsRead();
  Future<Either<Failure, void>> deleteNotification(String id);
  Future<Either<Failure, int>> getUnreadCount();
  Future<Either<Failure, void>> sendNotification(AppNotification notification);
}
