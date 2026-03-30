import 'dart:developer' as developer;

import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/profile_sync_service.dart';
import '../../domain/entities/auth_security.dart';
import '../../domain/entities/google_auth_result.dart';
import '../../domain/entities/password_policy_validation.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/auth_security_model.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  final NetworkInfo networkInfo;
  final ProfileSyncService? profileSyncService;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
    this.profileSyncService,
  });

  @override
  Future<Either<Failure, User>> signInWithEmail(
    String email,
    String password,
  ) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final user = await remoteDataSource.signInWithEmail(email, password);
      if (user.dateJoining != null) {
        try {
          await localDataSource.cacheUser(user);
        } catch (e) {
          developer.log(
            'Failed to cache user after sign-in',
            error: e,
            name: 'AuthRepositoryImpl',
          );
        }
      }
      return Right(user);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, GoogleAuthResult>> signInWithGoogle() async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final result = await remoteDataSource.signInWithGoogle();

      if (result is GoogleAuthAuthenticated &&
          result.user.dateJoining != null) {
        try {
          await localDataSource.cacheUser(UserModel.fromEntity(result.user));
        } catch (e) {
          developer.log(
            'Failed to cache user after Google sign-in',
            error: e,
            name: 'AuthRepositoryImpl',
          );
        }
      }

      return Right(result);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, User>> registerWithEmail(
    String email,
    String password,
    String username,
    String displayName,
  ) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final user = await remoteDataSource.registerWithEmail(
        email,
        password,
        username,
        displayName,
      );
      return Right(user);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword(String email) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      await remoteDataSource.resetPassword(email);
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> sendEmailLinkSignIn(String email) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      await remoteDataSource.sendEmailLinkSignIn(email);
      try {
        await localDataSource.cachePendingEmailLinkEmail(email);
      } catch (e) {
        developer.log(
          'Failed to cache pending email-link email',
          error: e,
          name: 'AuthRepositoryImpl',
        );
      }
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, String?>> getPendingEmailLinkEmail() async {
    try {
      final email = await localDataSource.getPendingEmailLinkEmail();
      return Right(email);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, User>> completeEmailLinkSignIn({
    required String email,
    required String emailLink,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final user = await remoteDataSource.completeEmailLinkSignIn(
        email: email,
        emailLink: emailLink,
      );
      await localDataSource.clearPendingEmailLinkEmail();
      if (user.dateJoining != null) {
        try {
          await localDataSource.cacheUser(UserModel.fromEntity(user));
        } catch (e) {
          developer.log(
            'Failed to cache user after email-link sign-in',
            error: e,
            name: 'AuthRepositoryImpl',
          );
        }
      }
      return Right(user);
    } on AuthException catch (e) {
      try {
        await localDataSource.clearPendingEmailLinkEmail();
      } catch (_) {}
      return Left(AuthFailure(message: e.message));
    } on ServerException catch (e) {
      try {
        await localDataSource.clearPendingEmailLinkEmail();
      } catch (_) {}
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      try {
        await localDataSource.clearPendingEmailLinkEmail();
      } catch (_) {}
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    Failure? remoteFailure;

    try {
      await remoteDataSource.signOut();
    } on AuthException catch (e) {
      remoteFailure = AuthFailure(message: e.message);
    } catch (e) {
      developer.log(
        'Remote sign-out failed',
        error: e,
        name: 'AuthRepositoryImpl',
      );
      remoteFailure = const ServerFailure(
        message: 'Failed to sign out. Please try again.',
      );
    }

    try {
      await localDataSource.clearCache();
    } catch (e) {
      developer.log(
        'Failed to clear local cache during sign-out',
        error: e,
        name: 'AuthRepositoryImpl',
      );
    }

    if (remoteFailure != null) {
      return Left(remoteFailure);
    }

    return const Right(null);
  }

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    try {
      if (!await networkInfo.isConnected) {
        try {
          final cachedUser = await localDataSource.getCachedUser();
          return Right(cachedUser);
        } on CacheException {
          return const Right(null);
        }
      }

      final user = await remoteDataSource.getCurrentUser();
      if (user != null && user.dateJoining != null) {
        try {
          await localDataSource.cacheUser(user);
        } catch (e) {
          developer.log(
            'Failed to cache user during getCurrentUser',
            error: e,
            name: 'AuthRepositoryImpl',
          );
        }
      }
      return Right(user);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, AuthSecurity>> getAuthSecurity() async {
    try {
      final security = await remoteDataSource.getAuthSecurity();
      return Right(security);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, User>> completeGoogleOnboarding(
    String username, {
    String? password,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final user = await remoteDataSource.completeGoogleOnboarding(
        username,
        password: password,
      );
      if (user.dateJoining != null) {
        try {
          await localDataSource.cacheUser(UserModel.fromEntity(user));
        } catch (e) {
          developer.log(
            'Failed to cache user after Google onboarding',
            error: e,
            name: 'AuthRepositoryImpl',
          );
        }
      }
      return Right(user);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, User>> linkGoogleSignIn({
    required String password,
    required GooglePendingProfileData profile,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final user = await remoteDataSource.linkGoogleSignIn(
        password: password,
        profile: profile,
      );
      if (user.dateJoining != null) {
        try {
          await localDataSource.cacheUser(UserModel.fromEntity(user));
        } catch (e) {
          developer.log(
            'Failed to cache user after linking Google sign-in',
            error: e,
            name: 'AuthRepositoryImpl',
          );
        }
      }
      return Right(user);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, bool>> checkUsernameAvailability(
    String username,
  ) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final available = await remoteDataSource.checkUsernameAvailability(
        username,
      );
      return Right(available);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, bool>> checkPhoneAvailability(String phone) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final available = await remoteDataSource.checkPhoneAvailability(phone);
      return Right(available);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, PasswordPolicyValidation>> validatePasswordPolicy(
    String password,
  ) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final validation = await remoteDataSource.validatePasswordPolicy(
        password,
      );
      return Right(validation);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, AuthSecurity>> setPassword(String password) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final security = await remoteDataSource.setPassword(password);
      return Right(AuthSecurityModel.fromEntity(security));
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, String>> uploadProfileImage(
    String userId,
    String imagePath,
  ) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final downloadUrl = await remoteDataSource.uploadProfileImage(
        userId,
        imagePath,
      );
      return Right(downloadUrl);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(
        ServerFailure(
          message: 'Failed to upload profile picture: ${e.toString()}',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, User>> updateProfile(
    String displayName,
    String phone,
    String? photoUrl,
    String? paymentIdentity,
  ) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final user = await remoteDataSource.updateProfile(
        displayName,
        phone,
        photoUrl,
        paymentIdentity,
      );
      await localDataSource.cacheUser(user);

      // Best-effort profile sync — don't fail the profile update if this fails
      try {
        await profileSyncService?.syncProfile(
          user.id,
          user.displayName,
          user.username,
          user.phone,
          user.photoUrl,
        );
      } catch (e) {
        developer.log(
          'Profile sync failed',
          error: e,
          name: 'AuthRepositoryImpl',
        );
      }

      return Right(user);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return const Left(ServerFailure());
    }
  }
}
