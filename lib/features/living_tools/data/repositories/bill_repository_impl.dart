import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/bill.dart';
import '../../domain/entities/bill_summary.dart';
import '../../domain/repositories/bill_repository.dart';
import '../datasources/bill_remote_datasource.dart';
import '../models/bill_model.dart';

class BillRepositoryImpl implements BillRepository {
  final BillRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  BillRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<Bill>>> getBills(List<String> chatRoomIds) async {
    try {
      final bills = await remoteDataSource.getBills(chatRoomIds);
      return Right(bills);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Stream<List<Bill>> watchBills(List<String> chatRoomIds) {
    return remoteDataSource.watchBills(chatRoomIds);
  }

  @override
  Future<Either<Failure, Bill>> getBillById(String id) async {
    try {
      final bill = await remoteDataSource.getBillById(id);
      return Right(bill);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, Bill>> createBill(Bill bill) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final model = BillModel.fromEntity(bill);
      final result = await remoteDataSource.createBill(model);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, Bill>> updateBill(Bill bill) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final model = BillModel.fromEntity(bill);
      final result = await remoteDataSource.updateBill(model);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> deleteBill(String id) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      await remoteDataSource.deleteBill(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> markBillAsPaid(String billId, String memberId) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      await remoteDataSource.markBillAsPaid(billId, memberId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> nudgeMember(String billId, String memberId) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      await remoteDataSource.nudgeMember(billId, memberId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, BillSummary>> getBillsSummary(String userId, List<String> chatRoomIds) async {
    try {
      final summary = await remoteDataSource.getBillsSummary(userId, chatRoomIds);
      return Right(summary);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, List<Bill>>> getBillsByChatRoom(String chatRoomId) async {
    try {
      final bills = await remoteDataSource.getBillsByChatRoom(chatRoomId);
      return Right(bills);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }
}
