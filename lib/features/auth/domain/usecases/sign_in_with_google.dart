import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/google_auth_result.dart';
import '../repositories/auth_repository.dart';

class SignInWithGoogle implements UseCase<GoogleAuthResult, NoParams> {
  final AuthRepository repository;

  SignInWithGoogle(this.repository);

  @override
  Future<Either<Failure, GoogleAuthResult>> call(NoParams params) {
    return repository.signInWithGoogle();
  }
}
