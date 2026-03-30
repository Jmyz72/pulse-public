import 'dart:developer' as developer;

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecases/usecase.dart';
import '../../../expense/domain/usecases/sync_owner_payment_identity_to_pending_expenses.dart';
import '../../domain/entities/auth_security.dart';
import '../../domain/entities/google_auth_result.dart';
import '../../domain/entities/password_policy_validation.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/check_phone_availability.dart';
import '../../domain/usecases/check_username_availability.dart';
import '../../domain/usecases/complete_email_link_sign_in.dart';
import '../../domain/usecases/complete_google_onboarding.dart';
import '../../domain/usecases/get_auth_security.dart';
import '../../domain/usecases/get_current_user.dart';
import '../../domain/usecases/get_pending_email_link_email.dart';
import '../../domain/usecases/link_google_sign_in.dart';
import '../../domain/usecases/login.dart';
import '../../domain/usecases/logout.dart';
import '../../domain/usecases/register.dart';
import '../../domain/usecases/reset_password.dart';
import '../../domain/usecases/send_email_link_sign_in.dart';
import '../../domain/usecases/set_password.dart';
import '../../domain/usecases/sign_in_with_google.dart';
import '../../domain/usecases/update_profile.dart';
import '../../domain/usecases/upload_profile_image.dart';
import '../../domain/usecases/validate_password_policy.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final GetCurrentUser getCurrentUser;
  final GetAuthSecurity getAuthSecurity;
  final Login login;
  final SignInWithGoogle signInWithGoogle;
  final SendEmailLinkSignIn sendEmailLinkSignIn;
  final GetPendingEmailLinkEmail getPendingEmailLinkEmail;
  final CompleteEmailLinkSignIn completeEmailLinkSignIn;
  final CompleteGoogleOnboarding completeGoogleOnboarding;
  final LinkGoogleSignIn linkGoogleSignIn;
  final Register register;
  final Logout logout;
  final ResetPassword resetPassword;
  final SetPassword setPassword;
  final UpdateProfile updateProfile;
  final CheckUsernameAvailability checkUsernameAvailability;
  final CheckPhoneAvailability checkPhoneAvailability;
  final ValidatePasswordPolicy validatePasswordPolicy;
  final UploadProfileImage uploadProfileImage;
  final SyncOwnerPaymentIdentityToPendingExpenses
  syncOwnerPaymentIdentityToPendingExpenses;

  AuthBloc({
    required this.getCurrentUser,
    required this.getAuthSecurity,
    required this.login,
    required this.signInWithGoogle,
    required this.sendEmailLinkSignIn,
    required this.getPendingEmailLinkEmail,
    required this.completeEmailLinkSignIn,
    required this.completeGoogleOnboarding,
    required this.linkGoogleSignIn,
    required this.register,
    required this.logout,
    required this.resetPassword,
    required this.setPassword,
    required this.updateProfile,
    required this.checkUsernameAvailability,
    required this.checkPhoneAvailability,
    required this.validatePasswordPolicy,
    required this.uploadProfileImage,
    required this.syncOwnerPaymentIdentityToPendingExpenses,
  }) : super(const AuthState()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested, transformer: droppable());
    on<AuthEmailLinkSignInRequested>(
      _onAuthEmailLinkSignInRequested,
      transformer: droppable(),
    );
    on<AuthEmailLinkDetected>(
      _onAuthEmailLinkDetected,
      transformer: droppable(),
    );
    on<AuthEmailLinkCompletionRequested>(
      _onAuthEmailLinkCompletionRequested,
      transformer: droppable(),
    );
    on<AuthGoogleSignInRequested>(
      _onAuthGoogleSignInRequested,
      transformer: droppable(),
    );
    on<AuthGoogleUsernameCompletionRequested>(
      _onAuthGoogleUsernameCompletionRequested,
      transformer: droppable(),
    );
    on<AuthGoogleLinkRequested>(
      _onAuthGoogleLinkRequested,
      transformer: droppable(),
    );
    on<AuthGoogleOnboardingCancelled>(
      _onAuthGoogleOnboardingCancelled,
      transformer: droppable(),
    );
    on<AuthRegisterRequested>(
      _onAuthRegisterRequested,
      transformer: droppable(),
    );
    on<AuthResetPasswordRequested>(
      _onAuthResetPasswordRequested,
      transformer: droppable(),
    );
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<AuthProfileUpdateRequested>(_onProfileUpdateRequested);
    on<AuthProfileCompletionSkipped>(_onProfileCompletionSkipped);
    on<AuthProfileCompletionChecked>(_onProfileCompletionChecked);
    on<AuthAccountSecurityRequested>(
      _onAuthAccountSecurityRequested,
      transformer: droppable(),
    );
    on<AuthSetPasswordRequested>(
      _onAuthSetPasswordRequested,
      transformer: droppable(),
    );
    on<AuthProfilePictureUpdateRequested>(
      _onProfilePictureUpdateRequested,
      transformer: droppable(),
    );
    on<AuthErrorReset>(_onAuthErrorReset);
    on<AuthVerificationAcknowledged>(_onVerificationAcknowledged);
    on<AuthUsernameCheckRequested>(_onUsernameCheckRequested);
    on<AuthPhoneCheckRequested>(_onPhoneCheckRequested);
    on<AuthPasswordPolicyCheckRequested>(
      _onPasswordPolicyCheckRequested,
      transformer: restartable(),
    );
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));

    final result = await getCurrentUser(const NoParams());

    result.fold(
      (_) => emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          clearAuthSecurity: true,
          shouldCompleteProfile: false,
          isCheckingUsername: false,
          clearEmailLinkSentEmail: true,
          clearPendingEmailLink: true,
          clearPendingGoogleProfileData: true,
        ),
      ),
      (user) {
        if (user == null) {
          emit(
            state.copyWith(
              status: AuthStatus.unauthenticated,
              clearAuthSecurity: true,
              shouldCompleteProfile: false,
              isCheckingUsername: false,
              clearEmailLinkSentEmail: true,
              clearPendingEmailLink: true,
              clearPendingGoogleProfileData: true,
            ),
          );
          return;
        }

        if (user.username.trim().isEmpty) {
          emit(
            state.copyWith(
              status: AuthStatus.usernameSetupRequired,
              user: user,
              clearError: true,
              clearAuthSecurity: true,
              clearPendingVerificationEmail: true,
              clearEmailLinkSentEmail: true,
              clearPendingEmailLink: true,
              shouldCompleteProfile: false,
              pendingGoogleProfileData: GooglePendingProfileData(
                email: user.email,
                displayName: user.displayName,
                photoUrl: user.photoUrl,
              ),
            ),
          );
          return;
        }

        _emitAuthenticatedState(
          emit,
          user,
          clearPendingVerificationEmail: true,
          clearPendingGoogleProfileData: true,
        );
      },
    );
  }

  Future<void> _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    developer.log('_onAuthLoginRequested: emitting loading', name: 'AuthBloc');
    emit(state.copyWith(status: AuthStatus.loading));

    final result = await login(
      LoginParams(email: event.email, password: event.password),
    );

    result.fold(
      (failure) {
        developer.log('login failed: ${failure.message}', name: 'AuthBloc');
        emit(
          state.copyWith(
            status: AuthStatus.error,
            errorMessage: failure.message,
            shouldCompleteProfile: false,
            isCheckingUsername: false,
          ),
        );
      },
      (user) {
        developer.log('login success: user=${user.id}', name: 'AuthBloc');
        _emitAuthenticatedState(
          emit,
          user,
          clearPendingVerificationEmail: true,
          clearPendingGoogleProfileData: true,
        );
      },
    );
  }

  Future<void> _onAuthEmailLinkSignInRequested(
    AuthEmailLinkSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(
      state.copyWith(
        isSendingEmailLink: true,
        clearError: true,
        clearEmailLinkSentEmail: true,
      ),
    );

    final result = await sendEmailLinkSignIn(
      SendEmailLinkSignInParams(email: event.email),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: AuthStatus.error,
          errorMessage: failure.message,
          isSendingEmailLink: false,
          shouldCompleteProfile: false,
          isCheckingUsername: false,
        ),
      ),
      (_) => emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          isSendingEmailLink: false,
          emailLinkSentEmail: event.email.trim().toLowerCase(),
          clearError: true,
        ),
      ),
    );
  }

  Future<void> _onAuthEmailLinkDetected(
    AuthEmailLinkDetected event,
    Emitter<AuthState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AuthStatus.loading,
        clearError: true,
        clearAccountSecurityMessage: true,
      ),
    );

    final storedEmailResult = await getPendingEmailLinkEmail(const NoParams());

    await storedEmailResult.fold(
      (failure) async => emit(
        state.copyWith(
          status: AuthStatus.error,
          errorMessage: failure.message,
          shouldCompleteProfile: false,
        ),
      ),
      (storedEmail) async {
        final normalizedEmail = storedEmail?.trim().toLowerCase() ?? '';
        if (normalizedEmail.isEmpty) {
          emit(
            state.copyWith(
              status: AuthStatus.unauthenticated,
              pendingEmailLink: event.emailLink,
              clearError: true,
            ),
          );
          return;
        }

        await _completeEmailLinkFlow(
          emit,
          email: normalizedEmail,
          emailLink: event.emailLink,
        );
      },
    );
  }

  Future<void> _onAuthEmailLinkCompletionRequested(
    AuthEmailLinkCompletionRequested event,
    Emitter<AuthState> emit,
  ) async {
    final pendingEmailLink = state.pendingEmailLink;
    if (pendingEmailLink == null || pendingEmailLink.isEmpty) {
      emit(
        state.copyWith(
          status: AuthStatus.error,
          errorMessage: 'Open the latest sign-in link from your email first.',
          shouldCompleteProfile: false,
        ),
      );
      return;
    }

    emit(state.copyWith(status: AuthStatus.loading, clearError: true));

    await _completeEmailLinkFlow(
      emit,
      email: event.email.trim().toLowerCase(),
      emailLink: pendingEmailLink,
    );
  }

  Future<void> _onAuthGoogleSignInRequested(
    AuthGoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AuthStatus.loading,
        clearError: true,
        clearEmailLinkSentEmail: true,
        clearPendingVerificationEmail: true,
      ),
    );

    final result = await signInWithGoogle(const NoParams());

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: AuthStatus.error,
          errorMessage: failure.message,
          shouldCompleteProfile: false,
          isCheckingUsername: false,
        ),
      ),
      (googleResult) {
        switch (googleResult) {
          case GoogleAuthAuthenticated():
            _emitAuthenticatedState(
              emit,
              googleResult.user,
              clearPendingVerificationEmail: true,
              clearPendingGoogleProfileData: true,
            );
          case GoogleAuthUsernameSetupRequired():
            emit(
              state.copyWith(
                status: AuthStatus.usernameSetupRequired,
                clearError: true,
                clearAuthSecurity: true,
                clearPendingVerificationEmail: true,
                clearEmailLinkSentEmail: true,
                clearPendingEmailLink: true,
                shouldCompleteProfile: false,
                pendingGoogleProfileData: googleResult.pendingProfileData,
                isCheckingUsername: false,
              ),
            );
          case GoogleAuthLinkRequired():
            emit(
              state.copyWith(
                status: AuthStatus.googleLinkRequired,
                clearError: true,
                clearAuthSecurity: true,
                clearPendingVerificationEmail: true,
                clearEmailLinkSentEmail: true,
                clearPendingEmailLink: true,
                shouldCompleteProfile: false,
                pendingGoogleProfileData: googleResult.pendingProfileData,
                isCheckingUsername: false,
              ),
            );
        }
      },
    );
  }

  Future<void> _onAuthGoogleUsernameCompletionRequested(
    AuthGoogleUsernameCompletionRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));

    final result = await completeGoogleOnboarding(
      CompleteGoogleOnboardingParams(
        username: event.username,
        password: event.password,
      ),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: AuthStatus.error,
          errorMessage: failure.message,
          shouldCompleteProfile: false,
          isCheckingUsername: false,
        ),
      ),
      (user) => _emitAuthenticatedState(
        emit,
        user,
        clearPendingVerificationEmail: true,
        clearPendingGoogleProfileData: true,
      ),
    );
  }

  Future<void> _onAuthGoogleLinkRequested(
    AuthGoogleLinkRequested event,
    Emitter<AuthState> emit,
  ) async {
    final pendingProfile = state.pendingGoogleProfileData;
    if (pendingProfile == null) {
      emit(
        state.copyWith(
          status: AuthStatus.error,
          errorMessage: 'Google sign-in must be restarted before linking.',
          shouldCompleteProfile: false,
        ),
      );
      return;
    }

    emit(state.copyWith(status: AuthStatus.loading, clearError: true));

    final result = await linkGoogleSignIn(
      LinkGoogleSignInParams(password: event.password, profile: pendingProfile),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: AuthStatus.error,
          errorMessage: failure.message,
          shouldCompleteProfile: false,
          isCheckingUsername: false,
        ),
      ),
      (user) => _emitAuthenticatedState(
        emit,
        user,
        clearPendingVerificationEmail: true,
        clearPendingGoogleProfileData: true,
      ),
    );
  }

  Future<void> _onAuthGoogleOnboardingCancelled(
    AuthGoogleOnboardingCancelled event,
    Emitter<AuthState> emit,
  ) async {
    await logout(const NoParams());
    emit(
      state.copyWith(
        status: AuthStatus.unauthenticated,
        clearUser: true,
        clearAuthSecurity: true,
        clearError: true,
        clearAccountSecurityMessage: true,
        clearEmailLinkSentEmail: true,
        clearPendingEmailLink: true,
        clearPendingVerificationEmail: true,
        clearPendingGoogleProfileData: true,
        shouldCompleteProfile: false,
        isCheckingUsername: false,
      ),
    );
  }

  Future<void> _onAuthRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));

    final result = await register(
      RegisterParams(
        email: event.email,
        password: event.password,
        username: event.username,
        displayName: event.displayName,
      ),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: AuthStatus.error,
          errorMessage: failure.message,
          shouldCompleteProfile: false,
          isCheckingUsername: false,
          clearAuthSecurity: true,
          clearPendingGoogleProfileData: true,
        ),
      ),
      (user) => emit(
        state.copyWith(
          status: AuthStatus.emailVerificationSent,
          user: user,
          clearError: true,
          clearAuthSecurity: true,
          clearEmailLinkSentEmail: true,
          clearPendingEmailLink: true,
          pendingVerificationEmail: user.email,
          shouldCompleteProfile: false,
          isCheckingUsername: false,
          clearPendingGoogleProfileData: true,
        ),
      ),
    );
  }

  Future<void> _onAuthResetPasswordRequested(
    AuthResetPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));

    final result = await resetPassword(ResetPasswordParams(email: event.email));

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: AuthStatus.error,
          errorMessage: failure.message,
          shouldCompleteProfile: false,
          isCheckingUsername: false,
          clearAuthSecurity: true,
          clearPendingGoogleProfileData: true,
        ),
      ),
      (_) => emit(
        state.copyWith(
          status: AuthStatus.passwordResetSent,
          clearError: true,
          clearAuthSecurity: true,
        ),
      ),
    );
  }

  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));

    final result = await logout(const NoParams());

    result.fold(
      (failure) => emit(
        state.copyWith(status: AuthStatus.error, errorMessage: failure.message),
      ),
      (_) => emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          clearUser: true,
          clearAuthSecurity: true,
          clearAccountSecurityMessage: true,
          clearEmailLinkSentEmail: true,
          clearPendingEmailLink: true,
          clearPendingVerificationEmail: true,
          clearPendingGoogleProfileData: true,
          shouldCompleteProfile: false,
        ),
      ),
    );
  }

  Future<void> _onProfileUpdateRequested(
    AuthProfileUpdateRequested event,
    Emitter<AuthState> emit,
  ) async {
    final previousPaymentIdentity = _normalizePaymentIdentity(
      state.user?.paymentIdentity,
    );
    final wasProfileCompletionRequired =
        state.status == AuthStatus.profileCompletionRequired;
    emit(state.copyWith(status: AuthStatus.loading));

    final result = await updateProfile(
      UpdateProfileParams(
        displayName: event.displayName,
        phone: event.phone,
        photoUrl: null,
        paymentIdentity: event.paymentIdentity,
      ),
    );

    await result.fold(
      (failure) async {
        emit(
          state.copyWith(
            status: AuthStatus.error,
            errorMessage: failure.message,
            shouldCompleteProfile: wasProfileCompletionRequired,
          ),
        );
      },
      (user) async {
        final shouldGateProfileCompletion =
            wasProfileCompletionRequired && _requiresProfileCompletion(user);
        emit(
          state.copyWith(
            status: shouldGateProfileCompletion
                ? AuthStatus.profileCompletionRequired
                : AuthStatus.authenticated,
            user: user,
            clearError: true,
            clearAccountSecurityMessage: true,
            clearEmailLinkSentEmail: true,
            clearPendingEmailLink: true,
            clearPendingVerificationEmail: true,
            clearPendingGoogleProfileData: true,
            shouldCompleteProfile: shouldGateProfileCompletion,
          ),
        );

        await _syncPendingExpensePaymentIdentityIfNeeded(
          user: user,
          previousPaymentIdentity: previousPaymentIdentity,
        );
      },
    );
  }

  Future<void> _onProfileCompletionSkipped(
    AuthProfileCompletionSkipped event,
    Emitter<AuthState> emit,
  ) async {
    if (state.user == null) return;

    emit(
      state.copyWith(
        status: AuthStatus.authenticated,
        clearError: true,
        clearAccountSecurityMessage: true,
        clearEmailLinkSentEmail: true,
        clearPendingEmailLink: true,
        clearPendingVerificationEmail: true,
        clearPendingGoogleProfileData: true,
        shouldCompleteProfile: false,
      ),
    );
  }

  Future<void> _onProfileCompletionChecked(
    AuthProfileCompletionChecked event,
    Emitter<AuthState> emit,
  ) async {
    final user = state.user;
    if (user == null) return;

    _emitAuthenticatedState(
      emit,
      user,
      clearPendingVerificationEmail: true,
      clearPendingGoogleProfileData: true,
    );
  }

  Future<void> _onAuthAccountSecurityRequested(
    AuthAccountSecurityRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(
      state.copyWith(
        isLoadingAccountSecurity: true,
        clearError: true,
        clearAccountSecurityMessage: true,
      ),
    );

    final result = await getAuthSecurity(const NoParams());

    result.fold(
      (failure) => emit(
        state.copyWith(
          errorMessage: failure.message,
          isLoadingAccountSecurity: false,
        ),
      ),
      (security) => emit(
        state.copyWith(
          authSecurity: security,
          isLoadingAccountSecurity: false,
          clearError: true,
        ),
      ),
    );
  }

  Future<void> _onAuthSetPasswordRequested(
    AuthSetPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(
      state.copyWith(
        isSettingPassword: true,
        clearError: true,
        clearAccountSecurityMessage: true,
      ),
    );

    final result = await setPassword(
      SetPasswordParams(password: event.password),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(errorMessage: failure.message, isSettingPassword: false),
      ),
      (security) => emit(
        state.copyWith(
          authSecurity: security,
          isSettingPassword: false,
          accountSecurityMessage: 'Password sign-in is now enabled.',
          clearError: true,
          clearPasswordValidation: true,
          clearPasswordValidationError: true,
        ),
      ),
    );
  }

  Future<void> _onProfilePictureUpdateRequested(
    AuthProfilePictureUpdateRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (state.user == null) return;

    final wasProfileCompletionRequired =
        state.status == AuthStatus.profileCompletionRequired;
    emit(state.copyWith(isUploadingPhoto: true, uploadProgress: 0.0));

    final uploadResult = await uploadProfileImage(
      UploadProfileImageParams(
        userId: state.user!.id,
        imagePath: event.imagePath,
      ),
    );

    await uploadResult.fold(
      (failure) async => emit(
        state.copyWith(
          status: AuthStatus.error,
          errorMessage: failure.message,
          isUploadingPhoto: false,
          uploadProgress: 0.0,
          shouldCompleteProfile: wasProfileCompletionRequired,
        ),
      ),
      (photoUrl) async {
        emit(state.copyWith(uploadProgress: 0.5));

        final result = await updateProfile(
          UpdateProfileParams(
            displayName: state.user!.displayName,
            phone: state.user!.phone,
            photoUrl: photoUrl,
            paymentIdentity: state.user!.paymentIdentity,
          ),
        );

        result.fold(
          (failure) => emit(
            state.copyWith(
              status: AuthStatus.error,
              errorMessage: failure.message,
              isUploadingPhoto: false,
              uploadProgress: 0.0,
            ),
          ),
          (user) => emit(
            state.copyWith(
              status:
                  wasProfileCompletionRequired &&
                      _requiresProfileCompletion(user)
                  ? AuthStatus.profileCompletionRequired
                  : AuthStatus.authenticated,
              user: user,
              clearError: true,
              clearAccountSecurityMessage: true,
              clearEmailLinkSentEmail: true,
              clearPendingEmailLink: true,
              isUploadingPhoto: false,
              uploadProgress: 1.0,
              shouldCompleteProfile:
                  wasProfileCompletionRequired &&
                  _requiresProfileCompletion(user),
              clearPendingVerificationEmail: true,
              clearPendingGoogleProfileData: true,
            ),
          ),
        );
      },
    );
  }

  void _onAuthErrorReset(AuthErrorReset event, Emitter<AuthState> emit) {
    final keepStatus = switch (state.status) {
      AuthStatus.authenticated => AuthStatus.authenticated,
      AuthStatus.profileCompletionRequired =>
        AuthStatus.profileCompletionRequired,
      AuthStatus.usernameSetupRequired => AuthStatus.usernameSetupRequired,
      AuthStatus.googleLinkRequired => AuthStatus.googleLinkRequired,
      _ => AuthStatus.unauthenticated,
    };

    emit(
      state.copyWith(
        status: keepStatus,
        clearUser: keepStatus == AuthStatus.unauthenticated,
        clearAuthSecurity: keepStatus == AuthStatus.unauthenticated,
        clearError: true,
        clearAccountSecurityMessage: true,
        shouldCompleteProfile:
            keepStatus == AuthStatus.profileCompletionRequired,
        isCheckingUsername: false,
      ),
    );
  }

  void _onVerificationAcknowledged(
    AuthVerificationAcknowledged event,
    Emitter<AuthState> emit,
  ) {
    emit(
      state.copyWith(
        status: AuthStatus.unauthenticated,
        clearUser: true,
        clearAuthSecurity: true,
        clearError: true,
        clearAccountSecurityMessage: true,
        clearEmailLinkSentEmail: true,
        clearPendingEmailLink: true,
        shouldCompleteProfile: false,
        isCheckingUsername: false,
        clearPendingGoogleProfileData: true,
      ),
    );
  }

  Future<void> _onUsernameCheckRequested(
    AuthUsernameCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (event.username.isEmpty) {
      emit(
        state.copyWith(
          clearUsernameAvailable: true,
          isCheckingUsername: false,
          clearError: true,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        clearUsernameAvailable: true,
        isCheckingUsername: true,
        clearError: true,
      ),
    );

    final result = await checkUsernameAvailability(event.username);

    result.fold(
      (failure) => emit(
        state.copyWith(
          errorMessage: failure.message,
          isCheckingUsername: false,
        ),
      ),
      (available) => emit(
        state.copyWith(
          usernameAvailable: available,
          isCheckingUsername: false,
          clearError: true,
        ),
      ),
    );
  }

  Future<void> _onPhoneCheckRequested(
    AuthPhoneCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (event.phone.isEmpty) {
      emit(state.copyWith(clearPhoneAvailable: true));
      return;
    }

    emit(state.copyWith(clearPhoneAvailable: true));

    final result = await checkPhoneAvailability(event.phone);

    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (available) => emit(state.copyWith(phoneAvailable: available)),
    );
  }

  Future<void> _onPasswordPolicyCheckRequested(
    AuthPasswordPolicyCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (event.password.isEmpty) {
      emit(
        state.copyWith(
          clearPasswordValidation: true,
          clearPasswordValidationError: true,
          isCheckingPasswordPolicy: false,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        clearPasswordValidation: true,
        clearPasswordValidationError: true,
        isCheckingPasswordPolicy: true,
      ),
    );

    final result = await validatePasswordPolicy(event.password);

    result.fold(
      (failure) => emit(
        state.copyWith(
          passwordValidationError: failure.message,
          isCheckingPasswordPolicy: false,
        ),
      ),
      (validation) => emit(
        state.copyWith(
          passwordValidation: validation,
          clearPasswordValidationError: true,
          isCheckingPasswordPolicy: false,
        ),
      ),
    );
  }

  Future<void> _syncPendingExpensePaymentIdentityIfNeeded({
    required User user,
    required String? previousPaymentIdentity,
  }) async {
    final nextPaymentIdentity = _normalizePaymentIdentity(user.paymentIdentity);
    if (nextPaymentIdentity == null ||
        nextPaymentIdentity == previousPaymentIdentity) {
      return;
    }

    final result = await syncOwnerPaymentIdentityToPendingExpenses(
      SyncOwnerPaymentIdentityToPendingExpensesParams(
        ownerId: user.id,
        paymentIdentity: nextPaymentIdentity,
      ),
    );

    result.fold(
      (failure) => developer.log(
        'Pending expense payment identity sync failed',
        error: failure.message,
        name: 'AuthBloc',
      ),
      (_) => null,
    );
  }

  String? _normalizePaymentIdentity(String? paymentIdentity) {
    final trimmed = paymentIdentity?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> _completeEmailLinkFlow(
    Emitter<AuthState> emit, {
    required String email,
    required String emailLink,
  }) async {
    final result = await completeEmailLinkSignIn(
      CompleteEmailLinkSignInParams(email: email, emailLink: emailLink),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: AuthStatus.error,
          errorMessage: failure.message,
          shouldCompleteProfile: false,
          isCheckingUsername: false,
          pendingEmailLink: emailLink,
        ),
      ),
      (user) => _emitAuthenticatedState(
        emit,
        user,
        clearPendingVerificationEmail: true,
        clearPendingGoogleProfileData: true,
      ),
    );
  }

  void _emitAuthenticatedState(
    Emitter<AuthState> emit,
    User user, {
    required bool clearPendingVerificationEmail,
    required bool clearPendingGoogleProfileData,
  }) {
    final shouldCompleteProfile = _requiresProfileCompletion(user);
    emit(
      state.copyWith(
        status: shouldCompleteProfile
            ? AuthStatus.profileCompletionRequired
            : AuthStatus.authenticated,
        user: user,
        clearError: true,
        clearAccountSecurityMessage: true,
        clearEmailLinkSentEmail: true,
        clearPendingEmailLink: true,
        clearPendingVerificationEmail: clearPendingVerificationEmail,
        clearPendingGoogleProfileData: clearPendingGoogleProfileData,
        shouldCompleteProfile: shouldCompleteProfile,
        isCheckingUsername: false,
      ),
    );
  }

  bool _requiresProfileCompletion(User user) {
    final phone = user.phone.trim();
    final paymentIdentity = user.paymentIdentity?.trim() ?? '';
    final photoUrl = user.photoUrl?.trim() ?? '';
    return phone.isEmpty && paymentIdentity.isEmpty && photoUrl.isEmpty;
  }
}
