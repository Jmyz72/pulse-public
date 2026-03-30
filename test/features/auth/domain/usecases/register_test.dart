import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/failures.dart';
import 'package:pulse/features/auth/domain/entities/user.dart';
import 'package:pulse/features/auth/domain/repositories/auth_repository.dart';
import 'package:pulse/features/auth/domain/usecases/register.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late Register usecase;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    usecase = Register(mockAuthRepository);
  });

  const tEmail = 'newuser@example.com';
  const tPassword = 'Password123!';
  const tUsername = 'newuser';
  const tDisplayName = 'New User';
  const tUser = User(
    id: '1',
    username: tUsername,
    displayName: tDisplayName,
    email: tEmail,
    phone: '',
  );

  test('should return User when registration is successful', () async {
    // arrange
    when(
      () => mockAuthRepository.registerWithEmail(
        tEmail,
        tPassword,
        tUsername,
        tDisplayName,
      ),
    ).thenAnswer((_) async => const Right(tUser));

    // act
    final result = await usecase(
      const RegisterParams(
        email: tEmail,
        password: tPassword,
        username: tUsername,
        displayName: tDisplayName,
      ),
    );

    // assert
    expect(result, const Right(tUser));
    verify(
      () => mockAuthRepository.registerWithEmail(
        tEmail,
        tPassword,
        tUsername,
        tDisplayName,
      ),
    ).called(1);
    verifyNoMoreInteractions(mockAuthRepository);
  });

  test('should return AuthFailure when email already exists', () async {
    // arrange
    when(
      () => mockAuthRepository.registerWithEmail(
        tEmail,
        tPassword,
        tUsername,
        tDisplayName,
      ),
    ).thenAnswer(
      (_) async => const Left(AuthFailure(message: 'Email already in use')),
    );

    // act
    final result = await usecase(
      const RegisterParams(
        email: tEmail,
        password: tPassword,
        username: tUsername,
        displayName: tDisplayName,
      ),
    );

    // assert
    expect(result, const Left(AuthFailure(message: 'Email already in use')));
    verify(
      () => mockAuthRepository.registerWithEmail(
        tEmail,
        tPassword,
        tUsername,
        tDisplayName,
      ),
    ).called(1);
  });

  test('should return ServerFailure when server error occurs', () async {
    // arrange
    when(
      () => mockAuthRepository.registerWithEmail(
        tEmail,
        tPassword,
        tUsername,
        tDisplayName,
      ),
    ).thenAnswer(
      (_) async => const Left(ServerFailure(message: 'Server error')),
    );

    // act
    final result = await usecase(
      const RegisterParams(
        email: tEmail,
        password: tPassword,
        username: tUsername,
        displayName: tDisplayName,
      ),
    );

    // assert
    expect(result, const Left(ServerFailure(message: 'Server error')));
  });
}
