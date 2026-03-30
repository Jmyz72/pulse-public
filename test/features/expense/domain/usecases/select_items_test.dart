import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/failures.dart';
import 'package:pulse/features/expense/domain/entities/expense.dart';
import 'package:pulse/features/expense/domain/entities/expense_item.dart';
import 'package:pulse/features/expense/domain/entities/expense_split.dart';
import 'package:pulse/features/expense/domain/repositories/expense_repository.dart';
import 'package:pulse/features/expense/domain/usecases/select_items.dart';

class MockExpenseRepository extends Mock implements ExpenseRepository {}

void main() {
  late SelectItems usecase;
  late MockExpenseRepository mockRepository;

  setUp(() {
    mockRepository = MockExpenseRepository();
    usecase = SelectItems(mockRepository);
  });

  const tExpenseId = 'expense-1';
  const tUserId = 'user-1';
  const tItemIds = ['item-1', 'item-2'];

  final tExistingExpense = Expense(
    id: tExpenseId,
    ownerId: 'owner-1',
    title: 'Test Expense',
    totalAmount: 100.0,
    date: DateTime(2024, 1, 15),
    status: ExpenseStatus.pending,
    type: ExpenseType.group,
    chatRoomId: 'chat-1',
    items: const [
      ExpenseItem(id: 'item-1', name: 'Item 1', price: 30.0),
      ExpenseItem(id: 'item-2', name: 'Item 2', price: 20.0),
      ExpenseItem(
        id: 'item-3',
        name: 'Item 3',
        price: 50.0,
        assignedUserIds: ['user-2'],
      ),
    ],
    splits: const [
      ExpenseSplit(userId: tUserId, userName: 'User 1', amount: 50.0),
      ExpenseSplit(userId: 'user-2', userName: 'User 2', amount: 50.0),
    ],
  );

  final tLockedExpense = tExistingExpense.copyWith(
    items: const [
      ExpenseItem(
        id: 'item-1',
        name: 'Item 1',
        price: 30.0,
        assignedUserIds: ['user-2'],
      ),
      ExpenseItem(id: 'item-2', name: 'Item 2', price: 20.0),
      ExpenseItem(id: 'item-3', name: 'Item 3', price: 50.0),
    ],
    splits: const [
      ExpenseSplit(userId: tUserId, userName: 'User 1', amount: 50.0),
      ExpenseSplit(
        userId: 'user-2',
        userName: 'User 2',
        amount: 50.0,
        paymentStatus: ExpensePaymentStatus.paid,
      ),
    ],
  );

  final tPaidUserExpense = tExistingExpense.copyWith(
    splits: const [
      ExpenseSplit(
        userId: tUserId,
        userName: 'User 1',
        amount: 50.0,
        paymentStatus: ExpensePaymentStatus.paid,
      ),
      ExpenseSplit(userId: 'user-2', userName: 'User 2', amount: 50.0),
    ],
  );

  final tReviewLockedExpense = tExistingExpense.copyWith(
    items: const [
      ExpenseItem(
        id: 'item-1',
        name: 'Item 1',
        price: 30.0,
        assignedUserIds: ['user-2'],
      ),
      ExpenseItem(id: 'item-2', name: 'Item 2', price: 20.0),
      ExpenseItem(id: 'item-3', name: 'Item 3', price: 50.0),
    ],
    splits: const [
      ExpenseSplit(userId: tUserId, userName: 'User 1', amount: 50.0),
      ExpenseSplit(
        userId: 'user-2',
        userName: 'User 2',
        amount: 50.0,
        paymentStatus: ExpensePaymentStatus.proofSubmitted,
      ),
    ],
  );

  final tReviewingUserExpense = tExistingExpense.copyWith(
    splits: const [
      ExpenseSplit(
        userId: tUserId,
        userName: 'User 1',
        amount: 50.0,
        paymentStatus: ExpensePaymentStatus.proofSubmitted,
      ),
      ExpenseSplit(userId: 'user-2', userName: 'User 2', amount: 50.0),
    ],
  );

  final tUpdatedExpense = Expense(
    id: tExpenseId,
    ownerId: 'owner-1',
    title: 'Test Expense',
    totalAmount: 100.0,
    date: DateTime(2024, 1, 15),
    status: ExpenseStatus.pending,
    type: ExpenseType.group,
    chatRoomId: 'chat-1',
    items: const [
      ExpenseItem(
        id: 'item-1',
        name: 'Item 1',
        price: 30.0,
        assignedUserIds: [tUserId],
      ),
      ExpenseItem(
        id: 'item-2',
        name: 'Item 2',
        price: 20.0,
        assignedUserIds: [tUserId],
      ),
      ExpenseItem(
        id: 'item-3',
        name: 'Item 3',
        price: 50.0,
        assignedUserIds: ['user-2'],
      ),
    ],
    splits: const [
      ExpenseSplit(
        userId: tUserId,
        userName: 'User 1',
        amount: 50.0,
        itemIds: tItemIds,
        hasSelectedItems: true,
      ),
      ExpenseSplit(
        userId: 'user-2',
        userName: 'User 2',
        amount: 50.0,
        itemIds: ['item-3'],
        hasSelectedItems: true,
      ),
    ],
  );

  group('SelectItems', () {
    test(
      'should return updated expense when items are selected successfully',
      () async {
        // arrange
        when(
          () => mockRepository.getExpenseById(tExpenseId),
        ).thenAnswer((_) async => Right(tExistingExpense));
        when(
          () => mockRepository.selectItems(
            expenseId: any(named: 'expenseId'),
            userId: any(named: 'userId'),
            itemIds: any(named: 'itemIds'),
          ),
        ).thenAnswer((_) async => Right(tUpdatedExpense));

        // act
        final result = await usecase(
          const SelectItemsParams(
            expenseId: tExpenseId,
            userId: tUserId,
            itemIds: tItemIds,
          ),
        );

        // assert
        expect(result, Right(tUpdatedExpense));
        verify(
          () => mockRepository.selectItems(
            expenseId: tExpenseId,
            userId: tUserId,
            itemIds: tItemIds,
          ),
        ).called(1);
        verify(() => mockRepository.getExpenseById(tExpenseId)).called(1);
      },
    );

    test('should return ServerFailure when expense is not found', () async {
      // arrange
      when(() => mockRepository.getExpenseById(tExpenseId)).thenAnswer(
        (_) async => const Left(ServerFailure(message: 'Expense not found')),
      );

      // act
      final result = await usecase(
        const SelectItemsParams(
          expenseId: tExpenseId,
          userId: tUserId,
          itemIds: tItemIds,
        ),
      );

      // assert
      expect(result, const Left(ServerFailure(message: 'Expense not found')));
      verifyNever(
        () => mockRepository.selectItems(
          expenseId: any(named: 'expenseId'),
          userId: any(named: 'userId'),
          itemIds: any(named: 'itemIds'),
        ),
      );
    });

    test('should return failure when user split is already paid', () async {
      // arrange
      when(
        () => mockRepository.getExpenseById(tExpenseId),
      ).thenAnswer((_) async => Right(tPaidUserExpense));

      // act
      final result = await usecase(
        const SelectItemsParams(
          expenseId: tExpenseId,
          userId: tUserId,
          itemIds: tItemIds,
        ),
      );

      // assert
      expect(
        result,
        const Left(
          InvalidInputFailure(
            message:
                'Your payment is already recorded; item selection is locked',
          ),
        ),
      );
      verifyNever(
        () => mockRepository.selectItems(
          expenseId: any(named: 'expenseId'),
          userId: any(named: 'userId'),
          itemIds: any(named: 'itemIds'),
        ),
      );
    });

    test(
      'should return failure when user payment proof is waiting for review',
      () async {
        when(
          () => mockRepository.getExpenseById(tExpenseId),
        ).thenAnswer((_) async => Right(tReviewingUserExpense));

        final result = await usecase(
          const SelectItemsParams(
            expenseId: tExpenseId,
            userId: tUserId,
            itemIds: tItemIds,
          ),
        );

        expect(
          result,
          const Left(
            InvalidInputFailure(
              message:
                  'Your payment proof is waiting for owner review; item selection is locked',
            ),
          ),
        );
        verifyNever(
          () => mockRepository.selectItems(
            expenseId: any(named: 'expenseId'),
            userId: any(named: 'userId'),
            itemIds: any(named: 'itemIds'),
          ),
        );
      },
    );

    test('should return NetworkFailure when there is no internet', () async {
      // arrange
      when(
        () => mockRepository.getExpenseById(tExpenseId),
      ).thenAnswer((_) async => const Left(NetworkFailure()));

      // act
      final result = await usecase(
        const SelectItemsParams(
          expenseId: tExpenseId,
          userId: tUserId,
          itemIds: tItemIds,
        ),
      );

      // assert
      expect(result, const Left(NetworkFailure()));
    });

    test(
      'should return failure when changed item is locked by paid user',
      () async {
        when(
          () => mockRepository.getExpenseById(tExpenseId),
        ).thenAnswer((_) async => Right(tLockedExpense));

        final result = await usecase(
          const SelectItemsParams(
            expenseId: tExpenseId,
            userId: tUserId,
            itemIds: ['item-1'],
          ),
        );

        expect(
          result,
          const Left(
            InvalidInputFailure(
              message:
                  'This item is locked because payment is under review or already recorded',
            ),
          ),
        );
        verifyNever(
          () => mockRepository.selectItems(
            expenseId: any(named: 'expenseId'),
            userId: any(named: 'userId'),
            itemIds: any(named: 'itemIds'),
          ),
        );
      },
    );

    test(
      'should return failure when changed item is locked by user awaiting review',
      () async {
        when(
          () => mockRepository.getExpenseById(tExpenseId),
        ).thenAnswer((_) async => Right(tReviewLockedExpense));

        final result = await usecase(
          const SelectItemsParams(
            expenseId: tExpenseId,
            userId: tUserId,
            itemIds: ['item-1'],
          ),
        );

        expect(
          result,
          const Left(
            InvalidInputFailure(
              message:
                  'This item is locked because payment is under review or already recorded',
            ),
          ),
        );
        verifyNever(
          () => mockRepository.selectItems(
            expenseId: any(named: 'expenseId'),
            userId: any(named: 'userId'),
            itemIds: any(named: 'itemIds'),
          ),
        );
      },
    );

    test('should return failure when expense is already settled', () async {
      when(() => mockRepository.getExpenseById(tExpenseId)).thenAnswer(
        (_) async =>
            Right(tExistingExpense.copyWith(status: ExpenseStatus.settled)),
      );

      final result = await usecase(
        const SelectItemsParams(
          expenseId: tExpenseId,
          userId: tUserId,
          itemIds: tItemIds,
        ),
      );

      expect(
        result,
        const Left(
          InvalidInputFailure(message: 'This expense is already settled'),
        ),
      );
      verifyNever(
        () => mockRepository.selectItems(
          expenseId: any(named: 'expenseId'),
          userId: any(named: 'userId'),
          itemIds: any(named: 'itemIds'),
        ),
      );
    });

    test('should handle empty itemIds (deselecting all items)', () async {
      // arrange
      final expenseWithNoSelection = tUpdatedExpense.copyWith(
        splits: const [
          ExpenseSplit(
            userId: tUserId,
            userName: 'User 1',
            amount: 0,
            itemIds: [],
            hasSelectedItems: true,
          ),
          ExpenseSplit(
            userId: 'user-2',
            userName: 'User 2',
            amount: 100.0,
            itemIds: ['item-1', 'item-2', 'item-3'],
            hasSelectedItems: true,
          ),
        ],
      );

      when(
        () => mockRepository.getExpenseById(tExpenseId),
      ).thenAnswer((_) async => Right(tExistingExpense));
      when(
        () => mockRepository.selectItems(
          expenseId: any(named: 'expenseId'),
          userId: any(named: 'userId'),
          itemIds: any(named: 'itemIds'),
        ),
      ).thenAnswer((_) async => Right(expenseWithNoSelection));

      // act
      final result = await usecase(
        const SelectItemsParams(
          expenseId: tExpenseId,
          userId: tUserId,
          itemIds: [],
        ),
      );

      // assert
      expect(result.isRight(), true);
      result.fold((l) => fail('Expected Right'), (r) {
        final userSplit = r.splits.firstWhere((s) => s.userId == tUserId);
        expect(userSplit.itemIds, isEmpty);
      });
    });
  });

  group('SelectItemsParams', () {
    test('should have correct props', () {
      const params = SelectItemsParams(
        expenseId: tExpenseId,
        userId: tUserId,
        itemIds: tItemIds,
      );
      expect(params.props, [tExpenseId, tUserId, tItemIds]);
    });

    test('should be equal when all props are the same', () {
      const params1 = SelectItemsParams(
        expenseId: 'expense-1',
        userId: 'user-1',
        itemIds: ['item-1', 'item-2'],
      );
      const params2 = SelectItemsParams(
        expenseId: 'expense-1',
        userId: 'user-1',
        itemIds: ['item-1', 'item-2'],
      );
      expect(params1, params2);
    });

    test('should not be equal when expenseId is different', () {
      const params1 = SelectItemsParams(
        expenseId: 'expense-1',
        userId: 'user-1',
        itemIds: ['item-1'],
      );
      const params2 = SelectItemsParams(
        expenseId: 'expense-2',
        userId: 'user-1',
        itemIds: ['item-1'],
      );
      expect(params1, isNot(params2));
    });

    test('should not be equal when itemIds is different', () {
      const params1 = SelectItemsParams(
        expenseId: 'expense-1',
        userId: 'user-1',
        itemIds: ['item-1'],
      );
      const params2 = SelectItemsParams(
        expenseId: 'expense-1',
        userId: 'user-1',
        itemIds: ['item-2'],
      );
      expect(params1, isNot(params2));
    });
  });
}
