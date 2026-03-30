import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/constants/storage_keys.dart';
import '../../../../core/error/exceptions.dart';
import '../models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<UserModel?> getCachedUser();
  Future<void> cacheUser(UserModel user);
  Future<void> cachePendingEmailLinkEmail(String email);
  Future<String?> getPendingEmailLinkEmail();
  Future<void> clearPendingEmailLinkEmail();
  Future<void> clearCache();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final FlutterSecureStorage secureStorage;

  AuthLocalDataSourceImpl({required this.secureStorage});

  @override
  Future<UserModel?> getCachedUser() async {
    final jsonString = await secureStorage.read(key: StorageKeys.cachedUser);
    if (jsonString == null) return null;

    try {
      return UserModel.fromJson(json.decode(jsonString));
    } catch (e) {
      developer.log(
        'Failed to parse cached user',
        error: e,
        name: 'AuthLocalDataSource',
      );
      throw const CacheException(message: 'Failed to parse cached user');
    }
  }

  @override
  Future<void> cacheUser(UserModel user) async {
    try {
      await secureStorage.write(
        key: StorageKeys.cachedUser,
        value: json.encode(user.toJson()),
      );
    } catch (e) {
      developer.log(
        'Failed to cache user',
        error: e,
        name: 'AuthLocalDataSource',
      );
      throw const CacheException(message: 'Failed to cache user');
    }
  }

  @override
  Future<void> cachePendingEmailLinkEmail(String email) async {
    try {
      await secureStorage.write(
        key: StorageKeys.pendingEmailLinkEmail,
        value: email.trim().toLowerCase(),
      );
    } catch (e) {
      developer.log(
        'Failed to cache pending email-link email',
        error: e,
        name: 'AuthLocalDataSource',
      );
      throw const CacheException(
        message: 'Failed to cache pending email-link email',
      );
    }
  }

  @override
  Future<String?> getPendingEmailLinkEmail() async {
    return secureStorage.read(key: StorageKeys.pendingEmailLinkEmail);
  }

  @override
  Future<void> clearPendingEmailLinkEmail() async {
    try {
      await secureStorage.delete(key: StorageKeys.pendingEmailLinkEmail);
    } catch (e) {
      developer.log(
        'Failed to clear pending email-link email',
        error: e,
        name: 'AuthLocalDataSource',
      );
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      await secureStorage.delete(key: StorageKeys.cachedUser);
      await secureStorage.delete(key: StorageKeys.pendingEmailLinkEmail);
    } catch (e) {
      developer.log(
        'Failed to clear cache',
        error: e,
        name: 'AuthLocalDataSource',
      );
    }
  }
}
