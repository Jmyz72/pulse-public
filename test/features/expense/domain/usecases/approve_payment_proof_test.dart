import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/failures.dart';
import 'package:pulse/features/expense/domain/entities/expense.dart';
import 'package:pulse/features/expense/domain/entities/expense_split.dart';
import 'package:pulse/features/expense/domain/repositories/expense_repository.dart';
import 'package:pulse/features/expense/domain/services/expense_payment_announcement_service.dart';
import 'package:pulse/features/expense/domain/usecases/approve_payment_proof.dart';

class MockExpenseRepository extends Mock implements ExpenseRepository {}

class MockExpensePaymentAnnouncementService extends Mock
    implements ExpensePaymentAnnouncementService {}

void main() {
  late MockExpenseRepository repository;
  late MockExpensePaymentAnnouncementService announcementService;
  late ApprovePaymentProof usecase;

  const expenseId = 'expense-1';
  const ownerId = 'owner-1';
  const participantId = 'user-2';

  final expense = Expense(
    id: expenseId,
    ownerId: ownerId,
    title: 'Dinner',
    totalAmount: 53.68,
    date: DateTime(2026, 3, 13),
    chatRoomId: 'chat-1',
    splits: const [
      ExpenseSplit(
        userId: ownerId,
        userName: 'Owner',
        amount: 26.84,
        isPaid: true,
      ),
      ExpenseSplit(
        userId: participantId,
        userName: 'Participant',
        amount: 26.84,
        paymentStatus: ExpensePaymentStatus.proofSubmitted,
      ),
    ],
  );

  final approvedExpense = expense.copyWith(
    splits: expense.splits
        .map(
          (split) => split.userId == participantId
              ? split.copyWith(paymentStatus: ExpensePaymentStatus.paid)
              : split,
        )
        .toList(),
  );

  setUpAll(() {
    registerFallbackValue(expense);
    registerFallbackValue(
      const ExpenseSplit(userId: 'fallback', userName: 'Fallback', amount: 0),
    );
  });

  setUp(() {
    repository = MockExpenseRepository();
    announcementService = MockExpensePaymentAnnouncementService();
    usecase = ApprovePaymentProof(
      repository: repository,
      announcementService: announcementService,
    );
  });

  test('announces payment when proof approval marks split as paid', () async {
    when(
      () => repository.getExpenseById(expenseId),
    ).thenAnswer((_) async => Right(expense));
    when(
      () => repository.approvePaymentProof(
        expenseId: expenseId,
        userId: participantId,
        reviewerId: ownerId,
      ),
    ).thenAnswer((_) async => Right(approvedExpense));
    when(
      () => announcementService.announceSplitPaid(
        expense: approvedExpense,
        split: approvedExpense.splits[1],
      ),
    ).thenAnswer((_) async {});

    final result = await usecase(
      const ApprovePaymentProofParams(
        expenseId: expenseId,
        userId: participantId,
        reviewerId: ownerId,
      ),
    );

    expect(result, Right(approvedExpense));
    verify(() => repository.getExpenseById(expenseId)).called(1);
    verify(
      () => repository.approvePaymentProof(
        expenseId: expenseId,
        userId: participantId,
        reviewerId: ownerId,
      ),
    ).called(1);
    verify(
      () => announcementService.announceSplitPaid(
        expense: approvedExpense,
        split: approvedExpense.splits[1],
      ),
    ).called(1);
  });

  test('returns failure when there is no pending proof to approve', () async {
    when(() => repository.getExpenseById(expenseId)).thenAnswer(
      (_) async => Right(
        expense.copyWith(
          splits: expense.splits
              .map(
                (split) => split.userId == participantId
                    ? split.copyWith(paymentStatus: ExpensePaymentStatus.paid)
                    : split,
              )
              .toList(),
        ),
      ),
    );

    final result = await usecase(
      const ApprovePaymentProofParams(
        expenseId: expenseId,
        userId: participantId,
        reviewerId: ownerId,
      ),
    );

    expect(
      result,
      const Left(InvalidInputFailure(message: 'No pending proof to approve')),
    );
    verifyNever(
      () => announcementService.announceSplitPaid(
        expense: any(named: 'expense'),
        split: any(named: 'split'),
      ),
    );
  });
}
