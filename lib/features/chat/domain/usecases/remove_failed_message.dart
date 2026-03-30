import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/failed_message_storage.dart';

class RemoveFailedMessage extends UseCase<void, RemoveFailedMessageParams> {
  final FailedMessageStorage storage;

  RemoveFailedMessage(this.storage);

  @override
  Future<Either<Failure, void>> call(RemoveFailedMessageParams params) async {
    try {
      await storage.removeFailedMessage(params.chatRoomId, params.messageId);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }
}

class RemoveFailedMessageParams extends Equatable {
  final String chatRoomId;
  final String messageId;

  const RemoveFailedMessageParams({
    required this.chatRoomId,
    required this.messageId,
  });

  @override
  List<Object> get props => [chatRoomId, messageId];
}
