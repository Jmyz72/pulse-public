import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/friend_profile_stats.dart';
import '../repositories/friend_repository.dart';

class GetFriendProfileStats
    extends UseCase<FriendProfileStats, GetFriendProfileStatsParams> {
  final FriendRepository repository;

  GetFriendProfileStats(this.repository);

  @override
  Future<Either<Failure, FriendProfileStats>> call(
    GetFriendProfileStatsParams params,
  ) {
    return repository.getFriendProfileStats(
      currentUserId: params.currentUserId,
      friendUserId: params.friendUserId,
    );
  }
}

class GetFriendProfileStatsParams extends Equatable {
  final String currentUserId;
  final String friendUserId;

  const GetFriendProfileStatsParams({
    required this.currentUserId,
    required this.friendUserId,
  });

  @override
  List<Object?> get props => [currentUserId, friendUserId];
}
