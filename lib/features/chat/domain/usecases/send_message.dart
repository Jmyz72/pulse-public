import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/message.dart';
import '../repositories/chat_repository.dart';

class SendMessage implements UseCase<Message, SendMessageParams> {
  final ChatRepository repository;

  SendMessage(this.repository);

  @override
  Future<Either<Failure, Message>> call(SendMessageParams params) {
    return repository.sendMessage(params.message);
  }
}

class SendMessageParams extends Equatable {
  final Message message;

  SendMessageParams({required this.message})
      : assert(message.chatRoomId.isNotEmpty, 'chatRoomId cannot be empty'),
        assert(
          message.content.isNotEmpty || message.imageUrl != null,
          'message must have content or an image',
        );

  @override
  List<Object> get props => [message];
}
