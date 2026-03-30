import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart' hide Task;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/failures.dart';
import 'package:pulse/core/usecases/usecase.dart';
import 'package:pulse/features/tasks/domain/entities/task.dart';
import 'package:pulse/features/tasks/domain/usecases/create_task.dart';
import 'package:pulse/features/tasks/domain/usecases/complete_task_with_evidence.dart';
import 'package:pulse/features/tasks/domain/usecases/get_tasks.dart';
import 'package:pulse/features/tasks/domain/usecases/update_task.dart';
import 'package:pulse/features/notifications/domain/usecases/send_notification.dart';
import 'package:pulse/features/tasks/presentation/bloc/task_bloc.dart';

class MockGetTasks extends Mock implements GetTasks {}

class MockCreateTask extends Mock implements CreateTask {}

class MockUpdateTask extends Mock implements UpdateTask {}

class MockCompleteTaskWithEvidence extends Mock
    implements CompleteTaskWithEvidence {}

class MockSendNotification extends Mock implements SendNotification {}

void main() {
  late TaskBloc bloc;
  late MockGetTasks mockGetTasks;
  late MockCreateTask mockCreateTask;
  late MockUpdateTask mockUpdateTask;
  late MockCompleteTaskWithEvidence mockCompleteTaskWithEvidence;
  late MockSendNotification mockSendNotification;

  setUp(() {
    mockGetTasks = MockGetTasks();
    mockCreateTask = MockCreateTask();
    mockUpdateTask = MockUpdateTask();
    mockCompleteTaskWithEvidence = MockCompleteTaskWithEvidence();
    mockSendNotification = MockSendNotification();

    bloc = TaskBloc(
      getTasks: mockGetTasks,
      createTask: mockCreateTask,
      updateTask: mockUpdateTask,
      completeTaskWithEvidence: mockCompleteTaskWithEvidence,
      sendNotification: mockSendNotification,
    );
  });

  tearDown(() {
    bloc.close();
  });

  const tChatRoomIds = ['chat-1', 'chat-2'];

  final tTask = Task(
    id: '1',
    title: 'Clean Kitchen',
    description: 'Clean the kitchen thoroughly',
    chatRoomId: 'chat-1',
    assignedTo: 'user-1',
    assignedToName: 'John Doe',
    dueDate: DateTime(2024, 1, 15),
    createdAt: DateTime(2024, 1, 1),
    createdBy: 'user-1',
  );

  final tTasks = [tTask];

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(const GetTasksParams(chatRoomIds: ['chat-1']));
    registerFallbackValue(CreateTaskParams(task: tTask));
    registerFallbackValue(UpdateTaskParams(task: tTask));
  });

  group('TaskLoadRequested', () {
    blocTest<TaskBloc, TaskState>(
      'emits [loading, loaded] when tasks are loaded successfully',
      build: () {
        when(() => mockGetTasks(any())).thenAnswer((_) async => Right(tTasks));
        return bloc;
      },
      act: (bloc) =>
          bloc.add(const TaskLoadRequested(chatRoomIds: tChatRoomIds)),
      expect: () => [
        const TaskState(status: TaskBlocStatus.loading),
        TaskState(status: TaskBlocStatus.loaded, tasks: tTasks),
      ],
      verify: (_) {
        verify(() => mockGetTasks(any())).called(1);
      },
    );

    blocTest<TaskBloc, TaskState>(
      'emits [loading, loaded] with empty list when no tasks exist',
      build: () {
        when(
          () => mockGetTasks(any()),
        ).thenAnswer((_) async => const Right([]));
        return bloc;
      },
      act: (bloc) =>
          bloc.add(const TaskLoadRequested(chatRoomIds: tChatRoomIds)),
      expect: () => [
        const TaskState(status: TaskBlocStatus.loading),
        const TaskState(status: TaskBlocStatus.loaded, tasks: []),
      ],
    );

    blocTest<TaskBloc, TaskState>(
      'emits [loading, error] when loading fails',
      build: () {
        when(() => mockGetTasks(any())).thenAnswer(
          (_) async => const Left(ServerFailure(message: 'Server error')),
        );
        return bloc;
      },
      act: (bloc) =>
          bloc.add(const TaskLoadRequested(chatRoomIds: tChatRoomIds)),
      expect: () => [
        const TaskState(status: TaskBlocStatus.loading),
        const TaskState(
          status: TaskBlocStatus.error,
          errorMessage: 'Server error',
        ),
      ],
    );
  });

  group('TaskCreateRequested', () {
    blocTest<TaskBloc, TaskState>(
      'emits [loading, loaded with new task] when task is created successfully',
      build: () {
        when(() => mockCreateTask(any())).thenAnswer((_) async => Right(tTask));
        return bloc;
      },
      act: (bloc) => bloc.add(TaskCreateRequested(task: tTask)),
      expect: () => [
        const TaskState(status: TaskBlocStatus.loading),
        TaskState(status: TaskBlocStatus.loaded, tasks: [tTask]),
      ],
      verify: (_) {
        verify(() => mockCreateTask(any())).called(1);
      },
    );

    blocTest<TaskBloc, TaskState>(
      'emits [loading, error] when task creation fails',
      build: () {
        when(() => mockCreateTask(any())).thenAnswer(
          (_) async => const Left(ServerFailure(message: 'Failed to create')),
        );
        return bloc;
      },
      act: (bloc) => bloc.add(TaskCreateRequested(task: tTask)),
      expect: () => [
        const TaskState(status: TaskBlocStatus.loading),
        const TaskState(
          status: TaskBlocStatus.error,
          errorMessage: 'Failed to create',
        ),
      ],
    );
  });

  group('TaskUpdateRequested', () {
    final tUpdatedTask = Task(
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

    blocTest<TaskBloc, TaskState>(
      'emits [loaded with updated task] when task is updated successfully',
      build: () {
        when(
          () => mockUpdateTask(any()),
        ).thenAnswer((_) async => Right(tUpdatedTask));
        return bloc;
      },
      seed: () => TaskState(status: TaskBlocStatus.loaded, tasks: [tTask]),
      act: (bloc) => bloc.add(TaskUpdateRequested(task: tUpdatedTask)),
      expect: () => [
        TaskState(status: TaskBlocStatus.loaded, tasks: [tUpdatedTask]),
      ],
      verify: (_) {
        verify(() => mockUpdateTask(any())).called(1);
      },
    );

    blocTest<TaskBloc, TaskState>(
      'emits [error] when task update fails',
      build: () {
        when(() => mockUpdateTask(any())).thenAnswer(
          (_) async => const Left(ServerFailure(message: 'Failed to update')),
        );
        return bloc;
      },
      seed: () => TaskState(status: TaskBlocStatus.loaded, tasks: [tTask]),
      act: (bloc) => bloc.add(TaskUpdateRequested(task: tUpdatedTask)),
      expect: () => [
        TaskState(
          status: TaskBlocStatus.error,
          tasks: [tTask],
          errorMessage: 'Failed to update',
        ),
      ],
    );
  });

  group('TaskFilterChanged', () {
    blocTest<TaskBloc, TaskState>(
      'emits state with status filter when filter is changed',
      build: () => bloc,
      seed: () => TaskState(status: TaskBlocStatus.loaded, tasks: tTasks),
      act: (bloc) =>
          bloc.add(const TaskFilterChanged(statusFilter: TaskStatus.pending)),
      expect: () => [
        TaskState(
          status: TaskBlocStatus.loaded,
          tasks: tTasks,
          statusFilter: TaskStatus.pending,
        ),
      ],
    );

    blocTest<TaskBloc, TaskState>(
      'emits state with category filter when filter is changed',
      build: () => bloc,
      seed: () => TaskState(status: TaskBlocStatus.loaded, tasks: tTasks),
      act: (bloc) => bloc.add(
        const TaskFilterChanged(categoryFilter: TaskCategory.cleaning),
      ),
      expect: () => [
        TaskState(
          status: TaskBlocStatus.loaded,
          tasks: tTasks,
          categoryFilter: TaskCategory.cleaning,
        ),
      ],
    );
  });
}
