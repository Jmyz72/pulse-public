import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/exceptions.dart';
import 'package:pulse/core/error/failures.dart';
import 'package:pulse/core/network/network_info.dart';
import 'package:pulse/core/services/profile_sync_service.dart';
import 'package:pulse/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:pulse/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:pulse/features/auth/data/models/password_policy_validation_model.dart';
import 'package:pulse/features/auth/data/models/user_model.dart';
import 'package:pulse/features/auth/data/repositories/auth_repository_impl.dart';

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

class MockAuthLocalDataSource extends Mock implements AuthLocalDataSource {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

class MockProfileSyncService extends Mock implements ProfileSyncService {}

void main() {
  late AuthRepositoryImpl repository;
  late MockAuthRemoteDataSource mockRemoteDataSource;
  late MockAuthLocalDataSource mockLocalDataSource;
  late MockNetworkInfo mockNetworkInfo;
  late MockProfileSyncService mockProfileSyncService;

  setUp(() {
    mockRemoteDataSource = MockAuthRemoteDataSource();
    mockLocalDataSource = MockAuthLocalDataSource();
    mockNetworkInfo = MockNetworkInfo();
    mockProfileSyncService = MockProfileSyncService();
    repository = AuthRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
      networkInfo: mockNetworkInfo,
      profileSyncService: mockProfileSyncService,
    );
  });

  const tEmail = 'test@example.com';
  const tPassword = 'Password123!';
  const tUsername = 'testuser';
  const tDisplayName = 'Test User';
  const tPhone = '+1234567890';
  const tPasswordValidation = PasswordPolicyValidationModel(
    isValid: true,
    minPasswordLength: 8,
    maxPasswordLength: 4096,
    requiresLowercase: true,
    requiresUppercase: true,
    requiresDigits: true,
    requiresSymbols: true,
    meetsMinPasswordLength: true,
    meetsMaxPasswordLength: true,
    meetsLowercaseRequirement: true,
    meetsUppercaseRequirement: true,
    meetsDigitsRequirement: true,
    meetsSymbolsRequirement: true,
  );

  final tUserModel = UserModel(
    id: '1',
    username: tUsername,
    displayName: tDisplayName,
    email: tEmail,
    phone: '',
    dateJoining: DateTime(2024, 1, 1),
  );

  const tUserModelWithoutDate = UserModel(
    id: '1',
    username: tUsername,
    displayName: tDisplayName,
    email: tEmail,
    phone: '',
  );

  setUpAll(() {
    registerFallbackValue(tUserModel);
  });

  void setUpNetworkConnected() {
    when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
  }

  void setUpNetworkDisconnected() {
    when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
  }

  group('signInWithEmail', () {
    test('should check if device is online', () async {
      // arrange
      setUpNetworkConnected();
      when(
        () => mockRemoteDataSource.signInWithEmail(any(), any()),
      ).thenAnswer((_) async => tUserModel);
      when(() => mockLocalDataSource.cacheUser(any())).thenAnswer((_) async {});

      // act
      await repository.signInWithEmail(tEmail, tPassword);

      // assert
      verify(() => mockNetworkInfo.isConnected).called(1);
    });

    test('should return NetworkFailure when device is offline', () async {
      // arrange
      setUpNetworkDisconnected();

      // act
      final result = await repository.signInWithEmail(tEmail, tPassword);

      // assert
      expect(result, const Left(NetworkFailure()));
      verifyNever(() => mockRemoteDataSource.signInWithEmail(any(), any()));
    });

    test('should return User and cache when sign in is successful', () async {
      // arrange
      setUpNetworkConnected();
      when(
        () => mockRemoteDataSource.signInWithEmail(tEmail, tPassword),
      ).thenAnswer((_) async => tUserModel);
      when(() => mockLocalDataSource.cacheUser(any())).thenAnswer((_) async {});

      // act
      final result = await repository.signInWithEmail(tEmail, tPassword);

      // assert
      expect(result, Right(tUserModel));
      verify(
        () => mockRemoteDataSource.signInWithEmail(tEmail, tPassword),
      ).called(1);
      verify(() => mockLocalDataSource.cacheUser(tUserModel)).called(1);
    });

    test('should not cache user when dateJoining is null', () async {
      // arrange
      setUpNetworkConnected();
      when(
        () => mockRemoteDataSource.signInWithEmail(tEmail, tPassword),
      ).thenAnswer((_) async => tUserModelWithoutDate);

      // act
      final result = await repository.signInWithEmail(tEmail, tPassword);

      // assert
      expect(result, const Right(tUserModelWithoutDate));
      verifyNever(() => mockLocalDataSource.cacheUser(any()));
    });

    test('should return AuthFailure when AuthException is thrown', () async {
      // arrange
      setUpNetworkConnected();
      when(
        () => mockRemoteDataSource.signInWithEmail(tEmail, tPassword),
      ).thenThrow(const AuthException(message: 'Invalid credentials'));

      // act
      final result = await repository.signInWithEmail(tEmail, tPassword);

      // assert
      expect(result, const Left(AuthFailure(message: 'Invalid credentials')));
    });

    test(
      'should return ServerFailure when ServerException is thrown',
      () async {
        // arrange
        setUpNetworkConnected();
        when(
          () => mockRemoteDataSource.signInWithEmail(tEmail, tPassword),
        ).thenThrow(const ServerException(message: 'Server error'));

        // act
        final result = await repository.signInWithEmail(tEmail, tPassword);

        // assert
        expect(result, const Left(ServerFailure(message: 'Server error')));
      },
    );

    test(
      'should return ServerFailure when unexpected exception is thrown',
      () async {
        // arrange
        setUpNetworkConnected();
        when(
          () => mockRemoteDataSource.signInWithEmail(tEmail, tPassword),
        ).thenThrow(Exception('Unexpected'));

        // act
        final result = await repository.signInWithEmail(tEmail, tPassword);

        // assert
        expect(result, const Left(ServerFailure()));
      },
    );
  });

  group('registerWithEmail', () {
    test('should return NetworkFailure when device is offline', () async {
      // arrange
      setUpNetworkDisconnected();

      // act
      final result = await repository.registerWithEmail(
        tEmail,
        tPassword,
        tUsername,
        tDisplayName,
      );

      // assert
      expect(result, const Left(NetworkFailure()));
    });

    test('should return User when registration is successful', () async {
      // arrange
      setUpNetworkConnected();
      when(
        () => mockRemoteDataSource.registerWithEmail(
          tEmail,
          tPassword,
          tUsername,
          tDisplayName,
        ),
      ).thenAnswer((_) async => tUserModel);

      // act
      final result = await repository.registerWithEmail(
        tEmail,
        tPassword,
        tUsername,
        tDisplayName,
      );

      // assert
      expect(result, Right(tUserModel));
      verify(
        () => mockRemoteDataSource.registerWithEmail(
          tEmail,
          tPassword,
          tUsername,
          tDisplayName,
        ),
      ).called(1);
    });

    test('should return AuthFailure when AuthException is thrown', () async {
      // arrange
      setUpNetworkConnected();
      when(
        () => mockRemoteDataSource.registerWithEmail(
          tEmail,
          tPassword,
          tUsername,
          tDisplayName,
        ),
      ).thenThrow(const AuthException(message: 'Email already in use'));

      // act
      final result = await repository.registerWithEmail(
        tEmail,
        tPassword,
        tUsername,
        tDisplayName,
      );

      // assert
      expect(result, const Left(AuthFailure(message: 'Email already in use')));
    });

    test(
      'should return ServerFailure when ServerException is thrown',
      () async {
        // arrange
        setUpNetworkConnected();
        when(
          () => mockRemoteDataSource.registerWithEmail(
            tEmail,
            tPassword,
            tUsername,
            tDisplayName,
          ),
        ).thenThrow(const ServerException(message: 'Server error'));

        // act
        final result = await repository.registerWithEmail(
          tEmail,
          tPassword,
          tUsername,
          tDisplayName,
        );

        // assert
        expect(result, const Left(ServerFailure(message: 'Server error')));
      },
    );
  });

  group('completeGoogleOnboarding', () {
    test('should return NetworkFailure when device is offline', () async {
      setUpNetworkDisconnected();

      final result = await repository.completeGoogleOnboarding(
        tUsername,
        password: tPassword,
      );

      expect(result, const Left(NetworkFailure()));
      verifyNever(
        () => mockRemoteDataSource.completeGoogleOnboarding(
          any(),
          password: any(named: 'password'),
        ),
      );
    });

    test(
      'should forward optional password, return user, and cache on success',
      () async {
        setUpNetworkConnected();
        when(
          () => mockRemoteDataSource.completeGoogleOnboarding(
            tUsername,
            password: tPassword,
          ),
        ).thenAnswer((_) async => tUserModel);
        when(
          () => mockLocalDataSource.cacheUser(any()),
        ).thenAnswer((_) async {});

        final result = await repository.completeGoogleOnboarding(
          tUsername,
          password: tPassword,
        );

        expect(result, Right(tUserModel));
        verify(
          () => mockRemoteDataSource.completeGoogleOnboarding(
            tUsername,
            password: tPassword,
          ),
        ).called(1);
        verify(() => mockLocalDataSource.cacheUser(any())).called(1);
      },
    );

    test('should return AuthFailure when AuthException is thrown', () async {
      setUpNetworkConnected();
      when(
        () => mockRemoteDataSource.completeGoogleOnboarding(
          tUsername,
          password: tPassword,
        ),
      ).thenThrow(const AuthException(message: 'Weak password'));

      final result = await repository.completeGoogleOnboarding(
        tUsername,
        password: tPassword,
      );

      expect(result, const Left(AuthFailure(message: 'Weak password')));
    });
  });

  group('resetPassword', () {
    test('should return NetworkFailure when device is offline', () async {
      // arrange
      setUpNetworkDisconnected();

      // act
      final result = await repository.resetPassword(tEmail);

      // assert
      expect(result, const Left(NetworkFailure()));
    });

    test('should return void when resetPassword is successful', () async {
      // arrange
      setUpNetworkConnected();
      when(
        () => mockRemoteDataSource.resetPassword(tEmail),
      ).thenAnswer((_) async {});

      // act
      final result = await repository.resetPassword(tEmail);

      // assert
      expect(result, const Right(null));
      verify(() => mockRemoteDataSource.resetPassword(tEmail)).called(1);
    });

    test('should return AuthFailure when AuthException is thrown', () async {
      // arrange
      setUpNetworkConnected();
      when(
        () => mockRemoteDataSource.resetPassword(tEmail),
      ).thenThrow(const AuthException(message: 'User not found'));

      // act
      final result = await repository.resetPassword(tEmail);

      // assert
      expect(result, const Left(AuthFailure(message: 'User not found')));
    });
  });

  group('validatePasswordPolicy', () {
    test('should return NetworkFailure when device is offline', () async {
      setUpNetworkDisconnected();

      final result = await repository.validatePasswordPolicy(tPassword);

      expect(result, const Left(NetworkFailure()));
      verifyNever(() => mockRemoteDataSource.validatePasswordPolicy(any()));
    });

    test('should return password validation when check succeeds', () async {
      setUpNetworkConnected();
      when(
        () => mockRemoteDataSource.validatePasswordPolicy(tPassword),
      ).thenAnswer((_) async => tPasswordValidation);

      final result = await repository.validatePasswordPolicy(tPassword);

      expect(result, const Right(tPasswordValidation));
      verify(
        () => mockRemoteDataSource.validatePasswordPolicy(tPassword),
      ).called(1);
    });

    test('should return AuthFailure when AuthException is thrown', () async {
      setUpNetworkConnected();
      when(
        () => mockRemoteDataSource.validatePasswordPolicy(tPassword),
      ).thenThrow(const AuthException(message: 'Password check failed'));

      final result = await repository.validatePasswordPolicy(tPassword);

      expect(result, const Left(AuthFailure(message: 'Password check failed')));
    });
  });

  group('signOut', () {
    test('should clear local cache and sign out remotely', () async {
      // arrange
      when(() => mockRemoteDataSource.signOut()).thenAnswer((_) async {});
      when(() => mockLocalDataSource.clearCache()).thenAnswer((_) async {});

      // act
      final result = await repository.signOut();

      // assert
      expect(result, const Right(null));
      verify(() => mockRemoteDataSource.signOut()).called(1);
      verify(() => mockLocalDataSource.clearCache()).called(1);
    });

    test('should still clear cache when remote sign out fails', () async {
      // arrange
      when(
        () => mockRemoteDataSource.signOut(),
      ).thenThrow(Exception('Remote error'));
      when(() => mockLocalDataSource.clearCache()).thenAnswer((_) async {});

      // act
      final result = await repository.signOut();

      // assert
      expect(
        result,
        const Left(
          ServerFailure(message: 'Failed to sign out. Please try again.'),
        ),
      );
      verify(() => mockLocalDataSource.clearCache()).called(1);
    });

    test('should return success even when cache clearing fails', () async {
      // arrange
      when(() => mockRemoteDataSource.signOut()).thenAnswer((_) async {});
      when(
        () => mockLocalDataSource.clearCache(),
      ).thenThrow(Exception('Cache error'));

      // act
      final result = await repository.signOut();

      // assert
      expect(result, const Right(null));
    });
  });

  group('getCurrentUser', () {
    test('should return cached user when device is offline', () async {
      // arrange
      setUpNetworkDisconnected();
      when(
        () => mockLocalDataSource.getCachedUser(),
      ).thenAnswer((_) async => tUserModel);

      // act
      final result = await repository.getCurrentUser();

      // assert
      expect(result, Right(tUserModel));
      verify(() => mockLocalDataSource.getCachedUser()).called(1);
      verifyNever(() => mockRemoteDataSource.getCurrentUser());
    });

    test('should return null when offline and no cached user', () async {
      // arrange
      setUpNetworkDisconnected();
      when(
        () => mockLocalDataSource.getCachedUser(),
      ).thenThrow(const CacheException(message: 'No cached user'));

      // act
      final result = await repository.getCurrentUser();

      // assert
      expect(result, const Right(null));
    });

    test('should return remote user and cache when online', () async {
      // arrange
      setUpNetworkConnected();
      when(
        () => mockRemoteDataSource.getCurrentUser(),
      ).thenAnswer((_) async => tUserModel);
      when(() => mockLocalDataSource.cacheUser(any())).thenAnswer((_) async {});

      // act
      final result = await repository.getCurrentUser();

      // assert
      expect(result, Right(tUserModel));
      verify(() => mockRemoteDataSource.getCurrentUser()).called(1);
      verify(() => mockLocalDataSource.cacheUser(tUserModel)).called(1);
    });

    test('should return null when remote returns null', () async {
      // arrange
      setUpNetworkConnected();
      when(
        () => mockRemoteDataSource.getCurrentUser(),
      ).thenAnswer((_) async => null);

      // act
      final result = await repository.getCurrentUser();

      // assert
      expect(result, const Right(null));
      verifyNever(() => mockLocalDataSource.cacheUser(any()));
    });

    test('should not cache when user has no dateJoining', () async {
      // arrange
      setUpNetworkConnected();
      when(
        () => mockRemoteDataSource.getCurrentUser(),
      ).thenAnswer((_) async => tUserModelWithoutDate);

      // act
      final result = await repository.getCurrentUser();

      // assert
      expect(result, const Right(tUserModelWithoutDate));
      verifyNever(() => mockLocalDataSource.cacheUser(any()));
    });

    test('should return AuthFailure when AuthException is thrown', () async {
      // arrange
      setUpNetworkConnected();
      when(
        () => mockRemoteDataSource.getCurrentUser(),
      ).thenThrow(const AuthException(message: 'Not authenticated'));

      // act
      final result = await repository.getCurrentUser();

      // assert
      expect(result, const Left(AuthFailure(message: 'Not authenticated')));
    });
  });

  group('checkUsernameAvailability', () {
    test('should return NetworkFailure when device is offline', () async {
      // arrange
      setUpNetworkDisconnected();

      // act
      final result = await repository.checkUsernameAvailability(tUsername);

      // assert
      expect(result, const Left(NetworkFailure()));
    });

    test('should return true when username is available', () async {
      // arrange
      setUpNetworkConnected();
      when(
        () => mockRemoteDataSource.checkUsernameAvailability(tUsername),
      ).thenAnswer((_) async => true);

      // act
      final result = await repository.checkUsernameAvailability(tUsername);

      // assert
      expect(result, const Right(true));
      verify(
        () => mockRemoteDataSource.checkUsernameAvailability(tUsername),
      ).called(1);
    });

    test('should return false when username is taken', () async {
      // arrange
      setUpNetworkConnected();
      when(
        () => mockRemoteDataSource.checkUsernameAvailability(tUsername),
      ).thenAnswer((_) async => false);

      // act
      final result = await repository.checkUsernameAvailability(tUsername);

      // assert
      expect(result, const Right(false));
    });

    test('should return AuthFailure when AuthException is thrown', () async {
      // arrange
      setUpNetworkConnected();
      when(
        () => mockRemoteDataSource.checkUsernameAvailability(tUsername),
      ).thenThrow(const AuthException(message: 'Auth error'));

      // act
      final result = await repository.checkUsernameAvailability(tUsername);

      // assert
      expect(result, const Left(AuthFailure(message: 'Auth error')));
    });

    test(
      'should return ServerFailure message when ServerException is thrown',
      () async {
        // arrange
        setUpNetworkConnected();
        when(
          () => mockRemoteDataSource.checkUsernameAvailability(tUsername),
        ).thenThrow(
          const ServerException(
            message: 'Unable to check username availability right now.',
          ),
        );

        // act
        final result = await repository.checkUsernameAvailability(tUsername);

        // assert
        expect(
          result,
          const Left(
            ServerFailure(
              message: 'Unable to check username availability right now.',
            ),
          ),
        );
      },
    );
  });

  group('checkPhoneAvailability', () {
    const tPhoneNumber = '+60123456789';

    test('should return NetworkFailure when device is offline', () async {
      // arrange
      setUpNetworkDisconnected();

      // act
      final result = await repository.checkPhoneAvailability(tPhoneNumber);

      // assert
      expect(result, const Left(NetworkFailure()));
    });

    test('should return true when phone number is available', () async {
      // arrange
      setUpNetworkConnected();
      when(
        () => mockRemoteDataSource.checkPhoneAvailability(tPhoneNumber),
      ).thenAnswer((_) async => true);

      // act
      final result = await repository.checkPhoneAvailability(tPhoneNumber);

      // assert
      expect(result, const Right(true));
      verify(
        () => mockRemoteDataSource.checkPhoneAvailability(tPhoneNumber),
      ).called(1);
    });

    test('should return false when phone number is taken', () async {
      // arrange
      setUpNetworkConnected();
      when(
        () => mockRemoteDataSource.checkPhoneAvailability(tPhoneNumber),
      ).thenAnswer((_) async => false);

      // act
      final result = await repository.checkPhoneAvailability(tPhoneNumber);

      // assert
      expect(result, const Right(false));
    });

    test('should return AuthFailure when AuthException is thrown', () async {
      // arrange
      setUpNetworkConnected();
      when(
        () => mockRemoteDataSource.checkPhoneAvailability(tPhoneNumber),
      ).thenThrow(const AuthException(message: 'Auth error'));

      // act
      final result = await repository.checkPhoneAvailability(tPhoneNumber);

      // assert
      expect(result, const Left(AuthFailure(message: 'Auth error')));
    });

    test(
      'should return ServerFailure message when ServerException is thrown',
      () async {
        // arrange
        setUpNetworkConnected();
        when(
          () => mockRemoteDataSource.checkPhoneAvailability(tPhoneNumber),
        ).thenThrow(
          const ServerException(
            message:
                'Connection issue while checking phone number availability.',
          ),
        );

        // act
        final result = await repository.checkPhoneAvailability(tPhoneNumber);

        // assert
        expect(
          result,
          const Left(
            ServerFailure(
              message:
                  'Connection issue while checking phone number availability.',
            ),
          ),
        );
      },
    );

    test(
      'should return ServerFailure when unexpected exception is thrown',
      () async {
        // arrange
        setUpNetworkConnected();
        when(
          () => mockRemoteDataSource.checkPhoneAvailability(tPhoneNumber),
        ).thenThrow(Exception('Unexpected'));

        // act
        final result = await repository.checkPhoneAvailability(tPhoneNumber);

        // assert
        expect(result, const Left(ServerFailure()));
      },
    );
  });

  group('updateProfile', () {
    test('should return NetworkFailure when device is offline', () async {
      // arrange
      setUpNetworkDisconnected();

      // act
      final result = await repository.updateProfile(
        tDisplayName,
        tPhone,
        null,
        null,
      );

      // assert
      expect(result, const Left(NetworkFailure()));
    });

    test('should return updated User, cache, and sync profile', () async {
      // arrange
      setUpNetworkConnected();
      when(
        () => mockRemoteDataSource.updateProfile(
          tDisplayName,
          tPhone,
          null,
          null,
        ),
      ).thenAnswer((_) async => tUserModel);
      when(() => mockLocalDataSource.cacheUser(any())).thenAnswer((_) async {});
      when(
        () => mockProfileSyncService.syncProfile(
          tUserModel.id,
          tUserModel.displayName,
          tUserModel.username,
          tUserModel.phone,
          any(),
        ),
      ).thenAnswer((_) async {});

      // act
      final result = await repository.updateProfile(
        tDisplayName,
        tPhone,
        null,
        null,
      );

      // assert
      expect(result, Right(tUserModel));
      verify(
        () => mockRemoteDataSource.updateProfile(
          tDisplayName,
          tPhone,
          null,
          null,
        ),
      ).called(1);
      verify(() => mockLocalDataSource.cacheUser(tUserModel)).called(1);
      verify(
        () => mockProfileSyncService.syncProfile(
          tUserModel.id,
          tUserModel.displayName,
          tUserModel.username,
          tUserModel.phone,
          any(),
        ),
      ).called(1);
    });

    test('should succeed even when profile sync fails', () async {
      // arrange
      setUpNetworkConnected();
      when(
        () => mockRemoteDataSource.updateProfile(
          tDisplayName,
          tPhone,
          null,
          null,
        ),
      ).thenAnswer((_) async => tUserModel);
      when(() => mockLocalDataSource.cacheUser(any())).thenAnswer((_) async {});
      when(
        () => mockProfileSyncService.syncProfile(
          any(),
          any(),
          any(),
          any(),
          any(),
        ),
      ).thenThrow(Exception('Sync failed'));

      // act
      final result = await repository.updateProfile(
        tDisplayName,
        tPhone,
        null,
        null,
      );

      // assert
      expect(result, Right(tUserModel));
    });

    test('should return AuthFailure when AuthException is thrown', () async {
      // arrange
      setUpNetworkConnected();
      when(
        () => mockRemoteDataSource.updateProfile(
          tDisplayName,
          tPhone,
          null,
          null,
        ),
      ).thenThrow(const AuthException(message: 'Not authenticated'));

      // act
      final result = await repository.updateProfile(
        tDisplayName,
        tPhone,
        null,
        null,
      );

      // assert
      expect(result, const Left(AuthFailure(message: 'Not authenticated')));
    });

    test(
      'should return ServerFailure when ServerException is thrown',
      () async {
        // arrange
        setUpNetworkConnected();
        when(
          () => mockRemoteDataSource.updateProfile(
            tDisplayName,
            tPhone,
            null,
            null,
          ),
        ).thenThrow(const ServerException(message: 'Server error'));

        // act
        final result = await repository.updateProfile(
          tDisplayName,
          tPhone,
          null,
          null,
        );

        // assert
        expect(result, const Left(ServerFailure(message: 'Server error')));
      },
    );
  });
}
