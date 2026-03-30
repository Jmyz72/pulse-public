import 'package:equatable/equatable.dart';

class PasswordPolicyValidation extends Equatable {
  final bool isValid;
  final int minPasswordLength;
  final int? maxPasswordLength;
  final bool requiresLowercase;
  final bool requiresUppercase;
  final bool requiresDigits;
  final bool requiresSymbols;
  final bool meetsMinPasswordLength;
  final bool meetsMaxPasswordLength;
  final bool meetsLowercaseRequirement;
  final bool meetsUppercaseRequirement;
  final bool meetsDigitsRequirement;
  final bool meetsSymbolsRequirement;

  const PasswordPolicyValidation({
    required this.isValid,
    required this.minPasswordLength,
    required this.maxPasswordLength,
    required this.requiresLowercase,
    required this.requiresUppercase,
    required this.requiresDigits,
    required this.requiresSymbols,
    required this.meetsMinPasswordLength,
    required this.meetsMaxPasswordLength,
    required this.meetsLowercaseRequirement,
    required this.meetsUppercaseRequirement,
    required this.meetsDigitsRequirement,
    required this.meetsSymbolsRequirement,
  });

  List<String> get unmetRequirements {
    final requirements = <String>[];

    if (!meetsMinPasswordLength) {
      requirements.add('at least $minPasswordLength characters');
    }
    if (maxPasswordLength != null && !meetsMaxPasswordLength) {
      requirements.add('no more than $maxPasswordLength characters');
    }
    if (requiresUppercase && !meetsUppercaseRequirement) {
      requirements.add('an uppercase letter');
    }
    if (requiresLowercase && !meetsLowercaseRequirement) {
      requirements.add('a lowercase letter');
    }
    if (requiresDigits && !meetsDigitsRequirement) {
      requirements.add('a number');
    }
    if (requiresSymbols && !meetsSymbolsRequirement) {
      requirements.add('a special character');
    }

    return requirements;
  }

  String get failureMessage {
    final requirements = unmetRequirements;
    if (requirements.isEmpty) {
      return 'Password does not meet the current account policy.';
    }
    if (requirements.length == 1) {
      return 'Password must include ${requirements.first}.';
    }

    final leading = requirements.sublist(0, requirements.length - 1).join(', ');
    return 'Password must include $leading, and ${requirements.last}.';
  }

  @override
  List<Object?> get props => [
    isValid,
    minPasswordLength,
    maxPasswordLength,
    requiresLowercase,
    requiresUppercase,
    requiresDigits,
    requiresSymbols,
    meetsMinPasswordLength,
    meetsMaxPasswordLength,
    meetsLowercaseRequirement,
    meetsUppercaseRequirement,
    meetsDigitsRequirement,
    meetsSymbolsRequirement,
  ];
}
