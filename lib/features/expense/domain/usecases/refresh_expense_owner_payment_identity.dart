import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/expense.dart';
import '../repositories/expense_repository.dart';

class RefreshExpenseOwnerPaymentIdentity
    implements UseCase<Expense, RefreshExpenseOwnerPaymentIdentityParams> {
  final ExpenseRepository repository;

  RefreshExpenseOwnerPaymentIdentity(this.repository);

  @override
  Future<Either<Failure, Expense>> call(
    RefreshExpenseOwnerPaymentIdentityParams params,
  ) {
    return repository.refreshExpenseOwnerPaymentIdentity(
      expenseId: params.expenseId,
      ownerId: params.ownerId,
      paymentIdentity: params.paymentIdentity,
    );
  }
}

class RefreshExpenseOwnerPaymentIdentityParams extends Equatable {
  final String expenseId;
  final String ownerId;
  final String paymentIdentity;

  const RefreshExpenseOwnerPaymentIdentityParams({
    required this.expenseId,
    required this.ownerId,
    required this.paymentIdentity,
  });

  @override
  List<Object> get props => [expenseId, ownerId, paymentIdentity];
}
