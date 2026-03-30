import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/expense.dart';
import '../entities/expense_split.dart';
import '../entities/payment_proof_evaluation.dart';
import '../repositories/expense_repository.dart';
import '../services/expense_payment_announcement_service.dart';
import '../services/payment_proof_matcher.dart';

class SubmitPaymentProof implements UseCase<Expense, SubmitPaymentProofParams> {
  final ExpenseRepository repository;
  final PaymentProofMatcher matcher;
  final ExpensePaymentAnnouncementService announcementService;

  SubmitPaymentProof({
    required this.repository,
    required this.matcher,
    required this.announcementService,
  });

  @override
  Future<Either<Failure, Expense>> call(SubmitPaymentProofParams params) async {
    if (params.expenseId.isEmpty || params.userId.isEmpty) {
      return const Left(
        InvalidInputFailure(message: 'Missing expense or user'),
      );
    }
    if (params.imagePath.isEmpty) {
      return const Left(
        InvalidInputFailure(message: 'Please select a payment proof image'),
      );
    }

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

    final split = expense!.splits[splitIndex];
    if (split.isPaid) {
      return const Left(
        InvalidInputFailure(message: 'This split is already marked as paid'),
      );
    }

    final analysisResult = await repository.analyzePaymentProof(
      params.imagePath,
    );
    final evaluation = analysisResult.fold(
      (_) => _manualReviewEvaluation(),
      (analysis) => matcher.evaluate(
        expectedAmount: split.amount,
        ownerPaymentIdentity: expense!.ownerPaymentIdentity,
        analysis: analysis,
      ),
    );

    final uploadResult = await repository.uploadPaymentProof(
      expenseId: params.expenseId,
      userId: params.userId,
      imagePath: params.imagePath,
    );

    failure = null;
    String? proofUrl;
    uploadResult.fold((left) => failure = left, (right) => proofUrl = right);
    if (failure != null) return Left(failure!);

    final result = await repository.submitPaymentProof(
      expenseId: params.expenseId,
      userId: params.userId,
      proofImageUrl: proofUrl!,
      evaluation: evaluation,
    );

    await result.fold((_) async {}, (updatedExpense) async {
      ExpenseSplit? updatedSplit;
      final updatedSplitIndex = updatedExpense.splits.indexWhere(
        (candidate) => candidate.userId == params.userId,
      );
      if (updatedSplitIndex >= 0) {
        updatedSplit = updatedExpense.splits[updatedSplitIndex];
      }
      if (evaluation.canAutoSettle &&
          !split.isPaid &&
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

  PaymentProofEvaluation _manualReviewEvaluation() {
    return const PaymentProofEvaluation(
      extractedAmount: null,
      extractedRecipient: null,
      confidence: 0,
      isAmountMatch: false,
      isRecipientMatch: false,
      canAutoSettle: false,
    );
  }
}

class SubmitPaymentProofParams extends Equatable {
  final String expenseId;
  final String userId;
  final String imagePath;

  const SubmitPaymentProofParams({
    required this.expenseId,
    required this.userId,
    required this.imagePath,
  });

  @override
  List<Object> get props => [expenseId, userId, imagePath];
}
