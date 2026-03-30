import 'package:equatable/equatable.dart';

class AuthSecurity extends Equatable {
  final String email;
  final bool hasPasswordProvider;
  final bool hasGoogleProvider;
  final bool emailVerified;

  const AuthSecurity({
    required this.email,
    required this.hasPasswordProvider,
    required this.hasGoogleProvider,
    required this.emailVerified,
  });

  @override
  List<Object?> get props => [
    email,
    hasPasswordProvider,
    hasGoogleProvider,
    emailVerified,
  ];
}
