import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/expense_item.dart';
import '../../domain/entities/payment_proof_analysis.dart';
import '../../domain/entities/payment_proof_evaluation.dart';
import '../../domain/repositories/expense_repository.dart';
import '../datasources/expense_remote_datasource.dart';
import '../models/expense_model.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  final ExpenseRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  ExpenseRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<Expense>>> getExpenses(
    List<String> chatRoomIds,
  ) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final expenses = await remoteDataSource.getExpenses(chatRoomIds);
      return Right(expenses);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, Expense>> getExpenseById(String id) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final expense = await remoteDataSource.getExpenseById(id);
      return Right(expense);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, Expense>> createExpense(Expense expense) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final model = ExpenseModel.fromEntity(expense);
      final created = await remoteDataSource.createExpense(model);
      return Right(created);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, Expense>> updateExpense(Expense expense) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final model = ExpenseModel.fromEntity(expense);
      final updated = await remoteDataSource.updateExpense(model);
      return Right(updated);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> deleteExpense(String id) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      await remoteDataSource.deleteExpense(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, List<Expense>>> getExpensesByChatRoom(
    String chatRoomId,
  ) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final expenses = await remoteDataSource.getExpensesByChatRoom(chatRoomId);
      return Right(expenses);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, Expense>> createAdHocExpense({
    required Expense masterExpense,
    required List<String> participantIds,
    required Map<String, String> chatRoomIdsByParticipant,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final model = ExpenseModel.fromEntity(masterExpense);
      final created = await remoteDataSource.createAdHocExpense(
        masterExpense: model,
        participantIds: participantIds,
        chatRoomIdsByParticipant: chatRoomIdsByParticipant,
      );
      return Right(created);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, Expense>> updateExpenseItems({
    required String expenseId,
    required List<ExpenseItem> items,
    double? taxPercent,
    double? serviceChargePercent,
    double? discountPercent,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final updated = await remoteDataSource.updateExpenseItems(
        expenseId: expenseId,
        items: items,
        taxPercent: taxPercent,
        serviceChargePercent: serviceChargePercent,
        discountPercent: discountPercent,
      );
      return Right(updated);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, Expense>> selectItems({
    required String expenseId,
    required String userId,
    required List<String> itemIds,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final updated = await remoteDataSource.selectItems(
        expenseId: expenseId,
        userId: userId,
        itemIds: itemIds,
      );
      return Right(updated);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, Expense>> markSplitAsPaid({
    required String expenseId,
    required String userId,
    required bool isPaid,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final updated = await remoteDataSource.markSplitAsPaid(
        expenseId: expenseId,
        userId: userId,
        isPaid: isPaid,
      );
      return Right(updated);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, PaymentProofAnalysis>> analyzePaymentProof(
    String imagePath,
  ) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final analysis = await remoteDataSource.analyzePaymentProof(imagePath);
      return Right(analysis);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, String>> uploadPaymentProof({
    required String expenseId,
    required String userId,
    required String imagePath,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final proofUrl = await remoteDataSource.uploadPaymentProof(
        expenseId: expenseId,
        userId: userId,
        imagePath: imagePath,
      );
      return Right(proofUrl);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, Expense>> submitPaymentProof({
    required String expenseId,
    required String userId,
    required String proofImageUrl,
    required PaymentProofEvaluation evaluation,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final updated = await remoteDataSource.submitPaymentProof(
        expenseId: expenseId,
        userId: userId,
        proofImageUrl: proofImageUrl,
        evaluation: evaluation,
      );
      return Right(updated);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, Expense>> approvePaymentProof({
    required String expenseId,
    required String userId,
    required String reviewerId,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final updated = await remoteDataSource.approvePaymentProof(
        expenseId: expenseId,
        userId: userId,
        reviewerId: reviewerId,
      );
      return Right(updated);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, Expense>> rejectPaymentProof({
    required String expenseId,
    required String userId,
    required String reviewerId,
    required String reason,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final updated = await remoteDataSource.rejectPaymentProof(
        expenseId: expenseId,
        userId: userId,
        reviewerId: reviewerId,
        reason: reason,
      );
      return Right(updated);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> syncOwnerPaymentIdentityToPendingExpenses({
    required String ownerId,
    required String paymentIdentity,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      await remoteDataSource.syncOwnerPaymentIdentityToPendingExpenses(
        ownerId: ownerId,
        paymentIdentity: paymentIdentity,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, Expense>> refreshExpenseOwnerPaymentIdentity({
    required String expenseId,
    required String ownerId,
    required String paymentIdentity,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final updated = await remoteDataSource.refreshExpenseOwnerPaymentIdentity(
        expenseId: expenseId,
        ownerId: ownerId,
        paymentIdentity: paymentIdentity,
      );
      return Right(updated);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> syncLinkedExpenses(
    String masterExpenseId,
  ) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      await remoteDataSource.syncLinkedExpenses(masterExpenseId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, List<Expense>>> getExpensesForUser(
    String userId,
  ) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final expenses = await remoteDataSource.getExpensesForUser(userId);
      return Right(expenses);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }
}
