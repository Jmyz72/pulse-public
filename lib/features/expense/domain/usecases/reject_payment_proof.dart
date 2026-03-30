import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/expense.dart';
import '../repositories/expense_repository.dart';

class RejectPaymentProof implements UseCase<Expense, RejectPaymentProofParams> {
  final ExpenseRepository repository;

  RejectPaymentProof(this.repository);

  @override
  Future<Either<Failure, Expense>> call(RejectPaymentProofParams params) async {
    if (params.reason.trim().isEmpty) {
      return const Left(
        InvalidInputFailure(message: 'Please provide a rejection reason'),
      );
    }

    final expenseResult = await repository.getExpenseById(params.expenseId);
    Expense? expense;
    Failure? failure;
    expenseResult.fold((left) => failure = left, (right) => expense = right);
    if (failure != null) return Left(failure!);

    if (expense!.ownerId != params.reviewerId) {
      return const Left(
        InvalidInputFailure(message: 'Only the expense owner can reject proof'),
      );
    }

    final split = expense!.splits.where((item) => item.userId == params.userId);
    if (split.isEmpty || !split.first.needsReview) {
      return const Left(
        InvalidInputFailure(message: 'No pending proof to reject'),
      );
    }

    return repository.rejectPaymentProof(
      expenseId: params.expenseId,
      userId: params.userId,
      reviewerId: params.reviewerId,
      reason: params.reason.trim(),
    );
  }
}

class RejectPaymentProofParams extends Equatable {
  final String expenseId;
  final String userId;
  final String reviewerId;
  final String reason;

  const RejectPaymentProofParams({
    required this.expenseId,
    required this.userId,
    required this.reviewerId,
    required this.reason,
  });

  @override
  List<Object> get props => [expenseId, userId, reviewerId, reason];
}
