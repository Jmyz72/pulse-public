import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/location_repository.dart';

class ToggleLocationSharing implements UseCase<void, ToggleLocationSharingParams> {
  final LocationRepository repository;

  ToggleLocationSharing(this.repository);

  @override
  Future<Either<Failure, void>> call(ToggleLocationSharingParams params) {
    return repository.toggleLocationSharing(params.isSharing);
  }
}

class ToggleLocationSharingParams extends Equatable {
  final bool isSharing;

  const ToggleLocationSharingParams({required this.isSharing});

  @override
  List<Object> get props => [isSharing];
}
