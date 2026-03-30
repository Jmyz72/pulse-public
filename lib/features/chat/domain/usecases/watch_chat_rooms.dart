import '../entities/message.dart';
import '../repositories/chat_repository.dart';

class WatchChatRooms {
  final ChatRepository repository;

  WatchChatRooms(this.repository);

  Stream<List<ChatRoom>> call() {
    return repository.watchChatRooms();
  }
}
