import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/event_repository.dart';

class DeleteEvent implements UseCase<void, DeleteEventParams> {
  final EventRepository repository;

  DeleteEvent(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteEventParams params) {
    return repository.deleteEvent(params.eventId);
  }
}

class DeleteEventParams extends Equatable {
  final String eventId;

  const DeleteEventParams({
    required this.eventId,
  });

  @override
  List<Object> get props => [eventId];
}
