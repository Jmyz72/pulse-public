import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/failures.dart';
import 'package:pulse/features/auth/domain/entities/password_policy_validation.dart';
import 'package:pulse/features/auth/domain/repositories/auth_repository.dart';
import 'package:pulse/features/auth/domain/usecases/validate_password_policy.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late ValidatePasswordPolicy usecase;
  late MockAuthRepository mockAuthRepository;

  const tPassword = 'Password123!';
  const tValidation = PasswordPolicyValidation(
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

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    usecase = ValidatePasswordPolicy(mockAuthRepository);
  });

  test(
    'should return password validation when Firebase policy check succeeds',
    () async {
      when(
        () => mockAuthRepository.validatePasswordPolicy(tPassword),
      ).thenAnswer((_) async => const Right(tValidation));

      final result = await usecase(tPassword);

      expect(result, const Right(tValidation));
      verify(
        () => mockAuthRepository.validatePasswordPolicy(tPassword),
      ).called(1);
      verifyNoMoreInteractions(mockAuthRepository);
    },
  );

  test('should return failure when policy check fails', () async {
    when(
      () => mockAuthRepository.validatePasswordPolicy(tPassword),
    ).thenAnswer((_) async => const Left(NetworkFailure()));

    final result = await usecase(tPassword);

    expect(result, const Left(NetworkFailure()));
  });
}
