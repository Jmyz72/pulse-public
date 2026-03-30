import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/chat_repository.dart';

class SetTypingStatus implements UseCase<void, SetTypingStatusParams> {
  final ChatRepository repository;

  SetTypingStatus(this.repository);

  @override
  Future<Either<Failure, void>> call(SetTypingStatusParams params) {
    return repository.setTypingStatus(params.chatRoomId, params.userId, params.isTyping);
  }
}

class SetTypingStatusParams extends Equatable {
  final String chatRoomId;
  final String userId;
  final bool isTyping;

  const SetTypingStatusParams({
    required this.chatRoomId,
    required this.userId,
    required this.isTyping,
  });

  @override
  List<Object> get props => [chatRoomId, userId, isTyping];
}
