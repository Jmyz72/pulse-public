import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/expense.dart';
import '../repositories/expense_repository.dart';

class GetExpenseById implements UseCase<Expense, GetExpenseByIdParams> {
  final ExpenseRepository repository;

  GetExpenseById(this.repository);

  @override
  Future<Either<Failure, Expense>> call(GetExpenseByIdParams params) {
    return repository.getExpenseById(params.id);
  }
}

class GetExpenseByIdParams extends Equatable {
  final String id;

  const GetExpenseByIdParams({required this.id});

  @override
  List<Object> get props => [id];
}
