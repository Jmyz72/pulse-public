import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/settings.dart';
import '../repositories/settings_repository.dart';

class GetSettings implements UseCase<UserSettings, GetSettingsParams> {
  final SettingsRepository repository;

  GetSettings(this.repository);

  @override
  Future<Either<Failure, UserSettings>> call(GetSettingsParams params) {
    return repository.getSettings(params.userId);
  }
}

class GetSettingsParams extends Equatable {
  final String userId;

  const GetSettingsParams({required this.userId});

  @override
  List<Object?> get props => [userId];
}
