import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/message.dart';

abstract class ChatRepository {
  Future<Either<Failure, List<ChatRoom>>> getChatRooms();
  Stream<List<ChatRoom>> watchChatRooms(); // Real-time listener for chat rooms
  Future<Either<Failure, ChatRoom>> getChatRoomById(String id);
  Stream<ChatRoom> watchChatRoom(String id); // Real-time listener for single chat room
  Future<Either<Failure, ChatRoom>> createChatRoom(ChatRoom chatRoom);
  Future<Either<Failure, void>> deleteChatRoom(String chatRoomId);
  Future<Either<Failure, List<Message>>> getMessages(String chatRoomId, {int limit, String? startAfterMessageId});
  Future<Either<Failure, Message>> sendMessage(Message message);
  Future<Either<Failure, void>> markAsRead(String chatRoomId, String userId);
  Stream<List<Message>> watchMessages(String chatRoomId, {int limit});
  Future<Either<Failure, void>> editMessage(String chatRoomId, String messageId, String newContent);
  Future<Either<Failure, void>> deleteMessage(String chatRoomId, String messageId);
  Future<Either<Failure, void>> setTypingStatus(String chatRoomId, String userId, bool isTyping);
  Stream<List<String>> watchTypingUsers(String chatRoomId, String currentUserId);
  Future<Either<Failure, String>> uploadChatMedia(String chatRoomId, String filePath, String fileName);
  Future<Either<Failure, void>> addChatMember(String chatRoomId, String userId);
  Future<Either<Failure, void>> removeChatMember(String chatRoomId, String userId);
  Future<Either<Failure, void>> leaveGroup(String chatRoomId, String userId);
  Future<Either<Failure, void>> makeAdmin(String chatRoomId, String userId);
  Future<Either<Failure, void>> removeAdmin(String chatRoomId, String userId);
}
