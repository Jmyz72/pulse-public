import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/message.dart';
import '../repositories/failed_message_storage.dart';

class GetFailedMessages extends UseCase<List<Message>, GetFailedMessagesParams> {
  final FailedMessageStorage storage;

  GetFailedMessages(this.storage);

  @override
  Future<Either<Failure, List<Message>>> call(
      GetFailedMessagesParams params) async {
    try {
      final messages = await storage.getFailedMessages(params.chatRoomId);
      return Right(messages);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }
}

class GetFailedMessagesParams extends Equatable {
  final String chatRoomId;

  const GetFailedMessagesParams({required this.chatRoomId});

  @override
  List<Object> get props => [chatRoomId];
}
