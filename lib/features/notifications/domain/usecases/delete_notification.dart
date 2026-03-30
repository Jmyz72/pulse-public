import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/notification_repository.dart';

class DeleteNotification implements UseCase<void, DeleteNotificationParams> {
  final NotificationRepository repository;

  DeleteNotification(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteNotificationParams params) {
    return repository.deleteNotification(params.id);
  }
}

class DeleteNotificationParams extends Equatable {
  final String id;

  const DeleteNotificationParams({required this.id});

  @override
  List<Object> get props => [id];
}
