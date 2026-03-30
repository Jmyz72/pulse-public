import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../auth/domain/entities/user.dart';
import '../repositories/friend_repository.dart';

class SearchUsers extends UseCase<List<User>, String> {
  final FriendRepository repository;

  SearchUsers(this.repository);

  @override
  Future<Either<Failure, List<User>>> call(String query) {
    return repository.searchUsers(query);
  }
}
