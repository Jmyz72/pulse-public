import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../../domain/entities/password_policy_validation.dart';

class PasswordPolicyValidationModel extends PasswordPolicyValidation {
  const PasswordPolicyValidationModel({
    required super.isValid,
    required super.minPasswordLength,
    required super.maxPasswordLength,
    required super.requiresLowercase,
    required super.requiresUppercase,
    required super.requiresDigits,
    required super.requiresSymbols,
    required super.meetsMinPasswordLength,
    required super.meetsMaxPasswordLength,
    required super.meetsLowercaseRequirement,
    required super.meetsUppercaseRequirement,
    required super.meetsDigitsRequirement,
    required super.meetsSymbolsRequirement,
  });

  factory PasswordPolicyValidationModel.fromFirebase(
    firebase_auth.PasswordValidationStatus status,
  ) {
    final policy = status.passwordPolicy;

    return PasswordPolicyValidationModel(
      isValid: status.isValid,
      minPasswordLength: policy.minPasswordLength,
      maxPasswordLength: policy.maxPasswordLength,
      requiresLowercase: policy.containsLowercaseCharacter ?? false,
      requiresUppercase: policy.containsUppercaseCharacter ?? false,
      requiresDigits: policy.containsNumericCharacter ?? false,
      requiresSymbols: policy.containsNonAlphanumericCharacter ?? false,
      meetsMinPasswordLength: status.meetsMinPasswordLength,
      meetsMaxPasswordLength: status.meetsMaxPasswordLength,
      meetsLowercaseRequirement: status.meetsLowercaseRequirement,
      meetsUppercaseRequirement: status.meetsUppercaseRequirement,
      meetsDigitsRequirement: status.meetsDigitsRequirement,
      meetsSymbolsRequirement: status.meetsSymbolsRequirement,
    );
  }
}
