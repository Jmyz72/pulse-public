import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../auth/domain/entities/user.dart';
import '../../domain/entities/friend_profile_stats.dart';
import '../../domain/entities/friendship.dart';
import '../../domain/repositories/friend_repository.dart';
import '../datasources/friend_remote_datasource.dart';

class FriendRepositoryImpl implements FriendRepository {
  final FriendRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  FriendRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<Friendship>>> getFriends(String userId) async {
    try {
      final friends = await remoteDataSource.getFriends(userId);
      return Right(friends);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, List<Friendship>>> getPendingRequests(
    String userId,
  ) async {
    try {
      final requests = await remoteDataSource.getPendingRequests(userId);
      return Right(requests);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, List<Friendship>>> getSentRequests(
    String userId,
  ) async {
    try {
      final requests = await remoteDataSource.getSentRequests(userId);
      return Right(requests);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, Friendship>> sendFriendRequest(
    String userId,
    String friendEmail,
  ) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final friendship = await remoteDataSource.sendFriendRequest(
        userId,
        friendEmail,
      );
      return Right(friendship);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> acceptFriendRequest(String friendshipId) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      await remoteDataSource.acceptFriendRequest(friendshipId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> declineFriendRequest(
    String friendshipId,
  ) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      await remoteDataSource.declineFriendRequest(friendshipId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> removeFriend(String friendshipId) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      await remoteDataSource.removeFriend(friendshipId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, List<User>>> searchUsers(String query) async {
    try {
      final users = await remoteDataSource.searchUsers(query);
      return Right(users);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, FriendProfileStats>> getFriendProfileStats({
    required String currentUserId,
    required String friendUserId,
  }) async {
    try {
      final stats = await remoteDataSource.getFriendProfileStats(
        currentUserId: currentUserId,
        friendUserId: friendUserId,
      );
      return Right(stats);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> syncDenormalizedData(
    String uid,
    String displayName,
    String username,
    String phone,
    String? photoUrl,
  ) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      await remoteDataSource.syncDenormalizedData(
        uid,
        displayName,
        username,
        phone,
        photoUrl,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }
}
