import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/failures.dart';
import 'package:pulse/core/usecases/usecase.dart';
import 'package:pulse/features/chat/domain/entities/message.dart';
import 'package:pulse/features/chat/domain/repositories/chat_repository.dart';
import 'package:pulse/features/chat/domain/usecases/get_chat_rooms.dart';

class MockChatRepository extends Mock implements ChatRepository {}

void main() {
  late GetChatRooms usecase;
  late MockChatRepository mockRepository;

  setUp(() {
    mockRepository = MockChatRepository();
    usecase = GetChatRooms(mockRepository);
  });

  final tChatRooms = [
    ChatRoom(
      id: '1',
      name: 'General',
      members: ['user-1', 'user-2'],
      createdAt: DateTime(2024, 1, 1),
      isGroup: true,
    ),
    ChatRoom(
      id: '2',
      name: 'John Doe',
      members: ['user-1', 'user-3'],
      createdAt: DateTime(2024, 1, 2),
      isGroup: false,
    ),
  ];

  test('should return list of chat rooms when successful', () async {
    // arrange
    when(() => mockRepository.getChatRooms())
        .thenAnswer((_) async => Right(tChatRooms));

    // act
    final result = await usecase(const NoParams());

    // assert
    expect(result, Right(tChatRooms));
    verify(() => mockRepository.getChatRooms()).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return empty list when no chat rooms exist', () async {
    // arrange
    when(() => mockRepository.getChatRooms())
        .thenAnswer((_) async => const Right([]));

    // act
    final result = await usecase(const NoParams());

    // assert
    expect(result, const Right(<ChatRoom>[]));
    verify(() => mockRepository.getChatRooms()).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return ServerFailure when server error occurs', () async {
    // arrange
    when(() => mockRepository.getChatRooms())
        .thenAnswer((_) async => const Left(ServerFailure(message: 'Server error')));

    // act
    final result = await usecase(const NoParams());

    // assert
    expect(result, const Left(ServerFailure(message: 'Server error')));
    verify(() => mockRepository.getChatRooms()).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return NetworkFailure when there is no internet', () async {
    // arrange
    when(() => mockRepository.getChatRooms())
        .thenAnswer((_) async => const Left(NetworkFailure()));

    // act
    final result = await usecase(const NoParams());

    // assert
    expect(result, const Left(NetworkFailure()));
    verify(() => mockRepository.getChatRooms()).called(1);
    verifyNoMoreInteractions(mockRepository);
  });
}
