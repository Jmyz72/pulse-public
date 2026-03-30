import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/expense.dart';
import '../repositories/expense_repository.dart';

class CreateAdHocExpense implements UseCase<Expense, CreateAdHocExpenseParams> {
  final ExpenseRepository repository;

  CreateAdHocExpense(this.repository);

  @override
  Future<Either<Failure, Expense>> call(CreateAdHocExpenseParams params) {
    return repository.createAdHocExpense(
      masterExpense: params.masterExpense,
      participantIds: params.participantIds,
      chatRoomIdsByParticipant: params.chatRoomIdsByParticipant,
    );
  }
}

class CreateAdHocExpenseParams extends Equatable {
  final Expense masterExpense;
  final List<String> participantIds;
  final Map<String, String> chatRoomIdsByParticipant;

  const CreateAdHocExpenseParams({
    required this.masterExpense,
    required this.participantIds,
    required this.chatRoomIdsByParticipant,
  });

  @override
  List<Object> get props => [masterExpense, participantIds, chatRoomIdsByParticipant];
}
