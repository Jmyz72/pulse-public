import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/failures.dart';
import 'package:pulse/features/auth/domain/repositories/auth_repository.dart';
import 'package:pulse/features/auth/domain/usecases/check_username_availability.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late CheckUsernameAvailability usecase;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    usecase = CheckUsernameAvailability(mockAuthRepository);
  });

  const tUsername = 'testuser';

  test('should return true when username is available', () async {
    // arrange
    when(() => mockAuthRepository.checkUsernameAvailability(tUsername))
        .thenAnswer((_) async => const Right(true));

    // act
    final result = await usecase(tUsername);

    // assert
    expect(result, const Right(true));
    verify(() => mockAuthRepository.checkUsernameAvailability(tUsername)).called(1);
    verifyNoMoreInteractions(mockAuthRepository);
  });

  test('should return false when username is taken', () async {
    // arrange
    when(() => mockAuthRepository.checkUsernameAvailability(tUsername))
        .thenAnswer((_) async => const Right(false));

    // act
    final result = await usecase(tUsername);

    // assert
    expect(result, const Right(false));
    verify(() => mockAuthRepository.checkUsernameAvailability(tUsername)).called(1);
    verifyNoMoreInteractions(mockAuthRepository);
  });

  test('should return ServerFailure when check fails', () async {
    // arrange
    when(() => mockAuthRepository.checkUsernameAvailability(tUsername))
        .thenAnswer((_) async => const Left(ServerFailure(message: 'Server error')));

    // act
    final result = await usecase(tUsername);

    // assert
    expect(result, const Left(ServerFailure(message: 'Server error')));
    verify(() => mockAuthRepository.checkUsernameAvailability(tUsername)).called(1);
    verifyNoMoreInteractions(mockAuthRepository);
  });

  test('should return NetworkFailure when there is no internet connection', () async {
    // arrange
    when(() => mockAuthRepository.checkUsernameAvailability(tUsername))
        .thenAnswer((_) async => const Left(NetworkFailure()));

    // act
    final result = await usecase(tUsername);

    // assert
    expect(result, const Left(NetworkFailure()));
    verify(() => mockAuthRepository.checkUsernameAvailability(tUsername)).called(1);
    verifyNoMoreInteractions(mockAuthRepository);
  });
}
