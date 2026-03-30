import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/location.dart';
import '../repositories/location_repository.dart';

class GetCurrentLocation implements UseCase<UserLocation, NoParams> {
  final LocationRepository repository;

  GetCurrentLocation(this.repository);

  @override
  Future<Either<Failure, UserLocation>> call(NoParams params) {
    return repository.getCurrentLocation();
  }
}
