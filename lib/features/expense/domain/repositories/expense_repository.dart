import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/expense.dart';
import '../entities/expense_item.dart';
import '../entities/payment_proof_analysis.dart';
import '../entities/payment_proof_evaluation.dart';

abstract class ExpenseRepository {
  Future<Either<Failure, List<Expense>>> getExpenses(List<String> chatRoomIds);
  Future<Either<Failure, Expense>> getExpenseById(String id);
  Future<Either<Failure, Expense>> createExpense(Expense expense);
  Future<Either<Failure, Expense>> updateExpense(Expense expense);
  Future<Either<Failure, void>> deleteExpense(String id);
  Future<Either<Failure, List<Expense>>> getExpensesByChatRoom(
    String chatRoomId,
  );

  /// Create an ad-hoc expense with linked records in each 1:1 chat
  Future<Either<Failure, Expense>> createAdHocExpense({
    required Expense masterExpense,
    required List<String> participantIds,
    required Map<String, String> chatRoomIdsByParticipant,
  });

  /// Update expense items
  Future<Either<Failure, Expense>> updateExpenseItems({
    required String expenseId,
    required List<ExpenseItem> items,
    double? taxPercent,
    double? serviceChargePercent,
    double? discountPercent,
  });

  /// Member selects their items
  Future<Either<Failure, Expense>> selectItems({
    required String expenseId,
    required String userId,
    required List<String> itemIds,
  });

  /// Mark a split as paid
  Future<Either<Failure, Expense>> markSplitAsPaid({
    required String expenseId,
    required String userId,
    required bool isPaid,
  });

  Future<Either<Failure, PaymentProofAnalysis>> analyzePaymentProof(
    String imagePath,
  );

  Future<Either<Failure, String>> uploadPaymentProof({
    required String expenseId,
    required String userId,
    required String imagePath,
  });

  Future<Either<Failure, Expense>> submitPaymentProof({
    required String expenseId,
    required String userId,
    required String proofImageUrl,
    required PaymentProofEvaluation evaluation,
  });

  Future<Either<Failure, Expense>> approvePaymentProof({
    required String expenseId,
    required String userId,
    required String reviewerId,
  });

  Future<Either<Failure, Expense>> rejectPaymentProof({
    required String expenseId,
    required String userId,
    required String reviewerId,
    required String reason,
  });

  Future<Either<Failure, void>> syncOwnerPaymentIdentityToPendingExpenses({
    required String ownerId,
    required String paymentIdentity,
  });

  Future<Either<Failure, Expense>> refreshExpenseOwnerPaymentIdentity({
    required String expenseId,
    required String ownerId,
    required String paymentIdentity,
  });

  /// Sync changes to all linked expenses (for ad-hoc)
  Future<Either<Failure, void>> syncLinkedExpenses(String masterExpenseId);

  /// Get all expenses for a user (including ad-hoc where user is participant)
  Future<Either<Failure, List<Expense>>> getExpensesForUser(String userId);
}
