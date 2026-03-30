import '../repositories/presence_repository.dart';

class UpdatePresence {
  final PresenceRepository repository;

  UpdatePresence(this.repository);

  Future<void> call(String userId, bool online, {bool updateLastSeen = true}) {
    return repository.updatePresence(
      userId,
      online,
      updateLastSeen: updateLastSeen,
    );
  }
}
