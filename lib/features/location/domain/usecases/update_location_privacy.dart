import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/location_repository.dart';

class UpdateLocationPrivacy implements UseCase<void, UpdateLocationPrivacyParams> {
  final LocationRepository repository;

  UpdateLocationPrivacy(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateLocationPrivacyParams params) {
    return repository.updateLocationPrivacy(params.hiddenFromUserIds);
  }
}

class UpdateLocationPrivacyParams extends Equatable {
  final List<String> hiddenFromUserIds;

  const UpdateLocationPrivacyParams({required this.hiddenFromUserIds});

  @override
  List<Object> get props => [hiddenFromUserIds];
}
