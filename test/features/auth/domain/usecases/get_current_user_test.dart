import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/failures.dart';
import 'package:pulse/core/usecases/usecase.dart';
import 'package:pulse/features/auth/domain/entities/user.dart';
import 'package:pulse/features/auth/domain/repositories/auth_repository.dart';
import 'package:pulse/features/auth/domain/usecases/get_current_user.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late GetCurrentUser usecase;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    usecase = GetCurrentUser(mockAuthRepository);
  });

  const tUser = User(
    id: '1',
    username: 'testuser',
    displayName: 'Test User',
    email: 'test@example.com',
    phone: '',
  );

  test('should return User when user is authenticated', () async {
    // arrange
    when(() => mockAuthRepository.getCurrentUser())
        .thenAnswer((_) async => const Right(tUser));

    // act
    final result = await usecase(const NoParams());

    // assert
    expect(result, const Right(tUser));
    verify(() => mockAuthRepository.getCurrentUser()).called(1);
    verifyNoMoreInteractions(mockAuthRepository);
  });

  test('should return null when no user is logged in', () async {
    // arrange
    when(() => mockAuthRepository.getCurrentUser())
        .thenAnswer((_) async => const Right(null));

    // act
    final result = await usecase(const NoParams());

    // assert
    expect(result, const Right(null));
    verify(() => mockAuthRepository.getCurrentUser()).called(1);
    verifyNoMoreInteractions(mockAuthRepository);
  });

  test('should return AuthFailure when authentication fails', () async {
    // arrange
    when(() => mockAuthRepository.getCurrentUser())
        .thenAnswer((_) async => const Left(AuthFailure(message: 'Not authenticated')));

    // act
    final result = await usecase(const NoParams());

    // assert
    expect(result, const Left(AuthFailure(message: 'Not authenticated')));
    verify(() => mockAuthRepository.getCurrentUser()).called(1);
    verifyNoMoreInteractions(mockAuthRepository);
  });

  test('should return CacheFailure when cache error occurs', () async {
    // arrange
    when(() => mockAuthRepository.getCurrentUser())
        .thenAnswer((_) async => const Left(CacheFailure(message: 'Cache error')));

    // act
    final result = await usecase(const NoParams());

    // assert
    expect(result, const Left(CacheFailure(message: 'Cache error')));
    verify(() => mockAuthRepository.getCurrentUser()).called(1);
    verifyNoMoreInteractions(mockAuthRepository);
  });

  test('should return NetworkFailure when there is no internet', () async {
    // arrange
    when(() => mockAuthRepository.getCurrentUser())
        .thenAnswer((_) async => const Left(NetworkFailure()));

    // act
    final result = await usecase(const NoParams());

    // assert
    expect(result, const Left(NetworkFailure()));
    verify(() => mockAuthRepository.getCurrentUser()).called(1);
    verifyNoMoreInteractions(mockAuthRepository);
  });
}
