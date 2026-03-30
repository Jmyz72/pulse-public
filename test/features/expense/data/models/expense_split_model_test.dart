import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/expense/data/models/expense_split_model.dart';
import 'package:pulse/features/expense/domain/entities/expense_split.dart';

void main() {
  group('ExpenseSplitModel', () {
    final tPaidAt = DateTime(2024, 1, 16, 10, 30);

    final tSplitModel = ExpenseSplitModel(
      userId: 'user-1',
      userName: 'John Doe',
      amount: 50.0,
      itemIds: ['item-1', 'item-2'],
      isPaid: true,
      paidAt: tPaidAt,
      hasSelectedItems: true,
    );

    const tSplitModelMinimal = ExpenseSplitModel(
      userId: 'user-2',
      userName: 'Jane Doe',
      amount: 30.0,
    );

    group('constructor', () {
      test('should create ExpenseSplitModel with all fields', () {
        expect(tSplitModel.userId, 'user-1');
        expect(tSplitModel.userName, 'John Doe');
        expect(tSplitModel.amount, 50.0);
        expect(tSplitModel.itemIds, ['item-1', 'item-2']);
        expect(tSplitModel.isPaid, true);
        expect(tSplitModel.paidAt, tPaidAt);
        expect(tSplitModel.hasSelectedItems, true);
      });

      test('should create ExpenseSplitModel with default values', () {
        expect(tSplitModelMinimal.itemIds, isEmpty);
        expect(tSplitModelMinimal.isPaid, false);
        expect(tSplitModelMinimal.paidAt, isNull);
        expect(tSplitModelMinimal.hasSelectedItems, false);
      });

      test('should be a subclass of ExpenseSplit', () {
        expect(tSplitModel, isA<ExpenseSplit>());
      });
    });

    group('fromJson', () {
      test('should return valid model when JSON has all fields', () {
        final json = {
          'userId': 'user-1',
          'userName': 'John Doe',
          'amount': 50.0,
          'itemIds': ['item-1', 'item-2'],
          'isPaid': true,
          'paidAt': '2024-01-16T10:30:00.000',
          'hasSelectedItems': true,
        };

        final result = ExpenseSplitModel.fromJson(json);

        expect(result.userId, 'user-1');
        expect(result.userName, 'John Doe');
        expect(result.amount, 50.0);
        expect(result.itemIds, ['item-1', 'item-2']);
        expect(result.isPaid, true);
        expect(result.paidAt, DateTime(2024, 1, 16, 10, 30));
        expect(result.hasSelectedItems, true);
      });

      test('should handle missing userId with empty string default', () {
        final json = {'userName': 'John Doe', 'amount': 50.0};

        final result = ExpenseSplitModel.fromJson(json);

        expect(result.userId, '');
      });

      test('should handle missing userName with empty string default', () {
        final json = {'userId': 'user-1', 'amount': 50.0};

        final result = ExpenseSplitModel.fromJson(json);

        expect(result.userName, '');
      });

      test('should handle missing amount with 0.0 default', () {
        final json = {'userId': 'user-1', 'userName': 'John Doe'};

        final result = ExpenseSplitModel.fromJson(json);

        expect(result.amount, 0.0);
      });

      test('should handle missing itemIds with empty list default', () {
        final json = {
          'userId': 'user-1',
          'userName': 'John Doe',
          'amount': 50.0,
        };

        final result = ExpenseSplitModel.fromJson(json);

        expect(result.itemIds, isEmpty);
      });

      test('should handle null itemIds with empty list', () {
        final json = {
          'userId': 'user-1',
          'userName': 'John Doe',
          'amount': 50.0,
          'itemIds': null,
        };

        final result = ExpenseSplitModel.fromJson(json);

        expect(result.itemIds, isEmpty);
      });

      test('should handle missing isPaid with false default', () {
        final json = {
          'userId': 'user-1',
          'userName': 'John Doe',
          'amount': 50.0,
        };

        final result = ExpenseSplitModel.fromJson(json);

        expect(result.isPaid, false);
      });

      test('should handle missing paidAt with null', () {
        final json = {
          'userId': 'user-1',
          'userName': 'John Doe',
          'amount': 50.0,
        };

        final result = ExpenseSplitModel.fromJson(json);

        expect(result.paidAt, isNull);
      });

      test('should handle null paidAt', () {
        final json = {
          'userId': 'user-1',
          'userName': 'John Doe',
          'amount': 50.0,
          'paidAt': null,
        };

        final result = ExpenseSplitModel.fromJson(json);

        expect(result.paidAt, isNull);
      });

      test('should handle missing hasSelectedItems with false default', () {
        final json = {
          'userId': 'user-1',
          'userName': 'John Doe',
          'amount': 50.0,
        };

        final result = ExpenseSplitModel.fromJson(json);

        expect(result.hasSelectedItems, false);
      });

      test('should convert integer amount to double', () {
        final json = {'userId': 'user-1', 'userName': 'John Doe', 'amount': 50};

        final result = ExpenseSplitModel.fromJson(json);

        expect(result.amount, 50.0);
        expect(result.amount, isA<double>());
      });

      test('should convert itemIds elements to strings', () {
        final json = {
          'userId': 'user-1',
          'userName': 'John Doe',
          'amount': 50.0,
          'itemIds': [1, 2, 3],
        };

        final result = ExpenseSplitModel.fromJson(json);

        expect(result.itemIds, ['1', '2', '3']);
      });

      test('should parse ISO 8601 date string for paidAt', () {
        final json = {
          'userId': 'user-1',
          'userName': 'John Doe',
          'amount': 50.0,
          'paidAt': '2024-01-16T10:30:00.000Z',
        };

        final result = ExpenseSplitModel.fromJson(json);

        expect(result.paidAt, isA<DateTime>());
        expect(result.paidAt!.year, 2024);
        expect(result.paidAt!.month, 1);
        expect(result.paidAt!.day, 16);
      });

      test('should derive paid paymentStatus from legacy isPaid field', () {
        final json = {
          'userId': 'user-1',
          'userName': 'John Doe',
          'amount': 50.0,
          'isPaid': true,
        };

        final result = ExpenseSplitModel.fromJson(json);

        expect(result.paymentStatus, ExpensePaymentStatus.paid);
        expect(result.isPaid, true);
      });

      test('should parse new payment proof fields', () {
        final json = {
          'userId': 'user-1',
          'userName': 'John Doe',
          'amount': 50.0,
          'paymentStatus': 'proofSubmitted',
          'proofImageUrl': 'https://example.com/proof.jpg',
          'proofSubmittedAt': '2024-01-16T10:30:00.000',
          'matchedAmount': 50.0,
          'matchedRecipient': 'Jimmy Test',
          'matchConfidence': 0.91,
        };

        final result = ExpenseSplitModel.fromJson(json);

        expect(result.paymentStatus, ExpensePaymentStatus.proofSubmitted);
        expect(result.proofImageUrl, 'https://example.com/proof.jpg');
        expect(result.proofSubmittedAt, DateTime(2024, 1, 16, 10, 30));
        expect(result.matchedAmount, 50.0);
        expect(result.matchedRecipient, 'Jimmy Test');
        expect(result.matchConfidence, 0.91);
      });
    });

    group('toJson', () {
      test('should return JSON map with all fields', () {
        final result = tSplitModel.toJson();

        expect(result['userId'], 'user-1');
        expect(result['userName'], 'John Doe');
        expect(result['amount'], 50.0);
        expect(result['itemIds'], ['item-1', 'item-2']);
        expect(result['isPaid'], true);
        expect(result['paymentStatus'], 'paid');
        expect(result['paidAt'], tPaidAt.toIso8601String());
        expect(result['hasSelectedItems'], true);
      });

      test('should include default values in JSON', () {
        final result = tSplitModelMinimal.toJson();

        expect(result['itemIds'], isEmpty);
        expect(result['isPaid'], false);
        expect(result['hasSelectedItems'], false);
      });

      test('should output null for paidAt when not set', () {
        final result = tSplitModelMinimal.toJson();

        expect(result['paidAt'], isNull);
      });

      test('should format paidAt as ISO 8601 string', () {
        final result = tSplitModel.toJson();

        expect(result['paidAt'], contains('2024-01-16'));
      });
    });

    group('fromEntity', () {
      test('should create model from entity with all fields', () {
        final entity = ExpenseSplit(
          userId: 'user-1',
          userName: 'John Doe',
          amount: 50.0,
          itemIds: const ['item-1', 'item-2'],
          isPaid: true,
          paidAt: tPaidAt,
          hasSelectedItems: true,
        );

        final result = ExpenseSplitModel.fromEntity(entity);

        expect(result.userId, entity.userId);
        expect(result.userName, entity.userName);
        expect(result.amount, entity.amount);
        expect(result.itemIds, entity.itemIds);
        expect(result.isPaid, entity.isPaid);
        expect(result.paidAt, entity.paidAt);
        expect(result.hasSelectedItems, entity.hasSelectedItems);
      });

      test('should create model from entity with default values', () {
        const entity = ExpenseSplit(
          userId: 'user-1',
          userName: 'John Doe',
          amount: 30.0,
        );

        final result = ExpenseSplitModel.fromEntity(entity);

        expect(result.userId, entity.userId);
        expect(result.itemIds, isEmpty);
        expect(result.isPaid, false);
        expect(result.paidAt, isNull);
        expect(result.hasSelectedItems, false);
      });

      test('should be assignable to ExpenseSplit', () {
        const entity = ExpenseSplit(
          userId: 'user-1',
          userName: 'John Doe',
          amount: 50.0,
        );

        final result = ExpenseSplitModel.fromEntity(entity);

        expect(result, isA<ExpenseSplit>());
      });
    });

    group('round-trip conversion', () {
      test('should preserve data through toJson -> fromJson', () {
        final json = tSplitModel.toJson();
        final result = ExpenseSplitModel.fromJson(json);

        expect(result.userId, tSplitModel.userId);
        expect(result.userName, tSplitModel.userName);
        expect(result.amount, tSplitModel.amount);
        expect(result.itemIds, tSplitModel.itemIds);
        expect(result.isPaid, tSplitModel.isPaid);
        expect(result.hasSelectedItems, tSplitModel.hasSelectedItems);
      });

      test('should preserve data through fromEntity -> toJson -> fromJson', () {
        final entity = ExpenseSplit(
          userId: 'user-1',
          userName: 'John Doe',
          amount: 50.0,
          itemIds: const ['item-1'],
          isPaid: true,
          paidAt: tPaidAt,
          hasSelectedItems: true,
        );

        final model = ExpenseSplitModel.fromEntity(entity);
        final json = model.toJson();
        final result = ExpenseSplitModel.fromJson(json);

        expect(result.userId, entity.userId);
        expect(result.userName, entity.userName);
        expect(result.amount, entity.amount);
        expect(result.itemIds, entity.itemIds);
        expect(result.isPaid, entity.isPaid);
        expect(result.hasSelectedItems, entity.hasSelectedItems);
      });

      test('should preserve data with null paidAt through round-trip', () {
        final json = tSplitModelMinimal.toJson();
        final result = ExpenseSplitModel.fromJson(json);

        expect(result.paidAt, isNull);
      });
    });
  });
}
