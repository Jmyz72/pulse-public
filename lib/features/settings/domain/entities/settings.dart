import 'package:equatable/equatable.dart';

class UserSettings extends Equatable {
  final String userId;
  final bool showTimeline;
  final bool showProfile;
  final bool invisibleMode;
  final bool notificationsEnabled;
  final bool darkMode;
  final String language;
  final bool searchableByUsername;
  final bool searchableByEmail;
  final bool searchableByPhone;

  const UserSettings({
    required this.userId,
    this.showTimeline = true,
    this.showProfile = true,
    this.invisibleMode = false,
    this.notificationsEnabled = true,
    this.darkMode = false,
    this.language = 'en',
    this.searchableByUsername = true,
    this.searchableByEmail = true,
    this.searchableByPhone = true,
  });

  UserSettings copyWith({
    bool? showTimeline,
    bool? showProfile,
    bool? invisibleMode,
    bool? notificationsEnabled,
    bool? darkMode,
    String? language,
    bool? searchableByUsername,
    bool? searchableByEmail,
    bool? searchableByPhone,
  }) {
    return UserSettings(
      userId: userId,
      showTimeline: showTimeline ?? this.showTimeline,
      showProfile: showProfile ?? this.showProfile,
      invisibleMode: invisibleMode ?? this.invisibleMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      darkMode: darkMode ?? this.darkMode,
      language: language ?? this.language,
      searchableByUsername: searchableByUsername ?? this.searchableByUsername,
      searchableByEmail: searchableByEmail ?? this.searchableByEmail,
      searchableByPhone: searchableByPhone ?? this.searchableByPhone,
    );
  }

  @override
  List<Object?> get props => [userId, showTimeline, showProfile, invisibleMode, notificationsEnabled, darkMode, language, searchableByUsername, searchableByEmail, searchableByPhone];
}
