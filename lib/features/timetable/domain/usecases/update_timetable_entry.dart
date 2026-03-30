import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/timetable_entry.dart';
import '../repositories/timetable_repository.dart';

class UpdateTimetableEntry
    implements UseCase<TimetableEntry, UpdateTimetableEntryParams> {
  final TimetableRepository repository;

  UpdateTimetableEntry(this.repository);

  @override
  Future<Either<Failure, TimetableEntry>> call(
    UpdateTimetableEntryParams params,
  ) {
    return repository.updateEntry(params.entry);
  }
}

class UpdateTimetableEntryParams extends Equatable {
  final TimetableEntry entry;

  const UpdateTimetableEntryParams({required this.entry});

  @override
  List<Object> get props => [entry];
}
