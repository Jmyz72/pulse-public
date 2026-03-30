import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/chat_repository.dart';

class UploadChatMedia implements UseCase<String, UploadChatMediaParams> {
  final ChatRepository repository;

  UploadChatMedia(this.repository);

  @override
  Future<Either<Failure, String>> call(UploadChatMediaParams params) {
    return repository.uploadChatMedia(params.chatRoomId, params.filePath, params.fileName);
  }
}

class UploadChatMediaParams extends Equatable {
  final String chatRoomId;
  final String filePath;
  final String fileName;

  const UploadChatMediaParams({
    required this.chatRoomId,
    required this.filePath,
    required this.fileName,
  });

  @override
  List<Object> get props => [chatRoomId, filePath, fileName];
}
