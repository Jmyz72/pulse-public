import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/friend_repository.dart';

class RemoveFriend extends UseCase<void, String> {
  final FriendRepository repository;

  RemoveFriend(this.repository);

  @override
  Future<Either<Failure, void>> call(String friendshipId) {
    return repository.removeFriend(friendshipId);
  }
}
