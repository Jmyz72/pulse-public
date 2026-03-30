import 'package:dartz/dartz.dart' hide Task;
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/task.dart';
import '../repositories/task_repository.dart';

class UpdateTask implements UseCase<Task, UpdateTaskParams> {
  final TaskRepository repository;

  UpdateTask(this.repository);

  @override
  Future<Either<Failure, Task>> call(UpdateTaskParams params) {
    return repository.updateTask(params.task);
  }
}

class UpdateTaskParams extends Equatable {
  final Task task;

  const UpdateTaskParams({required this.task});

  @override
  List<Object> get props => [task];
}
