import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/expense_repository.dart';

class SyncOwnerPaymentIdentityToPendingExpenses
    implements UseCase<void, SyncOwnerPaymentIdentityToPendingExpensesParams> {
  final ExpenseRepository repository;

  SyncOwnerPaymentIdentityToPendingExpenses(this.repository);

  @override
  Future<Either<Failure, void>> call(
    SyncOwnerPaymentIdentityToPendingExpensesParams params,
  ) {
    return repository.syncOwnerPaymentIdentityToPendingExpenses(
      ownerId: params.ownerId,
      paymentIdentity: params.paymentIdentity,
    );
  }
}

class SyncOwnerPaymentIdentityToPendingExpensesParams extends Equatable {
  final String ownerId;
  final String paymentIdentity;

  const SyncOwnerPaymentIdentityToPendingExpensesParams({
    required this.ownerId,
    required this.paymentIdentity,
  });

  @override
  List<Object> get props => [ownerId, paymentIdentity];
}
