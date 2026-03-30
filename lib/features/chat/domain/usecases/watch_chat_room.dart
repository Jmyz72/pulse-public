import 'package:equatable/equatable.dart';

import '../entities/message.dart';
import '../repositories/chat_repository.dart';

class WatchChatRoom {
  final ChatRepository repository;

  WatchChatRoom(this.repository);

  Stream<ChatRoom> call(WatchChatRoomParams params) {
    return repository.watchChatRoom(params.chatRoomId);
  }
}

class WatchChatRoomParams extends Equatable {
  final String chatRoomId;

  const WatchChatRoomParams({required this.chatRoomId});

  @override
  List<Object> get props => [chatRoomId];
}
