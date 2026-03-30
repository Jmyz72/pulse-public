import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/timetable_repository.dart';

class DeleteTimetableEntry
    implements UseCase<void, DeleteTimetableEntryParams> {
  final TimetableRepository repository;

  DeleteTimetableEntry(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteTimetableEntryParams params) {
    return repository.deleteEntry(params.entryId);
  }
}

class DeleteTimetableEntryParams extends Equatable {
  final String entryId;

  const DeleteTimetableEntryParams({required this.entryId});

  @override
  List<Object> get props => [entryId];
}
