import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/google_auth_result.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class LinkGoogleSignIn implements UseCase<User, LinkGoogleSignInParams> {
  final AuthRepository repository;

  LinkGoogleSignIn(this.repository);

  @override
  Future<Either<Failure, User>> call(LinkGoogleSignInParams params) {
    return repository.linkGoogleSignIn(
      password: params.password,
      profile: params.profile,
    );
  }
}

class LinkGoogleSignInParams extends Equatable {
  final String password;
  final GooglePendingProfileData profile;

  const LinkGoogleSignInParams({
    required this.password,
    required this.profile,
  });

  @override
  List<Object> get props => [password, profile];
}
