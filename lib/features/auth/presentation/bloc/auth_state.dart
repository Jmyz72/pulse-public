part of 'auth_bloc.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
  passwordResetSent,
  emailVerificationSent,
  profileCompletionRequired,
  usernameSetupRequired,
  googleLinkRequired,
}

class AuthState extends Equatable {
  final AuthStatus status;
  final User? user;
  final AuthSecurity? authSecurity;
  final String? errorMessage;
  final String? accountSecurityMessage;
  final bool? usernameAvailable;
  final bool isCheckingUsername;
  final bool? phoneAvailable;
  final PasswordPolicyValidation? passwordValidation;
  final String? passwordValidationError;
  final bool isCheckingPasswordPolicy;
  final bool isSendingEmailLink;
  final bool isLoadingAccountSecurity;
  final bool isSettingPassword;
  final bool isUploadingPhoto;
  final double uploadProgress;
  final String? emailLinkSentEmail;
  final String? pendingEmailLink;
  final String? pendingVerificationEmail;
  final bool shouldCompleteProfile;
  final GooglePendingProfileData? pendingGoogleProfileData;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.authSecurity,
    this.errorMessage,
    this.accountSecurityMessage,
    this.usernameAvailable,
    this.isCheckingUsername = false,
    this.phoneAvailable,
    this.passwordValidation,
    this.passwordValidationError,
    this.isCheckingPasswordPolicy = false,
    this.isSendingEmailLink = false,
    this.isLoadingAccountSecurity = false,
    this.isSettingPassword = false,
    this.isUploadingPhoto = false,
    this.uploadProgress = 0.0,
    this.emailLinkSentEmail,
    this.pendingEmailLink,
    this.pendingVerificationEmail,
    this.shouldCompleteProfile = false,
    this.pendingGoogleProfileData,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    bool clearUser = false,
    AuthSecurity? authSecurity,
    bool clearAuthSecurity = false,
    String? errorMessage,
    bool clearError = false,
    String? accountSecurityMessage,
    bool clearAccountSecurityMessage = false,
    bool? usernameAvailable,
    bool clearUsernameAvailable = false,
    bool? isCheckingUsername,
    bool? phoneAvailable,
    bool clearPhoneAvailable = false,
    PasswordPolicyValidation? passwordValidation,
    bool clearPasswordValidation = false,
    String? passwordValidationError,
    bool clearPasswordValidationError = false,
    bool? isCheckingPasswordPolicy,
    bool? isSendingEmailLink,
    String? emailLinkSentEmail,
    bool clearEmailLinkSentEmail = false,
    String? pendingEmailLink,
    bool clearPendingEmailLink = false,
    bool? isLoadingAccountSecurity,
    bool? isSettingPassword,
    bool? isUploadingPhoto,
    double? uploadProgress,
    String? pendingVerificationEmail,
    bool clearPendingVerificationEmail = false,
    bool? shouldCompleteProfile,
    GooglePendingProfileData? pendingGoogleProfileData,
    bool clearPendingGoogleProfileData = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      authSecurity: clearAuthSecurity
          ? null
          : (authSecurity ?? this.authSecurity),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      accountSecurityMessage: clearAccountSecurityMessage
          ? null
          : (accountSecurityMessage ?? this.accountSecurityMessage),
      usernameAvailable: clearUsernameAvailable
          ? null
          : (usernameAvailable ?? this.usernameAvailable),
      isCheckingUsername: isCheckingUsername ?? this.isCheckingUsername,
      phoneAvailable: clearPhoneAvailable
          ? null
          : (phoneAvailable ?? this.phoneAvailable),
      passwordValidation: clearPasswordValidation
          ? null
          : (passwordValidation ?? this.passwordValidation),
      passwordValidationError: clearPasswordValidationError
          ? null
          : (passwordValidationError ?? this.passwordValidationError),
      isCheckingPasswordPolicy:
          isCheckingPasswordPolicy ?? this.isCheckingPasswordPolicy,
      isSendingEmailLink: isSendingEmailLink ?? this.isSendingEmailLink,
      isLoadingAccountSecurity:
          isLoadingAccountSecurity ?? this.isLoadingAccountSecurity,
      isSettingPassword: isSettingPassword ?? this.isSettingPassword,
      isUploadingPhoto: isUploadingPhoto ?? this.isUploadingPhoto,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      emailLinkSentEmail: clearEmailLinkSentEmail
          ? null
          : (emailLinkSentEmail ?? this.emailLinkSentEmail),
      pendingEmailLink: clearPendingEmailLink
          ? null
          : (pendingEmailLink ?? this.pendingEmailLink),
      pendingVerificationEmail: clearPendingVerificationEmail
          ? null
          : (pendingVerificationEmail ?? this.pendingVerificationEmail),
      shouldCompleteProfile:
          shouldCompleteProfile ?? this.shouldCompleteProfile,
      pendingGoogleProfileData: clearPendingGoogleProfileData
          ? null
          : (pendingGoogleProfileData ?? this.pendingGoogleProfileData),
    );
  }

  @override
  List<Object?> get props => [
    status,
    user,
    authSecurity,
    errorMessage,
    accountSecurityMessage,
    usernameAvailable,
    isCheckingUsername,
    phoneAvailable,
    passwordValidation,
    passwordValidationError,
    isCheckingPasswordPolicy,
    isSendingEmailLink,
    isLoadingAccountSecurity,
    isSettingPassword,
    isUploadingPhoto,
    uploadProgress,
    emailLinkSentEmail,
    pendingEmailLink,
    pendingVerificationEmail,
    shouldCompleteProfile,
    pendingGoogleProfileData,
  ];
}
