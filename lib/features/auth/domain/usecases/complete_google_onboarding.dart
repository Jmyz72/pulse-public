import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class CompleteGoogleOnboarding
    implements UseCase<User, CompleteGoogleOnboardingParams> {
  final AuthRepository repository;

  CompleteGoogleOnboarding(this.repository);

  @override
  Future<Either<Failure, User>> call(CompleteGoogleOnboardingParams params) {
    return repository.completeGoogleOnboarding(
      params.username,
      password: params.password,
    );
  }
}

class CompleteGoogleOnboardingParams extends Equatable {
  final String username;
  final String? password;

  const CompleteGoogleOnboardingParams({required this.username, this.password});

  @override
  List<Object?> get props => [username, password];
}
