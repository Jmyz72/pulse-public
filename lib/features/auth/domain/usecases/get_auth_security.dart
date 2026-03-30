import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/auth_security.dart';
import '../repositories/auth_repository.dart';

class GetAuthSecurity implements UseCase<AuthSecurity, NoParams> {
  final AuthRepository repository;

  GetAuthSecurity(this.repository);

  @override
  Future<Either<Failure, AuthSecurity>> call(NoParams params) {
    return repository.getAuthSecurity();
  }
}
