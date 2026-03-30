import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/location.dart';

abstract class LocationRepository {
  Future<Either<Failure, UserLocation>> getCurrentLocation();
  Future<Either<Failure, void>> updateLocation(UserLocation location);
  Future<Either<Failure, List<UserLocation>>> getFriendsLocations(String userId);
  Future<Either<Failure, void>> toggleLocationSharing(bool isSharing);
  Future<Either<Failure, void>> updateLocationPrivacy(List<String> hiddenFromUserIds);
  Stream<List<UserLocation>> watchFriendsLocations(String userId);
}
