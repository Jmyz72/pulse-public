import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/chat_repository.dart';

class RemoveAdmin implements UseCase<void, RemoveAdminParams> {
  final ChatRepository repository;

  RemoveAdmin(this.repository);

  @override
  Future<Either<Failure, void>> call(RemoveAdminParams params) {
    return repository.removeAdmin(params.chatRoomId, params.userId);
  }
}

class RemoveAdminParams extends Equatable {
  final String chatRoomId;
  final String userId;

  RemoveAdminParams({required this.chatRoomId, required this.userId})
      : assert(chatRoomId.isNotEmpty, 'chatRoomId cannot be empty'),
        assert(userId.isNotEmpty, 'userId cannot be empty');

  @override
  List<Object> get props => [chatRoomId, userId];
}
