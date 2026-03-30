import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/chat_repository.dart';

class RemoveChatMember implements UseCase<void, RemoveChatMemberParams> {
  final ChatRepository repository;

  RemoveChatMember(this.repository);

  @override
  Future<Either<Failure, void>> call(RemoveChatMemberParams params) {
    return repository.removeChatMember(params.chatRoomId, params.userId);
  }
}

class RemoveChatMemberParams extends Equatable {
  final String chatRoomId;
  final String userId;

  const RemoveChatMemberParams({required this.chatRoomId, required this.userId});

  @override
  List<Object> get props => [chatRoomId, userId];
}
