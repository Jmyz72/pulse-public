import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_collections.dart';
import '../../../../core/error/exceptions.dart';
import '../models/user_settings_model.dart';

abstract class SettingsRemoteDataSource {
  Future<UserSettingsModel> getSettings(String userId);
  Future<void> updateSettings(UserSettingsModel settings);
  Future<void> updatePrivacySetting(String userId, String key, bool value);
  Future<void> updateSearchSetting(String userId, String key, bool value);
}

class SettingsRemoteDataSourceImpl implements SettingsRemoteDataSource {
  final FirebaseFirestore firestore;

  SettingsRemoteDataSourceImpl({required this.firestore});

  @override
  Future<UserSettingsModel> getSettings(String userId) async {
    try {
      final settingsDoc = await firestore.collection(FirestoreCollections.userSettings).doc(userId).get();
      final searchDoc = await firestore.collection(FirestoreCollections.userSearchSettings).doc(userId).get();

      if (!settingsDoc.exists) {
        final defaults = UserSettingsModel(userId: userId);
        // Write only non-search settings to user_settings
        final settingsJson = defaults.toJson()
          ..remove('searchableByUsername')
          ..remove('searchableByEmail')
          ..remove('searchableByPhone');
        await firestore
            .collection(FirestoreCollections.userSettings)
            .doc(userId)
            .set(settingsJson);
        await firestore
            .collection(FirestoreCollections.userSearchSettings)
            .doc(userId)
            .set({
          'searchableByUsername': defaults.searchableByUsername,
          'searchableByEmail': defaults.searchableByEmail,
          'searchableByPhone': defaults.searchableByPhone,
        });
        return defaults;
      }

      // Merge search settings into the main settings
      final settingsData = {'userId': userId, ...settingsDoc.data()!};
      if (searchDoc.exists) {
        settingsData.addAll(searchDoc.data()!);
      }

      return UserSettingsModel.fromJson(settingsData);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> updateSettings(UserSettingsModel settings) async {
    try {
      // Write only non-search settings to user_settings
      final settingsJson = settings.toJson()
        ..remove('searchableByUsername')
        ..remove('searchableByEmail')
        ..remove('searchableByPhone');
      await firestore
          .collection(FirestoreCollections.userSettings)
          .doc(settings.userId)
          .set(settingsJson, SetOptions(merge: true));
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  static const _allowedKeys = {
    'showTimeline',
    'showProfile',
    'invisibleMode',
    'notificationsEnabled',
    'darkMode',
    'language',
    'searchableByUsername',
    'searchableByEmail',
    'searchableByPhone',
  };

  static const _searchKeys = {
    'searchableByUsername',
    'searchableByEmail',
    'searchableByPhone',
  };

  @override
  Future<void> updatePrivacySetting(String userId, String key, bool value) async {
    if (!_allowedKeys.contains(key)) {
      throw ServerException(message: 'Invalid setting key: $key');
    }

    // Route searchability keys to the separate collection
    if (_searchKeys.contains(key)) {
      return updateSearchSetting(userId, key, value);
    }

    try {
      await firestore
          .collection(FirestoreCollections.userSettings)
          .doc(userId)
          .set({key: value}, SetOptions(merge: true));
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> updateSearchSetting(String userId, String key, bool value) async {
    if (!_searchKeys.contains(key)) {
      throw ServerException(message: 'Invalid search setting key: $key');
    }
    try {
      await firestore
          .collection(FirestoreCollections.userSearchSettings)
          .doc(userId)
          .set({key: value}, SetOptions(merge: true));
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }
}
