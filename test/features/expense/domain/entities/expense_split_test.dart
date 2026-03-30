import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/expense/domain/entities/expense_split.dart';

void main() {
  group('ExpenseSplit', () {
    final tPaidAt = DateTime(2024, 1, 15, 10, 30);

    final tSplit = ExpenseSplit(
      userId: 'user-1',
      userName: 'John Doe',
      amount: 50.0,
      itemIds: ['item-1', 'item-2'],
      isPaid: true,
      paidAt: tPaidAt,
      hasSelectedItems: true,
    );

    group('constructor', () {
      test('should create an ExpenseSplit with required fields', () {
        const split = ExpenseSplit(
          userId: 'user-1',
          userName: 'Test User',
          amount: 25.0,
        );

        expect(split.userId, 'user-1');
        expect(split.userName, 'Test User');
        expect(split.amount, 25.0);
        expect(split.itemIds, []); // default value
        expect(split.isPaid, false); // default value
        expect(split.paidAt, null); // default value
        expect(split.hasSelectedItems, false); // default value
      });

      test('should create an ExpenseSplit with all fields', () {
        expect(tSplit.userId, 'user-1');
        expect(tSplit.userName, 'John Doe');
        expect(tSplit.amount, 50.0);
        expect(tSplit.itemIds, ['item-1', 'item-2']);
        expect(tSplit.isPaid, true);
        expect(tSplit.paidAt, tPaidAt);
        expect(tSplit.hasSelectedItems, true);
      });

      test('should handle zero amount', () {
        const split = ExpenseSplit(
          userId: 'user-1',
          userName: 'Free Loader',
          amount: 0,
        );
        expect(split.amount, 0);
      });

      test('should handle empty itemIds', () {
        const split = ExpenseSplit(
          userId: 'user-1',
          userName: 'No Items',
          amount: 10.0,
          itemIds: [],
        );
        expect(split.itemIds, isEmpty);
      });
    });

    group('copyWith', () {
      test('should return same split when no parameters are provided', () {
        final copy = tSplit.copyWith();
        expect(copy, tSplit);
      });

      test('should update userId when provided', () {
        final copy = tSplit.copyWith(userId: 'user-2');
        expect(copy.userId, 'user-2');
        expect(copy.userName, tSplit.userName);
      });

      test('should update userName when provided', () {
        final copy = tSplit.copyWith(userName: 'Jane Doe');
        expect(copy.userName, 'Jane Doe');
        expect(copy.userId, tSplit.userId);
      });

      test('should update amount when provided', () {
        final copy = tSplit.copyWith(amount: 75.0);
        expect(copy.amount, 75.0);
      });

      test('should update itemIds when provided', () {
        final copy = tSplit.copyWith(itemIds: ['item-3', 'item-4']);
        expect(copy.itemIds, ['item-3', 'item-4']);
      });

      test('should update isPaid when provided', () {
        final copy = tSplit.copyWith(isPaid: false);
        expect(copy.isPaid, false);
      });

      test('should update paidAt when provided', () {
        final newPaidAt = DateTime(2024, 2, 20);
        final copy = tSplit.copyWith(paidAt: newPaidAt);
        expect(copy.paidAt, newPaidAt);
      });

      test('should update hasSelectedItems when provided', () {
        final copy = tSplit.copyWith(hasSelectedItems: false);
        expect(copy.hasSelectedItems, false);
      });

      test('should update multiple fields', () {
        final newPaidAt = DateTime(2024, 3, 1);
        final copy = tSplit.copyWith(
          userName: 'Updated User',
          amount: 100.0,
          isPaid: false,
          paidAt: newPaidAt,
        );
        expect(copy.userName, 'Updated User');
        expect(copy.amount, 100.0);
        expect(copy.isPaid, false);
        expect(copy.paidAt, newPaidAt);
        expect(copy.userId, tSplit.userId); // unchanged
      });
    });

    group('equality', () {
      test('should be equal when all properties are the same', () {
        final split1 = ExpenseSplit(
          userId: 'user-1',
          userName: 'Test',
          amount: 50.0,
          itemIds: const ['item-1'],
          isPaid: true,
          paidAt: tPaidAt,
          hasSelectedItems: true,
        );
        final split2 = ExpenseSplit(
          userId: 'user-1',
          userName: 'Test',
          amount: 50.0,
          itemIds: const ['item-1'],
          isPaid: true,
          paidAt: tPaidAt,
          hasSelectedItems: true,
        );
        expect(split1, split2);
      });

      test('should not be equal when userId is different', () {
        const split1 = ExpenseSplit(
          userId: 'user-1',
          userName: 'Test',
          amount: 50.0,
        );
        const split2 = ExpenseSplit(
          userId: 'user-2',
          userName: 'Test',
          amount: 50.0,
        );
        expect(split1, isNot(split2));
      });

      test('should not be equal when userName is different', () {
        const split1 = ExpenseSplit(
          userId: 'user-1',
          userName: 'Test1',
          amount: 50.0,
        );
        const split2 = ExpenseSplit(
          userId: 'user-1',
          userName: 'Test2',
          amount: 50.0,
        );
        expect(split1, isNot(split2));
      });

      test('should not be equal when amount is different', () {
        const split1 = ExpenseSplit(
          userId: 'user-1',
          userName: 'Test',
          amount: 50.0,
        );
        const split2 = ExpenseSplit(
          userId: 'user-1',
          userName: 'Test',
          amount: 75.0,
        );
        expect(split1, isNot(split2));
      });

      test('should not be equal when isPaid is different', () {
        const split1 = ExpenseSplit(
          userId: 'user-1',
          userName: 'Test',
          amount: 50.0,
          isPaid: true,
        );
        const split2 = ExpenseSplit(
          userId: 'user-1',
          userName: 'Test',
          amount: 50.0,
          isPaid: false,
        );
        expect(split1, isNot(split2));
      });

      test('should not be equal when itemIds are different', () {
        const split1 = ExpenseSplit(
          userId: 'user-1',
          userName: 'Test',
          amount: 50.0,
          itemIds: ['item-1'],
        );
        const split2 = ExpenseSplit(
          userId: 'user-1',
          userName: 'Test',
          amount: 50.0,
          itemIds: ['item-2'],
        );
        expect(split1, isNot(split2));
      });
    });

    group('props', () {
      test('should include all properties in props', () {
        expect(tSplit.props, [
          'user-1',
          'John Doe',
          50.0,
          ['item-1', 'item-2'],
          ExpensePaymentStatus.paid,
          tPaidAt,
          true,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
        ]);
      });

      test('should include null paidAt in props', () {
        const split = ExpenseSplit(
          userId: 'user-1',
          userName: 'Test',
          amount: 25.0,
        );
        expect(split.props, [
          'user-1',
          'Test',
          25.0,
          <String>[],
          ExpensePaymentStatus.unpaid,
          null,
          false,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
        ]);
      });
    });
  });
}
