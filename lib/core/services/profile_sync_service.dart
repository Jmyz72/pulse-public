/// Abstract interface for syncing profile data across features.
///
/// This allows the auth feature to trigger profile sync without
/// depending on specific feature implementations (like friends).
abstract class ProfileSyncService {
  /// Syncs denormalized profile data when a user updates their profile.
  ///
  /// [userId] - The user whose profile was updated
  /// [displayName] - Updated display name
  /// [username] - User's username (immutable, included for completeness)
  /// [phone] - Updated phone number
  /// [photoUrl] - Updated profile photo URL
  Future<void> syncProfile(
    String userId,
    String displayName,
    String username,
    String phone,
    String? photoUrl,
  );
}
