import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/expense.dart';
import '../entities/expense_item.dart';
import '../entities/expense_split.dart';
import '../repositories/expense_repository.dart';

class SelectItems implements UseCase<Expense, SelectItemsParams> {
  final ExpenseRepository repository;

  SelectItems(this.repository);

  @override
  Future<Either<Failure, Expense>> call(SelectItemsParams params) async {
    final expenseResult = await repository.getExpenseById(params.expenseId);
    Expense? expense;
    Failure? failure;
    expenseResult.fold((left) => failure = left, (right) => expense = right);
    if (failure != null) return Left(failure!);

    if (expense!.status == ExpenseStatus.settled) {
      return const Left(
        InvalidInputFailure(message: 'This expense is already settled'),
      );
    }

    final splitIndex = expense!.splits.indexWhere(
      (split) => split.userId == params.userId,
    );
    if (splitIndex == -1) {
      return const Left(
        InvalidInputFailure(message: 'Split not found for this user'),
      );
    }

    final currentUserSplit = expense!.splits[splitIndex];
    if (currentUserSplit.locksItemSelection) {
      return Left(
        InvalidInputFailure(message: _currentUserLockMessage(currentUserSplit)),
      );
    }

    final changedItems = _getChangedItems(
      expense: expense!,
      userId: params.userId,
      itemIds: params.itemIds,
    );
    final touchesLockedItem = changedItems.any(
      (item) => _isItemLocked(expense!, item),
    );
    if (touchesLockedItem) {
      return const Left(InvalidInputFailure(message: _itemLockMessage));
    }

    return repository.selectItems(
      expenseId: params.expenseId,
      userId: params.userId,
      itemIds: params.itemIds,
    );
  }

  List<ExpenseItem> _getChangedItems({
    required Expense expense,
    required String userId,
    required List<String> itemIds,
  }) {
    return expense.items
        .where((item) {
          final isAssigned = item.assignedUserIds.contains(userId);
          final shouldBeAssigned = itemIds.contains(item.id);
          return isAssigned != shouldBeAssigned;
        })
        .toList(growable: false);
  }

  bool _isItemLocked(Expense expense, ExpenseItem item) {
    for (final assignedUserId in item.assignedUserIds) {
      final splitIndex = expense.splits.indexWhere(
        (split) => split.userId == assignedUserId,
      );
      if (splitIndex != -1 && expense.splits[splitIndex].locksItemSelection) {
        return true;
      }
    }
    return false;
  }

  String _currentUserLockMessage(ExpenseSplit split) {
    if (split.needsReview) {
      return 'Your payment proof is waiting for owner review; item selection is locked';
    }
    return 'Your payment is already recorded; item selection is locked';
  }

  static const String _itemLockMessage =
      'This item is locked because payment is under review or already recorded';
}

class SelectItemsParams extends Equatable {
  final String expenseId;
  final String userId;
  final List<String> itemIds;

  const SelectItemsParams({
    required this.expenseId,
    required this.userId,
    required this.itemIds,
  });

  @override
  List<Object> get props => [expenseId, userId, itemIds];
}
