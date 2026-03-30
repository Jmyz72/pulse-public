import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/failures.dart';
import 'package:pulse/features/auth/domain/entities/user.dart';
import 'package:pulse/features/auth/domain/repositories/auth_repository.dart';
import 'package:pulse/features/auth/domain/usecases/update_profile.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late UpdateProfile usecase;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    usecase = UpdateProfile(mockAuthRepository);
  });

  const tDisplayName = 'Updated Name';
  const tPhone = '+1234567890';
  const tUser = User(
    id: '1',
    username: 'testuser',
    displayName: tDisplayName,
    email: 'test@example.com',
    phone: tPhone,
  );

  test('should return updated User when updateProfile is successful', () async {
    // arrange
    when(
      () =>
          mockAuthRepository.updateProfile(tDisplayName, tPhone, any(), any()),
    ).thenAnswer((_) async => const Right(tUser));

    // act
    final result = await usecase(
      const UpdateProfileParams(displayName: tDisplayName, phone: tPhone),
    );

    // assert
    expect(result, const Right(tUser));
    verify(
      () =>
          mockAuthRepository.updateProfile(tDisplayName, tPhone, any(), any()),
    ).called(1);
    verifyNoMoreInteractions(mockAuthRepository);
  });

  test('should return AuthFailure when user is not authenticated', () async {
    // arrange
    when(
      () =>
          mockAuthRepository.updateProfile(tDisplayName, tPhone, any(), any()),
    ).thenAnswer(
      (_) async => const Left(AuthFailure(message: 'User not authenticated')),
    );

    // act
    final result = await usecase(
      const UpdateProfileParams(displayName: tDisplayName, phone: tPhone),
    );

    // assert
    expect(result, const Left(AuthFailure(message: 'User not authenticated')));
    verify(
      () =>
          mockAuthRepository.updateProfile(tDisplayName, tPhone, any(), any()),
    ).called(1);
    verifyNoMoreInteractions(mockAuthRepository);
  });

  test('should return ServerFailure when updateProfile fails', () async {
    // arrange
    when(
      () =>
          mockAuthRepository.updateProfile(tDisplayName, tPhone, any(), any()),
    ).thenAnswer(
      (_) async => const Left(ServerFailure(message: 'Server error')),
    );

    // act
    final result = await usecase(
      const UpdateProfileParams(displayName: tDisplayName, phone: tPhone),
    );

    // assert
    expect(result, const Left(ServerFailure(message: 'Server error')));
    verify(
      () =>
          mockAuthRepository.updateProfile(tDisplayName, tPhone, any(), any()),
    ).called(1);
    verifyNoMoreInteractions(mockAuthRepository);
  });

  test(
    'should return NetworkFailure when there is no internet connection',
    () async {
      // arrange
      when(
        () => mockAuthRepository.updateProfile(
          tDisplayName,
          tPhone,
          any(),
          any(),
        ),
      ).thenAnswer((_) async => const Left(NetworkFailure()));

      // act
      final result = await usecase(
        const UpdateProfileParams(displayName: tDisplayName, phone: tPhone),
      );

      // assert
      expect(result, const Left(NetworkFailure()));
      verify(
        () => mockAuthRepository.updateProfile(
          tDisplayName,
          tPhone,
          any(),
          any(),
        ),
      ).called(1);
      verifyNoMoreInteractions(mockAuthRepository);
    },
  );

  group('UpdateProfileParams', () {
    test('should have correct props', () {
      const params = UpdateProfileParams(
        displayName: tDisplayName,
        phone: tPhone,
      );
      expect(params.props, [tDisplayName, tPhone, null, null]);
    });

    test('two params with same values should be equal', () {
      const params1 = UpdateProfileParams(
        displayName: tDisplayName,
        phone: tPhone,
      );
      const params2 = UpdateProfileParams(
        displayName: tDisplayName,
        phone: tPhone,
      );
      expect(params1, params2);
    });

    test('two params with different values should not be equal', () {
      const params1 = UpdateProfileParams(
        displayName: tDisplayName,
        phone: tPhone,
      );
      const params2 = UpdateProfileParams(
        displayName: 'Other Name',
        phone: tPhone,
      );
      expect(params1, isNot(params2));
    });
  });
}
