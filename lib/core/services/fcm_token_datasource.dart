/// Abstract interface for FCM token persistence.
/// Lives in core/services to avoid coupling core services to feature data layers.
abstract class FcmTokenDataSource {
  Future<void> saveToken(String userId, String token);
  Future<void> deleteToken(String userId);
}
