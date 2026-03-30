import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/failures.dart';
import 'package:pulse/core/usecases/usecase.dart';
import 'package:pulse/features/auth/domain/entities/auth_security.dart';
import 'package:pulse/features/auth/domain/entities/google_auth_result.dart';
import 'package:pulse/features/auth/domain/entities/password_policy_validation.dart';
import 'package:pulse/features/auth/domain/entities/user.dart';
import 'package:pulse/features/auth/domain/usecases/complete_email_link_sign_in.dart';
import 'package:pulse/features/auth/domain/usecases/get_current_user.dart';
import 'package:pulse/features/auth/domain/usecases/get_auth_security.dart';
import 'package:pulse/features/auth/domain/usecases/get_pending_email_link_email.dart';
import 'package:pulse/features/auth/domain/usecases/complete_google_onboarding.dart';
import 'package:pulse/features/auth/domain/usecases/link_google_sign_in.dart';
import 'package:pulse/features/auth/domain/usecases/login.dart';
import 'package:pulse/features/auth/domain/usecases/logout.dart';
import 'package:pulse/features/auth/domain/usecases/register.dart';
import 'package:pulse/features/auth/domain/usecases/reset_password.dart';
import 'package:pulse/features/auth/domain/usecases/send_email_link_sign_in.dart';
import 'package:pulse/features/auth/domain/usecases/set_password.dart';
import 'package:pulse/features/auth/domain/usecases/sign_in_with_google.dart';
import 'package:pulse/features/auth/domain/usecases/check_phone_availability.dart';
import 'package:pulse/features/auth/domain/usecases/check_username_availability.dart';
import 'package:pulse/features/auth/domain/usecases/update_profile.dart';
import 'package:pulse/features/auth/domain/usecases/upload_profile_image.dart';
import 'package:pulse/features/auth/domain/usecases/validate_password_policy.dart';
import 'package:pulse/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pulse/features/expense/domain/usecases/sync_owner_payment_identity_to_pending_expenses.dart';

class MockGetCurrentUser extends Mock implements GetCurrentUser {}

class MockGetAuthSecurity extends Mock implements GetAuthSecurity {}

class MockLogin extends Mock implements Login {}

class MockSignInWithGoogle extends Mock implements SignInWithGoogle {}

class MockSendEmailLinkSignIn extends Mock implements SendEmailLinkSignIn {}

class MockGetPendingEmailLinkEmail extends Mock
    implements GetPendingEmailLinkEmail {}

class MockCompleteEmailLinkSignIn extends Mock
    implements CompleteEmailLinkSignIn {}

class MockCompleteGoogleOnboarding extends Mock
    implements CompleteGoogleOnboarding {}

class MockLinkGoogleSignIn extends Mock implements LinkGoogleSignIn {}

class MockRegister extends Mock implements Register {}

class MockLogout extends Mock implements Logout {}

class MockResetPassword extends Mock implements ResetPassword {}

class MockSetPassword extends Mock implements SetPassword {}

class MockUpdateProfile extends Mock implements UpdateProfile {}

class MockCheckUsernameAvailability extends Mock
    implements CheckUsernameAvailability {}

class MockCheckPhoneAvailability extends Mock
    implements CheckPhoneAvailability {}

class MockValidatePasswordPolicy extends Mock
    implements ValidatePasswordPolicy {}

class MockUploadProfileImage extends Mock implements UploadProfileImage {}

class MockSyncOwnerPaymentIdentityToPendingExpenses extends Mock
    implements SyncOwnerPaymentIdentityToPendingExpenses {}

void main() {
  late AuthBloc bloc;
  late MockGetCurrentUser mockGetCurrentUser;
  late MockGetAuthSecurity mockGetAuthSecurity;
  late MockLogin mockLogin;
  late MockSignInWithGoogle mockSignInWithGoogle;
  late MockSendEmailLinkSignIn mockSendEmailLinkSignIn;
  late MockGetPendingEmailLinkEmail mockGetPendingEmailLinkEmail;
  late MockCompleteEmailLinkSignIn mockCompleteEmailLinkSignIn;
  late MockCompleteGoogleOnboarding mockCompleteGoogleOnboarding;
  late MockLinkGoogleSignIn mockLinkGoogleSignIn;
  late MockRegister mockRegister;
  late MockLogout mockLogout;
  late MockResetPassword mockResetPassword;
  late MockSetPassword mockSetPassword;
  late MockUpdateProfile mockUpdateProfile;
  late MockCheckUsernameAvailability mockCheckUsernameAvailability;
  late MockCheckPhoneAvailability mockCheckPhoneAvailability;
  late MockValidatePasswordPolicy mockValidatePasswordPolicy;
  late MockUploadProfileImage mockUploadProfileImage;
  late MockSyncOwnerPaymentIdentityToPendingExpenses
  mockSyncOwnerPaymentIdentityToPendingExpenses;

  setUp(() {
    mockGetCurrentUser = MockGetCurrentUser();
    mockGetAuthSecurity = MockGetAuthSecurity();
    mockLogin = MockLogin();
    mockSignInWithGoogle = MockSignInWithGoogle();
    mockSendEmailLinkSignIn = MockSendEmailLinkSignIn();
    mockGetPendingEmailLinkEmail = MockGetPendingEmailLinkEmail();
    mockCompleteEmailLinkSignIn = MockCompleteEmailLinkSignIn();
    mockCompleteGoogleOnboarding = MockCompleteGoogleOnboarding();
    mockLinkGoogleSignIn = MockLinkGoogleSignIn();
    mockRegister = MockRegister();
    mockLogout = MockLogout();
    mockResetPassword = MockResetPassword();
    mockSetPassword = MockSetPassword();
    mockUpdateProfile = MockUpdateProfile();
    mockCheckUsernameAvailability = MockCheckUsernameAvailability();
    mockCheckPhoneAvailability = MockCheckPhoneAvailability();
    mockValidatePasswordPolicy = MockValidatePasswordPolicy();
    mockUploadProfileImage = MockUploadProfileImage();
    mockSyncOwnerPaymentIdentityToPendingExpenses =
        MockSyncOwnerPaymentIdentityToPendingExpenses();

    bloc = AuthBloc(
      getCurrentUser: mockGetCurrentUser,
      getAuthSecurity: mockGetAuthSecurity,
      login: mockLogin,
      signInWithGoogle: mockSignInWithGoogle,
      sendEmailLinkSignIn: mockSendEmailLinkSignIn,
      getPendingEmailLinkEmail: mockGetPendingEmailLinkEmail,
      completeEmailLinkSignIn: mockCompleteEmailLinkSignIn,
      completeGoogleOnboarding: mockCompleteGoogleOnboarding,
      linkGoogleSignIn: mockLinkGoogleSignIn,
      register: mockRegister,
      logout: mockLogout,
      resetPassword: mockResetPassword,
      setPassword: mockSetPassword,
      updateProfile: mockUpdateProfile,
      checkUsernameAvailability: mockCheckUsernameAvailability,
      checkPhoneAvailability: mockCheckPhoneAvailability,
      validatePasswordPolicy: mockValidatePasswordPolicy,
      uploadProfileImage: mockUploadProfileImage,
      syncOwnerPaymentIdentityToPendingExpenses:
          mockSyncOwnerPaymentIdentityToPendingExpenses,
    );
  });

  tearDown(() {
    bloc.close();
  });

  const tEmail = 'test@example.com';
  const tPassword = 'Password123!';
  const tUsername = 'testuser';
  const tDisplayName = 'Test User';
  const tPhone = '+60123456789';
  const tGoogleProfile = GooglePendingProfileData(
    email: tEmail,
    displayName: tDisplayName,
    photoUrl: 'https://example.com/google.jpg',
  );
  const tUser = User(
    id: '1',
    username: tUsername,
    displayName: tDisplayName,
    email: tEmail,
    phone: tPhone,
  );
  const tUserNeedsProfileCompletion = User(
    id: '2',
    username: tUsername,
    displayName: tDisplayName,
    email: tEmail,
    phone: '',
  );
  const tUserWithProfileComplete = User(
    id: '3',
    username: tUsername,
    displayName: tDisplayName,
    email: tEmail,
    phone: tPhone,
    paymentIdentity: 'DuitNow Jimmy',
    photoUrl: 'https://example.com/photo.jpg',
  );
  const tPasswordValidation = PasswordPolicyValidation(
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
  const tInvalidPasswordValidation = PasswordPolicyValidation(
    isValid: false,
    minPasswordLength: 8,
    maxPasswordLength: 4096,
    requiresLowercase: true,
    requiresUppercase: true,
    requiresDigits: true,
    requiresSymbols: true,
    meetsMinPasswordLength: true,
    meetsMaxPasswordLength: true,
    meetsLowercaseRequirement: true,
    meetsUppercaseRequirement: false,
    meetsDigitsRequirement: true,
    meetsSymbolsRequirement: false,
  );
  const tAuthSecurity = AuthSecurity(
    email: tEmail,
    hasPasswordProvider: false,
    hasGoogleProvider: true,
    emailVerified: true,
  );
  const tAuthSecurityWithPassword = AuthSecurity(
    email: tEmail,
    hasPasswordProvider: true,
    hasGoogleProvider: true,
    emailVerified: true,
  );

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(
      const LoginParams(email: tEmail, password: tPassword),
    );
    registerFallbackValue(
      const RegisterParams(
        email: tEmail,
        password: tPassword,
        username: tUsername,
        displayName: tDisplayName,
      ),
    );
    registerFallbackValue(const ResetPasswordParams(email: tEmail));
    registerFallbackValue(const SendEmailLinkSignInParams(email: tEmail));
    registerFallbackValue(
      const CompleteEmailLinkSignInParams(
        email: tEmail,
        emailLink: 'https://example.invalid/__/auth/action',
      ),
    );
    registerFallbackValue(const SetPasswordParams(password: tPassword));
    registerFallbackValue(
      const UploadProfileImageParams(userId: '1', imagePath: '/tmp/test.jpg'),
    );
    registerFallbackValue(
      const UpdateProfileParams(displayName: tDisplayName, phone: tPhone),
    );
    registerFallbackValue(
      const SyncOwnerPaymentIdentityToPendingExpensesParams(
        ownerId: '1',
        paymentIdentity: 'DuitNow Jimmy',
      ),
    );
    registerFallbackValue(
      const CompleteGoogleOnboardingParams(
        username: tUsername,
        password: tPassword,
      ),
    );
    registerFallbackValue(
      const LinkGoogleSignInParams(
        password: tPassword,
        profile: tGoogleProfile,
      ),
    );
  });

  group('AuthCheckRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [loading, authenticated] when user is logged in',
      build: () {
        when(
          () => mockGetCurrentUser(any()),
        ).thenAnswer((_) async => const Right(tUser));
        return bloc;
      },
      act: (bloc) => bloc.add(AuthCheckRequested()),
      expect: () => [
        const AuthState(status: AuthStatus.loading),
        const AuthState(status: AuthStatus.authenticated, user: tUser),
      ],
      verify: (_) {
        verify(() => mockGetCurrentUser(any())).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'emits [loading, profileCompletionRequired] when cached user is missing optional profile data',
      build: () {
        when(
          () => mockGetCurrentUser(any()),
        ).thenAnswer((_) async => const Right(tUserNeedsProfileCompletion));
        return bloc;
      },
      act: (bloc) => bloc.add(AuthCheckRequested()),
      expect: () => [
        const AuthState(status: AuthStatus.loading),
        const AuthState(
          status: AuthStatus.profileCompletionRequired,
          user: tUserNeedsProfileCompletion,
          shouldCompleteProfile: true,
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [loading, usernameSetupRequired] when Google auth user has no username yet',
      build: () {
        when(() => mockGetCurrentUser(any())).thenAnswer(
          (_) async => const Right(
            User(
              id: 'google-1',
              username: '',
              displayName: tDisplayName,
              email: tEmail,
              phone: '',
              photoUrl: 'https://example.com/google.jpg',
            ),
          ),
        );
        return bloc;
      },
      act: (bloc) => bloc.add(AuthCheckRequested()),
      expect: () => [
        const AuthState(status: AuthStatus.loading),
        const AuthState(
          status: AuthStatus.usernameSetupRequired,
          user: User(
            id: 'google-1',
            username: '',
            displayName: tDisplayName,
            email: tEmail,
            phone: '',
            photoUrl: 'https://example.com/google.jpg',
          ),
          pendingGoogleProfileData: tGoogleProfile,
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [loading, unauthenticated] when no user is logged in',
      build: () {
        when(
          () => mockGetCurrentUser(any()),
        ).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (bloc) => bloc.add(AuthCheckRequested()),
      expect: () => [
        const AuthState(status: AuthStatus.loading),
        const AuthState(status: AuthStatus.unauthenticated),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [loading, unauthenticated] when auth check fails',
      build: () {
        when(() => mockGetCurrentUser(any())).thenAnswer(
          (_) async => const Left(AuthFailure(message: 'Auth check failed')),
        );
        return bloc;
      },
      act: (bloc) => bloc.add(AuthCheckRequested()),
      expect: () => [
        const AuthState(status: AuthStatus.loading),
        const AuthState(status: AuthStatus.unauthenticated),
      ],
    );
  });

  group('AuthGoogleSignInRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [loading, authenticated] when Google sign-in returns an existing user',
      build: () {
        when(
          () => mockSignInWithGoogle(any()),
        ).thenAnswer((_) async => const Right(GoogleAuthAuthenticated(tUser)));
        return bloc;
      },
      act: (bloc) => bloc.add(AuthGoogleSignInRequested()),
      expect: () => [
        const AuthState(status: AuthStatus.loading),
        const AuthState(status: AuthStatus.authenticated, user: tUser),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [loading, usernameSetupRequired] when Google sign-in needs onboarding',
      build: () {
        when(() => mockSignInWithGoogle(any())).thenAnswer(
          (_) async =>
              const Right(GoogleAuthUsernameSetupRequired(tGoogleProfile)),
        );
        return bloc;
      },
      act: (bloc) => bloc.add(AuthGoogleSignInRequested()),
      expect: () => [
        const AuthState(status: AuthStatus.loading),
        const AuthState(
          status: AuthStatus.usernameSetupRequired,
          pendingGoogleProfileData: tGoogleProfile,
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [loading, googleLinkRequired] when Google sign-in hits an existing email/password account',
      build: () {
        when(() => mockSignInWithGoogle(any())).thenAnswer(
          (_) async => const Right(
            GoogleAuthLinkRequired(
              pendingProfileData: tGoogleProfile,
              email: tEmail,
            ),
          ),
        );
        return bloc;
      },
      act: (bloc) => bloc.add(AuthGoogleSignInRequested()),
      expect: () => [
        const AuthState(status: AuthStatus.loading),
        const AuthState(
          status: AuthStatus.googleLinkRequired,
          pendingGoogleProfileData: tGoogleProfile,
        ),
      ],
    );
  });

  group('AuthLoginRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [loading, authenticated] when login succeeds',
      build: () {
        when(
          () => mockLogin(any()),
        ).thenAnswer((_) async => const Right(tUser));
        return bloc;
      },
      act: (bloc) => bloc.add(
        const AuthLoginRequested(email: tEmail, password: tPassword),
      ),
      expect: () => [
        const AuthState(status: AuthStatus.loading),
        const AuthState(status: AuthStatus.authenticated, user: tUser),
      ],
      verify: (_) {
        verify(() => mockLogin(any())).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'emits [loading, profileCompletionRequired] when login succeeds but optional profile data is missing',
      build: () {
        when(
          () => mockLogin(any()),
        ).thenAnswer((_) async => const Right(tUserNeedsProfileCompletion));
        return bloc;
      },
      act: (bloc) => bloc.add(
        const AuthLoginRequested(email: tEmail, password: tPassword),
      ),
      expect: () => [
        const AuthState(status: AuthStatus.loading),
        const AuthState(
          status: AuthStatus.profileCompletionRequired,
          user: tUserNeedsProfileCompletion,
          shouldCompleteProfile: true,
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [loading, error] when login fails with invalid credentials',
      build: () {
        when(() => mockLogin(any())).thenAnswer(
          (_) async => const Left(AuthFailure(message: 'Invalid credentials')),
        );
        return bloc;
      },
      act: (bloc) => bloc.add(
        const AuthLoginRequested(email: tEmail, password: tPassword),
      ),
      expect: () => [
        const AuthState(status: AuthStatus.loading),
        const AuthState(
          status: AuthStatus.error,
          errorMessage: 'Invalid credentials',
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [loading, error] when login fails with network error',
      build: () {
        when(
          () => mockLogin(any()),
        ).thenAnswer((_) async => const Left(NetworkFailure()));
        return bloc;
      },
      act: (bloc) => bloc.add(
        const AuthLoginRequested(email: tEmail, password: tPassword),
      ),
      expect: () => [
        const AuthState(status: AuthStatus.loading),
        const AuthState(
          status: AuthStatus.error,
          errorMessage: 'No internet connection',
        ),
      ],
    );
  });

  group('AuthRegisterRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [loading, emailVerificationSent] when registration succeeds',
      build: () {
        when(
          () => mockRegister(any()),
        ).thenAnswer((_) async => const Right(tUser));
        return bloc;
      },
      act: (bloc) => bloc.add(
        const AuthRegisterRequested(
          email: tEmail,
          password: tPassword,
          username: tUsername,
          displayName: tDisplayName,
          phone: tPhone,
        ),
      ),
      expect: () => [
        const AuthState(status: AuthStatus.loading),
        const AuthState(
          status: AuthStatus.emailVerificationSent,
          user: tUser,
          pendingVerificationEmail: tEmail,
        ),
      ],
      verify: (_) {
        verify(() => mockRegister(any())).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'emits [loading, error] when registration fails with email already in use',
      build: () {
        when(() => mockRegister(any())).thenAnswer(
          (_) async => const Left(AuthFailure(message: 'Email already in use')),
        );
        return bloc;
      },
      act: (bloc) => bloc.add(
        const AuthRegisterRequested(
          email: tEmail,
          password: tPassword,
          username: tUsername,
          displayName: tDisplayName,
          phone: tPhone,
        ),
      ),
      expect: () => [
        const AuthState(status: AuthStatus.loading),
        const AuthState(
          status: AuthStatus.error,
          errorMessage: 'Email already in use',
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [loading, error] when registration fails with network error',
      build: () {
        when(
          () => mockRegister(any()),
        ).thenAnswer((_) async => const Left(NetworkFailure()));
        return bloc;
      },
      act: (bloc) => bloc.add(
        const AuthRegisterRequested(
          email: tEmail,
          password: tPassword,
          username: tUsername,
          displayName: tDisplayName,
          phone: tPhone,
        ),
      ),
      expect: () => [
        const AuthState(status: AuthStatus.loading),
        const AuthState(
          status: AuthStatus.error,
          errorMessage: 'No internet connection',
        ),
      ],
    );
  });

  group('AuthResetPasswordRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [loading, passwordResetSent] when reset password succeeds',
      build: () {
        when(
          () => mockResetPassword(any()),
        ).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (bloc) => bloc.add(const AuthResetPasswordRequested(email: tEmail)),
      expect: () => [
        const AuthState(status: AuthStatus.loading),
        const AuthState(status: AuthStatus.passwordResetSent),
      ],
      verify: (_) {
        verify(() => mockResetPassword(any())).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'emits [loading, error] when reset password fails with user not found',
      build: () {
        when(() => mockResetPassword(any())).thenAnswer(
          (_) async => const Left(AuthFailure(message: 'User not found')),
        );
        return bloc;
      },
      act: (bloc) => bloc.add(const AuthResetPasswordRequested(email: tEmail)),
      expect: () => [
        const AuthState(status: AuthStatus.loading),
        const AuthState(
          status: AuthStatus.error,
          errorMessage: 'User not found',
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [loading, error] when reset password fails with network error',
      build: () {
        when(
          () => mockResetPassword(any()),
        ).thenAnswer((_) async => const Left(NetworkFailure()));
        return bloc;
      },
      act: (bloc) => bloc.add(const AuthResetPasswordRequested(email: tEmail)),
      expect: () => [
        const AuthState(status: AuthStatus.loading),
        const AuthState(
          status: AuthStatus.error,
          errorMessage: 'No internet connection',
        ),
      ],
    );
  });

  group('AuthLogoutRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [loading, unauthenticated] when logout succeeds',
      build: () {
        when(
          () => mockLogout(any()),
        ).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      seed: () =>
          const AuthState(status: AuthStatus.authenticated, user: tUser),
      act: (bloc) => bloc.add(AuthLogoutRequested()),
      expect: () => [
        const AuthState(status: AuthStatus.loading, user: tUser),
        const AuthState(status: AuthStatus.unauthenticated),
      ],
      verify: (_) {
        verify(() => mockLogout(any())).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'emits [loading, error] when logout fails',
      build: () {
        when(() => mockLogout(any())).thenAnswer(
          (_) async => const Left(AuthFailure(message: 'Logout failed')),
        );
        return bloc;
      },
      seed: () =>
          const AuthState(status: AuthStatus.authenticated, user: tUser),
      act: (bloc) => bloc.add(AuthLogoutRequested()),
      expect: () => [
        const AuthState(status: AuthStatus.loading, user: tUser),
        const AuthState(
          status: AuthStatus.error,
          user: tUser,
          errorMessage: 'Logout failed',
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [loading, error] when logout fails with network error',
      build: () {
        when(
          () => mockLogout(any()),
        ).thenAnswer((_) async => const Left(NetworkFailure()));
        return bloc;
      },
      seed: () =>
          const AuthState(status: AuthStatus.authenticated, user: tUser),
      act: (bloc) => bloc.add(AuthLogoutRequested()),
      expect: () => [
        const AuthState(status: AuthStatus.loading, user: tUser),
        const AuthState(
          status: AuthStatus.error,
          user: tUser,
          errorMessage: 'No internet connection',
        ),
      ],
    );
  });

  group('AuthProfileUpdateRequested', () {
    const updatedUser = User(
      id: '1',
      username: tUsername,
      displayName: tDisplayName,
      email: tEmail,
      phone: tPhone,
      paymentIdentity: 'DuitNow Jimmy',
    );

    blocTest<AuthBloc, AuthState>(
      'emits [loading, authenticated] and syncs pending expenses when payment identity changes',
      build: () {
        when(
          () => mockUpdateProfile(any()),
        ).thenAnswer((_) async => const Right(updatedUser));
        when(
          () => mockSyncOwnerPaymentIdentityToPendingExpenses(any()),
        ).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      seed: () =>
          const AuthState(status: AuthStatus.authenticated, user: tUser),
      act: (bloc) => bloc.add(
        const AuthProfileUpdateRequested(
          displayName: tDisplayName,
          phone: tPhone,
          paymentIdentity: 'DuitNow Jimmy',
        ),
      ),
      expect: () => [
        const AuthState(status: AuthStatus.loading, user: tUser),
        const AuthState(status: AuthStatus.authenticated, user: updatedUser),
      ],
      verify: (_) {
        verify(() => mockUpdateProfile(any())).called(1);
        verify(
          () => mockSyncOwnerPaymentIdentityToPendingExpenses(any()),
        ).called(1);
      },
    );
  });

  group('AuthPhoneCheckRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [clearPhoneAvailable, checking, phoneAvailable: true] when username is available',
      build: () {
        when(
          () => mockCheckUsernameAvailability(tUsername),
        ).thenAnswer((_) async => const Right(true));
        return bloc;
      },
      act: (bloc) =>
          bloc.add(const AuthUsernameCheckRequested(username: tUsername)),
      expect: () => [
        const AuthState(isCheckingUsername: true),
        const AuthState(usernameAvailable: true, isCheckingUsername: false),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [clearPhoneAvailable, checking, usernameAvailable: false] when username is taken',
      build: () {
        when(
          () => mockCheckUsernameAvailability(tUsername),
        ).thenAnswer((_) async => const Right(false));
        return bloc;
      },
      act: (bloc) =>
          bloc.add(const AuthUsernameCheckRequested(username: tUsername)),
      expect: () => [
        const AuthState(isCheckingUsername: true),
        const AuthState(usernameAvailable: false, isCheckingUsername: false),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [clearUsernameAvailable] when username is empty',
      build: () => bloc,
      act: (bloc) => bloc.add(const AuthUsernameCheckRequested(username: '')),
      expect: () => [const AuthState()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [checking, error] when username check fails',
      build: () {
        when(
          () => mockCheckUsernameAvailability(tUsername),
        ).thenAnswer((_) async => const Left(NetworkFailure()));
        return bloc;
      },
      act: (bloc) =>
          bloc.add(const AuthUsernameCheckRequested(username: tUsername)),
      expect: () => [
        const AuthState(isCheckingUsername: true),
        const AuthState(
          errorMessage: 'No internet connection',
          isCheckingUsername: false,
        ),
      ],
    );
  });

  group('AuthPasswordPolicyCheckRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [checking, validated] when password meets Firebase policy',
      build: () {
        when(
          () => mockValidatePasswordPolicy(any()),
        ).thenAnswer((_) async => const Right(tPasswordValidation));
        return bloc;
      },
      act: (bloc) =>
          bloc.add(const AuthPasswordPolicyCheckRequested(password: tPassword)),
      expect: () => [
        const AuthState(isCheckingPasswordPolicy: true),
        const AuthState(
          passwordValidation: tPasswordValidation,
          isCheckingPasswordPolicy: false,
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [checking, invalid validation] when password misses requirements',
      build: () {
        when(
          () => mockValidatePasswordPolicy(any()),
        ).thenAnswer((_) async => const Right(tInvalidPasswordValidation));
        return bloc;
      },
      act: (bloc) =>
          bloc.add(const AuthPasswordPolicyCheckRequested(password: tPassword)),
      expect: () => [
        const AuthState(isCheckingPasswordPolicy: true),
        const AuthState(
          passwordValidation: tInvalidPasswordValidation,
          isCheckingPasswordPolicy: false,
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits password validation error when Firebase check fails',
      build: () {
        when(
          () => mockValidatePasswordPolicy(any()),
        ).thenAnswer((_) async => const Left(NetworkFailure()));
        return bloc;
      },
      act: (bloc) =>
          bloc.add(const AuthPasswordPolicyCheckRequested(password: tPassword)),
      expect: () => [
        const AuthState(isCheckingPasswordPolicy: true),
        const AuthState(
          passwordValidationError: 'No internet connection',
          isCheckingPasswordPolicy: false,
        ),
      ],
    );
  });

  group('AuthErrorReset', () {
    blocTest<AuthBloc, AuthState>(
      'clears stale registration user and returns to unauthenticated',
      build: () => bloc,
      seed: () => const AuthState(
        status: AuthStatus.emailVerificationSent,
        user: tUser,
        errorMessage: 'Some error',
      ),
      act: (bloc) => bloc.add(AuthErrorReset()),
      expect: () => [const AuthState(status: AuthStatus.unauthenticated)],
    );

    blocTest<AuthBloc, AuthState>(
      'preserves authenticated user when resetting errors',
      build: () => bloc,
      seed: () => const AuthState(
        status: AuthStatus.authenticated,
        user: tUser,
        errorMessage: 'Some error',
      ),
      act: (bloc) => bloc.add(AuthErrorReset()),
      expect: () => [
        const AuthState(status: AuthStatus.authenticated, user: tUser),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'preserves Google username setup state when resetting errors',
      build: () => bloc,
      seed: () => const AuthState(
        status: AuthStatus.usernameSetupRequired,
        pendingGoogleProfileData: tGoogleProfile,
        errorMessage: 'Some error',
      ),
      act: (bloc) => bloc.add(AuthErrorReset()),
      expect: () => [
        const AuthState(
          status: AuthStatus.usernameSetupRequired,
          pendingGoogleProfileData: tGoogleProfile,
        ),
      ],
    );
  });

  group('AuthVerificationAcknowledged', () {
    blocTest<AuthBloc, AuthState>(
      'clears verification gate and returns to unauthenticated',
      build: () => bloc,
      seed: () => const AuthState(
        status: AuthStatus.emailVerificationSent,
        user: tUser,
        pendingVerificationEmail: tEmail,
      ),
      act: (bloc) => bloc.add(AuthVerificationAcknowledged()),
      expect: () => [
        const AuthState(
          status: AuthStatus.unauthenticated,
          pendingVerificationEmail: tEmail,
        ),
      ],
    );
  });

  group('AuthProfileCompletionSkipped', () {
    blocTest<AuthBloc, AuthState>(
      'clears profile completion gate and continues to authenticated',
      build: () => bloc,
      seed: () => const AuthState(
        status: AuthStatus.profileCompletionRequired,
        user: tUserNeedsProfileCompletion,
        shouldCompleteProfile: true,
      ),
      act: (bloc) => bloc.add(AuthProfileCompletionSkipped()),
      expect: () => [
        const AuthState(
          status: AuthStatus.authenticated,
          user: tUserNeedsProfileCompletion,
        ),
      ],
    );
  });

  group('AuthProfileCompletionChecked', () {
    blocTest<AuthBloc, AuthState>(
      're-evaluates profile completion and marks user authenticated when profile data is complete',
      build: () => bloc,
      seed: () => const AuthState(
        status: AuthStatus.profileCompletionRequired,
        user: tUserWithProfileComplete,
        shouldCompleteProfile: true,
      ),
      act: (bloc) => bloc.add(AuthProfileCompletionChecked()),
      expect: () => [
        const AuthState(
          status: AuthStatus.authenticated,
          user: tUserWithProfileComplete,
        ),
      ],
    );
  });

  group('Google onboarding actions', () {
    blocTest<AuthBloc, AuthState>(
      'completes Google onboarding and authenticates the user',
      build: () {
        when(
          () => mockCompleteGoogleOnboarding(any()),
        ).thenAnswer((_) async => const Right(tUser));
        return bloc;
      },
      seed: () => const AuthState(
        status: AuthStatus.usernameSetupRequired,
        pendingGoogleProfileData: tGoogleProfile,
      ),
      act: (bloc) => bloc.add(
        const AuthGoogleUsernameCompletionRequested(username: tUsername),
      ),
      expect: () => [
        const AuthState(
          status: AuthStatus.loading,
          pendingGoogleProfileData: tGoogleProfile,
        ),
        const AuthState(status: AuthStatus.authenticated, user: tUser),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'passes the optional password during Google onboarding',
      build: () {
        when(
          () => mockCompleteGoogleOnboarding(any()),
        ).thenAnswer((_) async => const Right(tUser));
        return bloc;
      },
      seed: () => const AuthState(
        status: AuthStatus.usernameSetupRequired,
        pendingGoogleProfileData: tGoogleProfile,
      ),
      act: (bloc) => bloc.add(
        const AuthGoogleUsernameCompletionRequested(
          username: tUsername,
          password: tPassword,
        ),
      ),
      verify: (_) {
        verify(
          () => mockCompleteGoogleOnboarding(
            const CompleteGoogleOnboardingParams(
              username: tUsername,
              password: tPassword,
            ),
          ),
        ).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'links Google sign-in to an existing account and authenticates',
      build: () {
        when(
          () => mockLinkGoogleSignIn(any()),
        ).thenAnswer((_) async => const Right(tUser));
        return bloc;
      },
      seed: () => const AuthState(
        status: AuthStatus.googleLinkRequired,
        pendingGoogleProfileData: tGoogleProfile,
      ),
      act: (bloc) =>
          bloc.add(const AuthGoogleLinkRequested(password: tPassword)),
      expect: () => [
        const AuthState(
          status: AuthStatus.loading,
          pendingGoogleProfileData: tGoogleProfile,
        ),
        const AuthState(status: AuthStatus.authenticated, user: tUser),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'cancels Google onboarding and returns to unauthenticated',
      build: () {
        when(
          () => mockLogout(any()),
        ).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      seed: () => const AuthState(
        status: AuthStatus.usernameSetupRequired,
        pendingGoogleProfileData: tGoogleProfile,
      ),
      act: (bloc) => bloc.add(AuthGoogleOnboardingCancelled()),
      expect: () => [const AuthState(status: AuthStatus.unauthenticated)],
    );
  });

  group('Email link auth actions', () {
    blocTest<AuthBloc, AuthState>(
      'sends an email-link sign-in and keeps user unauthenticated',
      build: () {
        when(
          () => mockSendEmailLinkSignIn(any()),
        ).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (bloc) =>
          bloc.add(const AuthEmailLinkSignInRequested(email: tEmail)),
      expect: () => [
        const AuthState(isSendingEmailLink: true),
        const AuthState(
          status: AuthStatus.unauthenticated,
          emailLinkSentEmail: tEmail,
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'stores a detected email link in state when the email must be re-entered',
      build: () {
        when(
          () => mockGetPendingEmailLinkEmail(any()),
        ).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (bloc) => bloc.add(
        const AuthEmailLinkDetected(
          emailLink: 'https://example.invalid/__/auth/action',
        ),
      ),
      expect: () => [
        const AuthState(status: AuthStatus.loading),
        const AuthState(
          status: AuthStatus.unauthenticated,
          pendingEmailLink:
              'https://example.invalid/__/auth/action',
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'loads account security and updates state',
      build: () {
        when(
          () => mockGetAuthSecurity(any()),
        ).thenAnswer((_) async => const Right(tAuthSecurity));
        return bloc;
      },
      act: (bloc) => bloc.add(AuthAccountSecurityRequested()),
      expect: () => [
        const AuthState(isLoadingAccountSecurity: true),
        const AuthState(authSecurity: tAuthSecurity),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'sets password and stores the updated account security',
      build: () {
        when(
          () => mockSetPassword(any()),
        ).thenAnswer((_) async => const Right(tAuthSecurityWithPassword));
        return bloc;
      },
      seed: () => const AuthState(
        status: AuthStatus.authenticated,
        authSecurity: tAuthSecurity,
      ),
      act: (bloc) =>
          bloc.add(const AuthSetPasswordRequested(password: tPassword)),
      expect: () => [
        const AuthState(
          status: AuthStatus.authenticated,
          authSecurity: tAuthSecurity,
          isSettingPassword: true,
        ),
        const AuthState(
          status: AuthStatus.authenticated,
          authSecurity: tAuthSecurityWithPassword,
          accountSecurityMessage: 'Password sign-in is now enabled.',
        ),
      ],
    );
  });
}
