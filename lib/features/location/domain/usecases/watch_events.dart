import '../entities/event.dart';
import '../repositories/event_repository.dart';

class WatchEvents {
  final EventRepository repository;

  WatchEvents(this.repository);

  Stream<List<Event>> call(String userId) {
    return repository.watchEvents(userId);
  }
}
