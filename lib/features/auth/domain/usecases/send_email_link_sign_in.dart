import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

class SendEmailLinkSignIn implements UseCase<void, SendEmailLinkSignInParams> {
  final AuthRepository repository;

  SendEmailLinkSignIn(this.repository);

  @override
  Future<Either<Failure, void>> call(SendEmailLinkSignInParams params) {
    return repository.sendEmailLinkSignIn(params.email);
  }
}

class SendEmailLinkSignInParams extends Equatable {
  final String email;

  const SendEmailLinkSignInParams({required this.email});

  @override
  List<Object?> get props => [email];
}
