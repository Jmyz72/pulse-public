import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

class ResetPassword implements UseCase<void, ResetPasswordParams> {
  final AuthRepository repository;

  ResetPassword(this.repository);

  @override
  Future<Either<Failure, void>> call(ResetPasswordParams params) {
    return repository.resetPassword(params.email);
  }
}

class ResetPasswordParams extends Equatable {
  final String email;

  const ResetPasswordParams({required this.email});

  @override
  List<Object> get props => [email];
}
