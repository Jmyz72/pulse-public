import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/error/exceptions.dart';
import '../models/user_settings_model.dart';

abstract class SettingsLocalDataSource {
  Future<UserSettingsModel?> getCachedSettings();
  Future<void> cacheSettings(UserSettingsModel settings);
  Future<void> clearCache();
}

class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  final SharedPreferences sharedPreferences;
  static const String _settingsKey = 'CACHED_SETTINGS';

  SettingsLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<UserSettingsModel?> getCachedSettings() async {
    try {
      final jsonString = sharedPreferences.getString(_settingsKey);
      if (jsonString == null) return null;
      return UserSettingsModel.fromJson(json.decode(jsonString));
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<void> cacheSettings(UserSettingsModel settings) async {
    try {
      await sharedPreferences.setString(
        _settingsKey,
        json.encode(settings.toJson()),
      );
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      await sharedPreferences.remove(_settingsKey);
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }
}
