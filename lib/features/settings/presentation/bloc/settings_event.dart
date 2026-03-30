part of 'settings_bloc.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

class SettingsLoadRequested extends SettingsEvent {
  final String userId;

  const SettingsLoadRequested({required this.userId});

  @override
  List<Object> get props => [userId];
}

class SettingsUpdated extends SettingsEvent {
  final String userId;
  final UserSettings settings;

  const SettingsUpdated({required this.userId, required this.settings});

  @override
  List<Object> get props => [userId, settings];
}

class SettingsClearRequested extends SettingsEvent {}

class PrivacySettingToggled extends SettingsEvent {
  final String userId;
  final String key;
  final bool value;

  const PrivacySettingToggled({required this.userId, required this.key, required this.value});

  @override
  List<Object> get props => [userId, key, value];
}

class SettingsErrorCleared extends SettingsEvent {}
