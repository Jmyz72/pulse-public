import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/expense.dart';
import '../repositories/expense_repository.dart';

class GetExpenses implements UseCase<List<Expense>, GetExpensesParams> {
  final ExpenseRepository repository;

  GetExpenses(this.repository);

  @override
  Future<Either<Failure, List<Expense>>> call(GetExpensesParams params) {
    return repository.getExpenses(params.chatRoomIds);
  }
}

class GetExpensesParams extends Equatable {
  final List<String> chatRoomIds;

  const GetExpensesParams({required this.chatRoomIds});

  @override
  List<Object> get props => [chatRoomIds];
}
