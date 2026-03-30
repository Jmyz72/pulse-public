import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/friend_repository.dart';

class AcceptFriendRequest extends UseCase<void, String> {
  final FriendRepository repository;

  AcceptFriendRequest(this.repository);

  @override
  Future<Either<Failure, void>> call(String friendshipId) {
    return repository.acceptFriendRequest(friendshipId);
  }
}
