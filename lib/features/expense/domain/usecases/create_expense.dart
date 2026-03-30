import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../chat/domain/entities/message.dart';
import '../../../chat/domain/usecases/send_message.dart';
import '../entities/expense.dart';
import '../entities/expense_submission.dart';
import '../repositories/expense_repository.dart';
import '../services/expense_submission_service.dart';

class CreateExpense implements UseCase<Expense, CreateExpenseParams> {
  final ExpenseRepository repository;
  final ExpenseSubmissionService submissionService;
  final SendMessage sendMessage;

  CreateExpense({
    required this.repository,
    required this.submissionService,
    required this.sendMessage,
  });

  @override
  Future<Either<Failure, Expense>> call(CreateExpenseParams params) async {
    final builtExpense = submissionService.createExpense(params.submission);
    Failure? validationFailure;
    Expense? expense;
    builtExpense.fold(
      (failure) => validationFailure = failure,
      (value) => expense = value,
    );
    if (validationFailure != null) {
      return Left(validationFailure!);
    }

    final result = await repository.createExpense(expense!);
    await result.fold(
      (_) async {},
      (createdExpense) => _sendExpenseMessageIfNeeded(
        createdExpense: createdExpense,
        submission: params.submission,
      ),
    );
    return result;
  }

  Future<void> _sendExpenseMessageIfNeeded({
    required Expense createdExpense,
    required ExpenseSubmission submission,
  }) async {
    final chatRoomId = createdExpense.chatRoomId;
    if (chatRoomId == null || chatRoomId.isEmpty) {
      return;
    }

    final participantNames = submission.participants
        .map((participant) => participant.name)
        .toList(growable: false);

    final message = Message(
      id: const Uuid().v4(),
      senderId: submission.currentUserId,
      senderName: submission.currentUserName,
      content: 'Shared a split: ${createdExpense.title}',
      chatRoomId: chatRoomId,
      timestamp: DateTime.now(),
      type: MessageType.expense,
      sendStatus: MessageSendStatus.sending,
      eventData: {
        'title': createdExpense.title,
        'amount': createdExpense.totalAmount,
        'memberNames': participantNames,
        'memberCount': participantNames.length,
        'requiresItemSelection': submission.isCustomSplit,
        if (!submission.isCustomSplit)
          'perPerson': createdExpense.totalAmount / participantNames.length,
      },
    );

    await sendMessage(SendMessageParams(message: message));
  }
}

class CreateExpenseParams extends Equatable {
  final ExpenseSubmission submission;

  const CreateExpenseParams({required this.submission});

  @override
  List<Object> get props => [submission];
}
