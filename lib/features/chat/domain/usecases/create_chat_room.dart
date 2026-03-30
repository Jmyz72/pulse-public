import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/message.dart';
import '../repositories/chat_repository.dart';

class CreateChatRoom implements UseCase<ChatRoom, CreateChatRoomParams> {
  final ChatRepository repository;

  CreateChatRoom(this.repository);

  @override
  Future<Either<Failure, ChatRoom>> call(CreateChatRoomParams params) {
    return repository.createChatRoom(params.chatRoom);
  }
}

class CreateChatRoomParams extends Equatable {
  final ChatRoom chatRoom;

  const CreateChatRoomParams({required this.chatRoom});

  @override
  List<Object> get props => [chatRoom];
}
