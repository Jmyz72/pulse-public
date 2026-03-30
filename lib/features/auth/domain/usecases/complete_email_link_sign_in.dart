import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class CompleteEmailLinkSignIn
    implements UseCase<User, CompleteEmailLinkSignInParams> {
  final AuthRepository repository;

  CompleteEmailLinkSignIn(this.repository);

  @override
  Future<Either<Failure, User>> call(CompleteEmailLinkSignInParams params) {
    return repository.completeEmailLinkSignIn(
      email: params.email,
      emailLink: params.emailLink,
    );
  }
}

class CompleteEmailLinkSignInParams extends Equatable {
  final String email;
  final String emailLink;

  const CompleteEmailLinkSignInParams({
    required this.email,
    required this.emailLink,
  });

  @override
  List<Object?> get props => [email, emailLink];
}
