import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/notification.dart';
import '../repositories/notification_repository.dart';

class GetNotifications implements UseCase<List<AppNotification>, NoParams> {
  final NotificationRepository repository;

  GetNotifications(this.repository);

  @override
  Future<Either<Failure, List<AppNotification>>> call(NoParams params) {
    return repository.getNotifications();
  }
}
