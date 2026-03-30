import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/expense.dart';
import '../entities/expense_submission.dart';
import '../repositories/expense_repository.dart';
import '../services/expense_submission_service.dart';

class UpdateExpense implements UseCase<Expense, UpdateExpenseParams> {
  final ExpenseRepository repository;
  final ExpenseSubmissionService submissionService;

  UpdateExpense({required this.repository, required this.submissionService});

  @override
  Future<Either<Failure, Expense>> call(UpdateExpenseParams params) async {
    final builtExpense = submissionService.updateExpense(
      existingExpense: params.existingExpense,
      submission: params.submission,
    );
    Failure? validationFailure;
    Expense? expense;
    builtExpense.fold(
      (failure) => validationFailure = failure,
      (value) => expense = value,
    );
    if (validationFailure != null) {
      return Left(validationFailure!);
    }

    return repository.updateExpense(expense!);
  }
}

class UpdateExpenseParams extends Equatable {
  final Expense existingExpense;
  final ExpenseSubmission submission;

  const UpdateExpenseParams({
    required this.existingExpense,
    required this.submission,
  });

  @override
  List<Object> get props => [existingExpense, submission];
}
