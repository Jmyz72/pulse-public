import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/expense/data/models/expense_model.dart';
import 'package:pulse/features/expense/data/models/expense_item_model.dart';
import 'package:pulse/features/expense/data/models/expense_split_model.dart';
import 'package:pulse/features/expense/domain/entities/expense.dart';
import 'package:pulse/features/expense/domain/entities/expense_item.dart';
import 'package:pulse/features/expense/domain/entities/expense_split.dart';

void main() {
  group('ExpenseModel', () {
    final tDate = DateTime(2024, 1, 15);
    final tPaidAt = DateTime(2024, 1, 16);

    final tExpenseModel = ExpenseModel(
      id: 'expense-1',
      ownerId: 'owner-1',
      chatRoomId: 'chat-1',
      title: 'Test Expense',
      description: 'Test description',
      totalAmount: 100.0,
      date: tDate,
      status: ExpenseStatus.pending,
      type: ExpenseType.group,
      items: const [
        ExpenseItemModel(
          id: 'item-1',
          name: 'Item 1',
          price: 50.0,
          quantity: 1,
          assignedUserIds: ['user-1'],
        ),
        ExpenseItemModel(
          id: 'item-2',
          name: 'Item 2',
          price: 50.0,
          quantity: 1,
          assignedUserIds: ['user-2'],
        ),
      ],
      taxPercent: 10.0,
      serviceChargePercent: 5.0,
      discountPercent: 2.0,
      splits: [
        ExpenseSplitModel(
          userId: 'user-1',
          userName: 'User 1',
          amount: 50.0,
          itemIds: const ['item-1'],
          isPaid: true,
          paidAt: tPaidAt,
          hasSelectedItems: true,
        ),
        const ExpenseSplitModel(
          userId: 'user-2',
          userName: 'User 2',
          amount: 50.0,
          itemIds: ['item-2'],
          hasSelectedItems: true,
        ),
      ],
      masterExpenseId: null,
      linkedExpenseIds: null,
      adHocParticipantIds: null,
      imageUrl: 'https://example.com/receipt.jpg',
    );

    final tExpenseModelMinimal = ExpenseModel(
      id: 'expense-2',
      ownerId: 'owner-1',
      title: 'Minimal Expense',
      totalAmount: 50.0,
      date: tDate,
    );

    final tAdHocMasterModel = ExpenseModel(
      id: 'master-1',
      ownerId: 'owner-1',
      title: 'Ad-hoc Expense',
      totalAmount: 150.0,
      date: tDate,
      type: ExpenseType.adHoc,
      linkedExpenseIds: const ['linked-1', 'linked-2'],
      adHocParticipantIds: const ['user-1', 'user-2', 'user-3'],
    );

    final tAdHocLinkedModel = ExpenseModel(
      id: 'linked-1',
      ownerId: 'owner-1',
      chatRoomId: 'chat-1',
      title: 'Ad-hoc Expense',
      totalAmount: 150.0,
      date: tDate,
      type: ExpenseType.adHoc,
      masterExpenseId: 'master-1',
    );

    group('constructor', () {
      test('should create ExpenseModel with all fields', () {
        expect(tExpenseModel.id, 'expense-1');
        expect(tExpenseModel.ownerId, 'owner-1');
        expect(tExpenseModel.chatRoomId, 'chat-1');
        expect(tExpenseModel.title, 'Test Expense');
        expect(tExpenseModel.description, 'Test description');
        expect(tExpenseModel.totalAmount, 100.0);
        expect(tExpenseModel.date, tDate);
        expect(tExpenseModel.status, ExpenseStatus.pending);
        expect(tExpenseModel.type, ExpenseType.group);
        expect(tExpenseModel.items.length, 2);
        expect(tExpenseModel.taxPercent, 10.0);
        expect(tExpenseModel.serviceChargePercent, 5.0);
        expect(tExpenseModel.discountPercent, 2.0);
        expect(tExpenseModel.splits.length, 2);
        expect(tExpenseModel.imageUrl, 'https://example.com/receipt.jpg');
      });

      test('should create ExpenseModel with default values', () {
        expect(tExpenseModelMinimal.chatRoomId, isNull);
        expect(tExpenseModelMinimal.description, isNull);
        expect(tExpenseModelMinimal.status, ExpenseStatus.pending);
        expect(tExpenseModelMinimal.type, ExpenseType.group);
        expect(tExpenseModelMinimal.items, isEmpty);
        expect(tExpenseModelMinimal.taxPercent, isNull);
        expect(tExpenseModelMinimal.serviceChargePercent, isNull);
        expect(tExpenseModelMinimal.discountPercent, isNull);
        expect(tExpenseModelMinimal.splits, isEmpty);
        expect(tExpenseModelMinimal.masterExpenseId, isNull);
        expect(tExpenseModelMinimal.linkedExpenseIds, isNull);
        expect(tExpenseModelMinimal.adHocParticipantIds, isNull);
        expect(tExpenseModelMinimal.imageUrl, isNull);
      });

      test('should be a subclass of Expense', () {
        expect(tExpenseModel, isA<Expense>());
      });
    });

    group('fromJson', () {
      test('should return valid model when JSON has all fields', () {
        final json = {
          'id': 'expense-1',
          'ownerId': 'owner-1',
          'chatRoomId': 'chat-1',
          'title': 'Test Expense',
          'description': 'Test description',
          'totalAmount': 100.0,
          'date': '2024-01-15T00:00:00.000',
          'status': 'pending',
          'type': 'group',
          'items': [
            {'id': 'item-1', 'name': 'Item 1', 'price': 50.0},
          ],
          'taxPercent': 10.0,
          'serviceChargePercent': 5.0,
          'discountPercent': 2.0,
          'splits': [
            {'userId': 'user-1', 'userName': 'User 1', 'amount': 50.0},
          ],
          'masterExpenseId': 'master-1',
          'linkedExpenseIds': ['linked-1'],
          'adHocParticipantIds': ['user-1', 'user-2'],
          'imageUrl': 'https://example.com/receipt.jpg',
        };

        final result = ExpenseModel.fromJson(json);

        expect(result.id, 'expense-1');
        expect(result.ownerId, 'owner-1');
        expect(result.chatRoomId, 'chat-1');
        expect(result.title, 'Test Expense');
        expect(result.description, 'Test description');
        expect(result.totalAmount, 100.0);
        expect(result.status, ExpenseStatus.pending);
        expect(result.type, ExpenseType.group);
        expect(result.items.length, 1);
        expect(result.taxPercent, 10.0);
        expect(result.serviceChargePercent, 5.0);
        expect(result.discountPercent, 2.0);
        expect(result.splits.length, 1);
        expect(result.masterExpenseId, 'master-1');
        expect(result.linkedExpenseIds, ['linked-1']);
        expect(result.adHocParticipantIds, ['user-1', 'user-2']);
        expect(result.imageUrl, 'https://example.com/receipt.jpg');
      });

      test('should handle missing id with empty string default', () {
        final json = {
          'ownerId': 'owner-1',
          'title': 'Test',
          'totalAmount': 100.0,
          'date': '2024-01-15T00:00:00.000',
        };

        final result = ExpenseModel.fromJson(json);

        expect(result.id, '');
      });

      test('should handle userId as fallback for ownerId', () {
        final json = {
          'id': 'expense-1',
          'userId': 'user-fallback',
          'title': 'Test',
          'totalAmount': 100.0,
          'date': '2024-01-15T00:00:00.000',
        };

        final result = ExpenseModel.fromJson(json);

        expect(result.ownerId, 'user-fallback');
      });

      test('should prefer ownerId over userId when both present', () {
        final json = {
          'id': 'expense-1',
          'ownerId': 'owner-1',
          'userId': 'user-fallback',
          'title': 'Test',
          'totalAmount': 100.0,
          'date': '2024-01-15T00:00:00.000',
        };

        final result = ExpenseModel.fromJson(json);

        expect(result.ownerId, 'owner-1');
      });

      test('should handle amount as fallback for totalAmount', () {
        final json = {
          'id': 'expense-1',
          'ownerId': 'owner-1',
          'title': 'Test',
          'amount': 75.0,
          'date': '2024-01-15T00:00:00.000',
        };

        final result = ExpenseModel.fromJson(json);

        expect(result.totalAmount, 75.0);
      });

      test('should prefer totalAmount over amount when both present', () {
        final json = {
          'id': 'expense-1',
          'ownerId': 'owner-1',
          'title': 'Test',
          'totalAmount': 100.0,
          'amount': 75.0,
          'date': '2024-01-15T00:00:00.000',
        };

        final result = ExpenseModel.fromJson(json);

        expect(result.totalAmount, 100.0);
      });

      test('should handle missing date with DateTime.now()', () {
        final json = {
          'id': 'expense-1',
          'ownerId': 'owner-1',
          'title': 'Test',
          'totalAmount': 100.0,
        };

        final before = DateTime.now();
        final result = ExpenseModel.fromJson(json);
        final after = DateTime.now();

        expect(result.date.isAfter(before.subtract(const Duration(seconds: 1))), true);
        expect(result.date.isBefore(after.add(const Duration(seconds: 1))), true);
      });

      test('should parse status as pending by default', () {
        final json = {
          'id': 'expense-1',
          'ownerId': 'owner-1',
          'title': 'Test',
          'totalAmount': 100.0,
          'date': '2024-01-15T00:00:00.000',
        };

        final result = ExpenseModel.fromJson(json);

        expect(result.status, ExpenseStatus.pending);
      });

      test('should parse status as settled', () {
        final json = {
          'id': 'expense-1',
          'ownerId': 'owner-1',
          'title': 'Test',
          'totalAmount': 100.0,
          'date': '2024-01-15T00:00:00.000',
          'status': 'settled',
        };

        final result = ExpenseModel.fromJson(json);

        expect(result.status, ExpenseStatus.settled);
      });

      test('should parse type as group by default', () {
        final json = {
          'id': 'expense-1',
          'ownerId': 'owner-1',
          'title': 'Test',
          'totalAmount': 100.0,
          'date': '2024-01-15T00:00:00.000',
        };

        final result = ExpenseModel.fromJson(json);

        expect(result.type, ExpenseType.group);
      });

      test('should parse type as oneOnOne', () {
        final json = {
          'id': 'expense-1',
          'ownerId': 'owner-1',
          'title': 'Test',
          'totalAmount': 100.0,
          'date': '2024-01-15T00:00:00.000',
          'type': 'oneOnOne',
        };

        final result = ExpenseModel.fromJson(json);

        expect(result.type, ExpenseType.oneOnOne);
      });

      test('should parse type as adHoc', () {
        final json = {
          'id': 'expense-1',
          'ownerId': 'owner-1',
          'title': 'Test',
          'totalAmount': 100.0,
          'date': '2024-01-15T00:00:00.000',
          'type': 'adHoc',
        };

        final result = ExpenseModel.fromJson(json);

        expect(result.type, ExpenseType.adHoc);
      });

      test('should handle null items with empty list', () {
        final json = {
          'id': 'expense-1',
          'ownerId': 'owner-1',
          'title': 'Test',
          'totalAmount': 100.0,
          'date': '2024-01-15T00:00:00.000',
          'items': null,
        };

        final result = ExpenseModel.fromJson(json);

        expect(result.items, isEmpty);
      });

      test('should handle null splits with empty list', () {
        final json = {
          'id': 'expense-1',
          'ownerId': 'owner-1',
          'title': 'Test',
          'totalAmount': 100.0,
          'date': '2024-01-15T00:00:00.000',
          'splits': null,
        };

        final result = ExpenseModel.fromJson(json);

        expect(result.splits, isEmpty);
      });

      test('should convert integer totalAmount to double', () {
        final json = {
          'id': 'expense-1',
          'ownerId': 'owner-1',
          'title': 'Test',
          'totalAmount': 100,
          'date': '2024-01-15T00:00:00.000',
        };

        final result = ExpenseModel.fromJson(json);

        expect(result.totalAmount, 100.0);
        expect(result.totalAmount, isA<double>());
      });

      test('should convert integer taxPercent to double', () {
        final json = {
          'id': 'expense-1',
          'ownerId': 'owner-1',
          'title': 'Test',
          'totalAmount': 100.0,
          'date': '2024-01-15T00:00:00.000',
          'taxPercent': 10,
        };

        final result = ExpenseModel.fromJson(json);

        expect(result.taxPercent, 10.0);
        expect(result.taxPercent, isA<double>());
      });

      test('should convert linkedExpenseIds elements to strings', () {
        final json = {
          'id': 'expense-1',
          'ownerId': 'owner-1',
          'title': 'Test',
          'totalAmount': 100.0,
          'date': '2024-01-15T00:00:00.000',
          'linkedExpenseIds': [1, 2, 3],
        };

        final result = ExpenseModel.fromJson(json);

        expect(result.linkedExpenseIds, ['1', '2', '3']);
      });

      test('should parse items correctly', () {
        final json = {
          'id': 'expense-1',
          'ownerId': 'owner-1',
          'title': 'Test',
          'totalAmount': 100.0,
          'date': '2024-01-15T00:00:00.000',
          'items': [
            {'id': 'item-1', 'name': 'Item 1', 'price': 30.0, 'quantity': 2},
            {'id': 'item-2', 'name': 'Item 2', 'price': 40.0},
          ],
        };

        final result = ExpenseModel.fromJson(json);

        expect(result.items.length, 2);
        expect(result.items[0].id, 'item-1');
        expect(result.items[0].price, 30.0);
        expect(result.items[0].quantity, 2);
        expect(result.items[1].id, 'item-2');
        expect(result.items[1].quantity, 1);
      });

      test('should parse splits correctly', () {
        final json = {
          'id': 'expense-1',
          'ownerId': 'owner-1',
          'title': 'Test',
          'totalAmount': 100.0,
          'date': '2024-01-15T00:00:00.000',
          'splits': [
            {'userId': 'user-1', 'userName': 'User 1', 'amount': 50.0, 'isPaid': true},
            {'userId': 'user-2', 'userName': 'User 2', 'amount': 50.0},
          ],
        };

        final result = ExpenseModel.fromJson(json);

        expect(result.splits.length, 2);
        expect(result.splits[0].userId, 'user-1');
        expect(result.splits[0].isPaid, true);
        expect(result.splits[1].userId, 'user-2');
        expect(result.splits[1].isPaid, false);
      });
    });

    group('toJson', () {
      test('should return JSON map with all fields', () {
        final result = tExpenseModel.toJson();

        expect(result['id'], 'expense-1');
        expect(result['ownerId'], 'owner-1');
        expect(result['chatRoomId'], 'chat-1');
        expect(result['title'], 'Test Expense');
        expect(result['description'], 'Test description');
        expect(result['totalAmount'], 100.0);
        expect(result['date'], tDate.toIso8601String());
        expect(result['status'], 'pending');
        expect(result['type'], 'group');
        expect(result['items'], isA<List>());
        expect((result['items'] as List).length, 2);
        expect(result['taxPercent'], 10.0);
        expect(result['serviceChargePercent'], 5.0);
        expect(result['discountPercent'], 2.0);
        expect(result['splits'], isA<List>());
        expect((result['splits'] as List).length, 2);
        expect(result['imageUrl'], 'https://example.com/receipt.jpg');
      });

      test('should include null values in JSON', () {
        final result = tExpenseModelMinimal.toJson();

        expect(result['chatRoomId'], isNull);
        expect(result['description'], isNull);
        expect(result['taxPercent'], isNull);
        expect(result['serviceChargePercent'], isNull);
        expect(result['discountPercent'], isNull);
        expect(result['masterExpenseId'], isNull);
        expect(result['linkedExpenseIds'], isNull);
        expect(result['adHocParticipantIds'], isNull);
        expect(result['imageUrl'], isNull);
      });

      test('should serialize status as string', () {
        final settledModel = tExpenseModel.copyWith(status: ExpenseStatus.settled);
        final modelFromEntity = ExpenseModel.fromEntity(settledModel);
        final result = modelFromEntity.toJson();

        expect(result['status'], 'settled');
      });

      test('should serialize type as string', () {
        final adHocModel = tExpenseModel.copyWith(type: ExpenseType.adHoc);
        final modelFromEntity = ExpenseModel.fromEntity(adHocModel);
        final result = modelFromEntity.toJson();

        expect(result['type'], 'adHoc');
      });

      test('should serialize items correctly', () {
        final result = tExpenseModel.toJson();
        final items = result['items'] as List;

        expect(items[0]['id'], 'item-1');
        expect(items[0]['name'], 'Item 1');
        expect(items[0]['price'], 50.0);
      });

      test('should serialize splits correctly', () {
        final result = tExpenseModel.toJson();
        final splits = result['splits'] as List;

        expect(splits[0]['userId'], 'user-1');
        expect(splits[0]['userName'], 'User 1');
        expect(splits[0]['amount'], 50.0);
        expect(splits[0]['isPaid'], true);
      });

      test('should format date as ISO 8601 string', () {
        final result = tExpenseModel.toJson();

        expect(result['date'], contains('2024-01-15'));
      });
    });

    group('fromEntity', () {
      test('should create model from entity with all fields', () {
        final entity = Expense(
          id: 'expense-1',
          ownerId: 'owner-1',
          chatRoomId: 'chat-1',
          title: 'Test Expense',
          description: 'Test description',
          totalAmount: 100.0,
          date: tDate,
          status: ExpenseStatus.pending,
          type: ExpenseType.group,
          items: const [
            ExpenseItem(id: 'item-1', name: 'Item 1', price: 50.0),
          ],
          taxPercent: 10.0,
          serviceChargePercent: 5.0,
          discountPercent: 2.0,
          splits: const [
            ExpenseSplit(userId: 'user-1', userName: 'User 1', amount: 50.0),
          ],
          masterExpenseId: 'master-1',
          linkedExpenseIds: const ['linked-1'],
          adHocParticipantIds: const ['user-1', 'user-2'],
          imageUrl: 'https://example.com/receipt.jpg',
        );

        final result = ExpenseModel.fromEntity(entity);

        expect(result.id, entity.id);
        expect(result.ownerId, entity.ownerId);
        expect(result.chatRoomId, entity.chatRoomId);
        expect(result.title, entity.title);
        expect(result.description, entity.description);
        expect(result.totalAmount, entity.totalAmount);
        expect(result.date, entity.date);
        expect(result.status, entity.status);
        expect(result.type, entity.type);
        expect(result.items.length, entity.items.length);
        expect(result.taxPercent, entity.taxPercent);
        expect(result.serviceChargePercent, entity.serviceChargePercent);
        expect(result.discountPercent, entity.discountPercent);
        expect(result.splits.length, entity.splits.length);
        expect(result.masterExpenseId, entity.masterExpenseId);
        expect(result.linkedExpenseIds, entity.linkedExpenseIds);
        expect(result.adHocParticipantIds, entity.adHocParticipantIds);
        expect(result.imageUrl, entity.imageUrl);
      });

      test('should create model from entity with default values', () {
        final entity = Expense(
          id: 'expense-1',
          ownerId: 'owner-1',
          title: 'Test',
          totalAmount: 50.0,
          date: tDate,
        );

        final result = ExpenseModel.fromEntity(entity);

        expect(result.chatRoomId, isNull);
        expect(result.description, isNull);
        expect(result.items, isEmpty);
        expect(result.splits, isEmpty);
      });

      test('should be assignable to Expense', () {
        final entity = Expense(
          id: 'expense-1',
          ownerId: 'owner-1',
          title: 'Test',
          totalAmount: 50.0,
          date: tDate,
        );

        final result = ExpenseModel.fromEntity(entity);

        expect(result, isA<Expense>());
      });
    });

    group('round-trip conversion', () {
      test('should preserve data through toJson -> fromJson', () {
        final json = tExpenseModel.toJson();
        final result = ExpenseModel.fromJson(json);

        expect(result.id, tExpenseModel.id);
        expect(result.ownerId, tExpenseModel.ownerId);
        expect(result.chatRoomId, tExpenseModel.chatRoomId);
        expect(result.title, tExpenseModel.title);
        expect(result.description, tExpenseModel.description);
        expect(result.totalAmount, tExpenseModel.totalAmount);
        expect(result.status, tExpenseModel.status);
        expect(result.type, tExpenseModel.type);
        expect(result.items.length, tExpenseModel.items.length);
        expect(result.taxPercent, tExpenseModel.taxPercent);
        expect(result.serviceChargePercent, tExpenseModel.serviceChargePercent);
        expect(result.discountPercent, tExpenseModel.discountPercent);
        expect(result.splits.length, tExpenseModel.splits.length);
        expect(result.imageUrl, tExpenseModel.imageUrl);
      });

      test('should preserve data through fromEntity -> toJson -> fromJson', () {
        final entity = Expense(
          id: 'expense-1',
          ownerId: 'owner-1',
          chatRoomId: 'chat-1',
          title: 'Test Expense',
          totalAmount: 100.0,
          date: tDate,
          status: ExpenseStatus.settled,
          type: ExpenseType.oneOnOne,
          items: const [
            ExpenseItem(id: 'item-1', name: 'Item 1', price: 50.0),
          ],
          taxPercent: 8.0,
          splits: const [
            ExpenseSplit(userId: 'user-1', userName: 'User 1', amount: 50.0, isPaid: true),
          ],
        );

        final model = ExpenseModel.fromEntity(entity);
        final json = model.toJson();
        final result = ExpenseModel.fromJson(json);

        expect(result.id, entity.id);
        expect(result.status, entity.status);
        expect(result.type, entity.type);
        expect(result.taxPercent, entity.taxPercent);
        expect(result.items.length, 1);
        expect(result.splits.length, 1);
        expect(result.splits[0].isPaid, true);
      });

      test('should preserve ad-hoc master expense through round-trip', () {
        final json = tAdHocMasterModel.toJson();
        final result = ExpenseModel.fromJson(json);

        expect(result.type, ExpenseType.adHoc);
        expect(result.linkedExpenseIds, ['linked-1', 'linked-2']);
        expect(result.adHocParticipantIds, ['user-1', 'user-2', 'user-3']);
        expect(result.masterExpenseId, isNull);
      });

      test('should preserve ad-hoc linked expense through round-trip', () {
        final json = tAdHocLinkedModel.toJson();
        final result = ExpenseModel.fromJson(json);

        expect(result.type, ExpenseType.adHoc);
        expect(result.masterExpenseId, 'master-1');
        expect(result.chatRoomId, 'chat-1');
      });
    });

    group('inherited functionality', () {
      test('should identify ad-hoc master correctly', () {
        expect(tAdHocMasterModel.isAdHocMaster, true);
        expect(tAdHocLinkedModel.isAdHocMaster, false);
      });

      test('should identify ad-hoc linked correctly', () {
        expect(tAdHocLinkedModel.isAdHocLinked, true);
        expect(tAdHocMasterModel.isAdHocLinked, false);
      });

      test('should calculate payment progress correctly', () {
        expect(tExpenseModel.paidSplitsCount, 1);
        expect(tExpenseModel.paymentProgress, '1/2 paid');
      });
    });
  });
}
