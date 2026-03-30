import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/failures.dart';
import 'package:pulse/features/settings/domain/entities/settings.dart';
import 'package:pulse/features/settings/domain/repositories/settings_repository.dart';
import 'package:pulse/features/settings/domain/usecases/get_settings.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  late GetSettings usecase;
  late MockSettingsRepository mockSettingsRepository;

  setUp(() {
    mockSettingsRepository = MockSettingsRepository();
    usecase = GetSettings(mockSettingsRepository);
  });

  const tUserId = 'user-123';
  const tUserSettings = UserSettings(
    userId: tUserId,
    showTimeline: true,
    showProfile: true,
    invisibleMode: false,
    notificationsEnabled: true,
    darkMode: false,
    language: 'en',
  );

  test('should return UserSettings when getSettings is successful', () async {
    // arrange
    when(() => mockSettingsRepository.getSettings(tUserId))
        .thenAnswer((_) async => const Right(tUserSettings));

    // act
    final result = await usecase(const GetSettingsParams(userId: tUserId));

    // assert
    expect(result, const Right(tUserSettings));
    verify(() => mockSettingsRepository.getSettings(tUserId)).called(1);
    verifyNoMoreInteractions(mockSettingsRepository);
  });

  test('should return ServerFailure when getSettings fails', () async {
    // arrange
    when(() => mockSettingsRepository.getSettings(tUserId))
        .thenAnswer((_) async => const Left(ServerFailure(message: 'Failed to load settings')));

    // act
    final result = await usecase(const GetSettingsParams(userId: tUserId));

    // assert
    expect(result, const Left(ServerFailure(message: 'Failed to load settings')));
    verify(() => mockSettingsRepository.getSettings(tUserId)).called(1);
    verifyNoMoreInteractions(mockSettingsRepository);
  });

  test('should return NetworkFailure when there is no internet connection', () async {
    // arrange
    when(() => mockSettingsRepository.getSettings(tUserId))
        .thenAnswer((_) async => const Left(NetworkFailure()));

    // act
    final result = await usecase(const GetSettingsParams(userId: tUserId));

    // assert
    expect(result, const Left(NetworkFailure()));
    verify(() => mockSettingsRepository.getSettings(tUserId)).called(1);
    verifyNoMoreInteractions(mockSettingsRepository);
  });
}
