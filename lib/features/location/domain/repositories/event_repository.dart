import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/event.dart';

abstract class EventRepository {
  Future<Either<Failure, Event>> createEvent(Event event);
  Stream<List<Event>> watchEvents(String userId);
  Future<Either<Failure, void>> joinEvent(
    String eventId,
    String userId,
    String userName,
  );
  Future<Either<Failure, void>> leaveEvent(String eventId, String userId);
  Future<Either<Failure, void>> deleteEvent(String eventId);
}
