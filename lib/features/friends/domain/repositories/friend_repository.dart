import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../auth/domain/entities/user.dart';
import '../entities/friend_profile_stats.dart';
import '../entities/friendship.dart';

abstract class FriendRepository {
  Future<Either<Failure, List<Friendship>>> getFriends(String userId);
  Future<Either<Failure, List<Friendship>>> getPendingRequests(String userId);
  Future<Either<Failure, List<Friendship>>> getSentRequests(String userId);
  Future<Either<Failure, Friendship>> sendFriendRequest(
    String userId,
    String friendEmail,
  );
  Future<Either<Failure, void>> acceptFriendRequest(String friendshipId);
  Future<Either<Failure, void>> declineFriendRequest(String friendshipId);
  Future<Either<Failure, void>> removeFriend(String friendshipId);
  Future<Either<Failure, List<User>>> searchUsers(String query);
  Future<Either<Failure, FriendProfileStats>> getFriendProfileStats({
    required String currentUserId,
    required String friendUserId,
  });
  Future<Either<Failure, void>> syncDenormalizedData(
    String uid,
    String displayName,
    String username,
    String phone,
    String? photoUrl,
  );
}
