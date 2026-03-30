import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/failures.dart';
import 'package:pulse/features/expense/domain/entities/expense.dart';
import 'package:pulse/features/expense/domain/entities/expense_split.dart';
import 'package:pulse/features/expense/domain/usecases/approve_payment_proof.dart';
import 'package:pulse/features/expense/domain/usecases/create_adhoc_expense.dart';
import 'package:pulse/features/expense/domain/usecases/create_expense.dart';
import 'package:pulse/features/expense/domain/usecases/delete_expense.dart';
import 'package:pulse/features/expense/domain/usecases/get_expense_by_id.dart';
import 'package:pulse/features/expense/domain/usecases/get_expenses.dart';
import 'package:pulse/features/expense/domain/usecases/mark_split_paid.dart';
import 'package:pulse/features/expense/domain/usecases/refresh_expense_owner_payment_identity.dart';
import 'package:pulse/features/expense/domain/usecases/reject_payment_proof.dart';
import 'package:pulse/features/expense/domain/usecases/select_items.dart';
import 'package:pulse/features/expense/domain/usecases/submit_payment_proof.dart';
import 'package:pulse/features/expense/domain/usecases/update_expense.dart';
import 'package:pulse/features/expense/presentation/bloc/expense_bloc.dart';

class _MockGetExpenses extends Mock implements GetExpenses {}

class _MockGetExpenseById extends Mock implements GetExpenseById {}

class _MockCreateExpense extends Mock implements CreateExpense {}

class _MockCreateAdHocExpense extends Mock implements CreateAdHocExpense {}

class _MockUpdateExpense extends Mock implements UpdateExpense {}

class _MockDeleteExpense extends Mock implements DeleteExpense {}

class _MockSelectItems extends Mock implements SelectItems {}

class _MockMarkSplitPaid extends Mock implements MarkSplitPaid {}

class _MockSubmitPaymentProof extends Mock implements SubmitPaymentProof {}

class _MockApprovePaymentProof extends Mock implements ApprovePaymentProof {}

class _MockRejectPaymentProof extends Mock implements RejectPaymentProof {}

class _MockRefreshExpenseOwnerPaymentIdentity extends Mock
    implements RefreshExpenseOwnerPaymentIdentity {}

void main() {
  late _MockGetExpenses getExpenses;
  late _MockGetExpenseById getExpenseById;
  late _MockCreateExpense createExpense;
  late _MockCreateAdHocExpense createAdHocExpense;
  late _MockUpdateExpense updateExpense;
  late _MockDeleteExpense deleteExpense;
  late _MockSelectItems selectItems;
  late _MockMarkSplitPaid markSplitPaid;
  late _MockSubmitPaymentProof submitPaymentProof;
  late _MockApprovePaymentProof approvePaymentProof;
  late _MockRejectPaymentProof rejectPaymentProof;
  late _MockRefreshExpenseOwnerPaymentIdentity
  refreshExpenseOwnerPaymentIdentity;
  late ExpenseBloc bloc;

  final expense = Expense(
    id: 'expense-1',
    ownerId: 'owner-1',
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
      ExpenseSplit(userId: 'user-2', userName: 'Participant', amount: 26.84),
    ],
  );

  final updatedExpense = Expense(
    id: 'expense-1',
    ownerId: 'owner-1',
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
      ExpenseSplit(
        userId: 'user-2',
        userName: 'Participant',
        amount: 26.84,
        paymentStatus: ExpensePaymentStatus.proofSubmitted,
      ),
    ],
  );

  setUpAll(() {
    registerFallbackValue(
      const SubmitPaymentProofParams(
        expenseId: 'expense-1',
        userId: 'user-2',
        imagePath: '/tmp/proof.jpg',
      ),
    );
    registerFallbackValue(
      const MarkSplitPaidParams(
        expenseId: 'expense-1',
        userId: 'user-2',
        isPaid: true,
      ),
    );
    registerFallbackValue(
      const ApprovePaymentProofParams(
        expenseId: 'expense-1',
        userId: 'user-2',
        reviewerId: 'owner-1',
      ),
    );
  });

  setUp(() {
    getExpenses = _MockGetExpenses();
    getExpenseById = _MockGetExpenseById();
    createExpense = _MockCreateExpense();
    createAdHocExpense = _MockCreateAdHocExpense();
    updateExpense = _MockUpdateExpense();
    deleteExpense = _MockDeleteExpense();
    selectItems = _MockSelectItems();
    markSplitPaid = _MockMarkSplitPaid();
    submitPaymentProof = _MockSubmitPaymentProof();
    approvePaymentProof = _MockApprovePaymentProof();
    rejectPaymentProof = _MockRejectPaymentProof();
    refreshExpenseOwnerPaymentIdentity =
        _MockRefreshExpenseOwnerPaymentIdentity();

    bloc = ExpenseBloc(
      getExpenses: getExpenses,
      getExpenseById: getExpenseById,
      createExpense: createExpense,
      createAdHocExpense: createAdHocExpense,
      updateExpense: updateExpense,
      deleteExpense: deleteExpense,
      selectItems: selectItems,
      markSplitPaid: markSplitPaid,
      submitPaymentProof: submitPaymentProof,
      approvePaymentProof: approvePaymentProof,
      rejectPaymentProof: rejectPaymentProof,
      refreshExpenseOwnerPaymentIdentity: refreshExpenseOwnerPaymentIdentity,
      currentUserId: 'user-2',
    );
  });

  blocTest<ExpenseBloc, ExpenseState>(
    'participant proof submission updates selected expense instead of using mark-paid toggle',
    build: () {
      when(
        () => submitPaymentProof(any()),
      ).thenAnswer((_) async => Right(updatedExpense));
      return bloc;
    },
    seed: () => ExpenseState(
      currentUserId: 'user-2',
      expenses: [expense],
      selectedExpense: expense,
      detailStatus: ExpenseDetailStatus.loaded,
    ),
    act: (bloc) => bloc.add(
      const ExpensePaymentProofSubmissionRequested(
        expenseId: 'expense-1',
        userId: 'user-2',
        imagePath: '/tmp/proof.jpg',
      ),
    ),
    expect: () => [
      ExpenseState(
        currentUserId: 'user-2',
        expenses: [expense],
        selectedExpense: expense,
        detailStatus: ExpenseDetailStatus.loaded,
        detailAction: ExpenseDetailAction.submittingPaymentProof,
      ),
      ExpenseState(
        currentUserId: 'user-2',
        expenses: [updatedExpense],
        selectedExpense: updatedExpense,
        detailStatus: ExpenseDetailStatus.loaded,
        detailAction: ExpenseDetailAction.none,
      ),
    ],
    verify: (_) {
      verify(() => submitPaymentProof(any())).called(1);
      verifyNever(() => markSplitPaid(any()));
    },
  );

  blocTest<ExpenseBloc, ExpenseState>(
    'owner approval failure restores previous detail state',
    build: () {
      when(() => approvePaymentProof(any())).thenAnswer(
        (_) async => const Left(ServerFailure(message: 'review failed')),
      );
      return bloc;
    },
    seed: () => ExpenseState(
      currentUserId: 'owner-1',
      expenses: [updatedExpense],
      selectedExpense: updatedExpense,
      detailStatus: ExpenseDetailStatus.loaded,
    ),
    act: (bloc) => bloc.add(
      const ExpensePaymentProofApproved(
        expenseId: 'expense-1',
        userId: 'user-2',
        reviewerId: 'owner-1',
      ),
    ),
    expect: () => [
      ExpenseState(
        currentUserId: 'owner-1',
        expenses: [updatedExpense],
        selectedExpense: updatedExpense,
        detailStatus: ExpenseDetailStatus.loading,
      ),
      ExpenseState(
        currentUserId: 'owner-1',
        expenses: [updatedExpense],
        selectedExpense: updatedExpense,
        detailStatus: ExpenseDetailStatus.error,
        errorMessage: 'review failed',
      ),
    ],
  );

  blocTest<ExpenseBloc, ExpenseState>(
    'proof submission failure clears action state and restores previous detail state',
    build: () {
      when(() => submitPaymentProof(any())).thenAnswer(
        (_) async => const Left(ServerFailure(message: 'upload failed')),
      );
      return bloc;
    },
    seed: () => ExpenseState(
      currentUserId: 'user-2',
      expenses: [expense],
      selectedExpense: expense,
      detailStatus: ExpenseDetailStatus.loaded,
    ),
    act: (bloc) => bloc.add(
      const ExpensePaymentProofSubmissionRequested(
        expenseId: 'expense-1',
        userId: 'user-2',
        imagePath: '/tmp/proof.jpg',
      ),
    ),
    expect: () => [
      ExpenseState(
        currentUserId: 'user-2',
        expenses: [expense],
        selectedExpense: expense,
        detailStatus: ExpenseDetailStatus.loaded,
        detailAction: ExpenseDetailAction.submittingPaymentProof,
      ),
      ExpenseState(
        currentUserId: 'user-2',
        expenses: [expense],
        selectedExpense: expense,
        detailStatus: ExpenseDetailStatus.error,
        detailAction: ExpenseDetailAction.none,
        errorMessage: 'upload failed',
      ),
    ],
  );
}
