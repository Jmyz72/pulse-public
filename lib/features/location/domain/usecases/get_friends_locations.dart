import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/location.dart';
import '../repositories/location_repository.dart';

class GetFriendsLocations implements UseCase<List<UserLocation>, GetFriendsLocationsParams> {
  final LocationRepository repository;

  GetFriendsLocations(this.repository);

  @override
  Future<Either<Failure, List<UserLocation>>> call(GetFriendsLocationsParams params) {
    return repository.getFriendsLocations(params.userId);
  }
}

class GetFriendsLocationsParams extends Equatable {
  final String userId;

  const GetFriendsLocationsParams({required this.userId});

  @override
  List<Object> get props => [userId];
}
