import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/failures.dart';
import 'package:pulse/features/settings/domain/entities/settings.dart';
import 'package:pulse/features/settings/domain/repositories/settings_repository.dart';
import 'package:pulse/features/settings/domain/usecases/update_settings.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  late UpdateSettings usecase;
  late MockSettingsRepository mockSettingsRepository;

  setUp(() {
    mockSettingsRepository = MockSettingsRepository();
    usecase = UpdateSettings(mockSettingsRepository);
  });

  const tUserId = 'user-123';
  const tUserSettings = UserSettings(
    userId: tUserId,
    showTimeline: false,
    showProfile: true,
    invisibleMode: true,
    notificationsEnabled: false,
    darkMode: true,
    language: 'es',
  );

  setUpAll(() {
    registerFallbackValue(tUserSettings);
  });

  test('should return void when updateSettings is successful', () async {
    // arrange
    when(() => mockSettingsRepository.updateSettings(tUserId, any()))
        .thenAnswer((_) async => const Right(null));

    // act
    final result = await usecase(const UpdateSettingsParams(userId: tUserId, settings: tUserSettings));

    // assert
    expect(result, const Right(null));
    verify(() => mockSettingsRepository.updateSettings(tUserId, tUserSettings)).called(1);
    verifyNoMoreInteractions(mockSettingsRepository);
  });

  test('should return ServerFailure when updateSettings fails', () async {
    // arrange
    when(() => mockSettingsRepository.updateSettings(tUserId, any()))
        .thenAnswer((_) async => const Left(ServerFailure(message: 'Failed to update settings')));

    // act
    final result = await usecase(const UpdateSettingsParams(userId: tUserId, settings: tUserSettings));

    // assert
    expect(result, const Left(ServerFailure(message: 'Failed to update settings')));
    verify(() => mockSettingsRepository.updateSettings(tUserId, tUserSettings)).called(1);
    verifyNoMoreInteractions(mockSettingsRepository);
  });

  test('should return NetworkFailure when there is no internet connection', () async {
    // arrange
    when(() => mockSettingsRepository.updateSettings(tUserId, any()))
        .thenAnswer((_) async => const Left(NetworkFailure()));

    // act
    final result = await usecase(const UpdateSettingsParams(userId: tUserId, settings: tUserSettings));

    // assert
    expect(result, const Left(NetworkFailure()));
    verify(() => mockSettingsRepository.updateSettings(tUserId, tUserSettings)).called(1);
    verifyNoMoreInteractions(mockSettingsRepository);
  });

  group('UpdateSettingsParams', () {
    test('should have correct props', () {
      // arrange
      const tParams = UpdateSettingsParams(userId: tUserId, settings: tUserSettings);

      // assert
      expect(tParams.props, [tUserId, tUserSettings]);
    });

    test('two UpdateSettingsParams with same values should be equal', () {
      // arrange
      const tParams1 = UpdateSettingsParams(userId: tUserId, settings: tUserSettings);
      const tParams2 = UpdateSettingsParams(userId: tUserId, settings: tUserSettings);

      // assert
      expect(tParams1, equals(tParams2));
    });
  });
}
