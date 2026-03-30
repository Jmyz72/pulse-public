import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/failures.dart';
import 'package:pulse/features/expense/domain/entities/expense.dart';
import 'package:pulse/features/expense/domain/entities/expense_split.dart';
import 'package:pulse/features/expense/domain/entities/payment_proof_analysis.dart';
import 'package:pulse/features/expense/domain/entities/payment_proof_evaluation.dart';
import 'package:pulse/features/expense/domain/repositories/expense_repository.dart';
import 'package:pulse/features/expense/domain/services/expense_payment_announcement_service.dart';
import 'package:pulse/features/expense/domain/services/payment_proof_matcher.dart';
import 'package:pulse/features/expense/domain/usecases/submit_payment_proof.dart';

class MockExpenseRepository extends Mock implements ExpenseRepository {}

class MockExpensePaymentAnnouncementService extends Mock
    implements ExpensePaymentAnnouncementService {}

void main() {
  late MockExpenseRepository repository;
  late MockExpensePaymentAnnouncementService announcementService;
  late SubmitPaymentProof usecase;

  const expenseId = 'expense-1';
  const userId = 'user-2';
  const imagePath = '/tmp/proof.jpg';
  final expense = Expense(
    id: expenseId,
    ownerId: 'owner-1',
    ownerPaymentIdentity: 'Jimmy Test',
    title: 'Dinner',
    totalAmount: 53.68,
    date: DateTime(2026, 3, 13),
    splits: const [
      ExpenseSplit(
        userId: 'owner-1',
        userName: 'Owner',
        amount: 26.84,
        isPaid: true,
      ),
      ExpenseSplit(userId: userId, userName: 'Participant', amount: 26.84),
    ],
  );

  setUpAll(() {
    registerFallbackValue(expense);
    registerFallbackValue(
      const ExpenseSplit(userId: 'fallback', userName: 'Fallback', amount: 0),
    );
    registerFallbackValue(
      const PaymentProofEvaluation(
        extractedAmount: 26.84,
        extractedRecipient: 'Jimmy Test',
        confidence: 0.9,
        isAmountMatch: true,
        isRecipientMatch: true,
        canAutoSettle: true,
      ),
    );
  });

  setUp(() {
    repository = MockExpenseRepository();
    announcementService = MockExpensePaymentAnnouncementService();
    usecase = SubmitPaymentProof(
      repository: repository,
      matcher: PaymentProofMatcher(),
      announcementService: announcementService,
    );
  });

  test('submits proof with auto-settle evaluation when OCR matches', () async {
    when(
      () => repository.getExpenseById(expenseId),
    ).thenAnswer((_) async => Right(expense));
    when(() => repository.analyzePaymentProof(imagePath)).thenAnswer(
      (_) async => const Right(
        PaymentProofAnalysis(
          extractedAmount: 26.84,
          extractedRecipient: 'Jimmy Test',
          confidence: 0.9,
          rawText: 'Transfer to Jimmy Test RM 26.84',
        ),
      ),
    );
    when(
      () => repository.uploadPaymentProof(
        expenseId: expenseId,
        userId: userId,
        imagePath: imagePath,
      ),
    ).thenAnswer((_) async => const Right('https://example.com/proof.jpg'));
    when(
      () => repository.submitPaymentProof(
        expenseId: expenseId,
        userId: userId,
        proofImageUrl: 'https://example.com/proof.jpg',
        evaluation: any(named: 'evaluation'),
      ),
    ).thenAnswer((invocation) async {
      final evaluation =
          invocation.namedArguments[#evaluation] as PaymentProofEvaluation;
      expect(evaluation.canAutoSettle, true);
      return Right(
        expense.copyWith(
          splits: expense.splits
              .map(
                (split) => split.userId == userId
                    ? split.copyWith(paymentStatus: ExpensePaymentStatus.paid)
                    : split,
              )
              .toList(),
        ),
      );
    });
    final updatedExpense = expense.copyWith(
      splits: expense.splits
          .map(
            (split) => split.userId == userId
                ? split.copyWith(paymentStatus: ExpensePaymentStatus.paid)
                : split,
          )
          .toList(),
    );
    when(
      () => announcementService.announceSplitPaid(
        expense: updatedExpense,
        split: updatedExpense.splits[1],
      ),
    ).thenAnswer((_) async {});

    final result = await usecase(
      const SubmitPaymentProofParams(
        expenseId: expenseId,
        userId: userId,
        imagePath: imagePath,
      ),
    );

    expect(result.isRight(), true);
    verify(() => repository.getExpenseById(expenseId)).called(1);
    verify(() => repository.analyzePaymentProof(imagePath)).called(1);
    verify(
      () => repository.uploadPaymentProof(
        expenseId: expenseId,
        userId: userId,
        imagePath: imagePath,
      ),
    ).called(1);
    verify(
      () => announcementService.announceSplitPaid(
        expense: updatedExpense,
        split: updatedExpense.splits[1],
      ),
    ).called(1);
  });

  test('keeps proof pending review when recipient does not match', () async {
    when(
      () => repository.getExpenseById(expenseId),
    ).thenAnswer((_) async => Right(expense));
    when(() => repository.analyzePaymentProof(imagePath)).thenAnswer(
      (_) async => const Right(
        PaymentProofAnalysis(
          extractedAmount: 26.84,
          extractedRecipient: 'Wrong Recipient',
          confidence: 0.9,
          rawText: 'Transfer to Wrong Recipient RM 26.84',
        ),
      ),
    );
    when(
      () => repository.uploadPaymentProof(
        expenseId: expenseId,
        userId: userId,
        imagePath: imagePath,
      ),
    ).thenAnswer((_) async => const Right('https://example.com/proof.jpg'));
    when(
      () => repository.submitPaymentProof(
        expenseId: expenseId,
        userId: userId,
        proofImageUrl: 'https://example.com/proof.jpg',
        evaluation: any(named: 'evaluation'),
      ),
    ).thenAnswer((invocation) async {
      final evaluation =
          invocation.namedArguments[#evaluation] as PaymentProofEvaluation;
      expect(evaluation.canAutoSettle, false);
      return Right(
        expense.copyWith(
          splits: expense.splits
              .map(
                (split) => split.userId == userId
                    ? split.copyWith(
                        paymentStatus: ExpensePaymentStatus.proofSubmitted,
                      )
                    : split,
              )
              .toList(),
        ),
      );
    });

    final result = await usecase(
      const SubmitPaymentProofParams(
        expenseId: expenseId,
        userId: userId,
        imagePath: imagePath,
      ),
    );

    expect(result.isRight(), true);
    verifyNever(
      () => announcementService.announceSplitPaid(
        expense: any(named: 'expense'),
        split: any(named: 'split'),
      ),
    );
  });

  test('submits proof for manual review when analysis fails', () async {
    when(
      () => repository.getExpenseById(expenseId),
    ).thenAnswer((_) async => Right(expense));
    when(() => repository.analyzePaymentProof(imagePath)).thenAnswer(
      (_) async => const Left(ServerFailure(message: 'Parser unavailable')),
    );
    when(
      () => repository.uploadPaymentProof(
        expenseId: expenseId,
        userId: userId,
        imagePath: imagePath,
      ),
    ).thenAnswer((_) async => const Right('https://example.com/proof.jpg'));
    when(
      () => repository.submitPaymentProof(
        expenseId: expenseId,
        userId: userId,
        proofImageUrl: 'https://example.com/proof.jpg',
        evaluation: any(named: 'evaluation'),
      ),
    ).thenAnswer((invocation) async {
      final evaluation =
          invocation.namedArguments[#evaluation] as PaymentProofEvaluation;
      expect(evaluation.extractedAmount, isNull);
      expect(evaluation.extractedRecipient, isNull);
      expect(evaluation.confidence, 0);
      expect(evaluation.canAutoSettle, false);
      return Right(
        expense.copyWith(
          splits: expense.splits
              .map(
                (split) => split.userId == userId
                    ? split.copyWith(
                        paymentStatus: ExpensePaymentStatus.proofSubmitted,
                      )
                    : split,
              )
              .toList(),
        ),
      );
    });

    final result = await usecase(
      const SubmitPaymentProofParams(
        expenseId: expenseId,
        userId: userId,
        imagePath: imagePath,
      ),
    );

    expect(result.isRight(), true);
    verify(() => repository.analyzePaymentProof(imagePath)).called(1);
    verify(
      () => repository.uploadPaymentProof(
        expenseId: expenseId,
        userId: userId,
        imagePath: imagePath,
      ),
    ).called(1);
    verify(
      () => repository.submitPaymentProof(
        expenseId: expenseId,
        userId: userId,
        proofImageUrl: 'https://example.com/proof.jpg',
        evaluation: any(named: 'evaluation'),
      ),
    ).called(1);
    verifyNever(
      () => announcementService.announceSplitPaid(
        expense: any(named: 'expense'),
        split: any(named: 'split'),
      ),
    );
  });

  test('returns failure when split is already paid', () async {
    when(() => repository.getExpenseById(expenseId)).thenAnswer(
      (_) async => Right(
        expense.copyWith(
          splits: expense.splits
              .map(
                (split) => split.userId == userId
                    ? split.copyWith(paymentStatus: ExpensePaymentStatus.paid)
                    : split,
              )
              .toList(),
        ),
      ),
    );

    final result = await usecase(
      const SubmitPaymentProofParams(
        expenseId: expenseId,
        userId: userId,
        imagePath: imagePath,
      ),
    );

    expect(
      result,
      const Left(
        InvalidInputFailure(message: 'This split is already marked as paid'),
      ),
    );
    verifyNever(
      () => announcementService.announceSplitPaid(
        expense: any(named: 'expense'),
        split: any(named: 'split'),
      ),
    );
  });
}
