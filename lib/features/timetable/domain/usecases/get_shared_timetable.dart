import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/timetable_entry.dart';
import '../repositories/timetable_repository.dart';

class GetSharedTimetable
    implements UseCase<List<TimetableEntry>, GetSharedTimetableParams> {
  final TimetableRepository repository;

  GetSharedTimetable(this.repository);

  @override
  Future<Either<Failure, List<TimetableEntry>>> call(
    GetSharedTimetableParams params,
  ) {
    return repository.getSharedTimetable(
      params.targetUserId,
      params.viewerId,
      TimetableQueryRange(
        rangeStart: params.rangeStart,
        rangeEnd: params.rangeEnd,
      ),
    );
  }
}

class GetSharedTimetableParams extends Equatable {
  final String targetUserId;
  final String viewerId;
  final DateTime rangeStart;
  final DateTime rangeEnd;

  const GetSharedTimetableParams({
    required this.targetUserId,
    required this.viewerId,
    required this.rangeStart,
    required this.rangeEnd,
  });

  @override
  List<Object> get props => [targetUserId, viewerId, rangeStart, rangeEnd];
}
