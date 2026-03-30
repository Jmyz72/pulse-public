import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/notification.dart';
import '../repositories/notification_repository.dart';

class SendNotification implements UseCase<void, SendNotificationParams> {
  final NotificationRepository repository;

  SendNotification(this.repository);

  @override
  Future<Either<Failure, void>> call(SendNotificationParams params) {
    return repository.sendNotification(params.notification);
  }
}

class SendNotificationParams extends Equatable {
  final AppNotification notification;

  const SendNotificationParams({required this.notification});

  @override
  List<Object> get props => [notification];
}
