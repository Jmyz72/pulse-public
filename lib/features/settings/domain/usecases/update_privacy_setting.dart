import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/settings_repository.dart';

class UpdatePrivacySetting implements UseCase<void, UpdatePrivacySettingParams> {
  final SettingsRepository repository;

  UpdatePrivacySetting(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdatePrivacySettingParams params) {
    return repository.updatePrivacySetting(params.userId, params.key, params.value);
  }
}

class UpdatePrivacySettingParams extends Equatable {
  final String userId;
  final String key;
  final bool value;

  const UpdatePrivacySettingParams({required this.userId, required this.key, required this.value});

  @override
  List<Object> get props => [userId, key, value];
}
