import 'package:dartz/dartz.dart' hide Task;
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/task.dart';
import '../repositories/task_repository.dart';

class GetTasks implements UseCase<List<Task>, GetTasksParams> {
  final TaskRepository repository;

  GetTasks(this.repository);

  @override
  Future<Either<Failure, List<Task>>> call(GetTasksParams params) {
    return repository.getTasks(params.chatRoomIds);
  }
}

class GetTasksParams extends Equatable {
  final List<String> chatRoomIds;

  const GetTasksParams({required this.chatRoomIds});

  @override
  List<Object> get props => [chatRoomIds];
}
