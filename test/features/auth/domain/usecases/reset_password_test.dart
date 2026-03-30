import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/failures.dart';
import 'package:pulse/features/auth/domain/repositories/auth_repository.dart';
import 'package:pulse/features/auth/domain/usecases/reset_password.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late ResetPassword usecase;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    usecase = ResetPassword(mockAuthRepository);
  });

  const tEmail = 'test@example.com';

  test('should return void when password reset is successful', () async {
    // arrange
    when(() => mockAuthRepository.resetPassword(tEmail))
        .thenAnswer((_) async => const Right(null));

    // act
    final result = await usecase(const ResetPasswordParams(email: tEmail));

    // assert
    expect(result, const Right(null));
    verify(() => mockAuthRepository.resetPassword(tEmail)).called(1);
    verifyNoMoreInteractions(mockAuthRepository);
  });

  test('should return AuthFailure when reset password fails', () async {
    // arrange
    when(() => mockAuthRepository.resetPassword(tEmail))
        .thenAnswer((_) async => const Left(AuthFailure(message: 'User not found')));

    // act
    final result = await usecase(const ResetPasswordParams(email: tEmail));

    // assert
    expect(result, const Left(AuthFailure(message: 'User not found')));
    verify(() => mockAuthRepository.resetPassword(tEmail)).called(1);
    verifyNoMoreInteractions(mockAuthRepository);
  });

  test('should return NetworkFailure when there is no internet', () async {
    // arrange
    when(() => mockAuthRepository.resetPassword(tEmail))
        .thenAnswer((_) async => const Left(NetworkFailure()));

    // act
    final result = await usecase(const ResetPasswordParams(email: tEmail));

    // assert
    expect(result, const Left(NetworkFailure()));
    verify(() => mockAuthRepository.resetPassword(tEmail)).called(1);
    verifyNoMoreInteractions(mockAuthRepository);
  });

  test('should return InvalidInputFailure when email is invalid', () async {
    // arrange
    const invalidEmail = 'invalid-email';
    when(() => mockAuthRepository.resetPassword(invalidEmail))
        .thenAnswer((_) async => const Left(InvalidInputFailure(message: 'Invalid email format')));

    // act
    final result = await usecase(const ResetPasswordParams(email: invalidEmail));

    // assert
    expect(result, const Left(InvalidInputFailure(message: 'Invalid email format')));
    verify(() => mockAuthRepository.resetPassword(invalidEmail)).called(1);
    verifyNoMoreInteractions(mockAuthRepository);
  });
}
