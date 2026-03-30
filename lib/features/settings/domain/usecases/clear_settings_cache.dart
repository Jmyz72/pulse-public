import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/settings_repository.dart';

class ClearSettingsCache implements UseCase<void, NoParams> {
  final SettingsRepository repository;

  ClearSettingsCache(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) {
    return repository.clearCache();
  }
}
