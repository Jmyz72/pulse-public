import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/chat_repository.dart';

class MakeAdmin implements UseCase<void, MakeAdminParams> {
  final ChatRepository repository;

  MakeAdmin(this.repository);

  @override
  Future<Either<Failure, void>> call(MakeAdminParams params) {
    return repository.makeAdmin(params.chatRoomId, params.userId);
  }
}

class MakeAdminParams extends Equatable {
  final String chatRoomId;
  final String userId;

  MakeAdminParams({required this.chatRoomId, required this.userId})
      : assert(chatRoomId.isNotEmpty, 'chatRoomId cannot be empty'),
        assert(userId.isNotEmpty, 'userId cannot be empty');

  @override
  List<Object> get props => [chatRoomId, userId];
}
