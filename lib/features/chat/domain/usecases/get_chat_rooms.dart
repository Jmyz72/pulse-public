import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/message.dart';
import '../repositories/chat_repository.dart';

class GetChatRooms implements UseCase<List<ChatRoom>, NoParams> {
  final ChatRepository repository;

  GetChatRooms(this.repository);

  @override
  Future<Either<Failure, List<ChatRoom>>> call(NoParams params) {
    return repository.getChatRooms();
  }
}
