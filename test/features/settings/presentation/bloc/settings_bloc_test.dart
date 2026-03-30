import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/failures.dart';
import 'package:pulse/core/usecases/usecase.dart';
import 'package:pulse/features/settings/domain/entities/settings.dart';
import 'package:pulse/features/settings/domain/usecases/get_settings.dart';
import 'package:pulse/features/settings/domain/usecases/update_privacy_setting.dart';
import 'package:pulse/features/settings/domain/usecases/clear_settings_cache.dart';
import 'package:pulse/features/settings/domain/usecases/update_settings.dart';
import 'package:pulse/features/settings/presentation/bloc/settings_bloc.dart';

class MockGetSettings extends Mock implements GetSettings {}

class MockUpdateSettings extends Mock implements UpdateSettings {}

class MockUpdatePrivacySetting extends Mock implements UpdatePrivacySetting {}

class MockClearSettingsCache extends Mock implements ClearSettingsCache {}

void main() {
  late SettingsBloc bloc;
  late MockGetSettings mockGetSettings;
  late MockUpdateSettings mockUpdateSettings;
  late MockUpdatePrivacySetting mockUpdatePrivacySetting;
  late MockClearSettingsCache mockClearSettingsCache;

  setUp(() {
    mockGetSettings = MockGetSettings();
    mockUpdateSettings = MockUpdateSettings();
    mockUpdatePrivacySetting = MockUpdatePrivacySetting();
    mockClearSettingsCache = MockClearSettingsCache();

    bloc = SettingsBloc(
      getSettings: mockGetSettings,
      updateSettings: mockUpdateSettings,
      updatePrivacySetting: mockUpdatePrivacySetting,
      clearSettingsCache: mockClearSettingsCache,
    );
  });

  tearDown(() {
    bloc.close();
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

  const tUpdatedUserSettings = UserSettings(
    userId: tUserId,
    showTimeline: false,
    showProfile: true,
    invisibleMode: true,
    notificationsEnabled: false,
    darkMode: true,
    language: 'es',
  );

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(const GetSettingsParams(userId: tUserId));
    registerFallbackValue(const UpdateSettingsParams(userId: tUserId, settings: tUserSettings));
    registerFallbackValue(const UpdatePrivacySettingParams(userId: tUserId, key: 'showTimeline', value: false));
  });

  test('initial state should be SettingsState with initial status', () {
    expect(bloc.state, const SettingsState());
    expect(bloc.state.status, SettingsStatus.initial);
  });

  group('SettingsLoadRequested', () {
    blocTest<SettingsBloc, SettingsState>(
      'emits [loading, loaded] when GetSettings returns successfully',
      build: () {
        when(() => mockGetSettings(any()))
            .thenAnswer((_) async => const Right(tUserSettings));
        return bloc;
      },
      act: (bloc) => bloc.add(const SettingsLoadRequested(userId: tUserId)),
      expect: () => [
        const SettingsState(status: SettingsStatus.loading),
        const SettingsState(
          status: SettingsStatus.loaded,
          settings: tUserSettings,
        ),
      ],
      verify: (_) {
        verify(() => mockGetSettings(any())).called(1);
      },
    );

    blocTest<SettingsBloc, SettingsState>(
      'emits [loading, error] when GetSettings returns ServerFailure',
      build: () {
        when(() => mockGetSettings(any()))
            .thenAnswer((_) async => const Left(ServerFailure(message: 'Server error')));
        return bloc;
      },
      act: (bloc) => bloc.add(const SettingsLoadRequested(userId: tUserId)),
      expect: () => [
        const SettingsState(status: SettingsStatus.loading),
        const SettingsState(
          status: SettingsStatus.error,
          errorMessage: 'Server error',
        ),
      ],
    );

    blocTest<SettingsBloc, SettingsState>(
      'emits [loading, error] when GetSettings returns NetworkFailure',
      build: () {
        when(() => mockGetSettings(any()))
            .thenAnswer((_) async => const Left(NetworkFailure()));
        return bloc;
      },
      act: (bloc) => bloc.add(const SettingsLoadRequested(userId: tUserId)),
      expect: () => [
        const SettingsState(status: SettingsStatus.loading),
        const SettingsState(
          status: SettingsStatus.error,
          errorMessage: 'No internet connection',
        ),
      ],
    );
  });

  group('SettingsUpdated', () {
    blocTest<SettingsBloc, SettingsState>(
      'emits [loaded] with updated settings when UpdateSettings succeeds',
      build: () {
        when(() => mockUpdateSettings(any()))
            .thenAnswer((_) async => const Right(null));
        return bloc;
      },
      seed: () => const SettingsState(
        status: SettingsStatus.loaded,
        settings: tUserSettings,
      ),
      act: (bloc) => bloc.add(const SettingsUpdated(userId: tUserId, settings: tUpdatedUserSettings)),
      expect: () => [
        const SettingsState(
          status: SettingsStatus.updated,
          settings: tUpdatedUserSettings,
        ),
      ],
      verify: (_) {
        verify(() => mockUpdateSettings(any())).called(1);
      },
    );

    blocTest<SettingsBloc, SettingsState>(
      'emits [error] when UpdateSettings returns ServerFailure',
      build: () {
        when(() => mockUpdateSettings(any()))
            .thenAnswer((_) async => const Left(ServerFailure(message: 'Failed to update')));
        return bloc;
      },
      seed: () => const SettingsState(
        status: SettingsStatus.loaded,
        settings: tUserSettings,
      ),
      act: (bloc) => bloc.add(const SettingsUpdated(userId: tUserId, settings: tUpdatedUserSettings)),
      expect: () => [
        const SettingsState(
          status: SettingsStatus.error,
          settings: tUserSettings,
          errorMessage: 'Failed to update',
        ),
      ],
    );

    blocTest<SettingsBloc, SettingsState>(
      'emits [error] when UpdateSettings returns NetworkFailure',
      build: () {
        when(() => mockUpdateSettings(any()))
            .thenAnswer((_) async => const Left(NetworkFailure()));
        return bloc;
      },
      seed: () => const SettingsState(
        status: SettingsStatus.loaded,
        settings: tUserSettings,
      ),
      act: (bloc) => bloc.add(const SettingsUpdated(userId: tUserId, settings: tUpdatedUserSettings)),
      expect: () => [
        const SettingsState(
          status: SettingsStatus.error,
          settings: tUserSettings,
          errorMessage: 'No internet connection',
        ),
      ],
    );
  });

  group('PrivacySettingToggled', () {
    blocTest<SettingsBloc, SettingsState>(
      'emits state with updated showTimeline when toggling showTimeline succeeds',
      build: () {
        when(() => mockUpdatePrivacySetting(any()))
            .thenAnswer((_) async => const Right(null));
        return bloc;
      },
      seed: () => const SettingsState(
        status: SettingsStatus.loaded,
        settings: tUserSettings,
      ),
      act: (bloc) => bloc.add(const PrivacySettingToggled(userId: tUserId, key: 'showTimeline', value: false)),
      expect: () => [
        SettingsState(
          status: SettingsStatus.updated,
          settings: tUserSettings.copyWith(showTimeline: false),
        ),
      ],
      verify: (_) {
        verify(() => mockUpdatePrivacySetting(any())).called(1);
      },
    );

    blocTest<SettingsBloc, SettingsState>(
      'emits state with updated showProfile when toggling showProfile succeeds',
      build: () {
        when(() => mockUpdatePrivacySetting(any()))
            .thenAnswer((_) async => const Right(null));
        return bloc;
      },
      seed: () => const SettingsState(
        status: SettingsStatus.loaded,
        settings: tUserSettings,
      ),
      act: (bloc) => bloc.add(const PrivacySettingToggled(userId: tUserId, key: 'showProfile', value: false)),
      expect: () => [
        SettingsState(
          status: SettingsStatus.updated,
          settings: tUserSettings.copyWith(showProfile: false),
        ),
      ],
    );

    blocTest<SettingsBloc, SettingsState>(
      'emits state with updated invisibleMode when toggling invisibleMode succeeds',
      build: () {
        when(() => mockUpdatePrivacySetting(any()))
            .thenAnswer((_) async => const Right(null));
        return bloc;
      },
      seed: () => const SettingsState(
        status: SettingsStatus.loaded,
        settings: tUserSettings,
      ),
      act: (bloc) => bloc.add(const PrivacySettingToggled(userId: tUserId, key: 'invisibleMode', value: true)),
      expect: () => [
        SettingsState(
          status: SettingsStatus.updated,
          settings: tUserSettings.copyWith(invisibleMode: true),
        ),
      ],
    );

    blocTest<SettingsBloc, SettingsState>(
      'emits [error] when PrivacySettingToggled returns ServerFailure',
      build: () {
        when(() => mockUpdatePrivacySetting(any()))
            .thenAnswer((_) async => const Left(ServerFailure(message: 'Failed to toggle')));
        return bloc;
      },
      seed: () => const SettingsState(
        status: SettingsStatus.loaded,
        settings: tUserSettings,
      ),
      act: (bloc) => bloc.add(const PrivacySettingToggled(userId: tUserId, key: 'showTimeline', value: false)),
      expect: () => [
        SettingsState(
          status: SettingsStatus.updated,
          settings: tUserSettings.copyWith(showTimeline: false),
        ),
        const SettingsState(
          status: SettingsStatus.error,
          settings: tUserSettings,
          errorMessage: 'Failed to toggle',
        ),
      ],
    );

    blocTest<SettingsBloc, SettingsState>(
      'emits [error] when PrivacySettingToggled returns NetworkFailure',
      build: () {
        when(() => mockUpdatePrivacySetting(any()))
            .thenAnswer((_) async => const Left(NetworkFailure()));
        return bloc;
      },
      seed: () => const SettingsState(
        status: SettingsStatus.loaded,
        settings: tUserSettings,
      ),
      act: (bloc) => bloc.add(const PrivacySettingToggled(userId: tUserId, key: 'showProfile', value: false)),
      expect: () => [
        SettingsState(
          status: SettingsStatus.updated,
          settings: tUserSettings.copyWith(showProfile: false),
        ),
        const SettingsState(
          status: SettingsStatus.error,
          settings: tUserSettings,
          errorMessage: 'No internet connection',
        ),
      ],
    );

    blocTest<SettingsBloc, SettingsState>(
      'does nothing when settings is null',
      build: () {
        return bloc;
      },
      seed: () => const SettingsState(status: SettingsStatus.initial),
      act: (bloc) => bloc.add(const PrivacySettingToggled(userId: tUserId, key: 'showTimeline', value: false)),
      expect: () => [],
      verify: (_) {
        verifyNever(() => mockUpdatePrivacySetting(any()));
      },
    );

    blocTest<SettingsBloc, SettingsState>(
      'does nothing when key is not recognized',
      build: () {
        return bloc;
      },
      seed: () => const SettingsState(
        status: SettingsStatus.loaded,
        settings: tUserSettings,
      ),
      act: (bloc) => bloc.add(const PrivacySettingToggled(userId: tUserId, key: 'unknownKey', value: true)),
      expect: () => [],
      verify: (_) {
        verifyNever(() => mockUpdatePrivacySetting(any()));
      },
    );
  });
}
