import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/failures.dart';
import 'package:pulse/features/expense/domain/entities/expense.dart';
import 'package:pulse/features/expense/domain/entities/expense_submission.dart';
import 'package:pulse/features/expense/domain/entities/expense_split.dart';
import 'package:pulse/features/expense/domain/usecases/create_adhoc_expense.dart';
import 'package:pulse/features/expense/domain/usecases/create_expense.dart';
import 'package:pulse/features/expense/domain/usecases/delete_expense.dart';
import 'package:pulse/features/expense/domain/usecases/get_expense_by_id.dart';
import 'package:pulse/features/expense/domain/usecases/get_expenses.dart';
import 'package:pulse/features/expense/domain/usecases/approve_payment_proof.dart';
import 'package:pulse/features/expense/domain/usecases/mark_split_paid.dart';
import 'package:pulse/features/expense/domain/usecases/refresh_expense_owner_payment_identity.dart';
import 'package:pulse/features/expense/domain/usecases/reject_payment_proof.dart';
import 'package:pulse/features/expense/domain/usecases/select_items.dart';
import 'package:pulse/features/expense/domain/usecases/submit_payment_proof.dart';
import 'package:pulse/features/expense/domain/usecases/update_expense.dart';
import 'package:pulse/features/expense/presentation/bloc/expense_bloc.dart';

class MockGetExpenses extends Mock implements GetExpenses {}

class MockGetExpenseById extends Mock implements GetExpenseById {}

class MockCreateExpense extends Mock implements CreateExpense {}

class MockCreateAdHocExpense extends Mock implements CreateAdHocExpense {}

class MockUpdateExpense extends Mock implements UpdateExpense {}

class MockDeleteExpense extends Mock implements DeleteExpense {}

class MockSelectItems extends Mock implements SelectItems {}

class MockMarkSplitPaid extends Mock implements MarkSplitPaid {}

class MockSubmitPaymentProof extends Mock implements SubmitPaymentProof {}

class MockApprovePaymentProof extends Mock implements ApprovePaymentProof {}

class MockRejectPaymentProof extends Mock implements RejectPaymentProof {}

class MockRefreshExpenseOwnerPaymentIdentity extends Mock
    implements RefreshExpenseOwnerPaymentIdentity {}

void main() {
  late ExpenseBloc bloc;
  late MockGetExpenses mockGetExpenses;
  late MockGetExpenseById mockGetExpenseById;
  late MockCreateExpense mockCreateExpense;
  late MockCreateAdHocExpense mockCreateAdHocExpense;
  late MockUpdateExpense mockUpdateExpense;
  late MockDeleteExpense mockDeleteExpense;
  late MockSelectItems mockSelectItems;
  late MockMarkSplitPaid mockMarkSplitPaid;
  late MockSubmitPaymentProof mockSubmitPaymentProof;
  late MockApprovePaymentProof mockApprovePaymentProof;
  late MockRejectPaymentProof mockRejectPaymentProof;
  late MockRefreshExpenseOwnerPaymentIdentity
  mockRefreshExpenseOwnerPaymentIdentity;

  setUp(() {
    mockGetExpenses = MockGetExpenses();
    mockGetExpenseById = MockGetExpenseById();
    mockCreateExpense = MockCreateExpense();
    mockCreateAdHocExpense = MockCreateAdHocExpense();
    mockUpdateExpense = MockUpdateExpense();
    mockDeleteExpense = MockDeleteExpense();
    mockSelectItems = MockSelectItems();
    mockMarkSplitPaid = MockMarkSplitPaid();
    mockSubmitPaymentProof = MockSubmitPaymentProof();
    mockApprovePaymentProof = MockApprovePaymentProof();
    mockRejectPaymentProof = MockRejectPaymentProof();
    mockRefreshExpenseOwnerPaymentIdentity =
        MockRefreshExpenseOwnerPaymentIdentity();
    bloc = ExpenseBloc(
      getExpenses: mockGetExpenses,
      getExpenseById: mockGetExpenseById,
      createExpense: mockCreateExpense,
      createAdHocExpense: mockCreateAdHocExpense,
      updateExpense: mockUpdateExpense,
      deleteExpense: mockDeleteExpense,
      selectItems: mockSelectItems,
      markSplitPaid: mockMarkSplitPaid,
      submitPaymentProof: mockSubmitPaymentProof,
      approvePaymentProof: mockApprovePaymentProof,
      rejectPaymentProof: mockRejectPaymentProof,
      refreshExpenseOwnerPaymentIdentity:
          mockRefreshExpenseOwnerPaymentIdentity,
      currentUserId: 'test-user-123',
    );
  });

  tearDown(() {
    bloc.close();
  });

  final tDate = DateTime(2024, 1, 15);

  final tExpense = Expense(
    id: '1',
    ownerId: 'user1',
    title: 'Groceries',
    description: 'Weekly groceries',
    totalAmount: 150.0,
    date: tDate,
    status: ExpenseStatus.pending,
    type: ExpenseType.group,
    chatRoomId: 'chat-1',
    splits: const [
      ExpenseSplit(userId: 'user1', userName: 'User 1', amount: 75.0),
      ExpenseSplit(userId: 'user2', userName: 'User 2', amount: 75.0),
    ],
  );

  final tExpense2 = Expense(
    id: '2',
    ownerId: 'user2',
    title: 'Dinner',
    totalAmount: 100.0,
    date: tDate,
    status: ExpenseStatus.settled,
    type: ExpenseType.oneOnOne,
    chatRoomId: 'chat-2',
    splits: const [
      ExpenseSplit(
        userId: 'user1',
        userName: 'User 1',
        amount: 50.0,
        isPaid: true,
      ),
      ExpenseSplit(
        userId: 'user2',
        userName: 'User 2',
        amount: 50.0,
        isPaid: true,
      ),
    ],
  );

  final tExpenseWithUnpaidSplit = Expense(
    id: '3',
    ownerId: 'user1',
    title: 'Rent',
    totalAmount: 200.0,
    date: tDate,
    status: ExpenseStatus.pending,
    type: ExpenseType.group,
    chatRoomId: 'chat-1',
    splits: const [
      ExpenseSplit(
        userId: 'user1',
        userName: 'User 1',
        amount: 100.0,
        isPaid: true,
      ),
      ExpenseSplit(
        userId: 'user2',
        userName: 'User 2',
        amount: 100.0,
        isPaid: false,
      ),
    ],
  );

  final tAdHocExpense = Expense(
    id: 'master-1',
    ownerId: 'user1',
    title: 'Ad-hoc Dinner',
    totalAmount: 300.0,
    date: tDate,
    status: ExpenseStatus.pending,
    type: ExpenseType.adHoc,
    linkedExpenseIds: const ['linked-1', 'linked-2'],
    adHocParticipantIds: const ['user1', 'user2', 'user3'],
    splits: const [],
  );

  final tUpdatedExpense = tExpense.copyWith(title: 'Updated Groceries');

  final tExpenseWithPaidSplit = tExpense.copyWith(
    splits: const [
      ExpenseSplit(
        userId: 'user1',
        userName: 'User 1',
        amount: 75.0,
        isPaid: true,
      ),
      ExpenseSplit(userId: 'user2', userName: 'User 2', amount: 75.0),
    ],
  );

  const tCreateSubmission = ExpenseSubmission(
    currentUserId: 'user1',
    currentUserName: 'User 1',
    title: 'Groceries',
    description: 'Weekly groceries',
    expenseType: ExpenseType.group,
    chatRoomId: 'chat-1',
    participants: [
      ExpenseParticipant(id: 'user1', name: 'User 1'),
      ExpenseParticipant(id: 'user2', name: 'User 2'),
    ],
    manualAmount: 150.0,
  );

  const tCreateSubmission2 = ExpenseSubmission(
    currentUserId: 'user2',
    currentUserName: 'User 2',
    title: 'Dinner',
    description: '',
    expenseType: ExpenseType.oneOnOne,
    chatRoomId: 'chat-2',
    participants: [
      ExpenseParticipant(id: 'user1', name: 'User 1'),
      ExpenseParticipant(id: 'user2', name: 'User 2'),
    ],
    manualAmount: 100.0,
  );

  const tUpdateSubmission = ExpenseSubmission(
    currentUserId: 'user1',
    currentUserName: 'User 1',
    title: 'Updated Groceries',
    description: 'Weekly groceries',
    expenseType: ExpenseType.group,
    chatRoomId: 'chat-1',
    participants: [
      ExpenseParticipant(id: 'user1', name: 'User 1'),
      ExpenseParticipant(id: 'user2', name: 'User 2'),
    ],
    manualAmount: 150.0,
  );

  setUpAll(() {
    registerFallbackValue(const GetExpensesParams(chatRoomIds: ['chat-1']));
    registerFallbackValue(
      const CreateExpenseParams(submission: tCreateSubmission),
    );
    registerFallbackValue(const DeleteExpenseParams(id: '1'));
    registerFallbackValue(const GetExpenseByIdParams(id: '1'));
    registerFallbackValue(
      UpdateExpenseParams(
        existingExpense: tExpense,
        submission: tUpdateSubmission,
      ),
    );
    registerFallbackValue(
      CreateAdHocExpenseParams(
        masterExpense: tAdHocExpense,
        participantIds: const ['user1', 'user2'],
        chatRoomIdsByParticipant: const {'user2': 'chat-2'},
      ),
    );
    registerFallbackValue(
      const SelectItemsParams(
        expenseId: '1',
        userId: 'user1',
        itemIds: ['item-1'],
      ),
    );
    registerFallbackValue(
      const MarkSplitPaidParams(expenseId: '1', userId: 'user1', isPaid: true),
    );
    registerFallbackValue(
      const RefreshExpenseOwnerPaymentIdentityParams(
        expenseId: '1',
        ownerId: 'user1',
        paymentIdentity: 'DuitNow Jimmy',
      ),
    );
  });

  const tChatRoomIds = ['chat-1', 'chat-2'];
  const tCurrentUserId = 'test-user-123';

  final tExpenses = [tExpense];

  group('Initial State', () {
    test('should have initial state', () {
      expect(bloc.state, const ExpenseState(currentUserId: tCurrentUserId));
      expect(bloc.state.currentUserId, tCurrentUserId);
      expect(bloc.state.status, ExpenseLoadStatus.initial);
      expect(bloc.state.detailStatus, ExpenseDetailStatus.initial);
      expect(bloc.state.expenses, isEmpty);
      expect(bloc.state.selectedExpense, isNull);
      expect(bloc.state.errorMessage, isNull);
    });
  });

  group('ExpenseLoadRequested', () {
    blocTest<ExpenseBloc, ExpenseState>(
      'emits [loading, loaded] when GetExpenses returns successfully',
      build: () {
        when(
          () => mockGetExpenses(any()),
        ).thenAnswer((_) async => Right(tExpenses));
        return bloc;
      },
      act: (bloc) =>
          bloc.add(const ExpenseLoadRequested(chatRoomIds: tChatRoomIds)),
      expect: () => [
        const ExpenseState(
          currentUserId: tCurrentUserId,
          status: ExpenseLoadStatus.loading,
        ),
        ExpenseState(
          currentUserId: tCurrentUserId,
          status: ExpenseLoadStatus.loaded,
          expenses: tExpenses,
        ),
      ],
      verify: (_) {
        verify(() => mockGetExpenses(any())).called(1);
      },
    );

    blocTest<ExpenseBloc, ExpenseState>(
      'emits [loading, error] when GetExpenses fails',
      build: () {
        when(() => mockGetExpenses(any())).thenAnswer(
          (_) async => const Left(ServerFailure(message: 'Server error')),
        );
        return bloc;
      },
      act: (bloc) =>
          bloc.add(const ExpenseLoadRequested(chatRoomIds: tChatRoomIds)),
      expect: () => [
        const ExpenseState(
          currentUserId: tCurrentUserId,
          status: ExpenseLoadStatus.loading,
        ),
        const ExpenseState(
          currentUserId: tCurrentUserId,
          status: ExpenseLoadStatus.error,
          errorMessage: 'Server error',
        ),
      ],
    );

    blocTest<ExpenseBloc, ExpenseState>(
      'emits [loading, error] when network failure occurs',
      build: () {
        when(
          () => mockGetExpenses(any()),
        ).thenAnswer((_) async => const Left(NetworkFailure()));
        return bloc;
      },
      act: (bloc) =>
          bloc.add(const ExpenseLoadRequested(chatRoomIds: tChatRoomIds)),
      expect: () => [
        const ExpenseState(
          currentUserId: tCurrentUserId,
          status: ExpenseLoadStatus.loading,
        ),
        const ExpenseState(
          currentUserId: tCurrentUserId,
          status: ExpenseLoadStatus.error,
          errorMessage: 'No internet connection',
        ),
      ],
    );
  });

  group('ExpenseByIdRequested', () {
    blocTest<ExpenseBloc, ExpenseState>(
      'emits [detail loading, detail loaded] when GetExpenseById returns successfully',
      build: () {
        when(
          () => mockGetExpenseById(any()),
        ).thenAnswer((_) async => Right(tExpense));
        return bloc;
      },
      act: (bloc) => bloc.add(const ExpenseByIdRequested(id: '1')),
      expect: () => [
        const ExpenseState(
          currentUserId: tCurrentUserId,
          detailStatus: ExpenseDetailStatus.loading,
        ),
        ExpenseState(
          currentUserId: tCurrentUserId,
          detailStatus: ExpenseDetailStatus.loaded,
          selectedExpense: tExpense,
        ),
      ],
      verify: (_) {
        verify(() => mockGetExpenseById(any())).called(1);
      },
    );

    blocTest<ExpenseBloc, ExpenseState>(
      'emits [detail loading, detail error] when GetExpenseById fails',
      build: () {
        when(() => mockGetExpenseById(any())).thenAnswer(
          (_) async => const Left(ServerFailure(message: 'Expense not found')),
        );
        return bloc;
      },
      act: (bloc) => bloc.add(const ExpenseByIdRequested(id: '1')),
      expect: () => [
        const ExpenseState(
          currentUserId: tCurrentUserId,
          detailStatus: ExpenseDetailStatus.loading,
        ),
        const ExpenseState(
          currentUserId: tCurrentUserId,
          detailStatus: ExpenseDetailStatus.error,
          errorMessage: 'Expense not found',
        ),
      ],
    );

    blocTest<ExpenseBloc, ExpenseState>(
      'emits [detail loading, detail error] when network failure occurs',
      build: () {
        when(
          () => mockGetExpenseById(any()),
        ).thenAnswer((_) async => const Left(NetworkFailure()));
        return bloc;
      },
      act: (bloc) => bloc.add(const ExpenseByIdRequested(id: '1')),
      expect: () => [
        const ExpenseState(
          currentUserId: tCurrentUserId,
          detailStatus: ExpenseDetailStatus.loading,
        ),
        const ExpenseState(
          currentUserId: tCurrentUserId,
          detailStatus: ExpenseDetailStatus.error,
          errorMessage: 'No internet connection',
        ),
      ],
    );
  });

  group('ExpenseCreateRequested', () {
    blocTest<ExpenseBloc, ExpenseState>(
      'emits [loading, loaded] when CreateExpense succeeds',
      build: () {
        when(
          () => mockCreateExpense(
            const CreateExpenseParams(submission: tCreateSubmission),
          ),
        ).thenAnswer((_) async => Right(tExpense));
        return bloc;
      },
      act: (bloc) =>
          bloc.add(const ExpenseCreateRequested(submission: tCreateSubmission)),
      expect: () => [
        const ExpenseState(
          currentUserId: tCurrentUserId,
          status: ExpenseLoadStatus.loading,
        ),
        ExpenseState(
          currentUserId: tCurrentUserId,
          status: ExpenseLoadStatus.loaded,
          expenses: [tExpense],
          selectedExpense: tExpense,
        ),
      ],
      verify: (_) {
        verify(
          () => mockCreateExpense(
            const CreateExpenseParams(submission: tCreateSubmission),
          ),
        ).called(1);
      },
    );

    blocTest<ExpenseBloc, ExpenseState>(
      'emits [loading, error] on CreateExpense failure',
      build: () {
        when(
          () => mockCreateExpense(
            const CreateExpenseParams(submission: tCreateSubmission),
          ),
        ).thenAnswer(
          (_) async => const Left(ServerFailure(message: 'Failed to create')),
        );
        return bloc;
      },
      act: (bloc) =>
          bloc.add(const ExpenseCreateRequested(submission: tCreateSubmission)),
      expect: () => [
        const ExpenseState(
          currentUserId: tCurrentUserId,
          status: ExpenseLoadStatus.loading,
        ),
        const ExpenseState(
          currentUserId: tCurrentUserId,
          status: ExpenseLoadStatus.error,
          errorMessage: 'Failed to create',
        ),
      ],
    );

    blocTest<ExpenseBloc, ExpenseState>(
      'prepends created expense to existing list',
      build: () {
        when(
          () => mockCreateExpense(any()),
        ).thenAnswer((_) async => Right(tExpense2));
        return bloc;
      },
      seed: () => ExpenseState(
        currentUserId: tCurrentUserId,
        status: ExpenseLoadStatus.loaded,
        expenses: [tExpense],
      ),
      act: (bloc) => bloc.add(
        const ExpenseCreateRequested(submission: tCreateSubmission2),
      ),
      expect: () => [
        ExpenseState(
          currentUserId: tCurrentUserId,
          status: ExpenseLoadStatus.loading,
          expenses: [tExpense],
        ),
        ExpenseState(
          currentUserId: tCurrentUserId,
          status: ExpenseLoadStatus.loaded,
          expenses: [tExpense2, tExpense],
          selectedExpense: tExpense2,
        ),
      ],
    );
  });

  group('ExpenseOwnerPaymentIdentityRefreshRequested', () {
    final refreshedExpense = tExpense.copyWith(
      ownerPaymentIdentity: 'DuitNow Jimmy',
    );

    blocTest<ExpenseBloc, ExpenseState>(
      'emits [detail loading, detail loaded] when refresh succeeds',
      build: () {
        when(
          () => mockRefreshExpenseOwnerPaymentIdentity(any()),
        ).thenAnswer((_) async => Right(refreshedExpense));
        return bloc;
      },
      seed: () => ExpenseState(
        currentUserId: tCurrentUserId,
        expenses: [tExpense],
        selectedExpense: tExpense,
        detailStatus: ExpenseDetailStatus.loaded,
      ),
      act: (bloc) => bloc.add(
        const ExpenseOwnerPaymentIdentityRefreshRequested(
          expenseId: '1',
          ownerId: 'user1',
          paymentIdentity: 'DuitNow Jimmy',
        ),
      ),
      expect: () => [
        ExpenseState(
          currentUserId: tCurrentUserId,
          expenses: [tExpense],
          selectedExpense: tExpense,
          detailStatus: ExpenseDetailStatus.loading,
        ),
        ExpenseState(
          currentUserId: tCurrentUserId,
          expenses: [refreshedExpense],
          selectedExpense: refreshedExpense,
          detailStatus: ExpenseDetailStatus.loaded,
        ),
      ],
    );
  });

  group('AdHocExpenseCreateRequested', () {
    blocTest<ExpenseBloc, ExpenseState>(
      'emits [loading, loaded] when CreateAdHocExpense succeeds',
      build: () {
        when(
          () => mockCreateAdHocExpense(any()),
        ).thenAnswer((_) async => Right(tAdHocExpense));
        return bloc;
      },
      act: (bloc) => bloc.add(
        AdHocExpenseCreateRequested(
          masterExpense: tAdHocExpense,
          participantIds: const ['user1', 'user2', 'user3'],
          chatRoomIdsByParticipant: const {
            'user2': 'chat-2',
            'user3': 'chat-3',
          },
        ),
      ),
      expect: () => [
        const ExpenseState(
          currentUserId: tCurrentUserId,
          status: ExpenseLoadStatus.loading,
        ),
        ExpenseState(
          currentUserId: tCurrentUserId,
          status: ExpenseLoadStatus.loaded,
          expenses: [tAdHocExpense],
        ),
      ],
      verify: (_) {
        verify(() => mockCreateAdHocExpense(any())).called(1);
      },
    );

    blocTest<ExpenseBloc, ExpenseState>(
      'emits [loading, error] when CreateAdHocExpense fails',
      build: () {
        when(() => mockCreateAdHocExpense(any())).thenAnswer(
          (_) async =>
              const Left(ServerFailure(message: 'Failed to create ad-hoc')),
        );
        return bloc;
      },
      act: (bloc) => bloc.add(
        AdHocExpenseCreateRequested(
          masterExpense: tAdHocExpense,
          participantIds: const ['user1', 'user2'],
          chatRoomIdsByParticipant: const {'user2': 'chat-2'},
        ),
      ),
      expect: () => [
        const ExpenseState(
          currentUserId: tCurrentUserId,
          status: ExpenseLoadStatus.loading,
        ),
        const ExpenseState(
          currentUserId: tCurrentUserId,
          status: ExpenseLoadStatus.error,
          errorMessage: 'Failed to create ad-hoc',
        ),
      ],
    );
  });

  group('ExpenseUpdateRequested', () {
    blocTest<ExpenseBloc, ExpenseState>(
      'emits [loading, loaded] when UpdateExpense succeeds',
      build: () {
        when(
          () => mockUpdateExpense(any()),
        ).thenAnswer((_) async => Right(tUpdatedExpense));
        return bloc;
      },
      seed: () => ExpenseState(
        currentUserId: tCurrentUserId,
        status: ExpenseLoadStatus.loaded,
        expenses: [tExpense],
      ),
      act: (bloc) => bloc.add(
        ExpenseUpdateRequested(
          existingExpense: tExpense,
          submission: tUpdateSubmission,
        ),
      ),
      expect: () => [
        ExpenseState(
          currentUserId: tCurrentUserId,
          status: ExpenseLoadStatus.loading,
          expenses: [tExpense],
        ),
        ExpenseState(
          currentUserId: tCurrentUserId,
          status: ExpenseLoadStatus.loaded,
          expenses: [tUpdatedExpense],
        ),
      ],
      verify: (_) {
        verify(() => mockUpdateExpense(any())).called(1);
      },
    );

    blocTest<ExpenseBloc, ExpenseState>(
      'updates selectedExpense if it matches updated expense',
      build: () {
        when(
          () => mockUpdateExpense(any()),
        ).thenAnswer((_) async => Right(tUpdatedExpense));
        return bloc;
      },
      seed: () => ExpenseState(
        currentUserId: tCurrentUserId,
        status: ExpenseLoadStatus.loaded,
        expenses: [tExpense],
        selectedExpense: tExpense,
      ),
      act: (bloc) => bloc.add(
        ExpenseUpdateRequested(
          existingExpense: tExpense,
          submission: tUpdateSubmission,
        ),
      ),
      expect: () => [
        ExpenseState(
          currentUserId: tCurrentUserId,
          status: ExpenseLoadStatus.loading,
          expenses: [tExpense],
          selectedExpense: tExpense,
        ),
        ExpenseState(
          currentUserId: tCurrentUserId,
          status: ExpenseLoadStatus.loaded,
          expenses: [tUpdatedExpense],
          selectedExpense: tUpdatedExpense,
        ),
      ],
    );

    blocTest<ExpenseBloc, ExpenseState>(
      'emits [loading, error] when UpdateExpense fails',
      build: () {
        when(() => mockUpdateExpense(any())).thenAnswer(
          (_) async => const Left(ServerFailure(message: 'Failed to update')),
        );
        return bloc;
      },
      seed: () => ExpenseState(
        currentUserId: tCurrentUserId,
        status: ExpenseLoadStatus.loaded,
        expenses: [tExpense],
      ),
      act: (bloc) => bloc.add(
        ExpenseUpdateRequested(
          existingExpense: tExpense,
          submission: tUpdateSubmission,
        ),
      ),
      expect: () => [
        ExpenseState(
          currentUserId: tCurrentUserId,
          status: ExpenseLoadStatus.loading,
          expenses: [tExpense],
        ),
        ExpenseState(
          currentUserId: tCurrentUserId,
          status: ExpenseLoadStatus.error,
          errorMessage: 'Failed to update',
          expenses: [tExpense],
        ),
      ],
    );
  });

  group('ExpenseDeleteRequested', () {
    blocTest<ExpenseBloc, ExpenseState>(
      'emits [loading, loaded without deleted expense] when DeleteExpense succeeds',
      build: () {
        when(
          () => mockDeleteExpense(const DeleteExpenseParams(id: '1')),
        ).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      seed: () => ExpenseState(
        currentUserId: tCurrentUserId,
        status: ExpenseLoadStatus.loaded,
        expenses: tExpenses,
      ),
      act: (bloc) => bloc.add(const ExpenseDeleteRequested(id: '1')),
      expect: () => [
        ExpenseState(
          currentUserId: tCurrentUserId,
          status: ExpenseLoadStatus.loading,
          expenses: tExpenses,
        ),
        const ExpenseState(
          currentUserId: tCurrentUserId,
          status: ExpenseLoadStatus.loaded,
          expenses: [],
        ),
      ],
      verify: (_) {
        verify(
          () => mockDeleteExpense(const DeleteExpenseParams(id: '1')),
        ).called(1);
      },
    );

    blocTest<ExpenseBloc, ExpenseState>(
      'clears selectedExpense if deleted expense was selected',
      build: () {
        when(
          () => mockDeleteExpense(any()),
        ).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      seed: () => ExpenseState(
        currentUserId: tCurrentUserId,
        status: ExpenseLoadStatus.loaded,
        expenses: tExpenses,
        selectedExpense: tExpense,
      ),
      act: (bloc) => bloc.add(const ExpenseDeleteRequested(id: '1')),
      expect: () => [
        ExpenseState(
          currentUserId: tCurrentUserId,
          status: ExpenseLoadStatus.loading,
          expenses: tExpenses,
          selectedExpense: tExpense,
        ),
        const ExpenseState(
          currentUserId: tCurrentUserId,
          status: ExpenseLoadStatus.loaded,
          expenses: [],
          selectedExpense: null,
        ),
      ],
    );

    blocTest<ExpenseBloc, ExpenseState>(
      'emits [loading, error] when DeleteExpense fails',
      build: () {
        when(
          () => mockDeleteExpense(const DeleteExpenseParams(id: '1')),
        ).thenAnswer(
          (_) async => const Left(ServerFailure(message: 'Failed to delete')),
        );
        return bloc;
      },
      seed: () => ExpenseState(
        currentUserId: tCurrentUserId,
        status: ExpenseLoadStatus.loaded,
        expenses: tExpenses,
      ),
      act: (bloc) => bloc.add(const ExpenseDeleteRequested(id: '1')),
      expect: () => [
        ExpenseState(
          currentUserId: tCurrentUserId,
          status: ExpenseLoadStatus.loading,
          expenses: tExpenses,
        ),
        ExpenseState(
          currentUserId: tCurrentUserId,
          status: ExpenseLoadStatus.error,
          errorMessage: 'Failed to delete',
          expenses: tExpenses,
        ),
      ],
    );
  });

  group('ExpenseItemsSelectionRequested', () {
    blocTest<ExpenseBloc, ExpenseState>(
      'emits [detail loading, detail loaded] when SelectItems succeeds',
      build: () {
        when(
          () => mockSelectItems(any()),
        ).thenAnswer((_) async => Right(tExpense));
        return bloc;
      },
      seed: () => ExpenseState(
        currentUserId: tCurrentUserId,
        status: ExpenseLoadStatus.loaded,
        expenses: [tExpense],
      ),
      act: (bloc) => bloc.add(
        const ExpenseItemsSelectionRequested(
          expenseId: '1',
          userId: 'user1',
          itemIds: ['item-1', 'item-2'],
        ),
      ),
      expect: () => [
        ExpenseState(
          currentUserId: tCurrentUserId,
          status: ExpenseLoadStatus.loaded,
          detailStatus: ExpenseDetailStatus.loading,
          expenses: [tExpense],
        ),
        ExpenseState(
          currentUserId: tCurrentUserId,
          status: ExpenseLoadStatus.loaded,
          detailStatus: ExpenseDetailStatus.loaded,
          expenses: [tExpense],
          selectedExpense: tExpense,
        ),
      ],
      verify: (_) {
        verify(() => mockSelectItems(any())).called(1);
      },
    );

    blocTest<ExpenseBloc, ExpenseState>(
      'emits [detail loading, detail error] when SelectItems fails',
      build: () {
        when(() => mockSelectItems(any())).thenAnswer(
          (_) async =>
              const Left(ServerFailure(message: 'Select items failed')),
        );
        return bloc;
      },
      seed: () => ExpenseState(
        currentUserId: tCurrentUserId,
        status: ExpenseLoadStatus.loaded,
        expenses: [tExpense],
      ),
      act: (bloc) => bloc.add(
        const ExpenseItemsSelectionRequested(
          expenseId: '1',
          userId: 'user1',
          itemIds: ['item-1'],
        ),
      ),
      expect: () => [
        ExpenseState(
          currentUserId: tCurrentUserId,
          status: ExpenseLoadStatus.loaded,
          detailStatus: ExpenseDetailStatus.loading,
          expenses: [tExpense],
        ),
        ExpenseState(
          currentUserId: tCurrentUserId,
          status: ExpenseLoadStatus.loaded,
          detailStatus: ExpenseDetailStatus.error,
          errorMessage: 'Select items failed',
          expenses: [tExpense],
        ),
      ],
    );

    blocTest<ExpenseBloc, ExpenseState>(
      'emits lock message when SelectItems is rejected after payment',
      build: () {
        when(() => mockSelectItems(any())).thenAnswer(
          (_) async => const Left(
            InvalidInputFailure(
              message:
                  'Your payment is already recorded; item selection is locked',
            ),
          ),
        );
        return bloc;
      },
      seed: () => ExpenseState(
        currentUserId: tCurrentUserId,
        status: ExpenseLoadStatus.loaded,
        expenses: [tExpense],
      ),
      act: (bloc) => bloc.add(
        const ExpenseItemsSelectionRequested(
          expenseId: '1',
          userId: 'user1',
          itemIds: ['item-1'],
        ),
      ),
      expect: () => [
        ExpenseState(
          currentUserId: tCurrentUserId,
          status: ExpenseLoadStatus.loaded,
          detailStatus: ExpenseDetailStatus.loading,
          expenses: [tExpense],
        ),
        ExpenseState(
          currentUserId: tCurrentUserId,
          status: ExpenseLoadStatus.loaded,
          detailStatus: ExpenseDetailStatus.error,
          errorMessage:
              'Your payment is already recorded; item selection is locked',
          expenses: [tExpense],
        ),
      ],
    );

    blocTest<ExpenseBloc, ExpenseState>(
      'emits review lock message when SelectItems is rejected during owner review',
      build: () {
        when(() => mockSelectItems(any())).thenAnswer(
          (_) async => const Left(
            InvalidInputFailure(
              message:
                  'Your payment proof is waiting for owner review; item selection is locked',
            ),
          ),
        );
        return bloc;
      },
      seed: () => ExpenseState(
        currentUserId: tCurrentUserId,
        status: ExpenseLoadStatus.loaded,
        expenses: [tExpense],
      ),
      act: (bloc) => bloc.add(
        const ExpenseItemsSelectionRequested(
          expenseId: '1',
          userId: 'user1',
          itemIds: ['item-1'],
        ),
      ),
      expect: () => [
        ExpenseState(
          currentUserId: tCurrentUserId,
          status: ExpenseLoadStatus.loaded,
          detailStatus: ExpenseDetailStatus.loading,
          expenses: [tExpense],
        ),
        ExpenseState(
          currentUserId: tCurrentUserId,
          status: ExpenseLoadStatus.loaded,
          detailStatus: ExpenseDetailStatus.error,
          errorMessage:
              'Your payment proof is waiting for owner review; item selection is locked',
          expenses: [tExpense],
        ),
      ],
    );
  });

  group('ExpenseSplitPaidToggled', () {
    blocTest<ExpenseBloc, ExpenseState>(
      'emits [detail loading, detail loaded] when MarkSplitPaid succeeds',
      build: () {
        when(
          () => mockMarkSplitPaid(any()),
        ).thenAnswer((_) async => Right(tExpenseWithPaidSplit));
        return bloc;
      },
      seed: () => ExpenseState(
        currentUserId: tCurrentUserId,
        status: ExpenseLoadStatus.loaded,
        expenses: [tExpense],
      ),
      act: (bloc) => bloc.add(
        const ExpenseSplitPaidToggled(
          expenseId: '1',
          userId: 'user1',
          isPaid: true,
        ),
      ),
      expect: () => [
        ExpenseState(
          currentUserId: tCurrentUserId,
          status: ExpenseLoadStatus.loaded,
          detailStatus: ExpenseDetailStatus.loading,
          expenses: [tExpense],
        ),
        ExpenseState(
          currentUserId: tCurrentUserId,
          status: ExpenseLoadStatus.loaded,
          detailStatus: ExpenseDetailStatus.loaded,
          expenses: [tExpenseWithPaidSplit],
          selectedExpense: tExpenseWithPaidSplit,
        ),
      ],
      verify: (_) {
        verify(() => mockMarkSplitPaid(any())).called(1);
      },
    );

    blocTest<ExpenseBloc, ExpenseState>(
      'emits [detail loading, detail error] when MarkSplitPaid fails',
      build: () {
        when(() => mockMarkSplitPaid(any())).thenAnswer(
          (_) async => const Left(ServerFailure(message: 'Mark paid failed')),
        );
        return bloc;
      },
      seed: () => ExpenseState(
        currentUserId: tCurrentUserId,
        status: ExpenseLoadStatus.loaded,
        expenses: [tExpense],
      ),
      act: (bloc) => bloc.add(
        const ExpenseSplitPaidToggled(
          expenseId: '1',
          userId: 'user1',
          isPaid: true,
        ),
      ),
      expect: () => [
        ExpenseState(
          currentUserId: tCurrentUserId,
          status: ExpenseLoadStatus.loaded,
          detailStatus: ExpenseDetailStatus.loading,
          expenses: [tExpense],
        ),
        ExpenseState(
          currentUserId: tCurrentUserId,
          status: ExpenseLoadStatus.loaded,
          detailStatus: ExpenseDetailStatus.error,
          errorMessage: 'Mark paid failed',
          expenses: [tExpense],
        ),
      ],
    );
  });

  group('ExpenseSelected', () {
    blocTest<ExpenseBloc, ExpenseState>(
      'emits state with selectedExpense set',
      build: () => bloc,
      act: (bloc) => bloc.add(ExpenseSelected(expense: tExpense)),
      expect: () => [
        ExpenseState(
          currentUserId: tCurrentUserId,
          selectedExpense: tExpense,
          detailStatus: ExpenseDetailStatus.loaded,
        ),
      ],
    );

    blocTest<ExpenseBloc, ExpenseState>(
      'updates selectedExpense when already set',
      build: () => bloc,
      seed: () => ExpenseState(
        currentUserId: tCurrentUserId,
        selectedExpense: tExpense,
      ),
      act: (bloc) => bloc.add(ExpenseSelected(expense: tExpense2)),
      expect: () => [
        ExpenseState(
          currentUserId: tCurrentUserId,
          selectedExpense: tExpense2,
          detailStatus: ExpenseDetailStatus.loaded,
        ),
      ],
    );
  });

  group('ExpenseCleared', () {
    blocTest<ExpenseBloc, ExpenseState>(
      'emits state with cleared selectedExpense and initial detailStatus',
      build: () => bloc,
      seed: () => ExpenseState(
        currentUserId: tCurrentUserId,
        selectedExpense: tExpense,
        detailStatus: ExpenseDetailStatus.loaded,
      ),
      act: (bloc) => bloc.add(const ExpenseCleared()),
      expect: () => [
        const ExpenseState(
          currentUserId: tCurrentUserId,
          selectedExpense: null,
          detailStatus: ExpenseDetailStatus.initial,
        ),
      ],
    );

    blocTest<ExpenseBloc, ExpenseState>(
      'emits state with null selectedExpense when starting from null',
      build: () => bloc,
      seed: () => const ExpenseState(
        currentUserId: tCurrentUserId,
        detailStatus: ExpenseDetailStatus.loaded,
      ),
      act: (bloc) => bloc.add(const ExpenseCleared()),
      expect: () => [
        const ExpenseState(
          currentUserId: tCurrentUserId,
          selectedExpense: null,
          detailStatus: ExpenseDetailStatus.initial,
        ),
      ],
    );
  });

  group('ExpenseState', () {
    test('totalExpenses calculates sum correctly', () {
      final state = ExpenseState(expenses: [tExpense, tExpense2]);
      expect(state.totalExpenses, 250.0); // 150 + 100
    });

    test('pendingExpenses filters correctly', () {
      final state = ExpenseState(expenses: [tExpense, tExpense2]);
      expect(state.pendingExpenses.length, 1);
      expect(state.pendingExpenses.first.status, ExpenseStatus.pending);
    });

    test('settledExpenses filters correctly', () {
      final state = ExpenseState(expenses: [tExpense, tExpense2]);
      expect(state.settledExpenses.length, 1);
      expect(state.settledExpenses.first.status, ExpenseStatus.settled);
    });

    test('expensesByChatRoom groups correctly', () {
      final state = ExpenseState(expenses: [tExpense, tExpense2]);
      final grouped = state.expensesByChatRoom;
      expect(grouped.keys.length, 2);
      expect(grouped['chat-1']?.length, 1);
      expect(grouped['chat-2']?.length, 1);
    });

    test('totalOwedToUser calculates correctly', () {
      // user1 owns expense with user2 unpaid split of 100
      final state = ExpenseState(expenses: [tExpenseWithUnpaidSplit]);
      expect(state.totalOwedToUser('user1'), 100.0);
    });

    test('totalOwedToUser returns 0 when no one owes', () {
      // All splits are paid in tExpense2
      final state = ExpenseState(expenses: [tExpense2]);
      expect(state.totalOwedToUser('user2'), 0.0);
    });

    test('totalUserOwes calculates correctly', () {
      // user2 owes user1 75.0 in pending tExpense
      final state = ExpenseState(expenses: [tExpense]);
      expect(state.totalUserOwes('user2'), 75.0);
    });

    test('totalUserOwes returns 0 when user is the owner', () {
      final state = ExpenseState(expenses: [tExpense]);
      expect(state.totalUserOwes('user1'), 0.0);
    });

    test('copyWith creates new state with updated values', () {
      const original = ExpenseState();
      final updated = original.copyWith(
        status: ExpenseLoadStatus.loaded,
        expenses: [tExpense],
      );

      expect(updated.status, ExpenseLoadStatus.loaded);
      expect(updated.expenses, [tExpense]);
      expect(original.status, ExpenseLoadStatus.initial);
    });

    test('copyWith preserves values when not provided', () {
      final original = ExpenseState(
        status: ExpenseLoadStatus.loaded,
        expenses: [tExpense],
        selectedExpense: tExpense,
      );
      final updated = original.copyWith(status: ExpenseLoadStatus.loading);

      expect(updated.status, ExpenseLoadStatus.loading);
      expect(updated.expenses, [tExpense]);
      expect(updated.selectedExpense, tExpense);
    });

    test('props contains all fields', () {
      final state = ExpenseState(
        currentUserId: tCurrentUserId,
        status: ExpenseLoadStatus.loaded,
        detailStatus: ExpenseDetailStatus.loaded,
        expenses: [tExpense],
        selectedExpense: tExpense,
        errorMessage: 'Error',
      );

      expect(state.props, [
        tCurrentUserId,
        const <String, String>{},
        ExpenseLoadStatus.loaded,
        ExpenseDetailStatus.loaded,
        ExpenseDetailAction.none,
        [tExpense],
        tExpense,
        'Error',
      ]);
    });
  });

  group('ExpenseEvent', () {
    test('ExpenseLoadRequested props', () {
      const event = ExpenseLoadRequested(chatRoomIds: ['chat-1']);
      expect(event.props, [
        ['chat-1'],
      ]);
    });

    test('ExpenseByIdRequested props', () {
      const event = ExpenseByIdRequested(id: '1');
      expect(event.props, ['1']);
    });

    test('ExpenseCreateRequested props', () {
      const event = ExpenseCreateRequested(submission: tCreateSubmission);
      expect(event.props, [tCreateSubmission]);
    });

    test('AdHocExpenseCreateRequested props', () {
      final event = AdHocExpenseCreateRequested(
        masterExpense: tAdHocExpense,
        participantIds: const ['user1', 'user2'],
        chatRoomIdsByParticipant: const {'user2': 'chat-2'},
      );
      expect(event.props, [
        tAdHocExpense,
        ['user1', 'user2'],
        {'user2': 'chat-2'},
      ]);
    });

    test('ExpenseUpdateRequested props', () {
      final event = ExpenseUpdateRequested(
        existingExpense: tExpense,
        submission: tUpdateSubmission,
      );
      expect(event.props, [tExpense, tUpdateSubmission]);
    });

    test('ExpenseDeleteRequested props', () {
      const event = ExpenseDeleteRequested(id: '1');
      expect(event.props, ['1']);
    });

    test('ExpenseItemsSelectionRequested props', () {
      const event = ExpenseItemsSelectionRequested(
        expenseId: '1',
        userId: 'user1',
        itemIds: ['item-1', 'item-2'],
      );
      expect(event.props, [
        '1',
        'user1',
        ['item-1', 'item-2'],
      ]);
    });

    test('ExpenseSplitPaidToggled props', () {
      const event = ExpenseSplitPaidToggled(
        expenseId: '1',
        userId: 'user1',
        isPaid: true,
      );
      expect(event.props, ['1', 'user1', true]);
    });

    test('ExpenseSelected props', () {
      final event = ExpenseSelected(expense: tExpense);
      expect(event.props, [tExpense]);
    });

    test('ExpenseCleared props', () {
      const event = ExpenseCleared();
      expect(event.props, isEmpty);
    });
  });
}
