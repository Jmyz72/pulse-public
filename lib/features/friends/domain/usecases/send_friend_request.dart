import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/friendship.dart';
import '../repositories/friend_repository.dart';

class SendFriendRequest extends UseCase<Friendship, SendFriendRequestParams> {
  final FriendRepository repository;

  SendFriendRequest(this.repository);

  @override
  Future<Either<Failure, Friendship>> call(SendFriendRequestParams params) {
    return repository.sendFriendRequest(params.userId, params.friendEmail);
  }
}

class SendFriendRequestParams extends Equatable {
  final String userId;
  final String friendEmail;

  const SendFriendRequestParams({required this.userId, required this.friendEmail});

  @override
  List<Object?> get props => [userId, friendEmail];
}
