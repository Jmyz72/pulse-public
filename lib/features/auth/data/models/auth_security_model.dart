import '../../domain/entities/auth_security.dart';

class AuthSecurityModel extends AuthSecurity {
  const AuthSecurityModel({
    required super.email,
    required super.hasPasswordProvider,
    required super.hasGoogleProvider,
    required super.emailVerified,
  });

  factory AuthSecurityModel.fromEntity(AuthSecurity security) {
    return AuthSecurityModel(
      email: security.email,
      hasPasswordProvider: security.hasPasswordProvider,
      hasGoogleProvider: security.hasGoogleProvider,
      emailVerified: security.emailVerified,
    );
  }
}
