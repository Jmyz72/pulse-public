import 'package:dartz/dartz.dart' hide Task;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/failures.dart';
import 'package:pulse/features/tasks/domain/entities/task.dart';
import 'package:pulse/features/tasks/domain/repositories/task_repository.dart';
import 'package:pulse/features/tasks/domain/usecases/get_tasks.dart';

class MockTaskRepository extends Mock implements TaskRepository {}

void main() {
  late GetTasks usecase;
  late MockTaskRepository mockRepository;

  setUp(() {
    mockRepository = MockTaskRepository();
    usecase = GetTasks(mockRepository);
  });

  const tChatRoomIds = ['chat-1', 'chat-2'];

  final tTasks = [
    Task(
      id: '1',
      title: 'Clean Kitchen',
      description: 'Clean the kitchen thoroughly',
      chatRoomId: 'chat-1',
      assignedTo: 'user-1',
      assignedToName: 'John Doe',
      dueDate: DateTime(2024, 1, 15),
      createdAt: DateTime(2024, 1, 1),
      createdBy: 'user-1',
    ),
    Task(
      id: '2',
      title: 'Buy Groceries',
      description: 'Buy items for the week',
      chatRoomId: 'chat-1',
      assignedTo: 'user-2',
      assignedToName: 'Jane Doe',
      dueDate: DateTime(2024, 1, 10),
      createdAt: DateTime(2024, 1, 1),
      createdBy: 'user-1',
    ),
  ];

  test('should return list of tasks when successful', () async {
    // arrange
    when(() => mockRepository.getTasks(tChatRoomIds))
        .thenAnswer((_) async => Right(tTasks));

    // act
    final result = await usecase(const GetTasksParams(chatRoomIds: tChatRoomIds));

    // assert
    expect(result, Right(tTasks));
    verify(() => mockRepository.getTasks(tChatRoomIds)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return empty list when no tasks exist', () async {
    // arrange
    when(() => mockRepository.getTasks(tChatRoomIds))
        .thenAnswer((_) async => const Right([]));

    // act
    final result = await usecase(const GetTasksParams(chatRoomIds: tChatRoomIds));

    // assert
    expect(result, const Right(<Task>[]));
    verify(() => mockRepository.getTasks(tChatRoomIds)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return ServerFailure when server error occurs', () async {
    // arrange
    when(() => mockRepository.getTasks(tChatRoomIds))
        .thenAnswer((_) async => const Left(ServerFailure(message: 'Server error')));

    // act
    final result = await usecase(const GetTasksParams(chatRoomIds: tChatRoomIds));

    // assert
    expect(result, const Left(ServerFailure(message: 'Server error')));
    verify(() => mockRepository.getTasks(tChatRoomIds)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return NetworkFailure when there is no internet', () async {
    // arrange
    when(() => mockRepository.getTasks(tChatRoomIds))
        .thenAnswer((_) async => const Left(NetworkFailure()));

    // act
    final result = await usecase(const GetTasksParams(chatRoomIds: tChatRoomIds));

    // assert
    expect(result, const Left(NetworkFailure()));
    verify(() => mockRepository.getTasks(tChatRoomIds)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });
}
