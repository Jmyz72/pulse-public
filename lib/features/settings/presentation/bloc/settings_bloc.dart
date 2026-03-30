import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/settings.dart';
import '../../domain/usecases/clear_settings_cache.dart';
import '../../domain/usecases/get_settings.dart';
import '../../domain/usecases/update_privacy_setting.dart';
import '../../domain/usecases/update_settings.dart';

part 'settings_event.dart';
part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final GetSettings getSettings;
  final UpdateSettings updateSettings;
  final UpdatePrivacySetting updatePrivacySetting;
  final ClearSettingsCache clearSettingsCache;

  SettingsBloc({
    required this.getSettings,
    required this.updateSettings,
    required this.updatePrivacySetting,
    required this.clearSettingsCache,
  }) : super(const SettingsState()) {
    on<SettingsLoadRequested>(_onLoadRequested);
    on<SettingsUpdated>(_onUpdated);
    on<SettingsClearRequested>(_onClearRequested);
    on<PrivacySettingToggled>(_onPrivacyToggled, transformer: droppable());
    on<SettingsErrorCleared>(_onErrorCleared);
  }

  void _onErrorCleared(
    SettingsErrorCleared event,
    Emitter<SettingsState> emit,
  ) {
    emit(state.copyWith(clearError: true));
  }

  Future<void> _onLoadRequested(
    SettingsLoadRequested event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(status: SettingsStatus.loading));

    final result = await getSettings(GetSettingsParams(userId: event.userId));

    result.fold(
      (failure) => emit(state.copyWith(
        status: SettingsStatus.error,
        errorMessage: failure.message,
      )),
      (settings) => emit(state.copyWith(
        status: SettingsStatus.loaded,
        settings: settings,
        clearError: true,
      )),
    );
  }

  Future<void> _onClearRequested(
    SettingsClearRequested event,
    Emitter<SettingsState> emit,
  ) async {
    await clearSettingsCache(const NoParams());
    emit(const SettingsState());
  }

  Future<void> _onUpdated(
    SettingsUpdated event,
    Emitter<SettingsState> emit,
  ) async {
    final result = await updateSettings(UpdateSettingsParams(userId: event.userId, settings: event.settings));

    result.fold(
      (failure) => emit(state.copyWith(
        status: SettingsStatus.error,
        errorMessage: failure.message,
      )),
      (_) => emit(state.copyWith(
        status: SettingsStatus.updated,
        settings: event.settings,
        clearError: true,
      )),
    );
  }

  Future<void> _onPrivacyToggled(
    PrivacySettingToggled event,
    Emitter<SettingsState> emit,
  ) async {
    if (state.settings == null) return;

    UserSettings updated;
    switch (event.key) {
      case 'showTimeline':
        updated = state.settings!.copyWith(showTimeline: event.value);
        break;
      case 'showProfile':
        updated = state.settings!.copyWith(showProfile: event.value);
        break;
      case 'invisibleMode':
        updated = state.settings!.copyWith(invisibleMode: event.value);
        break;
      case 'notificationsEnabled':
        updated = state.settings!.copyWith(notificationsEnabled: event.value);
        break;
      case 'darkMode':
        updated = state.settings!.copyWith(darkMode: event.value);
        break;
      case 'searchableByUsername':
        updated = state.settings!.copyWith(searchableByUsername: event.value);
        break;
      case 'searchableByEmail':
        updated = state.settings!.copyWith(searchableByEmail: event.value);
        break;
      case 'searchableByPhone':
        updated = state.settings!.copyWith(searchableByPhone: event.value);
        break;
      default:
        return;
    }

    final previousSettings = state.settings;

    emit(state.copyWith(status: SettingsStatus.updated, settings: updated, clearError: true));

    final result = await updatePrivacySetting(
      UpdatePrivacySettingParams(userId: event.userId, key: event.key, value: event.value),
    );

    result.fold(
      (failure) => emit(state.copyWith(
        status: SettingsStatus.error,
        errorMessage: failure.message,
        settings: previousSettings,
      )),
      (_) {},
    );
  }
}
