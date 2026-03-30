import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/core/error/exceptions.dart';
import 'package:pulse/features/expense/data/validators/expense_validator.dart';
import 'package:pulse/features/expense/domain/entities/expense.dart';
import 'package:pulse/features/expense/domain/entities/expense_item.dart';
import 'package:pulse/features/expense/domain/entities/expense_split.dart';

void main() {
  final tDate = DateTime(2024, 1, 15);

  group('ExpenseValidator.validateExpense', () {
    test('should pass for valid expense', () {
      final expense = Expense(
        id: '1',
        ownerId: 'owner-1',
        title: 'Groceries',
        totalAmount: 50.0,
        date: tDate,
        splits: const [
          ExpenseSplit(userId: 'u1', userName: 'User 1', amount: 50.0),
        ],
      );
      expect(() => ExpenseValidator.validateExpense(expense), returnsNormally);
    });

    test('should throw when title is empty', () {
      final expense = Expense(
        id: '1',
        ownerId: 'owner-1',
        title: '',
        totalAmount: 50.0,
        date: tDate,
        splits: const [
          ExpenseSplit(userId: 'u1', userName: 'User 1', amount: 50.0),
        ],
      );
      expect(
        () => ExpenseValidator.validateExpense(expense),
        throwsA(isA<ServerException>()),
      );
    });

    test('should throw when totalAmount is negative', () {
      final expense = Expense(
        id: '1',
        ownerId: 'owner-1',
        title: 'Test',
        totalAmount: -1.0,
        date: tDate,
        splits: const [
          ExpenseSplit(userId: 'u1', userName: 'User 1', amount: 50.0),
        ],
      );
      expect(
        () => ExpenseValidator.validateExpense(expense),
        throwsA(isA<ServerException>()),
      );
    });

    test('should throw when ownerId is empty', () {
      final expense = Expense(
        id: '1',
        ownerId: '',
        title: 'Test',
        totalAmount: 50.0,
        date: tDate,
        splits: const [
          ExpenseSplit(userId: 'u1', userName: 'User 1', amount: 50.0),
        ],
      );
      expect(
        () => ExpenseValidator.validateExpense(expense),
        throwsA(isA<ServerException>()),
      );
    });

    test('should throw when splits is empty', () {
      final expense = Expense(
        id: '1',
        ownerId: 'owner-1',
        title: 'Test',
        totalAmount: 50.0,
        date: tDate,
        splits: const [],
      );
      expect(
        () => ExpenseValidator.validateExpense(expense),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('ExpenseValidator.validateItems', () {
    const tItems = [
      ExpenseItem(id: 'i1', name: 'Item 1', price: 10.0, quantity: 2),
      ExpenseItem(id: 'i2', name: 'Item 2', price: 5.0, quantity: 1),
    ];

    test('should pass for valid items', () {
      expect(
        () => ExpenseValidator.validateItems(tItems, taxPercent: 6.0),
        returnsNormally,
      );
    });

    test('should throw when items list is empty', () {
      expect(
        () => ExpenseValidator.validateItems(const []),
        throwsA(isA<ServerException>()),
      );
    });

    test('should throw when item price is negative', () {
      const items = [
        ExpenseItem(id: 'i1', name: 'Item 1', price: -5.0, quantity: 1),
      ];
      expect(
        () => ExpenseValidator.validateItems(items),
        throwsA(isA<ServerException>()),
      );
    });

    test('should throw when item quantity is zero', () {
      const items = [
        ExpenseItem(id: 'i1', name: 'Item 1', price: 10.0, quantity: 0),
      ];
      expect(
        () => ExpenseValidator.validateItems(items),
        throwsA(isA<ServerException>()),
      );
    });

    test('should throw when taxPercent is out of range', () {
      expect(
        () => ExpenseValidator.validateItems(tItems, taxPercent: 101.0),
        throwsA(isA<ServerException>()),
      );
    });

    test('should throw when serviceChargePercent is out of range', () {
      expect(
        () => ExpenseValidator.validateItems(tItems, serviceChargePercent: -1.0),
        throwsA(isA<ServerException>()),
      );
    });

    test('should throw when discountPercent is out of range', () {
      expect(
        () => ExpenseValidator.validateItems(tItems, discountPercent: 200.0),
        throwsA(isA<ServerException>()),
      );
    });

    test('should allow null percentages', () {
      expect(
        () => ExpenseValidator.validateItems(tItems),
        returnsNormally,
      );
    });
  });

  group('ExpenseValidator.validatePercentage', () {
    test('should pass for null value', () {
      expect(
        () => ExpenseValidator.validatePercentage(null, 'Tax'),
        returnsNormally,
      );
    });

    test('should pass for valid percentage', () {
      expect(
        () => ExpenseValidator.validatePercentage(50.0, 'Tax'),
        returnsNormally,
      );
    });

    test('should pass for 0', () {
      expect(
        () => ExpenseValidator.validatePercentage(0, 'Tax'),
        returnsNormally,
      );
    });

    test('should pass for 100', () {
      expect(
        () => ExpenseValidator.validatePercentage(100, 'Tax'),
        returnsNormally,
      );
    });

    test('should throw for negative value', () {
      expect(
        () => ExpenseValidator.validatePercentage(-1, 'Tax'),
        throwsA(isA<ServerException>()),
      );
    });

    test('should throw for value over 100', () {
      expect(
        () => ExpenseValidator.validatePercentage(101, 'Tax'),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('ExpenseValidator.validateRequiredIds', () {
    test('should pass for valid IDs', () {
      expect(
        () => ExpenseValidator.validateRequiredIds(
          expenseId: 'exp-1',
          userId: 'user-1',
        ),
        returnsNormally,
      );
    });

    test('should throw when expenseId is empty', () {
      expect(
        () => ExpenseValidator.validateRequiredIds(
          expenseId: '',
          userId: 'user-1',
        ),
        throwsA(isA<ServerException>()),
      );
    });

    test('should throw when userId is empty', () {
      expect(
        () => ExpenseValidator.validateRequiredIds(
          expenseId: 'exp-1',
          userId: '',
        ),
        throwsA(isA<ServerException>()),
      );
    });
  });
}
