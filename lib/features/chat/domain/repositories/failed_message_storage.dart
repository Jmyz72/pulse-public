import '../entities/message.dart';

/// Domain-level abstraction for failed message persistence.
/// This allows the presentation layer to depend on domain contracts
/// rather than data layer implementations.
abstract class FailedMessageStorage {
  Future<void> saveFailedMessage(Message message);
  Future<List<Message>> getFailedMessages(String chatRoomId);
  Future<void> removeFailedMessage(String chatRoomId, String messageId);
}
