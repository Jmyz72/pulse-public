import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/failures.dart';
import 'package:pulse/features/chat/domain/entities/message.dart';
import 'package:pulse/features/chat/domain/repositories/chat_repository.dart';
import 'package:pulse/features/chat/domain/usecases/get_messages.dart';

class MockChatRepository extends Mock implements ChatRepository {}

void main() {
  late GetMessages usecase;
  late MockChatRepository mockRepository;

  setUp(() {
    mockRepository = MockChatRepository();
    usecase = GetMessages(mockRepository);
  });

  const tChatRoomId = 'chat-room-1';

  final tMessages = [
    Message(
      id: '1',
      senderId: 'user-1',
      senderName: 'John Doe',
      content: 'Hello!',
      chatRoomId: tChatRoomId,
      timestamp: DateTime(2024, 1, 1, 10, 0),
    ),
    Message(
      id: '2',
      senderId: 'user-2',
      senderName: 'Jane Doe',
      content: 'Hi there!',
      chatRoomId: tChatRoomId,
      timestamp: DateTime(2024, 1, 1, 10, 5),
    ),
  ];

  test('should return list of messages when successful', () async {
    // arrange
    when(() => mockRepository.getMessages(tChatRoomId, limit: any(named: 'limit'), startAfterMessageId: any(named: 'startAfterMessageId')))
        .thenAnswer((_) async => Right(tMessages));

    // act
    final result = await usecase(const GetMessagesParams(chatRoomId: tChatRoomId));

    // assert
    expect(result, Right(tMessages));
    verify(() => mockRepository.getMessages(tChatRoomId, limit: any(named: 'limit'), startAfterMessageId: any(named: 'startAfterMessageId'))).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return empty list when no messages exist', () async {
    // arrange
    when(() => mockRepository.getMessages(tChatRoomId, limit: any(named: 'limit'), startAfterMessageId: any(named: 'startAfterMessageId')))
        .thenAnswer((_) async => const Right([]));

    // act
    final result = await usecase(const GetMessagesParams(chatRoomId: tChatRoomId));

    // assert
    expect(result, const Right(<Message>[]));
    verify(() => mockRepository.getMessages(tChatRoomId, limit: any(named: 'limit'), startAfterMessageId: any(named: 'startAfterMessageId'))).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return ServerFailure when server error occurs', () async {
    // arrange
    when(() => mockRepository.getMessages(tChatRoomId, limit: any(named: 'limit'), startAfterMessageId: any(named: 'startAfterMessageId')))
        .thenAnswer((_) async => const Left(ServerFailure(message: 'Server error')));

    // act
    final result = await usecase(const GetMessagesParams(chatRoomId: tChatRoomId));

    // assert
    expect(result, const Left(ServerFailure(message: 'Server error')));
    verify(() => mockRepository.getMessages(tChatRoomId, limit: any(named: 'limit'), startAfterMessageId: any(named: 'startAfterMessageId'))).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return NetworkFailure when there is no internet', () async {
    // arrange
    when(() => mockRepository.getMessages(tChatRoomId, limit: any(named: 'limit'), startAfterMessageId: any(named: 'startAfterMessageId')))
        .thenAnswer((_) async => const Left(NetworkFailure()));

    // act
    final result = await usecase(const GetMessagesParams(chatRoomId: tChatRoomId));

    // assert
    expect(result, const Left(NetworkFailure()));
    verify(() => mockRepository.getMessages(tChatRoomId, limit: any(named: 'limit'), startAfterMessageId: any(named: 'startAfterMessageId'))).called(1);
    verifyNoMoreInteractions(mockRepository);
  });
}
