import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_local_datasource.dart';
import '../datasources/settings_remote_datasource.dart';
import '../models/user_settings_model.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsRemoteDataSource remoteDataSource;
  final SettingsLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  SettingsRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, UserSettings>> getSettings(String userId) async {
    if (userId.isEmpty) {
      return const Left(AuthFailure(message: 'User not authenticated'));
    }

    if (await networkInfo.isConnected) {
      try {
        final settings = await remoteDataSource.getSettings(userId);
        try {
          await localDataSource.cacheSettings(settings);
        } on CacheException catch (_) {
          // Cache failure is non-fatal; continue with remote data
        }
        return Right(settings);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      try {
        final cachedSettings = await localDataSource.getCachedSettings();
        if (cachedSettings != null) {
          return Right(cachedSettings);
        }
        return const Left(CacheFailure(message: 'No cached settings available'));
      } on CacheException catch (e) {
        return Left(CacheFailure(message: e.message));
      }
    }
  }

  @override
  Future<Either<Failure, void>> updateSettings(String userId, UserSettings settings) async {
    if (userId.isEmpty) {
      return const Left(AuthFailure(message: 'User not authenticated'));
    }
    if (userId != settings.userId) {
      return const Left(AuthFailure(message: 'Cannot update another user\'s settings'));
    }
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final model = UserSettingsModel.fromEntity(settings);
      await remoteDataSource.updateSettings(model);
      try {
        await localDataSource.cacheSettings(model);
      } on CacheException catch (_) {
        // Cache failure is non-fatal; remote update succeeded
      }
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> updatePrivacySetting(String userId, String key, bool value) async {
    if (userId.isEmpty) {
      return const Left(AuthFailure(message: 'User not authenticated'));
    }
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      await remoteDataSource.updatePrivacySetting(userId, key, value);
      try {
        final cached = await localDataSource.getCachedSettings();
        if (cached != null) {
          final json = cached.toJson();
          json[key] = value;
          final updatedModel = UserSettingsModel.fromJson(json);
          await localDataSource.cacheSettings(updatedModel);
        }
      } on CacheException catch (_) {
        // Cache update failure is non-fatal
      }
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> clearCache() async {
    try {
      await localDataSource.clearCache();
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }
}
