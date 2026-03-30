import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/auth_security.dart';
import '../entities/google_auth_result.dart';
import '../entities/password_policy_validation.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<Either<Failure, User>> signInWithEmail(String email, String password);
  Future<Either<Failure, GoogleAuthResult>> signInWithGoogle();
  Future<Either<Failure, User>> registerWithEmail(
    String email,
    String password,
    String username,
    String displayName,
  );
  Future<Either<Failure, void>> resetPassword(String email);
  Future<Either<Failure, void>> sendEmailLinkSignIn(String email);
  Future<Either<Failure, String?>> getPendingEmailLinkEmail();
  Future<Either<Failure, User>> completeEmailLinkSignIn({
    required String email,
    required String emailLink,
  });
  Future<Either<Failure, void>> signOut();
  Future<Either<Failure, User?>> getCurrentUser();
  Future<Either<Failure, AuthSecurity>> getAuthSecurity();
  Future<Either<Failure, User>> completeGoogleOnboarding(
    String username, {
    String? password,
  });
  Future<Either<Failure, User>> linkGoogleSignIn({
    required String password,
    required GooglePendingProfileData profile,
  });
  Future<Either<Failure, User>> updateProfile(
    String displayName,
    String phone,
    String? photoUrl,
    String? paymentIdentity,
  );
  Future<Either<Failure, bool>> checkUsernameAvailability(String username);
  Future<Either<Failure, bool>> checkPhoneAvailability(String phone);
  Future<Either<Failure, PasswordPolicyValidation>> validatePasswordPolicy(
    String password,
  );
  Future<Either<Failure, AuthSecurity>> setPassword(String password);
  Future<Either<Failure, String>> uploadProfileImage(
    String userId,
    String imagePath,
  );
}
