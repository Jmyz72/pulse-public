import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/timetable_entry.dart';
import '../repositories/timetable_repository.dart';

class AddTimetableEntry
    implements UseCase<TimetableEntry, AddTimetableEntryParams> {
  final TimetableRepository repository;

  AddTimetableEntry(this.repository);

  @override
  Future<Either<Failure, TimetableEntry>> call(AddTimetableEntryParams params) {
    return repository.addEntry(params.entry);
  }
}

class AddTimetableEntryParams extends Equatable {
  final TimetableEntry entry;

  const AddTimetableEntryParams({required this.entry});

  @override
  List<Object> get props => [entry];
}
