import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/event_repository.dart';

class LeaveEvent implements UseCase<void, LeaveEventParams> {
  final EventRepository repository;

  LeaveEvent(this.repository);

  @override
  Future<Either<Failure, void>> call(LeaveEventParams params) {
    return repository.leaveEvent(params.eventId, params.userId);
  }
}

class LeaveEventParams extends Equatable {
  final String eventId;
  final String userId;

  const LeaveEventParams({
    required this.eventId,
    required this.userId,
  });

  @override
  List<Object> get props => [eventId, userId];
}
