import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/password_policy_validation.dart';
import '../repositories/auth_repository.dart';

class ValidatePasswordPolicy
    implements UseCase<PasswordPolicyValidation, String> {
  final AuthRepository repository;

  ValidatePasswordPolicy(this.repository);

  @override
  Future<Either<Failure, PasswordPolicyValidation>> call(String password) {
    return repository.validatePasswordPolicy(password);
  }
}
