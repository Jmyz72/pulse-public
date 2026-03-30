import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/message.dart';
import '../repositories/chat_repository.dart';

class GetChatRoomById extends UseCase<ChatRoom, GetChatRoomByIdParams> {
  final ChatRepository repository;

  GetChatRoomById(this.repository);

  @override
  Future<Either<Failure, ChatRoom>> call(GetChatRoomByIdParams params) {
    return repository.getChatRoomById(params.chatRoomId);
  }
}

class GetChatRoomByIdParams extends Equatable {
  final String chatRoomId;

  const GetChatRoomByIdParams({required this.chatRoomId});

  @override
  List<Object> get props => [chatRoomId];
}
