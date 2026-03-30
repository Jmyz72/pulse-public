import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_remote_datasource.dart';
import '../models/app_notification_model.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;
  final FirebaseAuth firebaseAuth;

  NotificationRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
    required this.firebaseAuth,
  });

  @override
  Future<Either<Failure, List<AppNotification>>> getNotifications() async {
    try {
      final user = firebaseAuth.currentUser;
      if (user == null) {
        return const Left(AuthFailure(message: 'User not authenticated'));
      }
      final notifications = await remoteDataSource.getNotifications(user.uid);
      return Right(notifications);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> markAsRead(String id) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      await remoteDataSource.markAsRead(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> markAllAsRead() async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final user = firebaseAuth.currentUser;
      if (user == null) {
        return const Left(AuthFailure(message: 'User not authenticated'));
      }
      await remoteDataSource.markAllAsRead(user.uid);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> deleteNotification(String id) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      await remoteDataSource.deleteNotification(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, int>> getUnreadCount() async {
    try {
      final user = firebaseAuth.currentUser;
      if (user == null) {
        return const Left(AuthFailure(message: 'User not authenticated'));
      }
      final count = await remoteDataSource.getUnreadCount(user.uid);
      return Right(count);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> sendNotification(AppNotification notification) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final model = AppNotificationModel.fromEntity(notification);
      await remoteDataSource.sendNotification(model);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }
}
