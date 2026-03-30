import 'package:dartz/dartz.dart' hide Task;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/failures.dart';
import 'package:pulse/features/tasks/domain/entities/task.dart';
import 'package:pulse/features/tasks/domain/repositories/task_repository.dart';
import 'package:pulse/features/tasks/domain/usecases/update_task.dart';

class MockTaskRepository extends Mock implements TaskRepository {}

void main() {
  late UpdateTask usecase;
  late MockTaskRepository mockRepository;

  setUp(() {
    mockRepository = MockTaskRepository();
    usecase = UpdateTask(mockRepository);
  });

  final tTask = Task(
    id: '1',
    title: 'Clean Kitchen',
    description: 'Clean the kitchen thoroughly',
    chatRoomId: 'chat-1',
    assignedTo: 'user-1',
    assignedToName: 'John Doe',
    dueDate: DateTime(2024, 1, 15),
    status: TaskStatus.completed,
    createdAt: DateTime(2024, 1, 1),
    createdBy: 'user-1',
  );

  setUpAll(() {
    registerFallbackValue(tTask);
  });

  test('should return updated task when successful', () async {
    // arrange
    when(() => mockRepository.updateTask(any()))
        .thenAnswer((_) async => Right(tTask));

    // act
    final result = await usecase(UpdateTaskParams(task: tTask));

    // assert
    expect(result, Right(tTask));
    verify(() => mockRepository.updateTask(any())).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return ServerFailure when server error occurs', () async {
    // arrange
    when(() => mockRepository.updateTask(any()))
        .thenAnswer((_) async => const Left(ServerFailure(message: 'Failed to update task')));

    // act
    final result = await usecase(UpdateTaskParams(task: tTask));

    // assert
    expect(result, const Left(ServerFailure(message: 'Failed to update task')));
    verify(() => mockRepository.updateTask(any())).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return NetworkFailure when there is no internet', () async {
    // arrange
    when(() => mockRepository.updateTask(any()))
        .thenAnswer((_) async => const Left(NetworkFailure()));

    // act
    final result = await usecase(UpdateTaskParams(task: tTask));

    // assert
    expect(result, const Left(NetworkFailure()));
    verify(() => mockRepository.updateTask(any())).called(1);
    verifyNoMoreInteractions(mockRepository);
  });
}
