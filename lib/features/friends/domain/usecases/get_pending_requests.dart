import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/friendship.dart';
import '../repositories/friend_repository.dart';

class GetPendingRequests extends UseCase<List<Friendship>, String> {
  final FriendRepository repository;

  GetPendingRequests(this.repository);

  @override
  Future<Either<Failure, List<Friendship>>> call(String userId) {
    return repository.getPendingRequests(userId);
  }
}
