import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/expense.dart';
import '../entities/expense_split.dart';
import '../repositories/expense_repository.dart';
import '../services/expense_payment_announcement_service.dart';

class ApprovePaymentProof
    implements UseCase<Expense, ApprovePaymentProofParams> {
  final ExpenseRepository repository;
  final ExpensePaymentAnnouncementService announcementService;

  ApprovePaymentProof({
    required this.repository,
    required this.announcementService,
  });

  @override
  Future<Either<Failure, Expense>> call(
    ApprovePaymentProofParams params,
  ) async {
    final expenseResult = await repository.getExpenseById(params.expenseId);
    Expense? expense;
    Failure? failure;
    expenseResult.fold((left) => failure = left, (right) => expense = right);
    if (failure != null) return Left(failure!);

    if (expense!.ownerId != params.reviewerId) {
      return const Left(
        InvalidInputFailure(
          message: 'Only the expense owner can approve proof',
        ),
      );
    }

    final splitIndex = expense!.splits.indexWhere(
      (item) => item.userId == params.userId,
    );
    if (splitIndex == -1 || !expense!.splits[splitIndex].needsReview) {
      return const Left(
        InvalidInputFailure(message: 'No pending proof to approve'),
      );
    }
    final split = expense!.splits[splitIndex];

    final result = await repository.approvePaymentProof(
      expenseId: params.expenseId,
      userId: params.userId,
      reviewerId: params.reviewerId,
    );

    await result.fold((_) async {}, (updatedExpense) async {
      ExpenseSplit? updatedSplit;
      final updatedSplitIndex = updatedExpense.splits.indexWhere(
        (candidate) => candidate.userId == params.userId,
      );
      if (updatedSplitIndex >= 0) {
        updatedSplit = updatedExpense.splits[updatedSplitIndex];
      }
      if (updatedSplit != null && !split.isPaid && updatedSplit.isPaid) {
        await announcementService.announceSplitPaid(
          expense: updatedExpense,
          split: updatedSplit,
        );
      }
    });

    return result;
  }
}

class ApprovePaymentProofParams extends Equatable {
  final String expenseId;
  final String userId;
  final String reviewerId;

  const ApprovePaymentProofParams({
    required this.expenseId,
    required this.userId,
    required this.reviewerId,
  });

  @override
  List<Object> get props => [expenseId, userId, reviewerId];
}
