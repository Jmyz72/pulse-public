import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/expense/domain/entities/expense_item.dart';

void main() {
  group('ExpenseItem', () {
    const tItem = ExpenseItem(
      id: 'item-1',
      name: 'Nasi Lemak',
      price: 10.0,
      quantity: 2,
      assignedUserIds: ['user-1', 'user-2'],
    );

    group('constructor', () {
      test('should create an ExpenseItem with required fields', () {
        const item = ExpenseItem(
          id: 'item-1',
          name: 'Test Item',
          price: 15.0,
        );

        expect(item.id, 'item-1');
        expect(item.name, 'Test Item');
        expect(item.price, 15.0);
        expect(item.quantity, 1); // default value
        expect(item.assignedUserIds, []); // default value
      });

      test('should create an ExpenseItem with all fields', () {
        expect(tItem.id, 'item-1');
        expect(tItem.name, 'Nasi Lemak');
        expect(tItem.price, 10.0);
        expect(tItem.quantity, 2);
        expect(tItem.assignedUserIds, ['user-1', 'user-2']);
      });
    });

    group('subtotal', () {
      test('should calculate subtotal correctly', () {
        expect(tItem.subtotal, 20.0); // 10.0 * 2
      });

      test('should return price when quantity is 1', () {
        const item = ExpenseItem(
          id: 'item-1',
          name: 'Single Item',
          price: 25.0,
          quantity: 1,
        );
        expect(item.subtotal, 25.0);
      });

      test('should return 0 when price is 0', () {
        const item = ExpenseItem(
          id: 'item-1',
          name: 'Free Item',
          price: 0,
          quantity: 5,
        );
        expect(item.subtotal, 0);
      });
    });

    group('costPerPerson', () {
      test('should calculate cost per person correctly when users are assigned', () {
        expect(tItem.costPerPerson, 10.0); // 20.0 / 2 users
      });

      test('should return full subtotal when no users are assigned', () {
        const item = ExpenseItem(
          id: 'item-1',
          name: 'Unassigned Item',
          price: 30.0,
          quantity: 2,
          assignedUserIds: [],
        );
        expect(item.costPerPerson, 60.0); // full subtotal
      });

      test('should return full subtotal when assigned to one person', () {
        const item = ExpenseItem(
          id: 'item-1',
          name: 'Solo Item',
          price: 15.0,
          quantity: 2,
          assignedUserIds: ['user-1'],
        );
        expect(item.costPerPerson, 30.0);
      });
    });

    group('isAssigned', () {
      test('should return true when users are assigned', () {
        expect(tItem.isAssigned, true);
      });

      test('should return false when no users are assigned', () {
        const item = ExpenseItem(
          id: 'item-1',
          name: 'Unassigned Item',
          price: 10.0,
        );
        expect(item.isAssigned, false);
      });
    });

    group('isAssignedTo', () {
      test('should return true when user is in assigned list', () {
        expect(tItem.isAssignedTo('user-1'), true);
        expect(tItem.isAssignedTo('user-2'), true);
      });

      test('should return false when user is not in assigned list', () {
        expect(tItem.isAssignedTo('user-3'), false);
      });

      test('should return false when no users are assigned', () {
        const item = ExpenseItem(
          id: 'item-1',
          name: 'Unassigned Item',
          price: 10.0,
        );
        expect(item.isAssignedTo('user-1'), false);
      });
    });

    group('copyWith', () {
      test('should return same item when no parameters are provided', () {
        final copy = tItem.copyWith();
        expect(copy, tItem);
      });

      test('should update id when provided', () {
        final copy = tItem.copyWith(id: 'new-id');
        expect(copy.id, 'new-id');
        expect(copy.name, tItem.name);
      });

      test('should update name when provided', () {
        final copy = tItem.copyWith(name: 'New Name');
        expect(copy.name, 'New Name');
        expect(copy.id, tItem.id);
      });

      test('should update price when provided', () {
        final copy = tItem.copyWith(price: 99.99);
        expect(copy.price, 99.99);
      });

      test('should update quantity when provided', () {
        final copy = tItem.copyWith(quantity: 5);
        expect(copy.quantity, 5);
      });

      test('should update assignedUserIds when provided', () {
        final copy = tItem.copyWith(assignedUserIds: ['user-3']);
        expect(copy.assignedUserIds, ['user-3']);
      });

      test('should update multiple fields', () {
        final copy = tItem.copyWith(
          name: 'Updated Name',
          price: 50.0,
          quantity: 3,
        );
        expect(copy.name, 'Updated Name');
        expect(copy.price, 50.0);
        expect(copy.quantity, 3);
        expect(copy.id, tItem.id); // unchanged
      });
    });

    group('equality', () {
      test('should be equal when all properties are the same', () {
        const item1 = ExpenseItem(
          id: 'item-1',
          name: 'Test',
          price: 10.0,
          quantity: 2,
          assignedUserIds: ['user-1'],
        );
        const item2 = ExpenseItem(
          id: 'item-1',
          name: 'Test',
          price: 10.0,
          quantity: 2,
          assignedUserIds: ['user-1'],
        );
        expect(item1, item2);
      });

      test('should not be equal when id is different', () {
        const item1 = ExpenseItem(id: 'item-1', name: 'Test', price: 10.0);
        const item2 = ExpenseItem(id: 'item-2', name: 'Test', price: 10.0);
        expect(item1, isNot(item2));
      });

      test('should not be equal when name is different', () {
        const item1 = ExpenseItem(id: 'item-1', name: 'Test1', price: 10.0);
        const item2 = ExpenseItem(id: 'item-1', name: 'Test2', price: 10.0);
        expect(item1, isNot(item2));
      });

      test('should not be equal when price is different', () {
        const item1 = ExpenseItem(id: 'item-1', name: 'Test', price: 10.0);
        const item2 = ExpenseItem(id: 'item-1', name: 'Test', price: 20.0);
        expect(item1, isNot(item2));
      });
    });

    group('props', () {
      test('should include all properties in props', () {
        expect(tItem.props, [
          'item-1',
          'Nasi Lemak',
          10.0,
          2,
          ['user-1', 'user-2'],
        ]);
      });
    });
  });
}
