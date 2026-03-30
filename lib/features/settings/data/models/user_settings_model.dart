import '../../domain/entities/settings.dart';

class UserSettingsModel extends UserSettings {
  const UserSettingsModel({
    required super.userId,
    super.showTimeline,
    super.showProfile,
    super.invisibleMode,
    super.notificationsEnabled,
    super.darkMode,
    super.language,
    super.searchableByUsername,
    super.searchableByEmail,
    super.searchableByPhone,
  });

  factory UserSettingsModel.fromJson(Map<String, dynamic> json) {
    return UserSettingsModel(
      userId: json['userId'] ?? '',
      showTimeline: json['showTimeline'] ?? true,
      showProfile: json['showProfile'] ?? true,
      invisibleMode: json['invisibleMode'] ?? false,
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      darkMode: json['darkMode'] ?? false,
      language: json['language'] ?? 'en',
      searchableByUsername: json['searchableByUsername'] ?? true,
      searchableByEmail: json['searchableByEmail'] ?? true,
      searchableByPhone: json['searchableByPhone'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'showTimeline': showTimeline,
      'showProfile': showProfile,
      'invisibleMode': invisibleMode,
      'notificationsEnabled': notificationsEnabled,
      'darkMode': darkMode,
      'language': language,
      'searchableByUsername': searchableByUsername,
      'searchableByEmail': searchableByEmail,
      'searchableByPhone': searchableByPhone,
    };
  }

  factory UserSettingsModel.fromEntity(UserSettings settings) {
    return UserSettingsModel(
      userId: settings.userId,
      showTimeline: settings.showTimeline,
      showProfile: settings.showProfile,
      invisibleMode: settings.invisibleMode,
      notificationsEnabled: settings.notificationsEnabled,
      darkMode: settings.darkMode,
      language: settings.language,
      searchableByUsername: settings.searchableByUsername,
      searchableByEmail: settings.searchableByEmail,
      searchableByPhone: settings.searchableByPhone,
    );
  }
}
