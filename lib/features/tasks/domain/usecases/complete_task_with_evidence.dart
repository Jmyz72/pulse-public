import 'package:dartz/dartz.dart' hide Task;
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/task.dart';
import '../repositories/task_repository.dart';

class CompleteTaskWithEvidence implements UseCase<Task, CompleteTaskWithEvidenceParams> {
  final TaskRepository repository;

  CompleteTaskWithEvidence(this.repository);

  @override
  Future<Either<Failure, Task>> call(CompleteTaskWithEvidenceParams params) {
    return repository.completeTaskWithEvidence(params.taskId, params.imageFile);
  }
}

class CompleteTaskWithEvidenceParams extends Equatable {
  final String taskId;
  final dynamic imageFile;

  const CompleteTaskWithEvidenceParams({
    required this.taskId,
    required this.imageFile,
  });

  @override
  List<Object> get props => [taskId, imageFile];
}
