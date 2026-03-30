import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/chat_repository.dart';

class DeleteChatRoom implements UseCase<void, DeleteChatRoomParams> {
  final ChatRepository repository;

  DeleteChatRoom(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteChatRoomParams params) {
    return repository.deleteChatRoom(params.chatRoomId);
  }
}

class DeleteChatRoomParams extends Equatable {
  final String chatRoomId;

  const DeleteChatRoomParams({required this.chatRoomId});

  @override
  List<Object> get props => [chatRoomId];
}
