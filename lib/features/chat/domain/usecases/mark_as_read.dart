import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/chat_repository.dart';

class MarkAsRead extends UseCase<void, MarkAsReadParams> {
  final ChatRepository repository;

  MarkAsRead(this.repository);

  @override
  Future<Either<Failure, void>> call(MarkAsReadParams params) {
    return repository.markAsRead(params.chatRoomId, params.userId);
  }
}

class MarkAsReadParams extends Equatable {
  final String chatRoomId;
  final String userId;

  const MarkAsReadParams({required this.chatRoomId, required this.userId});

  @override
  List<Object> get props => [chatRoomId, userId];
}
