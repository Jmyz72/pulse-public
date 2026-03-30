part of 'settings_bloc.dart';

enum SettingsStatus { initial, loading, loaded, updated, error }

class SettingsState extends Equatable {
  final SettingsStatus status;
  final UserSettings? settings;
  final String? errorMessage;

  const SettingsState({
    this.status = SettingsStatus.initial,
    this.settings,
    this.errorMessage,
  });

  SettingsState copyWith({
    SettingsStatus? status,
    UserSettings? settings,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SettingsState(
      status: status ?? this.status,
      settings: settings ?? this.settings,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, settings, errorMessage];
}
