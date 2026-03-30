import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_datasource.dart';
import '../models/message_model.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  ChatRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<ChatRoom>>> getChatRooms() async {
    try {
      final chatRooms = await remoteDataSource.getChatRooms();
      return Right(chatRooms);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Stream<List<ChatRoom>> watchChatRooms() {
    return remoteDataSource.watchChatRooms();
  }

  @override
  Stream<ChatRoom> watchChatRoom(String id) {
    return remoteDataSource.watchChatRoom(id);
  }

  @override
  Future<Either<Failure, ChatRoom>> getChatRoomById(String id) async {
    try {
      final chatRoom = await remoteDataSource.getChatRoomById(id);
      return Right(chatRoom);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, ChatRoom>> createChatRoom(ChatRoom chatRoom) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final model = ChatRoomModel(
        id: chatRoom.id,
        name: chatRoom.name,
        members: chatRoom.members,
        createdAt: chatRoom.createdAt,
        isGroup: chatRoom.isGroup,
        imageUrl: chatRoom.imageUrl,
        createdBy: chatRoom.createdBy,
        admins: chatRoom.admins,
      );
      final created = await remoteDataSource.createChatRoom(model);
      return Right(created);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> deleteChatRoom(String chatRoomId) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      await remoteDataSource.deleteChatRoom(chatRoomId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, List<Message>>> getMessages(String chatRoomId, {int limit = 30, String? startAfterMessageId}) async {
    try {
      final messages = await remoteDataSource.getMessages(chatRoomId, limit: limit, startAfterMessageId: startAfterMessageId);
      return Right(messages);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, Message>> sendMessage(Message message) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final model = MessageModel.fromEntity(message);
      final sent = await remoteDataSource.sendMessage(model);
      return Right(sent);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> markAsRead(String chatRoomId, String userId) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      await remoteDataSource.markAsRead(chatRoomId, userId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Stream<List<Message>> watchMessages(String chatRoomId, {int limit = 30}) {
    return remoteDataSource.watchMessages(chatRoomId, limit: limit);
  }

  @override
  Future<Either<Failure, void>> editMessage(String chatRoomId, String messageId, String newContent) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      await remoteDataSource.editMessage(chatRoomId, messageId, newContent);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> deleteMessage(String chatRoomId, String messageId) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      await remoteDataSource.deleteMessage(chatRoomId, messageId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> setTypingStatus(String chatRoomId, String userId, bool isTyping) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      await remoteDataSource.setTypingStatus(chatRoomId, userId, isTyping);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Stream<List<String>> watchTypingUsers(String chatRoomId, String currentUserId) {
    return remoteDataSource.watchTypingUsers(chatRoomId, currentUserId)
        .handleError((error) => <String>[]);
  }

  @override
  Future<Either<Failure, String>> uploadChatMedia(String chatRoomId, String filePath, String fileName) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final url = await remoteDataSource.uploadChatMedia(chatRoomId, filePath, fileName);
      return Right(url);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> addChatMember(String chatRoomId, String userId) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      await remoteDataSource.addChatMember(chatRoomId, userId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> removeChatMember(String chatRoomId, String userId) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      await remoteDataSource.removeChatMember(chatRoomId, userId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> leaveGroup(String chatRoomId, String userId) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      await remoteDataSource.leaveGroup(chatRoomId, userId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> makeAdmin(String chatRoomId, String userId) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      await remoteDataSource.makeAdmin(chatRoomId, userId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> removeAdmin(String chatRoomId, String userId) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      await remoteDataSource.removeAdmin(chatRoomId, userId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

}
