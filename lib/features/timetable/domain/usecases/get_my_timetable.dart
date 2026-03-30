import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/timetable_entry.dart';
import '../repositories/timetable_repository.dart';

class GetMyTimetable
    implements UseCase<List<TimetableEntry>, GetMyTimetableParams> {
  final TimetableRepository repository;

  GetMyTimetable(this.repository);

  @override
  Future<Either<Failure, List<TimetableEntry>>> call(
    GetMyTimetableParams params,
  ) {
    return repository.getMyTimetable(
      params.userId,
      TimetableQueryRange(
        rangeStart: params.rangeStart,
        rangeEnd: params.rangeEnd,
      ),
    );
  }
}

class GetMyTimetableParams extends Equatable {
  final String userId;
  final DateTime rangeStart;
  final DateTime rangeEnd;

  const GetMyTimetableParams({
    required this.userId,
    required this.rangeStart,
    required this.rangeEnd,
  });

  @override
  List<Object> get props => [userId, rangeStart, rangeEnd];
}
