import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/message.dart';
import '../repositories/chat_repository.dart';

class GetMessages implements UseCase<List<Message>, GetMessagesParams> {
  final ChatRepository repository;

  GetMessages(this.repository);

  @override
  Future<Either<Failure, List<Message>>> call(GetMessagesParams params) {
    return repository.getMessages(
      params.chatRoomId,
      limit: params.limit,
      startAfterMessageId: params.startAfterMessageId,
    );
  }
}

class GetMessagesParams extends Equatable {
  final String chatRoomId;
  final int limit;
  final String? startAfterMessageId;

  const GetMessagesParams({
    required this.chatRoomId,
    this.limit = 30,
    this.startAfterMessageId,
  });

  @override
  List<Object?> get props => [chatRoomId, limit, startAfterMessageId];
}
