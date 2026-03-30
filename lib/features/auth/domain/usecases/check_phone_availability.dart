import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

class CheckPhoneAvailability implements UseCase<bool, String> {
  final AuthRepository repository;

  CheckPhoneAvailability(this.repository);

  @override
  Future<Either<Failure, bool>> call(String phone) {
    return repository.checkPhoneAvailability(phone);
  }
}
