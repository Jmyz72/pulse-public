import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/firestore_collections.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/validators.dart';
import '../../domain/entities/auth_security.dart';
import '../../domain/entities/google_auth_result.dart';
import '../models/auth_security_model.dart';
import '../models/password_policy_validation_model.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> signInWithEmail(String email, String password);
  Future<GoogleAuthResult> signInWithGoogle();
  Future<UserModel> registerWithEmail(
    String email,
    String password,
    String username,
    String displayName,
  );
  Future<void> resetPassword(String email);
  Future<void> sendEmailLinkSignIn(String email);
  Future<UserModel> completeEmailLinkSignIn({
    required String email,
    required String emailLink,
  });
  Future<void> signOut();
  Future<UserModel?> getCurrentUser();
  Future<AuthSecurity> getAuthSecurity();
  Future<UserModel> completeGoogleOnboarding(
    String username, {
    String? password,
  });
  Future<UserModel> linkGoogleSignIn({
    required String password,
    required GooglePendingProfileData profile,
  });
  Future<UserModel> updateProfile(
    String displayName,
    String phone,
    String? photoUrl,
    String? paymentIdentity,
  );
  Future<bool> checkUsernameAvailability(String username);
  Future<bool> checkPhoneAvailability(String phone);
  Future<PasswordPolicyValidationModel> validatePasswordPolicy(String password);
  Future<AuthSecurity> setPassword(String password);
  Future<String> uploadProfileImage(String userId, String filePath);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  static const _androidGoogleServerClientId =
      '185094909850-4t8csaaoghd5fte2515oqjo6jpv4mig3.apps.googleusercontent.com';
  static const _iosGoogleClientId =
      '185094909850-jfkrv0llvvg7nogv3tntcgr1eragfngk.apps.googleusercontent.com';
  static const _androidPackageName = 'com.example.pulse';
  static const _iosBundleId = 'com.example.pulse';
  static const _emailLinkContinueUrl =
      'https://example.invalid/auth/email-link/';

  final firebase_auth.FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;
  final FirebaseStorage? firebaseStorage;
  final GoogleSignIn googleSignIn;

  static const _firestoreTimeout = Duration(seconds: 10);
  static Completer<void>? _googleSignInInitializeCompleter;

  AuthRemoteDataSourceImpl({
    required this.firebaseAuth,
    required this.firestore,
    this.firebaseStorage,
    GoogleSignIn? googleSignIn,
  }) : googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  String _mapFirebaseAuthError(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return AppStrings.errorInvalidCredentials;
      case 'user-disabled':
        return AppStrings.errorAccountDisabled;
      case 'email-already-in-use':
        return AppStrings.errorEmailAlreadyInUse;
      case 'invalid-email':
        return AppStrings.errorInvalidEmail;
      case 'invalid-password':
      case 'weak-password':
        return AppStrings.errorWeakPassword;
      case 'too-many-requests':
        return AppStrings.errorTooManyRequests;
      case 'network-request-failed':
        return AppStrings.errorNetworkFailed;
      default:
        return AppStrings.errorUnexpected;
    }
  }

  String _mapAvailabilityLookupError(String code, {required String subject}) {
    switch (code) {
      case 'permission-denied':
        return 'Unable to check $subject availability right now.';
      case 'unavailable':
      case 'deadline-exceeded':
        return 'Connection issue while checking $subject availability.';
      default:
        return AppStrings.errorUnexpected;
    }
  }

  Future<void> _ensureGoogleSignInInitialized() {
    final existing = _googleSignInInitializeCompleter;
    if (existing != null) {
      return existing.future;
    }

    final completer = Completer<void>();
    _googleSignInInitializeCompleter = completer;

    () async {
      try {
        await googleSignIn.initialize(
          clientId: Platform.isIOS ? _iosGoogleClientId : null,
          serverClientId: _androidGoogleServerClientId,
        );
        completer.complete();
      } catch (error, stackTrace) {
        _googleSignInInitializeCompleter = null;
        completer.completeError(error, stackTrace);
      }
    }();

    return completer.future;
  }

  bool _isLinkRequiredException(firebase_auth.FirebaseAuthException error) {
    return error.code == 'account-exists-with-different-credential' ||
        error.code == 'email-already-in-use';
  }

  String _googleSignInErrorMessage(GoogleSignInException error) {
    switch (error.code) {
      case GoogleSignInExceptionCode.canceled:
        return 'Google sign-in was canceled.';
      case GoogleSignInExceptionCode.interrupted:
        return 'Google sign-in was interrupted. Please try again.';
      case GoogleSignInExceptionCode.uiUnavailable:
        return 'Google sign-in is unavailable on this device.';
      case GoogleSignInExceptionCode.clientConfigurationError:
      case GoogleSignInExceptionCode.providerConfigurationError:
        return 'Google sign-in is not configured correctly.';
      case GoogleSignInExceptionCode.userMismatch:
        return 'The selected Google account does not match the current session.';
      default:
        return 'Google sign-in failed. Please try again.';
    }
  }

  GooglePendingProfileData _buildPendingProfileData({
    required String email,
    required String displayName,
    String? photoUrl,
    firebase_auth.AuthCredential? pendingCredential,
  }) {
    final normalizedEmail = email.trim().toLowerCase();
    final fallbackDisplayName = displayName.trim().isNotEmpty
        ? displayName.trim()
        : normalizedEmail.contains('@')
        ? normalizedEmail.split('@').first
        : 'Google user';
    return GooglePendingProfileData(
      email: normalizedEmail,
      displayName: fallbackDisplayName,
      photoUrl: photoUrl,
      pendingCredential: pendingCredential,
    );
  }

  GooglePendingProfileData _pendingProfileFromGoogleAccount(
    GoogleSignInAccount account, {
    firebase_auth.AuthCredential? pendingCredential,
    String? fallbackEmail,
  }) {
    final email = (fallbackEmail?.trim().isNotEmpty ?? false)
        ? fallbackEmail!.trim().toLowerCase()
        : account.email.trim().toLowerCase();
    final displayName = account.displayName?.trim().isNotEmpty == true
        ? account.displayName!.trim()
        : email.contains('@')
        ? email.split('@').first
        : 'Google user';

    return _buildPendingProfileData(
      email: email,
      displayName: displayName,
      photoUrl: account.photoUrl,
      pendingCredential: pendingCredential,
    );
  }

  GooglePendingProfileData _pendingProfileFromFirebaseUser(
    firebase_auth.User user, {
    firebase_auth.AuthCredential? pendingCredential,
  }) {
    final email = user.email?.trim().toLowerCase() ?? '';
    final displayName = user.displayName?.trim().isNotEmpty == true
        ? user.displayName!.trim()
        : email.isNotEmpty
        ? email.split('@').first
        : 'Google user';

    return _buildPendingProfileData(
      email: email,
      displayName: displayName,
      photoUrl: user.photoURL,
      pendingCredential: pendingCredential,
    );
  }

  bool _hasProvider(firebase_auth.User user, String providerId) {
    return user.providerData.any(
      (provider) => provider.providerId == providerId,
    );
  }

  AuthSecurityModel _currentAuthSecurityFromUser(firebase_auth.User user) {
    return AuthSecurityModel(
      email: user.email?.trim().toLowerCase() ?? '',
      hasPasswordProvider: _hasProvider(user, 'password'),
      hasGoogleProvider: _hasProvider(user, 'google.com'),
      emailVerified: user.emailVerified,
    );
  }

  firebase_auth.ActionCodeSettings _emailLinkActionCodeSettings() {
    return firebase_auth.ActionCodeSettings(
      url: _emailLinkContinueUrl,
      handleCodeInApp: true,
      iOSBundleId: _iosBundleId,
      androidPackageName: _androidPackageName,
      androidInstallApp: true,
    );
  }

  Future<void> _linkEmailPasswordIfNeeded({
    required firebase_auth.User user,
    required String email,
    required String? password,
  }) async {
    final trimmedPassword = password?.trim() ?? '';
    if (trimmedPassword.isEmpty || _hasProvider(user, 'password')) {
      return;
    }

    final passwordValidation = await validatePasswordPolicy(trimmedPassword);
    if (!passwordValidation.isValid) {
      throw AuthException(message: passwordValidation.failureMessage);
    }

    try {
      await user.linkWithCredential(
        firebase_auth.EmailAuthProvider.credential(
          email: email,
          password: trimmedPassword,
        ),
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code != 'provider-already-linked') {
        rethrow;
      }
    }
  }

  Future<UserModel?> _getUserDoc(firebase_auth.User user) async {
    try {
      final snapshot = await firestore
          .collection(FirestoreCollections.users)
          .doc(user.uid)
          .get()
          .timeout(_firestoreTimeout);

      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }

      return UserModel.fromJson({'userId': user.uid, ...snapshot.data()!});
    } on FirebaseException catch (e) {
      throw ServerException(
        message: _mapAvailabilityLookupError(e.code, subject: 'Google profile'),
      );
    } on TimeoutException {
      throw const ServerException(
        message: 'Connection issue while loading Google profile.',
      );
    }
  }

  @override
  Future<UserModel> signInWithEmail(String email, String password) async {
    try {
      final credential = await firebaseAuth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      if (credential.user == null) {
        throw const AuthException(message: 'Sign in failed');
      }

      if (!credential.user!.emailVerified) {
        await credential.user!.sendEmailVerification();
        await firebaseAuth.signOut();
        throw const AuthException(message: AppStrings.errorEmailNotVerified);
      }

      final userDoc = await firestore
          .collection(FirestoreCollections.users)
          .doc(credential.user!.uid)
          .get()
          .timeout(_firestoreTimeout);

      if (!userDoc.exists) {
        throw const AuthException(
          message: 'User profile not found. Please contact support.',
        );
      }

      return UserModel.fromJson({
        'userId': credential.user!.uid,
        ...userDoc.data()!,
      });
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw AuthException(message: _mapFirebaseAuthError(e.code));
    } on AuthException {
      rethrow;
    } catch (e) {
      throw const AuthException(
        message: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  @override
  Future<void> sendEmailLinkSignIn(String email) async {
    try {
      await firebaseAuth.sendSignInLinkToEmail(
        email: email.trim().toLowerCase(),
        actionCodeSettings: _emailLinkActionCodeSettings(),
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw AuthException(message: _mapFirebaseAuthError(e.code));
    } catch (_) {
      throw const AuthException(
        message: 'Unable to send the sign-in link. Please try again.',
      );
    }
  }

  @override
  Future<UserModel> completeEmailLinkSignIn({
    required String email,
    required String emailLink,
  }) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();
      if (!firebaseAuth.isSignInWithEmailLink(emailLink)) {
        throw const AuthException(
          message: 'This sign-in link is invalid or has expired.',
        );
      }

      final userCredential = await firebaseAuth.signInWithEmailLink(
        email: normalizedEmail,
        emailLink: emailLink,
      );
      final firebaseUser = userCredential.user ?? firebaseAuth.currentUser;
      if (firebaseUser == null) {
        throw const AuthException(
          message: 'Unable to complete email-link sign-in.',
        );
      }

      final user = await _getUserDoc(firebaseUser);
      if (user == null) {
        await firebaseAuth.signOut();
        throw const AuthException(
          message:
              'This sign-in link is only for existing Pulse accounts. Please create your account first.',
        );
      }

      return user;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw AuthException(message: _mapFirebaseAuthError(e.code));
    } on AuthException {
      rethrow;
    } catch (_) {
      throw const AuthException(
        message: 'Unable to complete email-link sign-in. Please try again.',
      );
    }
  }

  @override
  Future<GoogleAuthResult> signInWithGoogle() async {
    GoogleSignInAccount? googleAccount;
    firebase_auth.AuthCredential? pendingCredential;
    try {
      await _ensureGoogleSignInInitialized();
      googleAccount = await googleSignIn.authenticate();
      final authentication = googleAccount.authentication;
      final idToken = authentication.idToken;
      if (idToken == null || idToken.trim().isEmpty) {
        throw const AuthException(
          message: 'Google authentication failed. Please try again.',
        );
      }

      final credential = firebase_auth.GoogleAuthProvider.credential(
        idToken: idToken,
      );
      pendingCredential = credential;

      final userCredential = await firebaseAuth.signInWithCredential(
        credential,
      );
      final firebaseUser = userCredential.user ?? firebaseAuth.currentUser;
      if (firebaseUser == null) {
        throw const AuthException(message: 'Google sign-in failed');
      }

      final user = await _getUserDoc(firebaseUser);
      if (user != null) {
        return GoogleAuthAuthenticated(user);
      }

      return GoogleAuthUsernameSetupRequired(
        _pendingProfileFromFirebaseUser(firebaseUser),
      );
    } on GoogleSignInException catch (e) {
      throw AuthException(message: _googleSignInErrorMessage(e));
    } on UnsupportedError {
      throw const AuthException(
        message: 'Google sign-in is not supported on this platform.',
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (_isLinkRequiredException(e)) {
        final account = googleAccount;
        if (account == null) {
          throw const AuthException(message: 'Google sign-in failed');
        }
        final pendingProfileData = _pendingProfileFromGoogleAccount(
          account,
          pendingCredential: pendingCredential ?? e.credential,
          fallbackEmail: e.email,
        );
        final email = e.email?.trim().isNotEmpty == true
            ? e.email!.trim().toLowerCase()
            : pendingProfileData.email;
        return GoogleAuthLinkRequired(
          pendingProfileData: pendingProfileData,
          email: email,
        );
      }
      throw AuthException(message: _mapFirebaseAuthError(e.code));
    } on ServerException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw const AuthException(
        message: 'Google sign-in failed. Please try again.',
      );
    }
  }

  @override
  Future<UserModel> registerWithEmail(
    String email,
    String password,
    String username,
    String displayName,
  ) async {
    try {
      final trimmedEmail = email.trim().toLowerCase();
      final lowerUsername = username.toLowerCase();
      final passwordValidation = await validatePasswordPolicy(password);

      if (!passwordValidation.isValid) {
        throw AuthException(message: passwordValidation.failureMessage);
      }

      // Create Firebase Auth account first
      final credential = await firebaseAuth.createUserWithEmailAndPassword(
        email: trimmedEmail,
        password: password,
      );

      if (credential.user == null) {
        throw const AuthException(message: 'Registration failed');
      }

      await credential.user!.sendEmailVerification();

      try {
        // Use a transaction to claim username and create user doc atomically
        await firestore.runTransaction((transaction) async {
          final usernameDoc = await transaction.get(
            firestore
                .collection(FirestoreCollections.usernames)
                .doc(lowerUsername),
          );

          if (usernameDoc.exists) {
            throw const AuthException(message: AppStrings.errorUsernameTaken);
          }

          transaction.set(
            firestore
                .collection(FirestoreCollections.usernames)
                .doc(lowerUsername),
            {
              'userId': credential.user!.uid,
              'createdAt': FieldValue.serverTimestamp(),
            },
          );

          transaction.set(
            firestore
                .collection(FirestoreCollections.users)
                .doc(credential.user!.uid),
            {
              'userId': credential.user!.uid,
              'username': lowerUsername,
              'displayName': displayName,
              'email': trimmedEmail,
              'phone': '',
              'phoneSearchDigits': '',
              'dateJoining': FieldValue.serverTimestamp(),
            },
          );
        });
      } catch (e) {
        // Clean up orphaned Firebase Auth account
        try {
          await credential.user!.delete();
        } catch (_) {
          developer.log(
            'Failed to delete orphaned Firebase Auth account',
            error: e,
            name: 'AuthRemoteDataSource',
          );
        }
        rethrow;
      }

      await firebaseAuth.signOut();

      return UserModel(
        id: credential.user!.uid,
        username: lowerUsername,
        displayName: displayName,
        email: trimmedEmail,
        phone: '',
        dateJoining: DateTime.now(),
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw AuthException(message: _mapFirebaseAuthError(e.code));
    } on FirebaseException catch (e) {
      throw ServerException(
        message: _mapAvailabilityLookupError(
          e.code,
          subject: 'Google onboarding',
        ),
      );
    } on TimeoutException {
      throw const ServerException(
        message: 'Connection issue while completing Google onboarding.',
      );
    } on AuthException {
      rethrow;
    } catch (e) {
      throw const AuthException(message: AppStrings.errorUnexpected);
    }
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      await firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'invalid-email') {
        return; // Silently return to prevent email enumeration
      }
      throw AuthException(message: _mapFirebaseAuthError(e.code));
    } catch (e) {
      throw const AuthException(message: AppStrings.errorUnexpected);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await firebaseAuth.signOut();
      try {
        await _ensureGoogleSignInInitialized();
        await googleSignIn.signOut();
      } catch (_) {
        // Ignore Google sign-out cleanup failures after Firebase sign-out.
      }
    } catch (e) {
      throw const AuthException(message: AppStrings.errorUnexpected);
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final firebaseUser = firebaseAuth.currentUser;
    if (firebaseUser == null) return null;

    final hasGoogleProvider = firebaseUser.providerData.any(
      (provider) => provider.providerId == 'google.com',
    );

    if (!hasGoogleProvider && !firebaseUser.emailVerified) {
      await firebaseAuth.signOut();
      return null;
    }

    final userDoc = await firestore
        .collection(FirestoreCollections.users)
        .doc(firebaseUser.uid)
        .get()
        .timeout(_firestoreTimeout);

    if (!userDoc.exists) {
      if (!hasGoogleProvider) {
        return null;
      }

      return UserModel(
        id: firebaseUser.uid,
        username: '',
        displayName: firebaseUser.displayName?.trim().isNotEmpty == true
            ? firebaseUser.displayName!.trim()
            : (firebaseUser.email?.split('@').first ?? 'Google user'),
        email: firebaseUser.email?.trim().toLowerCase() ?? '',
        phone: '',
        photoUrl: firebaseUser.photoURL,
      );
    }

    return UserModel.fromJson({'userId': firebaseUser.uid, ...userDoc.data()!});
  }

  @override
  Future<AuthSecurity> getAuthSecurity() async {
    final firebaseUser = firebaseAuth.currentUser;
    if (firebaseUser == null) {
      throw const AuthException(message: 'User not authenticated');
    }

    return _currentAuthSecurityFromUser(firebaseUser);
  }

  @override
  Future<UserModel> completeGoogleOnboarding(
    String username, {
    String? password,
  }) async {
    try {
      final firebaseUser = firebaseAuth.currentUser;
      if (firebaseUser == null) {
        throw const AuthException(message: 'User not authenticated');
      }

      final normalizedUsername = username.trim().toLowerCase();
      final usernameValidation = Validators.validateUsername(
        normalizedUsername,
      );
      if (usernameValidation != null) {
        throw AuthException(message: usernameValidation);
      }

      final email = firebaseUser.email?.trim().toLowerCase() ?? '';
      if (email.isEmpty) {
        throw const AuthException(
          message: 'Google account email is missing. Please try again.',
        );
      }

      await _linkEmailPasswordIfNeeded(
        user: firebaseUser,
        email: email,
        password: password,
      );

      final displayName = firebaseUser.displayName?.trim().isNotEmpty == true
          ? firebaseUser.displayName!.trim()
          : normalizedUsername;
      final photoUrl = firebaseUser.photoURL;
      final userRef = firestore
          .collection(FirestoreCollections.users)
          .doc(firebaseUser.uid);
      final usernameRef = firestore
          .collection(FirestoreCollections.usernames)
          .doc(normalizedUsername);

      await firestore.runTransaction((transaction) async {
        final userDoc = await transaction.get(userRef);
        if (userDoc.exists && userDoc.data() != null) {
          return;
        }

        final usernameDoc = await transaction.get(usernameRef);
        if (usernameDoc.exists) {
          final existingUserId = usernameDoc.data()?['userId'] as String?;
          if (existingUserId != null && existingUserId != firebaseUser.uid) {
            throw const AuthException(message: AppStrings.errorUsernameTaken);
          }
        } else {
          transaction.set(usernameRef, {
            'userId': firebaseUser.uid,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }

        transaction.set(userRef, {
          'userId': firebaseUser.uid,
          'username': normalizedUsername,
          'displayName': displayName,
          'email': email,
          'phone': '',
          'phoneSearchDigits': '',
          'photoUrl': photoUrl,
          'paymentIdentity': null,
          'dateJoining': FieldValue.serverTimestamp(),
        });
      });

      final userDoc = await userRef.get();
      if (!userDoc.exists || userDoc.data() == null) {
        throw const AuthException(
          message: 'Google onboarding failed. Please try again.',
        );
      }

      return UserModel.fromJson({
        'userId': firebaseUser.uid,
        ...userDoc.data()!,
      });
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw AuthException(message: _mapFirebaseAuthError(e.code));
    } on AuthException {
      rethrow;
    } catch (e) {
      throw const AuthException(message: AppStrings.errorUnexpected);
    }
  }

  @override
  Future<UserModel> linkGoogleSignIn({
    required String password,
    required GooglePendingProfileData profile,
  }) async {
    try {
      final pendingCredential = profile.pendingCredential;
      if (pendingCredential == null) {
        throw const AuthException(
          message: 'Google sign-in must be restarted before linking.',
        );
      }

      final normalizedEmail = profile.email.trim().toLowerCase();
      final userCredential = await firebaseAuth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      final firebaseUser = userCredential.user ?? firebaseAuth.currentUser;
      if (firebaseUser == null) {
        throw const AuthException(message: 'Unable to link Google sign-in.');
      }

      await firebaseUser.linkWithCredential(pendingCredential);

      final user = await _getUserDoc(firebaseUser);
      if (user == null) {
        throw const AuthException(
          message: 'User profile not found. Please contact support.',
        );
      }

      return user;
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'provider-already-linked' ||
          e.code == 'credential-already-in-use') {
        final firebaseUser = firebaseAuth.currentUser;
        if (firebaseUser != null) {
          final user = await _getUserDoc(firebaseUser);
          if (user != null) {
            return user;
          }
        }
      }
      throw AuthException(message: _mapFirebaseAuthError(e.code));
    } on AuthException {
      rethrow;
    } catch (_) {
      throw const AuthException(
        message: 'Unable to link Google sign-in. Please try again.',
      );
    }
  }

  @override
  Future<UserModel> updateProfile(
    String displayName,
    String phone,
    String? photoUrl,
    String? paymentIdentity,
  ) async {
    try {
      final firebaseUser = firebaseAuth.currentUser;
      if (firebaseUser == null) {
        throw const AuthException(message: 'User not authenticated');
      }

      final userRef = firestore
          .collection(FirestoreCollections.users)
          .doc(firebaseUser.uid);
      final newPhone = Validators.canonicalizeStoredPhone(phone) ?? '';
      final phoneSearchDigits = Validators.phoneSearchDigits(newPhone);
      final normalizedPaymentIdentity = paymentIdentity?.trim().isEmpty ?? true
          ? null
          : paymentIdentity!.trim();

      await firestore.runTransaction((transaction) async {
        final userDoc = await transaction.get(userRef);
        if (!userDoc.exists) {
          throw const AuthException(
            message: 'User profile not found. Please contact support.',
          );
        }

        final currentPhone =
            (userDoc.data()?['phone'] as String?)?.trim() ?? '';
        final updateData = <String, dynamic>{
          'displayName': displayName,
          'phone': newPhone,
          'phoneSearchDigits': phoneSearchDigits,
          'paymentIdentity': normalizedPaymentIdentity,
        };

        if (photoUrl != null) {
          updateData['photoUrl'] = photoUrl;
        }

        if (currentPhone != newPhone) {
          if (currentPhone.isNotEmpty) {
            transaction.delete(
              firestore
                  .collection(FirestoreCollections.phoneNumbers)
                  .doc(currentPhone),
            );
          }

          if (newPhone.isNotEmpty) {
            final newPhoneRef = firestore
                .collection(FirestoreCollections.phoneNumbers)
                .doc(newPhone);
            final newPhoneDoc = await transaction.get(newPhoneRef);
            final existingUserId = newPhoneDoc.data()?['userId'] as String?;
            if (newPhoneDoc.exists && existingUserId != firebaseUser.uid) {
              throw const AuthException(message: AppStrings.errorPhoneTaken);
            }
            transaction.set(newPhoneRef, {
              'userId': firebaseUser.uid,
              'createdAt': FieldValue.serverTimestamp(),
            });
          }
        } else if (newPhone.isNotEmpty) {
          final currentPhoneRef = firestore
              .collection(FirestoreCollections.phoneNumbers)
              .doc(newPhone);
          final currentPhoneDoc = await transaction.get(currentPhoneRef);
          final existingUserId = currentPhoneDoc.data()?['userId'] as String?;
          if (!currentPhoneDoc.exists || existingUserId != firebaseUser.uid) {
            transaction.set(currentPhoneRef, {
              'userId': firebaseUser.uid,
              'createdAt': FieldValue.serverTimestamp(),
            });
          }
        }

        transaction.update(userRef, updateData);
      });

      final userDoc = await userRef.get();

      return UserModel.fromJson({
        'userId': firebaseUser.uid,
        ...userDoc.data()!,
      });
    } on AuthException {
      rethrow;
    } catch (e) {
      throw const AuthException(message: AppStrings.errorUnexpected);
    }
  }

  @override
  Future<String> uploadProfileImage(String userId, String filePath) async {
    try {
      final storage = firebaseStorage ?? FirebaseStorage.instance;
      const uuid = Uuid();
      final uniqueId = uuid.v4();
      final fileName = filePath.split('/').last;
      final ref = storage.ref().child(
        'profile_images/$userId/${uniqueId}_$fileName',
      );

      final uploadTask = await ref.putFile(
        File(filePath),
        SettableMetadata(contentType: 'image/jpeg'),
      );

      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      throw ServerException(
        message: 'Failed to upload profile image: ${e.toString()}',
      );
    }
  }

  @override
  Future<bool> checkUsernameAvailability(String username) async {
    try {
      final doc = await firestore
          .collection(FirestoreCollections.usernames)
          .doc(username.toLowerCase())
          .get()
          .timeout(_firestoreTimeout);
      return !doc.exists;
    } on FirebaseException catch (e) {
      throw ServerException(
        message: _mapAvailabilityLookupError(e.code, subject: 'username'),
      );
    } on TimeoutException {
      throw const ServerException(
        message: 'Connection issue while checking username availability.',
      );
    }
  }

  @override
  Future<bool> checkPhoneAvailability(String phone) async {
    try {
      final canonicalPhone = Validators.canonicalizeStoredPhone(phone);
      if (canonicalPhone == null || canonicalPhone.isEmpty) {
        throw const AuthException(message: AppStrings.errorInvalidPhone);
      }

      final doc = await firestore
          .collection(FirestoreCollections.phoneNumbers)
          .doc(canonicalPhone)
          .get()
          .timeout(_firestoreTimeout);
      return !doc.exists;
    } on FirebaseException catch (e) {
      throw ServerException(
        message: _mapAvailabilityLookupError(e.code, subject: 'phone number'),
      );
    } on TimeoutException {
      throw const ServerException(
        message: 'Connection issue while checking phone number availability.',
      );
    }
  }

  @override
  Future<PasswordPolicyValidationModel> validatePasswordPolicy(
    String password,
  ) async {
    try {
      final status = await firebaseAuth.validatePassword(
        firebaseAuth,
        password,
      );
      return PasswordPolicyValidationModel.fromFirebase(status);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw AuthException(message: _mapFirebaseAuthError(e.code));
    } catch (e) {
      throw const AuthException(message: AppStrings.errorUnexpected);
    }
  }

  @override
  Future<AuthSecurity> setPassword(String password) async {
    try {
      final firebaseUser = firebaseAuth.currentUser;
      if (firebaseUser == null) {
        throw const AuthException(message: 'User not authenticated');
      }

      final email = firebaseUser.email?.trim().toLowerCase() ?? '';
      if (email.isEmpty) {
        throw const AuthException(
          message: 'Your account email is missing. Please contact support.',
        );
      }

      await _linkEmailPasswordIfNeeded(
        user: firebaseUser,
        email: email,
        password: password,
      );

      await firebaseUser.reload();
      final refreshedUser = firebaseAuth.currentUser;
      if (refreshedUser == null) {
        throw const AuthException(message: 'User not authenticated');
      }

      return _currentAuthSecurityFromUser(refreshedUser);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw AuthException(message: _mapFirebaseAuthError(e.code));
    } on AuthException {
      rethrow;
    } catch (_) {
      throw const AuthException(
        message: 'Unable to set a password right now. Please try again.',
      );
    }
  }
}
