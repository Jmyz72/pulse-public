import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/chat_repository.dart';

class DeleteMessage implements UseCase<void, DeleteMessageParams> {
  final ChatRepository repository;

  DeleteMessage(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteMessageParams params) {
    return repository.deleteMessage(params.chatRoomId, params.messageId);
  }
}

class DeleteMessageParams extends Equatable {
  final String chatRoomId;
  final String messageId;

  const DeleteMessageParams({
    required this.chatRoomId,
    required this.messageId,
  });

  @override
  List<Object> get props => [chatRoomId, messageId];
}
