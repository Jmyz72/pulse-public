/// Domain-level contract for presence operations.
/// Implemented by PresenceDataSourceImpl in the data layer.
abstract class PresenceRepository {
  Future<void> updatePresence(
    String userId,
    bool online, {
    bool updateLastSeen = true,
  });
  Stream<Map<String, bool>> watchPresence(List<String> userIds);
}
