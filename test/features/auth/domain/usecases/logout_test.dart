import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/failures.dart';
import 'package:pulse/core/usecases/usecase.dart';
import 'package:pulse/features/auth/domain/repositories/auth_repository.dart';
import 'package:pulse/features/auth/domain/usecases/logout.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late Logout usecase;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    usecase = Logout(mockAuthRepository);
  });

  test('should return void when logout is successful', () async {
    // arrange
    when(() => mockAuthRepository.signOut())
        .thenAnswer((_) async => const Right(null));

    // act
    final result = await usecase(const NoParams());

    // assert
    expect(result, const Right(null));
    verify(() => mockAuthRepository.signOut()).called(1);
    verifyNoMoreInteractions(mockAuthRepository);
  });

  test('should return AuthFailure when logout fails', () async {
    // arrange
    when(() => mockAuthRepository.signOut())
        .thenAnswer((_) async => const Left(AuthFailure(message: 'Logout failed')));

    // act
    final result = await usecase(const NoParams());

    // assert
    expect(result, const Left(AuthFailure(message: 'Logout failed')));
    verify(() => mockAuthRepository.signOut()).called(1);
    verifyNoMoreInteractions(mockAuthRepository);
  });

  test('should return NetworkFailure when there is no internet', () async {
    // arrange
    when(() => mockAuthRepository.signOut())
        .thenAnswer((_) async => const Left(NetworkFailure()));

    // act
    final result = await usecase(const NoParams());

    // assert
    expect(result, const Left(NetworkFailure()));
    verify(() => mockAuthRepository.signOut()).called(1);
    verifyNoMoreInteractions(mockAuthRepository);
  });
}
