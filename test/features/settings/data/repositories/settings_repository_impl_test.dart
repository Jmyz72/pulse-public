import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/exceptions.dart';
import 'package:pulse/core/error/failures.dart';
import 'package:pulse/core/network/network_info.dart';
import 'package:pulse/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:pulse/features/settings/data/datasources/settings_remote_datasource.dart';
import 'package:pulse/features/settings/data/models/user_settings_model.dart';
import 'package:pulse/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:pulse/features/settings/domain/entities/settings.dart';

class MockSettingsRemoteDataSource extends Mock implements SettingsRemoteDataSource {}

class MockSettingsLocalDataSource extends Mock implements SettingsLocalDataSource {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

void main() {
  late SettingsRepositoryImpl repository;
  late MockSettingsRemoteDataSource mockRemoteDataSource;
  late MockSettingsLocalDataSource mockLocalDataSource;
  late MockNetworkInfo mockNetworkInfo;

  setUp(() {
    mockRemoteDataSource = MockSettingsRemoteDataSource();
    mockLocalDataSource = MockSettingsLocalDataSource();
    mockNetworkInfo = MockNetworkInfo();
    repository = SettingsRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
      networkInfo: mockNetworkInfo,
    );
  });

  const tUserId = 'user-123';
  const tUserSettingsModel = UserSettingsModel(
    userId: tUserId,
    showTimeline: true,
    showProfile: true,
    invisibleMode: false,
    notificationsEnabled: true,
    darkMode: false,
    language: 'en',
    searchableByUsername: true,
    searchableByEmail: true,
    searchableByPhone: true,
  );
  const UserSettings tUserSettings = tUserSettingsModel;

  setUpAll(() {
    registerFallbackValue(tUserSettingsModel);
  });

  void setUpNetworkConnected() {
    when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
  }

  void setUpNetworkDisconnected() {
    when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
  }

  group('getSettings', () {
    test('should return AuthFailure when userId is empty', () async {
      // act
      final result = await repository.getSettings('');

      // assert
      expect(result, const Left(AuthFailure(message: 'User not authenticated')));
      verifyNever(() => mockNetworkInfo.isConnected);
    });

    test('should check if device is online', () async {
      // arrange
      setUpNetworkConnected();
      when(() => mockRemoteDataSource.getSettings(any()))
          .thenAnswer((_) async => tUserSettingsModel);
      when(() => mockLocalDataSource.cacheSettings(any()))
          .thenAnswer((_) async {});

      // act
      await repository.getSettings(tUserId);

      // assert
      verify(() => mockNetworkInfo.isConnected).called(1);
    });

    group('device is online', () {
      setUp(setUpNetworkConnected);

      test('should return remote settings and cache when successful', () async {
        // arrange
        when(() => mockRemoteDataSource.getSettings(tUserId))
            .thenAnswer((_) async => tUserSettingsModel);
        when(() => mockLocalDataSource.cacheSettings(any()))
            .thenAnswer((_) async {});

        // act
        final result = await repository.getSettings(tUserId);

        // assert
        expect(result, const Right(tUserSettings));
        verify(() => mockRemoteDataSource.getSettings(tUserId)).called(1);
        verify(() => mockLocalDataSource.cacheSettings(tUserSettingsModel)).called(1);
      });

      test('should return settings even when caching fails', () async {
        // arrange
        when(() => mockRemoteDataSource.getSettings(tUserId))
            .thenAnswer((_) async => tUserSettingsModel);
        when(() => mockLocalDataSource.cacheSettings(any()))
            .thenThrow(const CacheException(message: 'Cache error'));

        // act
        final result = await repository.getSettings(tUserId);

        // assert
        expect(result, const Right(tUserSettings));
        verify(() => mockRemoteDataSource.getSettings(tUserId)).called(1);
      });

      test('should return ServerFailure when remote throws ServerException', () async {
        // arrange
        when(() => mockRemoteDataSource.getSettings(tUserId))
            .thenThrow(const ServerException(message: 'Server error'));

        // act
        final result = await repository.getSettings(tUserId);

        // assert
        expect(result, const Left(ServerFailure(message: 'Server error')));
      });
    });

    group('device is offline', () {
      setUp(setUpNetworkDisconnected);

      test('should return cached settings when available', () async {
        // arrange
        when(() => mockLocalDataSource.getCachedSettings())
            .thenAnswer((_) async => tUserSettingsModel);

        // act
        final result = await repository.getSettings(tUserId);

        // assert
        expect(result, const Right(tUserSettings));
        verify(() => mockLocalDataSource.getCachedSettings()).called(1);
        verifyNever(() => mockRemoteDataSource.getSettings(any()));
      });

      test('should return CacheFailure when no cached settings available', () async {
        // arrange
        when(() => mockLocalDataSource.getCachedSettings())
            .thenAnswer((_) async => null);

        // act
        final result = await repository.getSettings(tUserId);

        // assert
        expect(result, const Left(CacheFailure(message: 'No cached settings available')));
      });

      test('should return CacheFailure when CacheException is thrown', () async {
        // arrange
        when(() => mockLocalDataSource.getCachedSettings())
            .thenThrow(const CacheException(message: 'Cache read error'));

        // act
        final result = await repository.getSettings(tUserId);

        // assert
        expect(result, const Left(CacheFailure(message: 'Cache read error')));
      });
    });
  });

  group('updateSettings', () {
    test('should return AuthFailure when userId is empty', () async {
      // act
      final result = await repository.updateSettings('', tUserSettings);

      // assert
      expect(result, const Left(AuthFailure(message: 'User not authenticated')));
    });

    test('should return AuthFailure when userId does not match settings userId', () async {
      // act
      final result = await repository.updateSettings('other-user', tUserSettings);

      // assert
      expect(result, const Left(AuthFailure(message: 'Cannot update another user\'s settings')));
    });

    test('should return NetworkFailure when device is offline', () async {
      // arrange
      setUpNetworkDisconnected();

      // act
      final result = await repository.updateSettings(tUserId, tUserSettings);

      // assert
      expect(result, const Left(NetworkFailure()));
    });

    test('should return void and cache when update is successful', () async {
      // arrange
      setUpNetworkConnected();
      when(() => mockRemoteDataSource.updateSettings(any()))
          .thenAnswer((_) async {});
      when(() => mockLocalDataSource.cacheSettings(any()))
          .thenAnswer((_) async {});

      // act
      final result = await repository.updateSettings(tUserId, tUserSettings);

      // assert
      expect(result, const Right(null));
      verify(() => mockRemoteDataSource.updateSettings(any())).called(1);
      verify(() => mockLocalDataSource.cacheSettings(any())).called(1);
    });

    test('should return success even when caching fails', () async {
      // arrange
      setUpNetworkConnected();
      when(() => mockRemoteDataSource.updateSettings(any()))
          .thenAnswer((_) async {});
      when(() => mockLocalDataSource.cacheSettings(any()))
          .thenThrow(const CacheException(message: 'Cache error'));

      // act
      final result = await repository.updateSettings(tUserId, tUserSettings);

      // assert
      expect(result, const Right(null));
    });

    test('should return ServerFailure when remote throws ServerException', () async {
      // arrange
      setUpNetworkConnected();
      when(() => mockRemoteDataSource.updateSettings(any()))
          .thenThrow(const ServerException(message: 'Update failed'));

      // act
      final result = await repository.updateSettings(tUserId, tUserSettings);

      // assert
      expect(result, const Left(ServerFailure(message: 'Update failed')));
    });
  });

  group('updatePrivacySetting', () {
    const tKey = 'showTimeline';
    const tValue = false;

    test('should return AuthFailure when userId is empty', () async {
      // act
      final result = await repository.updatePrivacySetting('', tKey, tValue);

      // assert
      expect(result, const Left(AuthFailure(message: 'User not authenticated')));
    });

    test('should return NetworkFailure when device is offline', () async {
      // arrange
      setUpNetworkDisconnected();

      // act
      final result = await repository.updatePrivacySetting(tUserId, tKey, tValue);

      // assert
      expect(result, const Left(NetworkFailure()));
    });

    test('should return void when update is successful', () async {
      // arrange
      setUpNetworkConnected();
      when(() => mockRemoteDataSource.updatePrivacySetting(tUserId, tKey, tValue))
          .thenAnswer((_) async {});
      when(() => mockLocalDataSource.getCachedSettings())
          .thenAnswer((_) async => tUserSettingsModel);
      when(() => mockLocalDataSource.cacheSettings(any()))
          .thenAnswer((_) async {});

      // act
      final result = await repository.updatePrivacySetting(tUserId, tKey, tValue);

      // assert
      expect(result, const Right(null));
      verify(() => mockRemoteDataSource.updatePrivacySetting(tUserId, tKey, tValue)).called(1);
    });

    test('should update cached settings when available', () async {
      // arrange
      setUpNetworkConnected();
      when(() => mockRemoteDataSource.updatePrivacySetting(tUserId, tKey, tValue))
          .thenAnswer((_) async {});
      when(() => mockLocalDataSource.getCachedSettings())
          .thenAnswer((_) async => tUserSettingsModel);
      when(() => mockLocalDataSource.cacheSettings(any()))
          .thenAnswer((_) async {});

      // act
      await repository.updatePrivacySetting(tUserId, tKey, tValue);

      // assert
      verify(() => mockLocalDataSource.getCachedSettings()).called(1);
      verify(() => mockLocalDataSource.cacheSettings(any())).called(1);
    });

    test('should succeed even when no cached settings exist', () async {
      // arrange
      setUpNetworkConnected();
      when(() => mockRemoteDataSource.updatePrivacySetting(tUserId, tKey, tValue))
          .thenAnswer((_) async {});
      when(() => mockLocalDataSource.getCachedSettings())
          .thenAnswer((_) async => null);

      // act
      final result = await repository.updatePrivacySetting(tUserId, tKey, tValue);

      // assert
      expect(result, const Right(null));
      verifyNever(() => mockLocalDataSource.cacheSettings(any()));
    });

    test('should succeed even when cache update fails', () async {
      // arrange
      setUpNetworkConnected();
      when(() => mockRemoteDataSource.updatePrivacySetting(tUserId, tKey, tValue))
          .thenAnswer((_) async {});
      when(() => mockLocalDataSource.getCachedSettings())
          .thenThrow(const CacheException(message: 'Cache error'));

      // act
      final result = await repository.updatePrivacySetting(tUserId, tKey, tValue);

      // assert
      expect(result, const Right(null));
    });

    test('should return ServerFailure when remote throws ServerException', () async {
      // arrange
      setUpNetworkConnected();
      when(() => mockRemoteDataSource.updatePrivacySetting(tUserId, tKey, tValue))
          .thenThrow(const ServerException(message: 'Invalid setting key'));

      // act
      final result = await repository.updatePrivacySetting(tUserId, tKey, tValue);

      // assert
      expect(result, const Left(ServerFailure(message: 'Invalid setting key')));
    });
  });

  group('clearCache', () {
    test('should return void when clearCache is successful', () async {
      // arrange
      when(() => mockLocalDataSource.clearCache())
          .thenAnswer((_) async {});

      // act
      final result = await repository.clearCache();

      // assert
      expect(result, const Right(null));
      verify(() => mockLocalDataSource.clearCache()).called(1);
    });

    test('should return CacheFailure when clearCache throws CacheException', () async {
      // arrange
      when(() => mockLocalDataSource.clearCache())
          .thenThrow(const CacheException(message: 'Failed to clear cache'));

      // act
      final result = await repository.clearCache();

      // assert
      expect(result, const Left(CacheFailure(message: 'Failed to clear cache')));
    });
  });
}
