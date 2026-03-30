import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/failures.dart';
import 'package:pulse/features/chat/domain/entities/message.dart';
import 'package:pulse/features/chat/domain/repositories/chat_repository.dart';
import 'package:pulse/features/chat/domain/usecases/send_message.dart';

class MockChatRepository extends Mock implements ChatRepository {}

void main() {
  late SendMessage usecase;
  late MockChatRepository mockRepository;

  setUp(() {
    mockRepository = MockChatRepository();
    usecase = SendMessage(mockRepository);
  });

  final tMessage = Message(
    id: '1',
    senderId: 'user-1',
    senderName: 'John Doe',
    content: 'Hello!',
    chatRoomId: 'chat-room-1',
    timestamp: DateTime(2024, 1, 1, 10, 0),
  );

  setUpAll(() {
    registerFallbackValue(tMessage);
  });

  test('should return sent message when successful', () async {
    // arrange
    when(() => mockRepository.sendMessage(any()))
        .thenAnswer((_) async => Right(tMessage));

    // act
    final result = await usecase(SendMessageParams(message: tMessage));

    // assert
    expect(result, Right(tMessage));
    verify(() => mockRepository.sendMessage(any())).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return ServerFailure when server error occurs', () async {
    // arrange
    when(() => mockRepository.sendMessage(any()))
        .thenAnswer((_) async => const Left(ServerFailure(message: 'Failed to send message')));

    // act
    final result = await usecase(SendMessageParams(message: tMessage));

    // assert
    expect(result, const Left(ServerFailure(message: 'Failed to send message')));
    verify(() => mockRepository.sendMessage(any())).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return NetworkFailure when there is no internet', () async {
    // arrange
    when(() => mockRepository.sendMessage(any()))
        .thenAnswer((_) async => const Left(NetworkFailure()));

    // act
    final result = await usecase(SendMessageParams(message: tMessage));

    // assert
    expect(result, const Left(NetworkFailure()));
    verify(() => mockRepository.sendMessage(any())).called(1);
    verifyNoMoreInteractions(mockRepository);
  });
}
