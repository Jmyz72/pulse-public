import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../entities/timetable_entry.dart';

class TimetableQueryRange extends Equatable {
  final DateTime rangeStart;
  final DateTime rangeEnd;

  const TimetableQueryRange({required this.rangeStart, required this.rangeEnd});

  @override
  List<Object> get props => [rangeStart, rangeEnd];
}

abstract class TimetableRepository {
  Future<Either<Failure, List<TimetableEntry>>> getMyTimetable(
    String userId,
    TimetableQueryRange range,
  );
  Future<Either<Failure, TimetableEntry>> addEntry(TimetableEntry entry);
  Future<Either<Failure, TimetableEntry>> updateEntry(TimetableEntry entry);
  Future<Either<Failure, void>> deleteEntry(String entryId);

  Future<Either<Failure, List<TimetableEntry>>> getSharedTimetable(
    String targetUserId,
    String viewerId,
    TimetableQueryRange range,
  );
  Future<Either<Failure, void>> updateVisibility(
    String entryId,
    String visibility,
    List<String> visibleTo,
  );
}
