import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/event_repository.dart';

class JoinEvent implements UseCase<void, JoinEventParams> {
  final EventRepository repository;

  JoinEvent(this.repository);

  @override
  Future<Either<Failure, void>> call(JoinEventParams params) {
    return repository.joinEvent(params.eventId, params.userId, params.userName);
  }
}

class JoinEventParams extends Equatable {
  final String eventId;
  final String userId;
  final String userName;

  const JoinEventParams({
    required this.eventId,
    required this.userId,
    required this.userName,
  });

  @override
  List<Object> get props => [eventId, userId, userName];
}
