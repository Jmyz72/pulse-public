import 'package:equatable/equatable.dart';

import '../entities/message.dart';
import '../repositories/chat_repository.dart';

class WatchMessages {
  final ChatRepository repository;

  WatchMessages(this.repository);

  Stream<List<Message>> call(WatchMessagesParams params) {
    return repository.watchMessages(params.chatRoomId);
  }
}

class WatchMessagesParams extends Equatable {
  final String chatRoomId;

  const WatchMessagesParams({required this.chatRoomId});

  @override
  List<Object> get props => [chatRoomId];
}
