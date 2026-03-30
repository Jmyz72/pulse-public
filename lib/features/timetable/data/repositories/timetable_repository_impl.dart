import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/timetable_entry.dart';
import '../../domain/repositories/timetable_repository.dart';
import '../datasources/timetable_remote_datasource.dart';
import '../models/timetable_entry_model.dart';

class TimetableRepositoryImpl implements TimetableRepository {
  final TimetableRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  TimetableRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<TimetableEntry>>> getMyTimetable(
    String userId,
    TimetableQueryRange range,
  ) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final entries = await remoteDataSource.getEntriesByUser(
        userId,
        range.rangeStart,
        range.rangeEnd,
      );
      return Right(entries);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, TimetableEntry>> addEntry(TimetableEntry entry) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final model = TimetableEntryModel.fromEntity(entry);
      final created = await remoteDataSource.addEntry(model);
      return Right(created);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, TimetableEntry>> updateEntry(
    TimetableEntry entry,
  ) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final model = TimetableEntryModel.fromEntity(entry);
      final updated = await remoteDataSource.updateEntry(model);
      return Right(updated);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> deleteEntry(String entryId) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      await remoteDataSource.deleteEntry(entryId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, List<TimetableEntry>>> getSharedTimetable(
    String targetUserId,
    String viewerId,
    TimetableQueryRange range,
  ) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final entries = await remoteDataSource.getSharedEntries(
        targetUserId,
        viewerId,
        range.rangeStart,
        range.rangeEnd,
      );
      return Right(entries);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> updateVisibility(
    String entryId,
    String visibility,
    List<String> visibleTo,
  ) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      await remoteDataSource.updateVisibility(entryId, visibility, visibleTo);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }
}
