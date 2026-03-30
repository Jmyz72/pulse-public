import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class Register implements UseCase<User, RegisterParams> {
  final AuthRepository repository;

  Register(this.repository);

  @override
  Future<Either<Failure, User>> call(RegisterParams params) {
    return repository.registerWithEmail(
      params.email,
      params.password,
      params.username,
      params.displayName,
    );
  }
}

class RegisterParams extends Equatable {
  final String email;
  final String password;
  final String username;
  final String displayName;

  const RegisterParams({
    required this.email,
    required this.password,
    required this.username,
    required this.displayName,
  });

  @override
  List<Object> get props => [email, password, username, displayName];
}
