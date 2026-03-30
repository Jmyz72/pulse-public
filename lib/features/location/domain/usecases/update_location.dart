import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/location.dart';
import '../repositories/location_repository.dart';

class UpdateLocation implements UseCase<void, UpdateLocationParams> {
  final LocationRepository repository;

  UpdateLocation(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateLocationParams params) {
    return repository.updateLocation(params.location);
  }
}

class UpdateLocationParams extends Equatable {
  final UserLocation location;

  const UpdateLocationParams({required this.location});

  @override
  List<Object> get props => [location];
}
