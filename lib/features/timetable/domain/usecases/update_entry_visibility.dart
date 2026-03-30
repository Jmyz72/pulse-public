import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/timetable_repository.dart';

class UpdateEntryVisibility
    implements UseCase<void, UpdateEntryVisibilityParams> {
  final TimetableRepository repository;

  UpdateEntryVisibility(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateEntryVisibilityParams params) {
    return repository.updateVisibility(
      params.entryId,
      params.visibility,
      params.visibleTo,
    );
  }
}

class UpdateEntryVisibilityParams extends Equatable {
  final String entryId;
  final String visibility;
  final List<String> visibleTo;

  const UpdateEntryVisibilityParams({
    required this.entryId,
    required this.visibility,
    this.visibleTo = const [],
  });

  @override
  List<Object> get props => [entryId, visibility, visibleTo];
}
