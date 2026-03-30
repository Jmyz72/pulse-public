import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/failures.dart';
import 'package:pulse/features/auth/domain/entities/user.dart';
import 'package:pulse/features/auth/domain/repositories/auth_repository.dart';
import 'package:pulse/features/auth/domain/usecases/login.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late Login usecase;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    usecase = Login(mockAuthRepository);
  });

  const tEmail = 'test@example.com';
  const tPassword = 'password123';
  const tUser = User(
    id: '1',
    username: 'testuser',
    displayName: 'Test User',
    email: tEmail,
    phone: '',
  );

  test('should return User when login is successful', () async {
    // arrange
    when(() => mockAuthRepository.signInWithEmail(tEmail, tPassword))
        .thenAnswer((_) async => const Right(tUser));

    // act
    final result = await usecase(const LoginParams(email: tEmail, password: tPassword));

    // assert
    expect(result, const Right(tUser));
    verify(() => mockAuthRepository.signInWithEmail(tEmail, tPassword)).called(1);
    verifyNoMoreInteractions(mockAuthRepository);
  });

  test('should return AuthFailure when login fails', () async {
    // arrange
    when(() => mockAuthRepository.signInWithEmail(tEmail, tPassword))
        .thenAnswer((_) async => const Left(AuthFailure(message: 'Invalid credentials')));

    // act
    final result = await usecase(const LoginParams(email: tEmail, password: tPassword));

    // assert
    expect(result, const Left(AuthFailure(message: 'Invalid credentials')));
    verify(() => mockAuthRepository.signInWithEmail(tEmail, tPassword)).called(1);
    verifyNoMoreInteractions(mockAuthRepository);
  });

  test('should return NetworkFailure when there is no internet', () async {
    // arrange
    when(() => mockAuthRepository.signInWithEmail(tEmail, tPassword))
        .thenAnswer((_) async => const Left(NetworkFailure()));

    // act
    final result = await usecase(const LoginParams(email: tEmail, password: tPassword));

    // assert
    expect(result, const Left(NetworkFailure()));
    verify(() => mockAuthRepository.signInWithEmail(tEmail, tPassword)).called(1);
  });
}
