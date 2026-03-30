part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}

class AuthEmailLinkSignInRequested extends AuthEvent {
  final String email;

  const AuthEmailLinkSignInRequested({required this.email});

  @override
  List<Object?> get props => [email];
}

class AuthEmailLinkDetected extends AuthEvent {
  final String emailLink;

  const AuthEmailLinkDetected({required this.emailLink});

  @override
  List<Object?> get props => [emailLink];
}

class AuthEmailLinkCompletionRequested extends AuthEvent {
  final String email;

  const AuthEmailLinkCompletionRequested({required this.email});

  @override
  List<Object?> get props => [email];
}

class AuthGoogleSignInRequested extends AuthEvent {}

class AuthGoogleUsernameCompletionRequested extends AuthEvent {
  final String username;
  final String? password;

  const AuthGoogleUsernameCompletionRequested({
    required this.username,
    this.password,
  });

  @override
  List<Object?> get props => [username, password];
}

class AuthGoogleLinkRequested extends AuthEvent {
  final String password;

  const AuthGoogleLinkRequested({required this.password});

  @override
  List<Object> get props => [password];
}

class AuthGoogleOnboardingCancelled extends AuthEvent {}

class AuthRegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String username;
  final String displayName;
  final String phone;

  const AuthRegisterRequested({
    required this.email,
    required this.password,
    required this.username,
    required this.displayName,
    required this.phone,
  });

  @override
  List<Object> get props => [email, password, username, displayName, phone];
}

class AuthResetPasswordRequested extends AuthEvent {
  final String email;

  const AuthResetPasswordRequested({required this.email});

  @override
  List<Object> get props => [email];
}

class AuthLogoutRequested extends AuthEvent {}

class AuthProfileUpdateRequested extends AuthEvent {
  final String displayName;
  final String phone;
  final String paymentIdentity;

  const AuthProfileUpdateRequested({
    required this.displayName,
    required this.phone,
    required this.paymentIdentity,
  });

  @override
  List<Object> get props => [displayName, phone, paymentIdentity];
}

class AuthErrorReset extends AuthEvent {}

class AuthVerificationAcknowledged extends AuthEvent {}

class AuthProfileCompletionSkipped extends AuthEvent {}

class AuthProfileCompletionChecked extends AuthEvent {}

class AuthAccountSecurityRequested extends AuthEvent {}

class AuthSetPasswordRequested extends AuthEvent {
  final String password;

  const AuthSetPasswordRequested({required this.password});

  @override
  List<Object?> get props => [password];
}

class AuthUsernameCheckRequested extends AuthEvent {
  final String username;

  const AuthUsernameCheckRequested({required this.username});

  @override
  List<Object> get props => [username];
}

class AuthPhoneCheckRequested extends AuthEvent {
  final String phone;

  const AuthPhoneCheckRequested({required this.phone});

  @override
  List<Object> get props => [phone];
}

class AuthPasswordPolicyCheckRequested extends AuthEvent {
  final String password;

  const AuthPasswordPolicyCheckRequested({required this.password});

  @override
  List<Object> get props => [password];
}

class AuthProfilePictureUpdateRequested extends AuthEvent {
  final String imagePath;

  const AuthProfilePictureUpdateRequested({required this.imagePath});

  @override
  List<Object> get props => [imagePath];
}
