import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/settings.dart';
import '../repositories/settings_repository.dart';

class UpdateSettings implements UseCase<void, UpdateSettingsParams> {
  final SettingsRepository repository;

  UpdateSettings(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateSettingsParams params) {
    return repository.updateSettings(params.userId, params.settings);
  }
}

class UpdateSettingsParams extends Equatable {
  final String userId;
  final UserSettings settings;

  const UpdateSettingsParams({required this.userId, required this.settings});

  @override
  List<Object> get props => [userId, settings];
}
