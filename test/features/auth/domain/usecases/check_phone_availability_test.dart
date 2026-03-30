import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/failures.dart';
import 'package:pulse/features/auth/domain/repositories/auth_repository.dart';
import 'package:pulse/features/auth/domain/usecases/check_phone_availability.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late CheckPhoneAvailability usecase;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    usecase = CheckPhoneAvailability(mockAuthRepository);
  });

  const tPhone = '+60123456789';

  test('should return true when phone number is available', () async {
    // arrange
    when(() => mockAuthRepository.checkPhoneAvailability(tPhone))
        .thenAnswer((_) async => const Right(true));

    // act
    final result = await usecase(tPhone);

    // assert
    expect(result, const Right(true));
    verify(() => mockAuthRepository.checkPhoneAvailability(tPhone)).called(1);
    verifyNoMoreInteractions(mockAuthRepository);
  });

  test('should return false when phone number is taken', () async {
    // arrange
    when(() => mockAuthRepository.checkPhoneAvailability(tPhone))
        .thenAnswer((_) async => const Right(false));

    // act
    final result = await usecase(tPhone);

    // assert
    expect(result, const Right(false));
    verify(() => mockAuthRepository.checkPhoneAvailability(tPhone)).called(1);
    verifyNoMoreInteractions(mockAuthRepository);
  });

  test('should return ServerFailure when check fails', () async {
    // arrange
    when(() => mockAuthRepository.checkPhoneAvailability(tPhone))
        .thenAnswer((_) async => const Left(ServerFailure(message: 'Server error')));

    // act
    final result = await usecase(tPhone);

    // assert
    expect(result, const Left(ServerFailure(message: 'Server error')));
    verify(() => mockAuthRepository.checkPhoneAvailability(tPhone)).called(1);
    verifyNoMoreInteractions(mockAuthRepository);
  });

  test('should return NetworkFailure when there is no internet connection', () async {
    // arrange
    when(() => mockAuthRepository.checkPhoneAvailability(tPhone))
        .thenAnswer((_) async => const Left(NetworkFailure()));

    // act
    final result = await usecase(tPhone);

    // assert
    expect(result, const Left(NetworkFailure()));
    verify(() => mockAuthRepository.checkPhoneAvailability(tPhone)).called(1);
    verifyNoMoreInteractions(mockAuthRepository);
  });
}
