import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class UpdateProfile implements UseCase<User, UpdateProfileParams> {
  final AuthRepository repository;

  UpdateProfile(this.repository);

  @override
  Future<Either<Failure, User>> call(UpdateProfileParams params) async {
    return repository.updateProfile(
      params.displayName,
      params.phone,
      params.photoUrl,
      params.paymentIdentity,
    );
  }
}

class UpdateProfileParams extends Equatable {
  final String displayName;
  final String phone;
  final String? photoUrl;
  final String? paymentIdentity;

  const UpdateProfileParams({
    required this.displayName,
    required this.phone,
    this.photoUrl,
    this.paymentIdentity,
  });

  @override
  List<Object?> get props => [displayName, phone, photoUrl, paymentIdentity];
}
