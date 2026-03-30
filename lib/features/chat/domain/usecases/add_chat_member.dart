import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/chat_repository.dart';

class AddChatMember implements UseCase<void, AddChatMemberParams> {
  final ChatRepository repository;

  AddChatMember(this.repository);

  @override
  Future<Either<Failure, void>> call(AddChatMemberParams params) {
    return repository.addChatMember(params.chatRoomId, params.userId);
  }
}

class AddChatMemberParams extends Equatable {
  final String chatRoomId;
  final String userId;

  const AddChatMemberParams({required this.chatRoomId, required this.userId});

  @override
  List<Object> get props => [chatRoomId, userId];
}
