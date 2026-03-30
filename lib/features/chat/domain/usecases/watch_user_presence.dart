import '../repositories/presence_repository.dart';

class WatchUserPresence {
  final PresenceRepository repository;

  WatchUserPresence(this.repository);

  Stream<Map<String, bool>> call(List<String> userIds) {
    return repository.watchPresence(userIds);
  }
}
