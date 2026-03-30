import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/location.dart';
import '../../domain/repositories/location_repository.dart';
import '../datasources/location_remote_datasource.dart';
import '../models/user_location_model.dart';

class LocationRepositoryImpl implements LocationRepository {
  final LocationRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;
  final FirebaseAuth firebaseAuth;

  LocationRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
    required this.firebaseAuth,
  });

  @override
  Future<Either<Failure, UserLocation>> getCurrentLocation() async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final user = firebaseAuth.currentUser;
      if (user == null) {
        return const Left(AuthFailure(message: 'User not authenticated'));
      }
      final location = await remoteDataSource.getCurrentLocation(
        user.uid,
        user.displayName ?? 'Unknown',
      );
      return Right(location);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> updateLocation(UserLocation location) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final model = UserLocationModel.fromEntity(location);
      await remoteDataSource.updateLocation(model);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, List<UserLocation>>> getFriendsLocations(String userId) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final locations = await remoteDataSource.getFriendsLocations(userId);
      return Right(locations);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> toggleLocationSharing(bool isSharing) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final user = firebaseAuth.currentUser;
      if (user == null) {
        return const Left(AuthFailure(message: 'User not authenticated'));
      }
      await remoteDataSource.toggleLocationSharing(user.uid, isSharing);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> updateLocationPrivacy(List<String> hiddenFromUserIds) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final user = firebaseAuth.currentUser;
      if (user == null) {
        return const Left(AuthFailure(message: 'User not authenticated'));
      }
      await remoteDataSource.updateLocationPrivacy(user.uid, hiddenFromUserIds);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Stream<List<UserLocation>> watchFriendsLocations(String userId) {
    return remoteDataSource.watchFriendsLocations(userId);
  }
}
