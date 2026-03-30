import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/expense/data/models/expense_item_model.dart';
import 'package:pulse/features/expense/domain/entities/expense_item.dart';

void main() {
  group('ExpenseItemModel', () {
    const tItemModel = ExpenseItemModel(
      id: 'item-1',
      name: 'Test Item',
      price: 25.0,
      quantity: 2,
      assignedUserIds: ['user-1', 'user-2'],
    );

    const tItemModelMinimal = ExpenseItemModel(
      id: 'item-2',
      name: 'Minimal Item',
      price: 10.0,
    );

    group('constructor', () {
      test('should create ExpenseItemModel with all fields', () {
        expect(tItemModel.id, 'item-1');
        expect(tItemModel.name, 'Test Item');
        expect(tItemModel.price, 25.0);
        expect(tItemModel.quantity, 2);
        expect(tItemModel.assignedUserIds, ['user-1', 'user-2']);
      });

      test('should create ExpenseItemModel with default values', () {
        expect(tItemModelMinimal.quantity, 1);
        expect(tItemModelMinimal.assignedUserIds, isEmpty);
      });

      test('should be a subclass of ExpenseItem', () {
        expect(tItemModel, isA<ExpenseItem>());
      });
    });

    group('fromJson', () {
      test('should return valid model when JSON has all fields', () {
        final json = {
          'id': 'item-1',
          'name': 'Test Item',
          'price': 25.0,
          'quantity': 2,
          'assignedUserIds': ['user-1', 'user-2'],
        };

        final result = ExpenseItemModel.fromJson(json);

        expect(result.id, 'item-1');
        expect(result.name, 'Test Item');
        expect(result.price, 25.0);
        expect(result.quantity, 2);
        expect(result.assignedUserIds, ['user-1', 'user-2']);
      });

      test('should handle missing id with empty string default', () {
        final json = {
          'name': 'Test Item',
          'price': 25.0,
        };

        final result = ExpenseItemModel.fromJson(json);

        expect(result.id, '');
      });

      test('should handle missing name with empty string default', () {
        final json = {
          'id': 'item-1',
          'price': 25.0,
        };

        final result = ExpenseItemModel.fromJson(json);

        expect(result.name, '');
      });

      test('should handle missing price with 0.0 default', () {
        final json = {
          'id': 'item-1',
          'name': 'Test Item',
        };

        final result = ExpenseItemModel.fromJson(json);

        expect(result.price, 0.0);
      });

      test('should handle missing quantity with 1 default', () {
        final json = {
          'id': 'item-1',
          'name': 'Test Item',
          'price': 25.0,
        };

        final result = ExpenseItemModel.fromJson(json);

        expect(result.quantity, 1);
      });

      test('should handle missing assignedUserIds with empty list default', () {
        final json = {
          'id': 'item-1',
          'name': 'Test Item',
          'price': 25.0,
        };

        final result = ExpenseItemModel.fromJson(json);

        expect(result.assignedUserIds, isEmpty);
      });

      test('should handle null assignedUserIds with empty list', () {
        final json = {
          'id': 'item-1',
          'name': 'Test Item',
          'price': 25.0,
          'assignedUserIds': null,
        };

        final result = ExpenseItemModel.fromJson(json);

        expect(result.assignedUserIds, isEmpty);
      });

      test('should convert integer price to double', () {
        final json = {
          'id': 'item-1',
          'name': 'Test Item',
          'price': 25,
        };

        final result = ExpenseItemModel.fromJson(json);

        expect(result.price, 25.0);
        expect(result.price, isA<double>());
      });

      test('should convert assignedUserIds elements to strings', () {
        final json = {
          'id': 'item-1',
          'name': 'Test Item',
          'price': 25.0,
          'assignedUserIds': [1, 2, 3],
        };

        final result = ExpenseItemModel.fromJson(json);

        expect(result.assignedUserIds, ['1', '2', '3']);
      });
    });

    group('toJson', () {
      test('should return JSON map with all fields', () {
        final result = tItemModel.toJson();

        expect(result['id'], 'item-1');
        expect(result['name'], 'Test Item');
        expect(result['price'], 25.0);
        expect(result['quantity'], 2);
        expect(result['assignedUserIds'], ['user-1', 'user-2']);
      });

      test('should include default values in JSON', () {
        final result = tItemModelMinimal.toJson();

        expect(result['quantity'], 1);
        expect(result['assignedUserIds'], isEmpty);
      });
    });

    group('fromEntity', () {
      test('should create model from entity with all fields', () {
        const entity = ExpenseItem(
          id: 'item-1',
          name: 'Test Item',
          price: 25.0,
          quantity: 2,
          assignedUserIds: ['user-1', 'user-2'],
        );

        final result = ExpenseItemModel.fromEntity(entity);

        expect(result.id, entity.id);
        expect(result.name, entity.name);
        expect(result.price, entity.price);
        expect(result.quantity, entity.quantity);
        expect(result.assignedUserIds, entity.assignedUserIds);
      });

      test('should create model from entity with default values', () {
        const entity = ExpenseItem(
          id: 'item-1',
          name: 'Test Item',
          price: 10.0,
        );

        final result = ExpenseItemModel.fromEntity(entity);

        expect(result.id, entity.id);
        expect(result.quantity, 1);
        expect(result.assignedUserIds, isEmpty);
      });

      test('should be assignable to ExpenseItem', () {
        const entity = ExpenseItem(
          id: 'item-1',
          name: 'Test Item',
          price: 25.0,
        );

        final result = ExpenseItemModel.fromEntity(entity);

        expect(result, isA<ExpenseItem>());
      });
    });

    group('round-trip conversion', () {
      test('should preserve data through toJson -> fromJson', () {
        final json = tItemModel.toJson();
        final result = ExpenseItemModel.fromJson(json);

        expect(result.id, tItemModel.id);
        expect(result.name, tItemModel.name);
        expect(result.price, tItemModel.price);
        expect(result.quantity, tItemModel.quantity);
        expect(result.assignedUserIds, tItemModel.assignedUserIds);
      });

      test('should preserve data through fromEntity -> toJson -> fromJson', () {
        const entity = ExpenseItem(
          id: 'item-1',
          name: 'Test Item',
          price: 25.0,
          quantity: 3,
          assignedUserIds: ['user-1'],
        );

        final model = ExpenseItemModel.fromEntity(entity);
        final json = model.toJson();
        final result = ExpenseItemModel.fromJson(json);

        expect(result.id, entity.id);
        expect(result.name, entity.name);
        expect(result.price, entity.price);
        expect(result.quantity, entity.quantity);
        expect(result.assignedUserIds, entity.assignedUserIds);
      });
    });

    group('inherited functionality', () {
      test('should calculate subtotal correctly', () {
        expect(tItemModel.subtotal, 50.0); // 25.0 * 2
      });

      test('should calculate costPerPerson correctly', () {
        expect(tItemModel.costPerPerson, 25.0); // 50.0 / 2 users
      });

      test('should return true for isAssigned when has users', () {
        expect(tItemModel.isAssigned, true);
      });

      test('should return correct isAssignedTo result', () {
        expect(tItemModel.isAssignedTo('user-1'), true);
        expect(tItemModel.isAssignedTo('user-3'), false);
      });
    });
  });
}
