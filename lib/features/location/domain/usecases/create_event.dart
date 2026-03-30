import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/event.dart';
import '../repositories/event_repository.dart';

class CreateEvent implements UseCase<Event, CreateEventParams> {
  final EventRepository repository;

  CreateEvent(this.repository);

  @override
  Future<Either<Failure, Event>> call(CreateEventParams params) {
    return repository.createEvent(params.event);
  }
}

class CreateEventParams extends Equatable {
  final Event event;

  const CreateEventParams({required this.event});

  @override
  List<Object> get props => [event];
}
