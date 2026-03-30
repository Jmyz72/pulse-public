import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/chat_repository.dart';

class EditMessage implements UseCase<void, EditMessageParams> {
  final ChatRepository repository;

  EditMessage(this.repository);

  @override
  Future<Either<Failure, void>> call(EditMessageParams params) {
    return repository.editMessage(params.chatRoomId, params.messageId, params.newContent);
  }
}

class EditMessageParams extends Equatable {
  final String chatRoomId;
  final String messageId;
  final String newContent;

  const EditMessageParams({
    required this.chatRoomId,
    required this.messageId,
    required this.newContent,
  });

  @override
  List<Object> get props => [chatRoomId, messageId, newContent];
}
