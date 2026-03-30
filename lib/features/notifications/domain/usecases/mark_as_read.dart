import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/notification_repository.dart';

class MarkAsRead implements UseCase<void, MarkAsReadParams> {
  final NotificationRepository repository;

  MarkAsRead(this.repository);

  @override
  Future<Either<Failure, void>> call(MarkAsReadParams params) {
    return repository.markAsRead(params.id);
  }
}

class MarkAsReadParams extends Equatable {
  final String id;

  const MarkAsReadParams({required this.id});

  @override
  List<Object> get props => [id];
}
