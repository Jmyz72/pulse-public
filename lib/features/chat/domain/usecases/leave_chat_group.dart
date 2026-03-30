import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/chat_repository.dart';

class LeaveChatGroup implements UseCase<void, LeaveChatGroupParams> {
  final ChatRepository repository;

  LeaveChatGroup(this.repository);

  @override
  Future<Either<Failure, void>> call(LeaveChatGroupParams params) {
    return repository.leaveGroup(params.chatRoomId, params.userId);
  }
}

class LeaveChatGroupParams extends Equatable {
  final String chatRoomId;
  final String userId;

  const LeaveChatGroupParams({required this.chatRoomId, required this.userId});

  @override
  List<Object> get props => [chatRoomId, userId];
}
