import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/auth_security.dart';
import '../repositories/auth_repository.dart';

class SetPassword implements UseCase<AuthSecurity, SetPasswordParams> {
  final AuthRepository repository;

  SetPassword(this.repository);

  @override
  Future<Either<Failure, AuthSecurity>> call(SetPasswordParams params) {
    return repository.setPassword(params.password);
  }
}

class SetPasswordParams extends Equatable {
  final String password;

  const SetPasswordParams({required this.password});

  @override
  List<Object?> get props => [password];
}
