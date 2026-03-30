import 'package:equatable/equatable.dart';

import '../repositories/chat_repository.dart';

class WatchTypingUsers {
  final ChatRepository repository;

  WatchTypingUsers(this.repository);

  Stream<List<String>> call(WatchTypingUsersParams params) {
    return repository.watchTypingUsers(params.chatRoomId, params.currentUserId);
  }
}

class WatchTypingUsersParams extends Equatable {
  final String chatRoomId;
  final String currentUserId;

  const WatchTypingUsersParams({
    required this.chatRoomId,
    required this.currentUserId,
  });

  @override
  List<Object> get props => [chatRoomId, currentUserId];
}
