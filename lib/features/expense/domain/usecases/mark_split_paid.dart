import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/expense.dart';
import '../entities/expense_split.dart';
import '../repositories/expense_repository.dart';
import '../services/expense_payment_announcement_service.dart';

class MarkSplitPaid implements UseCase<Expense, MarkSplitPaidParams> {
  final ExpenseRepository repository;
  final ExpensePaymentAnnouncementService announcementService;

  MarkSplitPaid({required this.repository, required this.announcementService});

  @override
  Future<Either<Failure, Expense>> call(MarkSplitPaidParams params) async {
    final existingExpenseResult = await repository.getExpenseById(
      params.expenseId,
    );
    Expense? existingExpense;
    existingExpenseResult.fold((_) {}, (expense) => existingExpense = expense);

    ExpenseSplit? previousSplit;
    final previousSplitIndex =
        existingExpense?.splits.indexWhere(
          (split) => split.userId == params.userId,
        ) ??
        -1;
    if (previousSplitIndex >= 0) {
      previousSplit = existingExpense!.splits[previousSplitIndex];
    }

    final result = await repository.markSplitAsPaid(
      expenseId: params.expenseId,
      userId: params.userId,
      isPaid: params.isPaid,
    );

    await result.fold((_) async {}, (updatedExpense) async {
      ExpenseSplit? updatedSplit;
      final updatedSplitIndex = updatedExpense.splits.indexWhere(
        (split) => split.userId == params.userId,
      );
      if (updatedSplitIndex >= 0) {
        updatedSplit = updatedExpense.splits[updatedSplitIndex];
      }
      if (params.isPaid &&
          previousSplit != null &&
          !previousSplit.isPaid &&
          updatedSplit != null &&
          updatedSplit.isPaid) {
        await announcementService.announceSplitPaid(
          expense: updatedExpense,
          split: updatedSplit,
        );
      }
    });

    return result;
  }
}

class MarkSplitPaidParams extends Equatable {
  final String expenseId;
  final String userId;
  final bool isPaid;

  const MarkSplitPaidParams({
    required this.expenseId,
    required this.userId,
    required this.isPaid,
  });

  @override
  List<Object> get props => [expenseId, userId, isPaid];
}
