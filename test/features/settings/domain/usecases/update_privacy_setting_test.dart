import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/failures.dart';
import 'package:pulse/features/settings/domain/repositories/settings_repository.dart';
import 'package:pulse/features/settings/domain/usecases/update_privacy_setting.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  late UpdatePrivacySetting usecase;
  late MockSettingsRepository mockSettingsRepository;

  setUp(() {
    mockSettingsRepository = MockSettingsRepository();
    usecase = UpdatePrivacySetting(mockSettingsRepository);
  });

  const tUserId = 'user-123';
  const tKey = 'showTimeline';
  const tValue = false;

  test('should return void when updatePrivacySetting is successful', () async {
    // arrange
    when(() => mockSettingsRepository.updatePrivacySetting(tUserId, tKey, tValue))
        .thenAnswer((_) async => const Right(null));

    // act
    final result = await usecase(const UpdatePrivacySettingParams(userId: tUserId, key: tKey, value: tValue));

    // assert
    expect(result, const Right(null));
    verify(() => mockSettingsRepository.updatePrivacySetting(tUserId, tKey, tValue)).called(1);
    verifyNoMoreInteractions(mockSettingsRepository);
  });

  test('should return ServerFailure when updatePrivacySetting fails', () async {
    // arrange
    when(() => mockSettingsRepository.updatePrivacySetting(tUserId, tKey, tValue))
        .thenAnswer((_) async => const Left(ServerFailure(message: 'Failed to update privacy setting')));

    // act
    final result = await usecase(const UpdatePrivacySettingParams(userId: tUserId, key: tKey, value: tValue));

    // assert
    expect(result, const Left(ServerFailure(message: 'Failed to update privacy setting')));
    verify(() => mockSettingsRepository.updatePrivacySetting(tUserId, tKey, tValue)).called(1);
    verifyNoMoreInteractions(mockSettingsRepository);
  });

  test('should return NetworkFailure when there is no internet connection', () async {
    // arrange
    when(() => mockSettingsRepository.updatePrivacySetting(tUserId, tKey, tValue))
        .thenAnswer((_) async => const Left(NetworkFailure()));

    // act
    final result = await usecase(const UpdatePrivacySettingParams(userId: tUserId, key: tKey, value: tValue));

    // assert
    expect(result, const Left(NetworkFailure()));
    verify(() => mockSettingsRepository.updatePrivacySetting(tUserId, tKey, tValue)).called(1);
    verifyNoMoreInteractions(mockSettingsRepository);
  });

  group('UpdatePrivacySettingParams', () {
    test('should have correct props', () {
      // arrange
      const tParams = UpdatePrivacySettingParams(userId: tUserId, key: tKey, value: tValue);

      // assert
      expect(tParams.props, [tUserId, tKey, tValue]);
    });

    test('two UpdatePrivacySettingParams with same values should be equal', () {
      // arrange
      const tParams1 = UpdatePrivacySettingParams(userId: tUserId, key: tKey, value: tValue);
      const tParams2 = UpdatePrivacySettingParams(userId: tUserId, key: tKey, value: tValue);

      // assert
      expect(tParams1, equals(tParams2));
    });

    test('two UpdatePrivacySettingParams with different key should not be equal', () {
      // arrange
      const tParams1 = UpdatePrivacySettingParams(userId: tUserId, key: 'showTimeline', value: tValue);
      const tParams2 = UpdatePrivacySettingParams(userId: tUserId, key: 'showProfile', value: tValue);

      // assert
      expect(tParams1, isNot(equals(tParams2)));
    });

    test('two UpdatePrivacySettingParams with different value should not be equal', () {
      // arrange
      const tParams1 = UpdatePrivacySettingParams(userId: tUserId, key: tKey, value: true);
      const tParams2 = UpdatePrivacySettingParams(userId: tUserId, key: tKey, value: false);

      // assert
      expect(tParams1, isNot(equals(tParams2)));
    });
  });
}
