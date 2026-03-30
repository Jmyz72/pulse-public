import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

class CheckUsernameAvailability implements UseCase<bool, String> {
  final AuthRepository repository;

  CheckUsernameAvailability(this.repository);

  @override
  Future<Either<Failure, bool>> call(String username) {
    return repository.checkUsernameAvailability(username);
  }
}
